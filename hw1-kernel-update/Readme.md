## Обновление ядра

Текущая версия ядра

`uname -r`

4.18.0-305.19.1.el8_4.x86_64


Раскомментировать репозитории

```
sudo -s
cd /etc/yum.repos.d/
sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
cd ~
```

Установка репозитория elrepo

```
yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```

Установка нового ядра из репозитория elrepo-kernel

```
yum --enablerepo elrepo-kernel install kernel-ml -y
```

Обновление параметров GRUB

```
grub2-mkconfig -o /boot/grub2/grub.cfg
grub2-set-default 0
```

Перезагрузка

`shutdown -r now`

Новая версия ядра

`uname -r`

6.1.2-1.el8.elrepo.x86_64
