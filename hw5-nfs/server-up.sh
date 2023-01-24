#!/bin/bash

yum -y install nfs-utils

# Включить сервис firewall
systemctl enable firewalld --now

# настройка firewall
firewall-cmd --add-service="nfs3" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent

firewall-cmd --reload

# включить сервис nfs
systemctl enable nfs --now

# общая папка
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload

# настроить exports
cat << EOF > /etc/exports
/srv/share 192.168.50.20/32(rw,sync,root_squash)
EOF

exportfs -r
