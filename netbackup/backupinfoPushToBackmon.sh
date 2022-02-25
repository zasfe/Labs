#!/bin/bash
# Backup Policy and Jobs Push BackupMon(251)
# written by myseit_at_gmail_com (190916)
# use: /backupinfoPushToBackmon.sh
#

export LANG=C.UTF-8
export PATH="${PATH}:/usr/openv/netbackup/bin/admincmd/:/usr/openv/netbackup/bin/"

HOSTNAME=`hostname`;

INFO_BPPLLIST="bppllist.${HOSTNAME}.`date +'%y%m%d%H%M'`";
INFO_BPDBJOBS="bpdbjobs.${HOSTNAME}.`date +'%y%m%d%H%M'`";

INFO_BPPL_SUMMARY="bppllistsummary.${HOSTNAME}.`date +'%y%m%d%H%M'`";
INFO_BPPL_TMP="tmp.bppl.${HOSTNAME}.`date +'%y%m%d%H%M'`";
INFO_BPPL_SUMMARY_ERROR="bppllistsummaryerror.${HOSTNAME}.`date +'%y%m%d%H%M'`";

[ -f ${INFO_BPPL_SUMMARY} ] && rm -f ${INFO_BPPL_SUMMARY}
[ -f ${INFO_BPPL_SUMMARY_ERROR} ] && rm -f ${INFO_BPPL_SUMMARY_ERROR}

# List policy infomation
bppllist | grep -v -e "^CATALOG$" > ${INFO_BPPLLIST} 2>&1

# List backup jobs
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
bpdbjobs -gdm > ${INFO_BPDBJOBS} 2>&1




