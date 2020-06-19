#!/bin/bash
set -e

# echo never > /sys/kernel/mm/transparent_hugepage/enabled 
# echo never > /sys/kernel/mm/transparent_hugepage/defrag

redis-server /usr/local/etc/redis/redis.conf