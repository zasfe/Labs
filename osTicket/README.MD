## osTicket

- 솔루션 정보
   * 홈페이지: https://osticket.com/
   * 업체명: Enhancesoft LLC (http://enhancesoft.com/)
- 에디션 비교 (https://osticket.com/editions/)
   * Open Source, $0, 커뮤니티 지원
   * Cloud-hosted, $9(1직원당1개월), Powered by SupportSystem
   * Virtual Appliance, 별도 문의, Powered by SupportSystem
- Open Source 에디션 라이선스
   * GNU General Public License v2.0(복제, 배포, 수정의 권한 허용, 라이선스 고지 필요)
   * URL: https://github.com/osTicket/osTicket/blob/develop/LICENSE.txt
   * GNU2 라이선스 한글 설명: https://www.olis.or.kr/license/Detailselect.do?lId=1004
- 테스트 구축(Open Source 에디션)
   * 구성 환경
      * 가상 서버: gCloud CentOS7 APM 이미지
      * 설치 버전: osTicket Core, v1.15.4 (Latest Release), Released October 07, 2021
      * 설치 요구 사항: IIS or Apache, PHP version 7.2, MySQL database version 5.5

## 설치

### Requirements Packeges

```
yum remove php-*
yum install epel-release yum-utils -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum-config-manager --enable remi-php74
yum install php php-common php-opcache php-mcrypt php-cli php-gd php-curl php-mysql -y
yum install -y php-imap php-xml php-xml php-mbstring php-intl php-pecl-apcu-bc
```

### Download And Unzip

```
unzip osTicket-v1.15.4.zip
unzip osTicket-v1.15.4.zip
cp -pa upload /var/www/html/support
```

### Plugin Install
```
cp -pa auth*.phar /var/www/html/support/include/plugins/
cp -pa storage-*.phar /var/www/html/support/include/plugins/
```

### Korean Language Install
```
cp -pa ko.phar /var/www/html/support/include/i18n/
```

### web configation

```
cp include/ost-sampleconfig.php include/ost-config.php
chmod 644 include/ost-config.php
```

```mysql
mysql>

create database osTicket;
grant select, insert, delete, update, create, drop, alter on osTicket.* to osTicket@localhost identified by 'P@ssw0rd';
flush privileges;
```

### Url 접속

* Your osTicket URL
   * http://139.xxx.xxx.70/support/	


* Your Staff Control Panel
   * http://139.xxx.xxx.70/support/scp



## 추가

- LDAP 연동
   - [https://blog.naver.com/itkairos/222430743239](https://blog.naver.com/itkairos/222430743239)
        - [https://tmib.net/osticket-1-8-1-how-to-configure-the-ldap-authentication-and-lookup-plugin/](https://tmib.net/osticket-1-8-1-how-to-configure-the-ldap-authentication-and-lookup-plugin/)


- [Awesome osTicket](https://github.com/clonemeagain/awesome-osticket)
   * https://www.notion.so/zasfe/IDC-e77074989bca4d56838020e582a95095#4e97bd08d5d14fbda375d85e0462c3ea
