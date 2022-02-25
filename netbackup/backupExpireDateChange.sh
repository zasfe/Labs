#!/bin/bash
# written by myseit_at_gmail.com 2019-07-22
# Backup Images ExpireDate Change
# use: bash ./backupExpireDateChange.sh

TIME_RUN=`date +'%y%m%d%H%M'`;

HOSTNAME=`echo \`hostname\` | sed -e 's/\./_/g'`;
BPPATH="/usr/openv/netbackup/bin/admincmd";

workdir="/root/scriptForDB/.tmp";
BPIMAGELIST_result="${workdir}/bpimagelist.${TIME_RUN}";

if [ ! -d "${workdir}" ]; then
  mkdir -p "${workdir}"
fi
cd ${workdir}
echo ""
read -p "Search Policy Name: " bpolicy

if [ "${bpolicy}" == "" ]; then
  echo "Policy Not Exist!";
  exit 1;
fi

echo ""
echo "## Backup History ( Policy name: ${bpolicy} )";
echo ""
${BPPATH}/bpimagelist -U -d 01/01/2014 -policy ${bpolicy} > ${BPIMAGELIST_result}

cat ${BPIMAGELIST_result}
echo "";
echo "";

# Expire Date
read -p "Change Expire Date Plus date (number) : " backupexpireplusday

#echo "${backupexpireplusday}";
if [ "${backupexpireplusday}" -le 0 ]; then
  echo "Not Number.. (1~30)";
  exit 4;
fi

echo "------------------------------------------------------------------------------------------------"
bpimagelist -l -d 01/01/2014 -policy ${bpolicy} | grep -e "^IMAGE " | awk '{print$6" "$14}'  | while IFS= read bpline ; do
  backupimage_id=`echo ${bpline} | awk '{print$1}'`
  backuphistoryexiredate=`echo ${bpline} | awk '{print$2}'`
  backuphistoryexiredate=$((${backuphistoryexiredate}+$((60*60*24*${backupexpireplusday}))))
  backuphistoryexiredate=`date -d @${backuphistoryexiredate} +'%m/%d/%y'`
  echo "${BPPATH}/bpexpdate -backupid ${backupimage_id} -d ${backuphistoryexiredate} -force";
done
echo "================================================================================================"
# bpexpdate -backupid userver178-204_1431205218 -d 12/25/2015 -force

# Delete temp file
if [ -f "${BPIMAGELIST_result}" ]; then
  /bin/rm -f "${BPIMAGELIST_result}"
fi

if [ -f "${BPIMAGELIST_idonly_result}" ]; then
  /bin/rm -f "${BPIMAGELIST_idonly_result}"
fi
