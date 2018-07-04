#!/bin/bash
set -e

NGINX_VOMS_IMAGE=${NGINX_VOMS_IMAGE:-storm2/ngx-voms:latest}

docker build -t ${NGINX_VOMS_IMAGE} .
