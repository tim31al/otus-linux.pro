#!/bin/bash

set -e

MEDIA="/etc/yum.repos.d/CentOS-Linux-Media.repo"

[ -f "$MEDIA" ] && rm "$MEDIA"
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

yum install -y \
redhat-lsb-core \
wget \
vim \
rpmdevtools \
rpm-build \
createrepo \
gcc
