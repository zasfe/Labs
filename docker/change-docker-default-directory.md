* original: https://gist.github.com/nileshsimaria/ec2ea6847d494d2a1935c95d7c4b7155


1. Take a backup of docker.service file.
```bash
$ cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.orig
```

2. Modify /lib/systemd/system/docker.service to tell docker to use our own directory <br>
   instead of default /var/lib/docker. In this example, I am using /p/var/lib/docker
   
   Apply below patch.
```bash
   $ diff -uP -N /lib/systemd/system/docker.service.orig /lib/systemd/system/docker.service
   --- /lib/systemd/system/docker.service.orig	2018-12-05 21:24:20.544852391 -0800
   +++ /lib/systemd/system/docker.service	2018-12-05 21:25:57.909455275 -0800
   @@ -10,7 +10,7 @@
    # the default is not to use systemd for cgroups because the delegate issues still
    # exists and systemd currently does not support the cgroup feature set required
    # for containers run by docker
  -ExecStart=/usr/bin/dockerd -H unix://
  +ExecStart=/usr/bin/dockerd -g /p/var/lib/docker -H unix://
   ExecReload=/bin/kill -s HUP $MAINPID
   TimeoutSec=0
   RestartSec=2
```

3. Stop docker service
```bash
   $ systemctl stop docker
```
5. Do daemon-reload as we changed docker.service file
```bash 
   $ systemctl daemon-reload
```
7. rsync existing docker data to our new location
```bash  
   $ rsync -aqxP /var/lib/docker/ /p/var/lib/docker/
```
9. Start docker service
```bash
   $ sysctl docker start
```
