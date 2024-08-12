#!/bin/bash

MIRROR="https://archive.apache.org/dist/tomcat/"
DOWNLOAD_DIR="/path/to/download/directory"

mkdir -p $DOWNLOAD_DIR
mkdir -p $DOWNLOAD_DIR/{5,6,7,8,9,10}
cd $DOWNLOAD_DIR

# Tomcat 주 버전 (5.x부터 10.x까지)
for major in {5..10}
do
  echo "major=${major}";
  # 각 주 버전의 부 버전 페이지 가져오기
  wget -q $MIRROR/tomcat-$major/ -O - | grep -oP 'v\d+\.\d+\.\d+/' | sort -u | while read version
  do
    echo "version=${version}";
    # 각 버전의 바이너리 다운로드
    # wget -q $MIRROR/tomcat-$major/${version}bin/ -O - | grep -oP 'apache-tomcat-\d+\.\d+\.\d+\.tar\.gz' | sort -u | while read file
    wget -q $MIRROR/tomcat-$major/${version}bin/ -O - | grep -oP 'apache-tomcat-\d+\.\d+\.\d+\.tar\.gz|apache-tomcat-\d+\.\d+\.\d+\-windows-x64\.zip|apache-tomcat-\d+\.\d+\.\d+\-windows-x86\.zip|apache-tomcat-\d+\.\d+\.\d+\.exe' | sort -u | while read file
    do
      echo " -> ${DOWNLOAD_DIR}/$major/$file";
      if [ ! -f "${DOWNLOAD_DIR}/$major/$file" ]; then
        echo "Downloading $file"
        wget $MIRROR/tomcat-$major/${version}bin/$file -O ${DOWNLOAD_DIR}/$major/$file
      fi
    done
  done
done


echo "<html><body><h1>Tomcat Versions</h1><ul>" > ${DOWNLOAD_DIR}/index.html
for dir in ${DOWNLOAD_DIR}/*; do
  if [ -d "$dir" ]; then
    echo "<li><a href='$dir'/>'$dir'.x</a></li>" >> $dir/index.html
    echo "<html><body><h1>Tomcat $(basename $dir).x</h1><ul>" > $dir/index.html
  fi
done
echo "</ul></body></html>"  >> ${DOWNLOAD_DIR}/index.html

for dir in ${DOWNLOAD_DIR}/*; do
  if [ -d "$dir" ]; then
    echo "<html><body><h1>Tomcat $(basename $dir).x</h1><ul>" > $dir/index.html
    for file in $dir/*.tar.gz; do
      if [ -f "$file" ]; then
        echo "<li><a href='$(basename $file)'>$(basename $file)</a></li>" >> $dir/index.html
      fi
    done
    echo "</ul></body></html>" >> $dir/index.html
  fi
done



