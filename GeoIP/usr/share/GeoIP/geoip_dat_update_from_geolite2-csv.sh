#!/bin/bash
######################################################################################
# CRON => 00  06  *  *  *  bash /usr/share/GeoIP/geoip_dat_update_from_geolite2-csv.sh
#
#                                        2024-05-02 by Enteroa ( enteroa.j@gmail.com )
######################################################################################
# ref - https://www.enteroa.com/2024/05/02/geoip-database-파일-업데이트-2/

 
Maxmind_Licensekey=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
 
### config - DISABLE city it'll be need free memory 2GB
CITYDATA="N"
PRIMARY_SERVER_HOSTNAME="배포서버호스트네임"
PRIMARY_DEPLOY_URL="https://www.enteroa.com"
### geoip setting
GEOIPDIR="/usr/share/GeoIP"
DATALINK="/usr/share/xt_geoip /var/lib/GeoIP"
### avoid overlap
lockfile=/var/lock/$(basename $0)
if [ -f $lockfile ];then P=$(cat $lockfile)
  if [ -n "$(ps --no-headers -f $P)" ];then exit 1
fi;fi
echo $$ > $lockfile
trap 'rm -f "$lockfile"' EXIT
 
### define server are primary or secandary.
if [[ "$HOSTNAME" != "$PRIMARY_SERVER_HOSTNAME" ]];then
  ### download GeoIP.dat file from Primary-server
  cd $GEOIPDIR
  if [ ! -e $GEOIPDIR/GeoIP.dat ];then touch $GEOIPDIR/GeoIP.dat;fi
  PRI_DATE=$(date +"%Y%m%d%H%M.%S" -d "$(curl -sI "$PRIMARY_DEPLOY_URL/GeoIP-dat.tgz"|grep -i ^Last-Modified:|cut -d, -f2)")
  SLV_DATE=$(date +"%Y%m%d%H%M.%S" -d "$(stat -c %y $GEOIPDIR/GeoIP.dat)")
  if [[ "$PRI_DATE" != "$SLV_DATE" ]];then
    curl -k -L $PRIMARY_DEPLOY_URL/GeoIP-dat.tgz -o GeoIP-dat.tgz >/dev/null 2>&1
    if [ -s GeoIP-dat.tgz ] || [[ $(stat -c %s GeoIP-dat.tgz) -le 10000 ]];then
      tar xfzp GeoIP-dat.tgz
    fi
    rm -f GeoIP-dat.tgz
  fi
else
  ### install dependances
  if [[ -z $(which git) ]];then                               sudo yum -y install git > /dev/null 2>&1        ;fi
# if [[ -z $(which pip2) ]];then                              sudo yum -y install python2-pip > /dev/null 2>&1;fi
# if [[ -z $(pip2 list --format=legacy| grep pygeoip) ]];then sudo pip2 install pygeoip > /dev/null 2>&1      ;fi
# if [[ -z $(pip2 list --format=legacy| grep ipaddr) ]];then  sudo pip2 install ipaddr > /dev/null 2>&1       ;fi
  ### link path
  if [[ ! -d $GEOIPDIR ]];then mkdir -p $GEOIPDIR;fi
  for a in $DATALINK
    do
    if [[ ! -d $a ]];then
      if [[ $(readlink $a) != $GEOIPDIR ]];then
        rm -rf $a;ln -s $GEOIPDIR $a
    fi;fi
    done
  ### https://github.com/sherpya/geolite2legacy
  if [ ! -e $GEOIPDIR/geolite2legacy/geolite2legacy.py ];then cd $GEOIPDIR
    cd $GEOIPDIR && git clone https://github.com/sherpya/geolite2legacy.git
  fi
  ### make GeoIP.dat files from GeoLite2 CSV file.
  if [ -d $GEOIPDIR/geolite2legacy ];then
    cd $GEOIPDIR/geolite2legacy
    array=( GeoLite2-Country-CSV:zip )
    if [[ $CITYDATA == "Y" ]];then
      array=( ${array[*]} GeoLite2-City-CSV:zip )
    fi
    for b in ${array[@]}
      do
      COF=$(cut -d: -f1 <<< $b)
      EXT=$(cut -d: -f2 <<< $b)
      BASEURL="https://download.maxmind.com/app/geoip_download?edition_id=$COF&license_key=$Maxmind_Licensekey&suffix=$EXT"
      DATE_ORI=$(date +"%Y%m%d%H%M.%S" -d "$(curl -sI $BASEURL|grep -i ^Last-Modified:|cut -d, -f2)")
      DATE_DAT=$(date +"%Y%m%d%H%M.%S" -d "$(stat -c %y ${COF}.${EXT})")
      if [[ "$DATE_ORI" != "$DATE_DAT" ]];then
        rm -f $COF.$EXT
        ### geoip csv file change to S3 presigned. so add -L option.
        curl -k -L "$BASEURL" -o $COF.$EXT >/dev/null 2>&1
        touch -t $DATE_ORI $COF.$EXT
        if [ -s $GEOIPDIR/geolite2legacy/$COF.$EXT ] || [[ $(stat -c %s $GEOIPDIR/geolite2legacy/$COF.$EXT) -ne 0 ]];then
          if [[ $COF == "GeoLite2-Country-CSV" ]];then datev4="GeoIP.dat";datev6="GeoIPv6.dat"
          elif [[ $COF == "GeoLite2-City-CSV" ]];then datev4="GeoLiteCity.dat";datev6="GeoLiteCityv6.dat";fi
          python geolite2legacy.py --input-file $COF.$EXT --fips-file geoname2fips.csv --output-file $datev4
          python geolite2legacy.py --input-file $COF.$EXT -6 --fips-file geoname2fips.csv --output-file $datev6
          touch -t $DATE_ORI $datev4 $datev6
          mv -f $datev4 $GEOIPDIR
          mv -f $datev6 $GEOIPDIR
        fi
        /bin/geoipupdate
      fi
      done
      ### Primary Server are deploy for other servers.
      cd $GEOIPDIR
      if [[ $CITYDATA == "Y" ]];then
        tar czfp GeoIP-dat.tgz Geo{IP,IPv6,LiteCity,LiteCityv6}.dat GeoLite2-{Country,City}.mmdb
      else
        tar czfp GeoIP-dat.tgz Geo{IP,IPv6}.dat GeoLite2-Country.mmdb
      fi
      touch -t $DATE_ORI GeoIP-dat.tgz
      if [ -s GeoIP-dat.tgz ];then
        mv -f $GEOIPDIR/GeoIP-dat.tgz /var/www/html/
        chown apache:apache /var/www/html/GeoIP-dat.tgz
fi;fi;fi
exit 0
