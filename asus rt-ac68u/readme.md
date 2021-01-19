
# nvram top 20 list


nvram show | awk '{print length(), $0 | "sort -n -r"}' | cut -d"=" -f 1 | head -n 20
