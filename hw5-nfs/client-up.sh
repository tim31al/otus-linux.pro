#!/bin/bash

yum -y install nfs-utils

# Включаем firewall
systemctl enable firewalld --now

# автомонтирование серверного каталога при первом обращении
echo "192.168.50.5:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab

# перезагрузить сервисы
systemctl daemon-reload
systemctl restart local-fs.target
systemctl restart remote-fs.target
