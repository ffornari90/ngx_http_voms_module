#!/bin/sh
set -ex

mkdir -p /etc/nginx/conf.d

chown -R ${STORM_USER}:${STORM_USER} /etc/nginx


