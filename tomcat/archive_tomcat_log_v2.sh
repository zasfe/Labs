#!/bin/bash

# 기본 로그 백업 경로
folder_backup_base="/nas/tomcat_log"

# 실행 중인 Tomcat 인스턴스의 catalina.base 경로를 찾는 함수
find_tomcat_bases() {
  ps aux | grep '[o]rg.apache.catalina.startup.Bootstrap' | awk -F 'catalina.base=' '{print $2}' | awk '{print $1}'
}

# 실행 중인 Tomcat 인스턴스의 catalina.base 경로 배열 생성
catalina_bases=($(find_tomcat_bases))

# catalina.base 경로가 비어있는지 확인
if [ ${#catalina_bases[@]} -eq 0 ]; then
  echo "No running Tomcat instances found."
  exit 1
fi

# 각 catalina.base 경로에 대해 로그 파일 처리
for catalina_base in "${catalina_bases[@]}"; do
  folder_tomcat_logs="${catalina_base}/logs"

  # 경로가 유효한지 확인
  if [ ! -d "$folder_tomcat_logs" ]; then
    echo "Invalid catalina.base path: $catalina_base"
    continue
  fi

  # 인스턴스 이름 추출
  instance_name=$(basename "$catalina_base")
  folder_backup="${folder_backup_base}/${instance_name}"

  # 백업 폴더가 존재하지 않으면 생성
  if [ ! -d "$folder_backup" ]; then
    mkdir -p "$folder_backup"
  fi

  echo "Processing logs for $catalina_base..."

  # 3일 이상 된 catalina 로그 파일 이동
  find ${folder_tomcat_logs} -maxdepth 1 -type f -name "catalina*.out-*" -mtime +3 -exec mv {} ${folder_backup} \;

  # 10일 이상 된 모든 로그 파일 이동
  find ${folder_tomcat_logs} -maxdepth 1 -type f -name "*" -mtime +10 -exec mv {} ${folder_backup} \;
done

# 30일 이상 된 파일 압축 (각 인스턴스에 대해 별도로 처리)
for catalina_base in "${catalina_bases[@]}"; do
  # 인스턴스 이름 추출
  instance_name=$(basename "$catalina_base")
  folder_backup="${folder_backup_base}/${instance_name}"

  cd ${folder_backup}
  find ${folder_backup} -maxdepth 1 -type f -name "*" ! -name "*.gz" -mtime +30 -exec sh -c "gzip {};" \;
done

echo "Log processing completed for all instances."
exit 0
