#!/bin/bash

is_cgroup_v2() {
  [ -f /sys/fs/cgroup/cgroup.controllers ]
}

for cid in $(docker ps -q); do
  cname=$(docker inspect --format='{{.Name}}' "$cid" | sed 's#^/##')

  echo "[$cname]"

  if is_cgroup_v2; then
    cgroup_path=$(docker inspect --format '{{.State.Pid}}' "$cid" | xargs -I{} grep -l "$cid" /sys/fs/cgroup/*/cgroup.procs 2>/dev/null | head -n1 | xargs dirname)
    [ -z "$cgroup_path" ] && cgroup_path="/sys/fs/cgroup/docker/$cid"

    # memory
    mem_file="/sys/fs/cgroup/docker/$cid/memory.current"
    [ -f "$mem_file" ] || mem_file="$cgroup_path/memory.current"
    mem_usage=$(cat "$mem_file" 2>/dev/null)

    # cpu
    cpu_file="/sys/fs/cgroup/docker/$cid/cpu.stat"
    [ -f "$cpu_file" ] || cpu_file="$cgroup_path/cpu.stat"
    cpu_usage=$(awk '/usage_usec/ {print $2}' "$cpu_file" 2>/dev/null)

    # io
    io_file="/sys/fs/cgroup/docker/$cid/io.stat"
    [ -f "$io_file" ] || io_file="$cgroup_path/io.stat"
    io_usage=$(cat "$io_file" 2>/dev/null)

    echo "  Memory (bytes): ${mem_usage:-N/A}"
    echo "  CPU (µsec): ${cpu_usage:-N/A}"
    echo "  Block IO:"
    echo "$io_usage" | sed 's/^/    /'

  else
    # cgroup v1 경로
    base="/sys/fs/cgroup"

    mem_usage=$(cat "$base/memory/docker/$cid/memory.usage_in_bytes" 2>/dev/null)
    cpu_usage=$(cat "$base/cpuacct/docker/$cid/cpuacct.usage" 2>/dev/null)
    io_usage=$(cat "$base/blkio/docker/$cid/blkio.throttle.io_service_bytes" 2>/dev/null | grep -E 'Read|Write' | awk '{r[$1]+=$2} END {for (k in r) print k, r[k]}')

    echo "  Memory (bytes): ${mem_usage:-N/A}"
    echo "  CPU (ns): ${cpu_usage:-N/A}"
    echo "  Block IO:"
    echo "$io_usage" | sed 's/^/    /'
  fi

  echo ""
done
