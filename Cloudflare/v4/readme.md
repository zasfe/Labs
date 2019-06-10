# Cloudflare DDNS Bash Script with Crontab/ Systemd Timer
This script will check if external IP is changed or not and will update the external IP of "A" or "AAAA" record in Cloudflare DNS.

# How to Use it?
1) Put the `cfddns.sh` file to anyhwere you like. E.g., `/home/scripts`.

2) For **crontab**:
  - Open terminal.
  - Give the file execute permission, type/ copy `chmod +x /location/cfddns.sh` press `Enter`.
  - Open crontab, type/ copy `crontab -e` press `Enter`.
  - If you want to run the job every minute, type/ copy `* * * * * /location/cfddns.sh`.
  - If you want to run the job every 5 minute, type/ copy `5 * * * * /location/cfddns.sh`.
  - If you want more time flexibility then goto this <a target="_blank" rel="noopener noreferrer" href="https://crontab.guru/">link</a>.
  - After setting cron press `Esc` and type `wq` then press `Enter`.
  - Setting up cron is completed!
  
3) For **systemd timer**:
  - Open terminal.
  - Give the file execute permission, type/ copy `chmod +x /location/cfddns.sh` press `Enter`.
  - Create a systemd service unit, type/ copy `/etc/systemd/system/cfddns.service` press `Enter`.
  - Copy all of the content from `cfddns.service` **down below**.
  - After setting service unit press `Esc` and type `wq` then press `Enter`.
  - Create a systemd timer unit at **the same location of service unit**, type/ copy `/etc/systemd/system/cfddns.timer` press               `Enter`.
  - Copy all of the content from `cfddns.timer` **down below**.
  - If you want to run the timer unit every minute, type/ copy `*:0/1`
  - If you want to run the timer unit every 5 minute, type/ copy `*:0/5`
  - If you want more time flexibility then goto this <a target="_blank" rel="noopener noreferrer" 
    href="https://www.redpill-linpro.com/sysadvent/2016/12/07/systemd-timers.html">link</a>.
  - After setting timer unit press `Esc` and type `wq` then press `Enter`.
  - Reload systemd, type/ copy `sudo systemctl daemon-reload`.
  - Enable timer unit, type/ copy `sudo systemctl enable cfddns.timer`.
  - Start timer unit, type/ copy `sudo systemctl start  cfddns.timer`.
  - Setting up systemd timer is completed!

# Notes
- Thanks to **@benkulbertis** and **@lifehome**!
- I have written the instructions based on **CentOS 7.6.x**.
- Files name are started with `0,1,2,3` because of orderly manner.
- I am noob to this **Scripting Business** so if you find any mistakes please comment it below!
- Keep in mind that whether you use `crontab` or `systemd timer` both will create **huge size log files**! It will be better if you use   `logrotate` to keep the log files at a minimum size.
- The default `cfddns.timer` is set to execute the script **every minute**. Please keep in mind not to **spam** the API or you will be     rate limited.
- A quote from Cloudflare FAQ:
  > All calls through the Cloudflare Client API are rate-limited to 1200 every 5 minutes.
  >
  > <a target="_blank" rel="noopener noreferrer" href="https://support.cloudflare.com/hc/en-us/articles/200171456">Link</a>
