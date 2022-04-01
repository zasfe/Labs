## Step 0: sd 카드 수명 연장하기

```
$ sudo nano /etc/fstab
..중략..
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=10m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=10m 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=10m 0 0

$sudo reboot
```



## Step 1: Package Update

```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo reboot
```

## Step 2: Desktop Install and Setting

> 이건 SD 카드를 Desktop 버전이 아닌 쉘버전으로 설치해서 하게된 것으로 추후 Desktop 버전으로 설치하면 안해도 됨

* 자동 로그인을 위한 lightdm
* 한글 사용을 위한 fcitx-hangul
* 손쉬운 관리를 위한 vnc

```bash
sudo apt install raspberrypi-ui-mods
sudo apt install xserver-xorg
sudo apt install lightdm
sudo ln -fs /etc/systemd/system/autologin@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
sed /etc/lightdm/lightdm.conf -i -e "s/^\(#\|\)autologin-user=.*/autologin-user=pi/"
sudo apt-get install fcitx-hangul
sudo apt install realvnc-vnc-server realvnc-vnc-viewer
sudo reboot
```

> 내가 구한 PI3 모델은 Display 화면이 함께 있는데, 전원 콘센트가 아래로 되어 있어서 화면을 돌여야 했다.
> 1=90, 2=180, 3=270

```bash
echo "lcd_rotate=2" | sudo tee --append /boot/config.txt
sudo reboot
```

## Step 3: Influxdb Install

```bash
sudo apt install influxdb influxdb-client
```

```conf
# /etc/influxdb/influxdb.conf
[meta]
dir = "/tmp/influxdb/meta"

# 중략

[data]
dir = "/tmp/influxdb/data"
wal-dir = "/tmp/influxdb/wal"

# 중략

[http]
enabled = true
bind-address = "127.0.0.1:8086"

# 중략

[[collectd]]
enabled = true
port = 25826
database = "collectd_db"
typesdb = "/usr/share/collectd/types.db"
````


```bash
$ sudo systemctl enable influxdb
$ sudo systemctl start influxdb
$ echo "CREATE DATABASE collectd_db"
$ influx
Connected to http://localhost:8086 version 1.6.4
InfluxDB shell version: 1.6.4
> CREATE DATABASE collectd_db
> CREATE RETENTION POLICY "twentyfour_hours" ON "collectd_db" DURATION 24h REPLICATION 1 DEFAULT
# influx prompt에서 나가려면 <CTRL><D> 키를 누르자
$ 
```

## Step 4: collectd Install

```bash
$ sudo apt install collectd collectd-utils
$ sudo nano /etc/collectd/collectd.conf
```

```conf
# /etc/collectd/collectd.conf
Hostname "myserverZasfe"

Interval 60
LoadPlugin syslog
LoadPlugin cpu
LoadPlugin cpufreq
LoadPlugin df
LoadPlugin disk
LoadPlugin entropy
LoadPlugin interface
LoadPlugin irq
LoadPlugin load
LoadPlugin memory
LoadPlugin network
LoadPlugin processes
LoadPlugin swap
LoadPlugin thermal
LoadPlugin users

## 중략

<Plugin df>
# This will ignore uninteresting file systems
# to keep our DB from cluttering
    FSType rootfs
    FSType sysfs
    FSType proc
    FSType devpts
    FSType tmpfs
    FSType fusectl
    FSType cgroup
    Ignore Selected true
</Plugin>

<Plugin "syslog">
# Skip messages with info label
    LogLevel "warning"
</Plugin>

## 중략

<Plugin "network">
    Server "127.0.0.1" "25826"
</Plugin>
```

```bash
$ sudo systemctl enable collectd
$ sudo systemctl start collectd
```

### 데이터가 추가되는지 확인

```bash
$ influx
Connected to http://localhost:8086 version 1.6.4
InfluxDB shell version: 1.6.4
> show databases;
name: databases
name
----
_internal
collectd_db
> use collectd_db
Using database collectd_db
> show measurements
name: measurements
name
----
cpu_value
cpufreq_value
df_value
disk_io_time
disk_read
disk_value
disk_weighted_io_time
disk_write
entropy_value
interface_rx
interface_tx
irq_value
load_longterm
load_midterm
load_shortterm
memory_value
processes_value
swap_value
thermal_value
users_value
> 
# influx prompt에서 나가려면 <CTRL><D> 키를 누르자
```

## Step 5 : Install grafana

```bash
sudo wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana
sudo /bin/systemctl enable grafana-server
sudo /bin/systemctl start grafana-server
```

## Step 6 : Application Install

```bash
sudo apt install chromium-browser
```


## 참고

* https://ch-st.de/raspberry-pi-grafana-influxdb-collectd/
* Raspberry Pi에서 SD 카드의 수명을 연장하는 방법
   * https://www.magdiblog.fr/divers/comment-prolonger-la-duree-de-vie-de-vos-cartes-sd-sur-raspberry-pi/


