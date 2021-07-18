# Prerequisites 
```
sudo apt update
sudo apt install git build-essential

raspi-config
# Advanced Options > GL Driver > GL (Fake KMS) select, <Finish> Enter, and reboot
```

# Installing Java Runtime Environment 

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
```
mkdir -p ~/{tools,server}
```
# Downloading and Compiling mcrcon

# https://linuxize.com/post/how-to-install-minecraft-server-on-raspberry-pi/
