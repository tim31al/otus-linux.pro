#! /bin/bash

sudo -s

# Раскомментировать репозитории
cd /etc/yum.repos.d/

sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

cd ~

# Установка репозитория elrepo
yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
echo "elrepo installed"

# Установка нового ядра из репозитория elrepo-kernel
yum --enablerepo elrepo-kernel install kernel-ml -y
echo "kernel installed"

# Обновление параметров GRUB
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
echo "Grub update done."

# Перезагрузка ВМ
shutdown -r now
