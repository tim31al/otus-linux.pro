# Задание
- vagrant up должен поднимать 2 виртуалки: сервер и клиент;
- на сервер должна быть расшарена директория;
- на клиента она должна автоматически монтироваться при старте (fstab или autofs);
- в шаре должна быть папка upload с правами на запись;
- требования для NFS: NFSv3 по UDP, включенный firewall.

## Сервер
включаем firewall и проверяем, что он работает 

```
systemctl enable firewalld --now
systemctl status firewalld
```
разрешаем в firewall доступ к сервисам NFS

```
firewall-cmd --add-service="nfs3" \
--add-service="rpc-bind" \
--add-service="mountd" \
--permanent
firewall-cmd --reload
```

включаем сервер NFS (для конфигурации NFSv3 over UDP /etc/nfs.conf)

```
systemctl enable nfs --now
```

проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp,
20048/tcp, 111/udp, 111/tcp

```
ss -tnplu
```

создаём и настраиваем директорию, которая будет экспортирована

```
mkdir -p /srv/share/upload && \
chown -R nfsnobody:nfsnobody /srv/share && \
chmod 0777 /srv/share/upload
```

создаём в файле /etc/exports структуру, которая позволит
экспортировать ранее созданную директорию

```
cat << EOF > /etc/exports
/srv/share 192.168.50.20/32(rw,sync,root_squash)
EOF
```

экспортируем ранее созданную директорию 

```
exportfs -r
```

проверяем экспортированную директорию следующей командои

```
[root@server vagrant]# exportfs -s
/srv/share  192.168.50.20/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

## Клиент
включаем firewall и проверяем, что он работает

```
systemctl enable firewalld --now
systemctl status firewalld
```

добавляем в /etc/fstab строку

```
echo "192.168.50.5:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
```
и выполняем

```
systemctl daemon-reload
systemctl restart remote-fs.target
```

В данном случае происходит автоматическая генерация
systemd units в каталоге `/run/systemd/generator/`, которые производят
монтирование при первом обращении к каталогу `/mnt/`
проверяем успешность монтирования

```
[root@client vagrant]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=23,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=26266)
```

## Проверка работоспособности
Сервер

```
touch /srv/share/upload/server-file
```

Клиент

```
[vagrant@client ~]$ ll /mnt/upload
total 0
-rw-rw-r--. 1 vagrant vagrant 0 Jan 24 12:04 server-file

touch /mnt/upload/client-file
```

перезагружаем клиент и проверяем работу RPC 
```
[vagrant@client ~]$ showmount -a 192.168.50.5
All mount points on 192.168.50.5:
192.168.50.20:/srv/share
```

Сервер

```
[vagrant@server ~]$ ll /srv/share/upload
total 0
-rw-rw-r--. 1 vagrant vagrant 0 Jan 24 12:06 client-file
-rw-rw-r--. 1 vagrant vagrant 0 Jan 24 12:04 server-file

```

- статус сервера NFS `systemctl status nfs`
- статус firewall `systemctl status firewalld`
- проверить экспорты `exportfs -s`
- проверить работу RPC `showmount -a 192.168.50.5`