cat ${INFO_BPPLLIST} | while IFS= read bpplname ; do
#  echo "bpplname=${bpplname}"
  bppllist ${bpplname} > ${INFO_BPPL_TMP}

  bppl_type=`cat ${INFO_BPPL_TMP} | grep -e "^INFO " | awk '{print$2}'`
  if [ "${bppl_type}" -eq 0 ]; then
    bppl_type="Standard/Linux"
  elif [ "${bppl_type}" -eq 13 ]; then
    bppl_type="MS-Windows"
  fi

  bppl_active=`cat ${INFO_BPPL_TMP} | grep -e "^INFO " | awk '{print$11}'`
  if [ "${bppl_active}" -eq 0 ]; then
    bppl_active="yes"
  elif [ "${bppl_active}" -eq 1 ]; then
    bppl_active="no"
  fi

  bppl_client=`cat ${INFO_BPPL_TMP}  | grep -e "^CLIENT " | awk '{print$2}'`
  bppl_clientip=`bpclntcmd -hn ${bppl_client} | head -n 1 | awk '{print$5}'`

  bppl_dir=`cat ${INFO_BPPL_TMP} | grep -e "^INCLUDE " | sed -e 's/^INCLUDE //g'`

  bppl_storage=`cat ${INFO_BPPL_TMP} | grep -e "^RES " | awk '{print$2}'`

  chk_daily_incr_num=`cat ${INFO_BPPL_TMP} | grep -e "^SCHED " | grep daily_std_incr | wc -l`
  chk_daily_incr="0"
  if [ "${chk_daily_incr_num}" -ne 0 ]; then
    chk_daily_incr="1"
  fi
  chk_daily_full_num=`cat ${INFO_BPPL_TMP} | grep -e "^SCHED " | grep daily_std_full | wc -l`
  chk_daily_full="0"
  if [ "${chk_daily_full_num}" -ne 0 ]; then
    chk_daily_full="1"
  fi
  chk_daily_syn_num=`cat ${INFO_BPPL_TMP} | grep -e "^SCHED " | grep daily_syn_full | wc -l`
  chk_daily_syn="0"
  if [ "${chk_daily_syn_num}" -ne 0 ]; then
    chk_daily_syn="1"
  fi
  chk_weekly_full_num=`cat ${INFO_BPPL_TMP} | grep -e "^SCHED " | grep weekly_std_full | wc -l`
  chk_weekly_full="0"
  if [ "${chk_weekly_full_num}" -ne 0 ]; then
    chk_weekly_full="1"
  fi

  case "${chk_daily_incr}${chk_daily_full}${chk_weekly_full}${chk_daily_syn}" in
    000?)
      # No Schedule
      echo "${bpplname},no Schedule" >> ${INFO_BPPL_SUMMARY_ERROR}
      bppl_dailyname="-"
      bppl_daily_schedule_time_hour="00"
      bppl_daily_schedule_time_minute="00"
      bppl_daily_schedule_time_lastrun="-"

      bppl_weeklyname="-"
      bppl_weekly_schedule_dayname="-"
      bppl_weekly_schedule_time_hour="00"
      bppl_weekly_schedule_time_minute="00"
      bppl_weekly_schedule_time_lastrun="-"
      ;;
    010?)
      # daily full only
      bppl_dailyname="daily_std_full"
      chk_dupl=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_dailyname} | wc -l`
      if [ "${chk_dupl}" -ne 1 ]; then
        echo "${bpplname},${bppl_dailyname} is duplicate" >> ${INFO_BPPL_SUMMARY_ERROR}
      fi

      bppl_schedule_type=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_dailyname} | head -n 1 | awk '{print$3}'`

      bppl_schedule_lineNumber=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_dailyname} | head -n 1 | awk -F: '{print$1}'`

      bppl_schedule_lineNumber="$((${bppl_schedule_lineNumber}+1))"

      bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$2}'`
      bppl_schedule_time_tmp_minute=`expr ${bppl_schedule_time_tmp} % $((60*60))`
      bppl_daily_schedule_time_hour=$(( $(( ${bppl_schedule_time_tmp} - ${bppl_schedule_time_tmp_minute} )) / $((60*60)) ))
      bppl_daily_schedule_time_minute=$(( ${bppl_schedule_time_tmp_minute} / 60 ))


      bppl_daily_schedule_time_hour="000${bppl_daily_schedule_time_hour}"
      bppl_daily_schedule_time_hour="${bppl_daily_schedule_time_hour:${#bppl_daily_schedule_time_hour}-2}"

      bppl_daily_schedule_time_minute="000${bppl_daily_schedule_time_minute}"
     bppl_daily_schedule_time_minute="${bppl_daily_schedule_time_minute:${#bppl_daily_schedule_time_minute}-2}"

      bppl_schedule_time_tmp=`cat ${INFO_BPDBJOBS} | grep ",${bpplname}," | grep ",${bppl_dailyname}," | awk -F, '{print$11}' | head -n 1 `
      if [[ ${bppl_schedule_time_tmp} =~ ^[0-9]+$ ]]; then
        bppl_daily_schedule_time_lastrun=`date -d @${bppl_schedule_time_tmp} +"%F %X"`
      else
        bppl_daily_schedule_time_lastrun="-"
      fi

      bppl_weeklyname="-"
      bppl_weekly_schedule_dayname="-"
      bppl_weekly_schedule_time_hour="00"
      bppl_weekly_schedule_time_minute="00"
      bppl_weekly_schedule_time_lastrun="-"
      ;;
    111?)
      # weekly full + daily incr

      bppl_dailyname="daily_std_incr"
      chk_dupl=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_dailyname} | wc -l`
      if [ "${chk_dupl}" -ne 1 ]; then
        echo "${bpplname},${bppl_dailyname} is duplicate" >> ${INFO_BPPL_SUMMARY_ERROR}
      fi

      bppl_schedule_type=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_dailyname} | head -n 1 | awk '{print$3}'`

      bppl_schedule_lineNumber=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_dailyname} |head -n 1 | awk -F: '{print$1}'`
      bppl_schedule_lineNumber="$((${bppl_schedule_lineNumber}+1))"

      bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$2}'`
      bppl_schedule_time_tmp_minute=`expr ${bppl_schedule_time_tmp} % $((60*60))`
      bppl_daily_schedule_time_hour=$(( $(( ${bppl_schedule_time_tmp} - ${bppl_schedule_time_tmp_minute} )) / $((60*60)) ))
      bppl_daily_schedule_time_minute=$(( ${bppl_schedule_time_tmp_minute} / 60 ))
      bppl_schedule_time_tmp=`cat ${INFO_BPDBJOBS} | grep ",${bpplname}," | grep ",${bppl_dailyname}," | awk -F, '{print$11}' | head -n 1 `
      if [[ ${bppl_schedule_time_tmp} =~ ^[0-9]+$ ]]; then
        bppl_daily_schedule_time_lastrun=`date -d @${bppl_schedule_time_tmp} +"%F %X"`
      else
        bppl_daily_schedule_time_lastrun="-"
      fi

      bppl_weeklyname="weekly_std_full"
      chk_dupl=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED" |  grep ${bppl_weeklyname} | wc -l`
      if [ "${chk_dupl}" -ne 1 ]; then
        echo "${bpplname},${bppl_weeklyname} is duplicate" >> ${INFO_BPPL_SUMMARY_ERROR}
      fi

      bppl_schedule_type=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED " | grep ${bppl_weeklyname} | head -n 1 | awk '{print$3}'`

      bppl_schedule_lineNumber=`cat ${INFO_BPPL_TMP} | grep -n . | grep ":SCHED" | grep ${bppl_weeklyname} | head -n 1 | awk -F: '{print$1}'`
      bppl_schedule_lineNumber="$((${bppl_schedule_lineNumber}+1))"

      bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$2}'`
      bppl_weekly_schedule_dayname="sun"
      if [ "${bppl_schedule_time_tmp}" -eq 0 ]; then
        bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$4}'`
        bppl_weekly_schedule_dayname="mon"
      fi

      if [ "${bppl_schedule_time_tmp}" -eq 0 ]; then
        bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$6}'`
        bppl_weekly_schedule_dayname="tue"
      fi

      if [ "${bppl_schedule_time_tmp}" -eq 0 ]; then
       bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$8}'`
       bppl_weekly_schedule_dayname="wed"
      fi

      if [ "${bppl_schedule_time_tmp}" -eq 0 ]; then
       bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$10}'`
       bppl_weekly_schedule_dayname="thu"
      fi

      if [ "${bppl_schedule_time_tmp}" -eq 0 ]; then
       bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$12}'`
       bppl_weekly_schedule_dayname="fri"
      fi

      if [ "${bppl_schedule_time_tmp}" -eq 0 ]; then
       bppl_schedule_time_tmp=`cat ${INFO_BPPL_TMP} | sed -n "${bppl_schedule_lineNumber}p" | awk '{print$14}'`
       bppl_weekly_schedule_dayname="sat"
      fi

      bppl_schedule_time_tmp_minute=`expr ${bppl_schedule_time_tmp} % $((60*60))`
      bppl_weekly_schedule_time_hour=$(( $(( ${bppl_schedule_time_tmp} - ${bppl_schedule_time_tmp_minute} )) / $((60*60)) ))
      bppl_weekly_schedule_time_minute=$(( ${bppl_schedule_time_tmp_minute} / 60 ))

      bppl_daily_schedule_time_hour="000${bppl_daily_schedule_time_hour}"
      bppl_daily_schedule_time_hour="${bppl_daily_schedule_time_hour:${#bppl_daily_schedule_time_hour}-2}"

      bppl_daily_schedule_time_minute="000${bppl_daily_schedule_time_minute}"
      bppl_daily_schedule_time_minute="${bppl_daily_schedule_time_minute:${#bppl_daily_schedule_time_minute}-2}"

      bppl_weekly_schedule_time_hour="000${bppl_weekly_schedule_time_hour}"
      bppl_weekly_schedule_time_hour="${bppl_weekly_schedule_time_hour:${#bppl_weekly_schedule_time_hour}-2}"

      bppl_schedule_time_tmp=`cat ${INFO_BPDBJOBS} | grep ",${bpplname}," | grep ",${bppl_weeklyname}," | awk -F, '{print$11}' | head -n 1 `
      if [[ ${bppl_schedule_time_tmp} =~ ^[0-9]+$ ]]; then
        bppl_weekly_schedule_time_lastrun=`date -d @${bppl_schedule_time_tmp} +"%F %X"`
      else
        bppl_weekly_schedule_time_lastrun="-"
      fi

      ;;
    *)
      echo "${bpplname} is not current (daily_incr_Count=${chk_daily_incr_num}/daily_full_Count=${chk_daily_full_num}/weekly_full_Count=${chk_weekly_full_num})" >> ${INFO_BPPL_SUMMARY_ERROR}
      ;;
  esac


  echo "${HOSTNAME},${bpplname},${bppl_type},${bppl_active},${bppl_client},${bppl_clientip},${bppl_storage},${bppl_dailyname},${bppl_daily_schedule_time_hour}:${bppl_daily_schedule_time_minute},${bppl_daily_schedule_time_lastrun},${bppl_weeklyname},${bppl_weekly_schedule_dayname},${bppl_weekly_schedule_time_hour}:${bppl_weekly_schedule_time_minute},${bppl_weekly_schedule_time_lastrun},\"${bppl_dir}\"" >> ${INFO_BPPL_SUMMARY}

done
# Delete Information File
echo "# Delete Information File"
[ -f ${INFO_BPPLLIST} ] && rm -f ${INFO_BPPLLIST};
[ -f ${INFO_BPDBJOBS} ] && rm -f ${INFO_BPDBJOBS};
[ -f ${INFO_BPPL_SUMMARY} ] && rm -f ${INFO_BPPL_SUMMARY}
[ -f ${INFO_BPPL_TMP} ] && rm -f ${INFO_BPPL_TMP}
[ -f ${INFO_BPPL_SUMMARY_ERROR} ] && rm -f ${INFO_BPPL_SUMMARY_ERROR}


