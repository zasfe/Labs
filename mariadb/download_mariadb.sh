#!/bin/bash

# ref - https://mariadb.org/mariadb/all-releases/
# ref - https://mariadb.com/kb/en/mirror-sites-for-mariadb/

MIRROR="archive.mariadb.org::mariadb"
DOWNLOAD_DIR="/path/to/download/directory"

mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR


rsync ${MIRROR} | grep -oP 'mariadb\-\d+\.\d+\.\d+' | while read version_full
do
  echo " # ${version_full}";
  mkdir -p $DOWNLOAD_DIR/${version_full};
  
  rsync ${MIRROR}/${version_full}/ | grep -P "(x86_64|-packages)" | awk '{print$5}'  | while read version_build
  do
    echo " -> ${version_build}";
    rsync ${MIRROR}/${version_full}/${version_build}/ | grep -oP 'mariadb\-\d+\.\d+\.\d+[^"]*\.tar\.gz|mariadb\-\d+\.\d+\.\d+[^"]*\-winx64\.zip|mariadb\-\d+\.\d+\.\d+[^"]*\-winx64\.msi|mariadb\-\d+\.\d+\.\d+[^"]*\-win32\.zip|mariadb\-\d+\.\d+\.\d+[^"]*\-win32\.msi'  | sort -u | while read file
    do
      echo " --> ${DOWNLOAD_DIR}/${version_full}/$file";
      if [ ! -f "${DOWNLOAD_DIR}/${version_full}/$file" ]; then
        echo "Downloading $file"
        rsync --bwlimit=2000 -avP ${MIRROR}/${version_full}/${version_build}/${file} $DOWNLOAD_DIR/${version_full}/
      fi
    done
  done
done

echo "<html><body><h1>mariadb Versions</h1><ul>" > ${DOWNLOAD_DIR}/index.html
for dir in ${DOWNLOAD_DIR}/*; do
  if [ -d "$dir" ]; then
    echo "<li><a href='$dir'/>'$dir'.x</a></li>" >> $dir/index.html
  fi
done
echo "</ul></body></html>"  >> ${DOWNLOAD_DIR}/index.html

for dir in ${DOWNLOAD_DIR}/*; do
  if [ -d "$dir" ]; then
    echo "<html><body><h1>$(basename $dir).x</h1><ul>" > $dir/index.html
    for file in $dir/*.tar.gz; do
      if [ -f "$file" ]; then
        echo "<li><a href='$(basename $file)'>$(basename $file)</a></li>" >> $dir/index.html
      fi
    done
    echo "</ul></body></html>" >> $dir/index.html
  fi
done
