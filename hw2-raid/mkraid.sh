#! /bin/bash

set -e


echo 'Занулить блоки'
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f} > /dev/null 2>&1


# Создание raid 5
echo 'Создание raid'
yes | mdadm --create -l 5 -n 5 -f /dev/md0 /dev/sd{b,c,d,e,f} > /dev/null 2>&1

echo 'Создан raid 5'


# Конфигурационный файл mdadm.conf
echo 'Создание конфигурационного файла mdadm.conf'

mkdir -p /etc/mdadm

echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

echo 'Конфигурационный файл создан'

