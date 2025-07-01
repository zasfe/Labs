#!/bin/bash

echo " # 영문 대소문자와 숫자로 구성된 16자리 랜덤 패스워드를 생성"
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ; echo


echo " # 특수문자를 포함"
tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c 16 ; echo

echo " # bash 함수"
genpasswd() { 
  local l=$1
  [ "$l" == "" ] && l=16
  tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}

echo $(genpasswd 20)

echo " # 12자리, 대문자/소문자/숫자/특수문자 각 1개 이상 포함"
pw=$(tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c12)
echo "$pw"

