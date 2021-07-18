# RPI3 Install Minecraft Server

## Prerequisites 
```
sudo apt update
sudo apt install git build-essential

raspi-config
# Advanced Options > GL Driver > GL (Fake KMS) select, <Finish> Enter, and reboot
```

## Installing Java Runtime Environment 

Minecraft requires Java 8 or higher to be installed on the system.

```
sudo apt install openjdk-8-jre-headless
java -version
```

# Creating Minecraft User 

For security purposes, Minecraft should not be run under the root user.
```
sudo useradd -r -m -U -d /opt/minecraft -s /bin/bash minecraft
```
# Installing Minecraft on Raspberry Pi

##  switch to user “minecraft”
```
sudo su - minecraft
```

## Downloading and Compiling mcrcon(on user “minecraft”)
```
mkdir -p ~/{tools,server}
cd ~/tools && git clone https://github.com/Tiiffi/mcrcon.git
cd ~/tools/mcrcon
make
sudo make install
./mcrcon -h
```


## Truble Shooting


https://raspberrytips.com/minecraft-server-raspberry-pi/
```
mkdir /home/pi/spigot
cd /home/pi/spigot
wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar
```

### 
*** The version you have requested to build requires Java versions between [Java 16, Java 16], but you are using Java 8
*** Please rerun BuildTools using an appropriate Java version. For obvious reasons outdated MC versions do not support Java versions that did not exist at their release.

https://java.tutorials24x7.com/blog/how-to-install-openjdk-16-on-ubuntu-20-04-lts

```
sudo mkdir -p /usr/java/openjdk
cd /usr/java/openjdk
sudo cp /data/setups/openjdk-16_linux-x64_bin.tar.gz openjdk-16_linux-x64_bin.tar.gz
sudo tar -xzvf openjdk-16_linux-x64_bin.tar.gz
```

# https://linuxize.com/post/how-to-install-minecraft-server-on-raspberry-pi/


# https://linuxize.com/post/how-to-install-minecraft-server-on-raspberry-pi/


# https://tlauncher.org/en/download_1/minecraft-1-16-5_12582.html
https://tlauncher.org/download/11784
