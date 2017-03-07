#!/bin/bash

# build all postgres-xl images(gtm gtm-proxy coord data)
images=("gtm" "coord" "proxy" "data")
for image in "${images[@]}" ; do
    docker build -t="woailuoli993/postgres-xl-${image}:0.1.0" -f=./Dockerfile.${image}.Dockerfile .
done