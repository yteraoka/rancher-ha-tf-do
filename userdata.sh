#!/bin/bash

curl https://releases.rancher.com/install-docker/18.09.sh | sh

useradd -G docker rancher
install -o rancher -g rancher -m 0700 -d ~rancher/.ssh
cp -p ~root/.ssh/authorized_keys ~rancher/.ssh/authorized_keys
chown rancher:rancher ~rancher/.ssh/authorized_keys
