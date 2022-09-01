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
   * git recent <br> → 최근에 작업한 브랜치 보여주기 <br> https://news.ycombinator.com/item?id=32470619

```bash
  # Branches
  2022-08-11 13:26:34 -0700 4 days ago    branch-1
  2022-07-13 07:49:36 -0700 5 weeks ago   branch-10
  2022-06-28 23:40:53 +0000 7 weeks ago   branch-8
  2022-06-28 22:47:31 +0000 7 weeks ago   main
  2022-06-28 19:24:10 +0000 7 weeks ago   branch-7
  # Stashes
  stash@{0}:Thu Aug 11 13:17:11 2022 -0700 WIP on branch-3: afa19e7444a Some changes based on morning sync
  stash@{1}:Tue Jul 26 13:25:37 2022 -0700 WIP on branch-5: bd6122e2dfa find() bugfix
  stash@{2}:Tue Jul 12 15:05:31 2022 -0700 WIP on branch-7: 1221d0640c5 linter


# Code: git alias
  recent() 
  { 
      echo -e "${PURPLE}# Branches${COLOR_END}";
      for k in $(git branch | perl -pe 's/^..(.*?)( ->.*)?$/\1/');
      do
          echo -e $(git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset " $k -- | head -n 1)\\\t$k;
      done | sort -r | head;
      _num_stashes=$(git stash list | wc -l | while read l; do echo "$l - 1"; done | bc);
      echo -e "${PURPLE}# Stashes${COLOR_END}";
      for i in $(seq 0 ${_num_stashes});
      do
          echo -en "${CYAN}stash@{${i}}:${GREEN}" && git show --format="%ad%Creset %s" stash@{$i} | head -n 1;
      done
  }
```



### ssh

> https://news.ycombinator.com/item?id=32468605

  * 접속하는 모든 서버에서 같은 환경을 구성하는 '.ssh/config' <br>→ 서버에 처음 접속시 필요한 dotfile을 자동으로 rsync 하고, 그 다음 접속부터는 자동 업데이트

```
   Match Host 192.168.123.*,another-example.org,*.example.com User myusername,myotherusername
      ForwardAgent yes
      PermitLocalCommand yes
      LocalCommand rsync -L --exclude .netrwhist --exclude .git --exclude .config/iterm2/AppSupport/ --exclude .vim/bundle/youcompleteme/ -vRrlptze "ssh -o PermitLocalCommand=no" %d/./.screenrc %d/./.gitignore %d/./.bash_profile %d/./.ssh/git_ed25519.pub %d/./.ssh/authorized_keys %d/./.vimrc %d/./.zshrc %d/./.config/iterm2/ %d/./.vim/ %d/./bin/ %d/./.bash/ %r@%n:/home/%r

```

