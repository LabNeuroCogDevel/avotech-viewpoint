#!/usr/bin/env bash
# 20220909 - simulate getting eye data
cd $(dirname $0)
test -r /tmp/x.txt && rm $_
cat ../eye/sub-will64screentest-low_ses-01_task-EC_run-1.txt| while read l; do
  echo $l >> /tmp/x.txt;
  sleep .016;
done &

gnuplot dot.gnuplot
