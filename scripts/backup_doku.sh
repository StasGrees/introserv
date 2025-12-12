#!/bin/bash
SRC="/var/lib/docker/volumes"
DST="/opt/backups/dokuwiki"
DATE=$(date +%Y-%m-%d_%H-%M)
mkdir -p $DST
rsync -a --delete $SRC "$DST/$DATE"
cd "$DST"
ls -1 | sort | head -n -7 | xargs rm -rf
