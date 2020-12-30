
#!/bin/sh
cd /var/www/dokuwiki/data && git add . && git add -u && git commit -a -m "Content update `date +'%H:%M %d/%m/%Y %Z'`" && git push origin master
