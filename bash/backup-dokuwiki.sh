#!/bin/sh

echo "## start - `date +'%H:%M %d/%m/%Y %Z'`"
echo "# 100mb over file delete"
find /var/www/html/wiki -type f -size +100M -delete

echo "# public wiki git push"
cd /var/www/html/wiki/public_wiki 
grep -Ev '^($|#)' data/deleted.files | xargs -n 1 rm -vf
git add . && git add -u && git commit -a -m "Public Content update `date +'%H:%M %d/%m/%Y %Z'`" && git push origin master

echo "# private wiki git  push"
cd /var/www/html/wiki/private_wiki 
grep -Ev '^($|#)' data/deleted.files | xargs -n 1 rm -vf
git add . && git add -u && git commit -a -m "Private Content update `date +'%H:%M %d/%m/%Y %Z'`" && git push origin master

echo "## end - `date +'%H:%M %d/%m/%Y %Z'`"
