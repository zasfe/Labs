#!/bin/bash

MIRROR="https://archive.apache.org/dist/tomcat"
DOWNLOAD_DIR="/path/to/download/directory"

mkdir -p $DOWNLOAD_DIR
cd $DOWNLOAD_DIR

# Tomcat 주 버전 (5.x부터 10.x까지)
for major in {5..10}
do
  # 각 주 버전의 부 버전 페이지 가져오기
  wget -q $MIRROR/tomcat-$major/ -O - | grep -oP 'v\d+\.\d+\.\d+/' | sort -u | while read version
  do
    # 각 버전의 바이너리 다운로드
    wget -q $MIRROR/tomcat-$major/$version/bin/ -O - | grep -oP 'apache-tomcat-\d+\.\d+\.\d+\.tar\.gz' | sort -u | while read file
    do
      if [ ! -f $file ]; then
        echo "Downloading $file"
        wget $MIRROR/tomcat-$major/bin/$version$file
      fi
    done
  done
done

echo "<html><body><h1>Tomcat Files</h1><ul>" > $DOWNLOAD_DIR/index.html
ls -al *.tar.gz | awk '{print$9}' | sort -u | awk '{print "\<li\>\<a href=\""$1"\"\</a\>\</li\>"}' >> $DOWNLOAD_DIR/index.html
echo "</ul></body></html>" >> $DOWNLOAD_DIR/index.html



