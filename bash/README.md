## TIP


### gif <-> Video

* GIF -> Video <br>→ ffmpeg -v warning -i "입력.gif" -y "출력.mp4" -pix_fmt yuv420p -c:v libx264 -movflags +faststart -filter:v "crop=floor(iw/2)*2:floor(ih/2)*2"
* Video -> GIF <br>→ ffmpeg -v warning -i "입력.mp4" -y "출력.gif" -filter_complex "[0:v] fps=15, split [1:v] [2:v]; [1:v] palettegen [p]; [2:v] fifo [3:v]; [3:v] [p] paletteuse" -loop 0

	
참고로 gif의 일반적인 최대 FPS는 50정도로 생각하시면 됩니다.
https://wunkolo.github.io/post/2020/02/buttery-smooth-10fps/


### Bash 

```bash
alias df='df -h -x tmpfs -x devtmpfs -x squashfs'
alias xc='xclip -sel clipboard'
alias ttfb='curl -so /dev/null -w "HTTP %{http_version} %{http_code} Remote IP: %{remote_ip}\nConnect: %{time_connect}\nTTFB: %{time_starttransfer}\nTotal time: %{time_total}\nDownload speed: %{speed_download}bps\nBytes: %{size_download}\n"'

ap() {
https $@ Accept:application/activity+json
}

shodan() {
xdg-open https://shodan.io/domain/$1
dig +short $1 | xargs -i xdg-open https://shodan.io/host/{}
}

check_mtu() {
local target=$1
shift
local lower=0
local upper=1500
until [[ $((lower + 1)) -eq $upper ]]; do
current=$(((lower + upper) / 2))
echo -n "lower: $lower, upper: $upper, testing: $current -- "
if ping -M do -s $current -c 2 -i 0.2 $target $@ &> /dev/null; then
echo "ok"
lower=$current
else
echo "fail"
upper=$current
fi
done

echo "max packet size: $lower, mtu: $((lower + 28))"  
}
```

### git

   * git log --pretty="%ad [%ae] %s" --author E_MAIL_ADDRESS <br>-> git 리비전에서 지정한 커미터만 필터링해서 보기


### ssh

> https://news.ycombinator.com/item?id=32468605

  * 접속하는 모든 서버에서 같은 환경을 구성하는 '.ssh/config' <br>→ 서버에 처음 접속시 필요한 dotfile을 자동으로 rsync 하고, 그 다음 접속부터는 자동 업데이트

```
   Match Host 192.168.123.*,another-example.org,*.example.com User myusername,myotherusername
      ForwardAgent yes
      PermitLocalCommand yes
      LocalCommand rsync -L --exclude .netrwhist --exclude .git --exclude .config/iterm2/AppSupport/ --exclude .vim/bundle/youcompleteme/ -vRrlptze "ssh -o PermitLocalCommand=no" %d/./.screenrc %d/./.gitignore %d/./.bash_profile %d/./.ssh/git_ed25519.pub %d/./.ssh/authorized_keys %d/./.vimrc %d/./.zshrc %d/./.config/iterm2/ %d/./.vim/ %d/./bin/ %d/./.bash/ %r@%n:/home/%r

```

