#!/bin/bash
# written by myseit_at_gmail_com 2019-07-18
# Retry FailJobs On Today
# use: ./backupFailJobsRetry.sh

TIME_RUN=`date +'%y%m%d%H%M'`;

HOSTNAME=`echo \`hostname\` | sed -e 's/\./_/g'`;
BPPATH="/usr/openv/netbackup/bin/admincmd";
FAIL_BPDBJOBS="bpdbjobs_fail.${HOSTNAME}.${TIME_RUN}";
RETRY_BPDBJOBS="bpdbjobs_retry.${HOSTNAME}.${TIME_RUN}";
TIME_UNIX=`date --date="$(date +'%F')" -d '8 hour ago' +%s`

# Interact with Netbackup jobs database
# - grep BPDBJOBS_COLDEFS /usr/openv/netbackup/bp.conf
# BPDBJOBS_COLDEFS = JOBID 5 true
# BPDBJOBS_COLDEFS = TYPE 4 true
# BPDBJOBS_COLDEFS = STATE 5 true
# BPDBJOBS_COLDEFS = STATUS 6 true
# BPDBJOBS_COLDEFS = POLICY 6 true
# BPDBJOBS_COLDEFS = SCHEDULE 8 true
# BPDBJOBS_COLDEFS = CLIENT 6 true
# BPDBJOBS_COLDEFS = KILOBYTES 9 true
# BPDBJOBS_COLDEFS = STARTED 20 true
# BPDBJOBS_COLDEFS = ENDED 20 true

# Today Fail Export with Netbackup jobs database
# field1 = Job ID
# field2 = Job type (0=backup, 1=archive, 2=restore)
# field3 = State of the job (0=queued and awaiting resources, 1=active, 2=requeued and awaiting resources, 3=done, 4=suspended, 5=incomplete)
# field4 = Job status code
# field5 = Policy name for the job
# field6 = Job schedule name
# field9 = Job started time
${BPPATH}/bpdbjobs -gdm | awk -F"," -v bptime="${TIME_UNIX}" '{if ($2==0 && $3==3 && $4!=0 && $4!=1 && $4!=71 && $4!=150 && $9>bptime) print$0}' > ${FAIL_BPDBJOBS}

cat ${FAIL_BPDBJOBS} | while IFS= read bpline ; do
  bp_client=`echo ${bpline} | cut -d , -f 5`;
  bp_schedule=`echo ${bpline} | cut -d , -f 6`;
  echo "bpbackup -i -p ${bp_client} -s ${bp_schedule}"
  echo "bpbackup -i -p ${bp_client} -s ${bp_schedule}" >> ${RETRY_BPDBJOBS}
  bpbackup -i -p ${bp_client} -s ${bp_schedule}
done

# Delete Information File
[ -f ${FAIL_BPDBJOBS} ] && rm -f ${FAIL_BPDBJOBS};
[ -f ${RETRY_BPDBJOBS} ] && rm -f ${RETRY_BPDBJOBS};
