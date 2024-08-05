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

mkdir -p "${DOWNLOAD_DIR}/{5,6,7,8,9,10}"

cat <<EOF > ${DOWNLOAD_DIR}/index.html
<html>
<body>
<h1>Tomcat Versions</h1>
<ul>
<li><a href="5/">Tomcat 5.x</a></li>
<li><a href="6/">Tomcat 6.x</a></li>
<li><a href="7/">Tomcat 7.x</a></li>
<li><a href="8/">Tomcat 8.x</a></li>
<li><a href="9/">Tomcat 9.x</a></li>
<li><a href="10/">Tomcat 10.x</a></li>
</ul>
</body>
</html>
EOF

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



