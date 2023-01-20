# На имеющемся образе centos/7 - v. 1804.2
- Уменьшить том под / до 8G
- Выделить том под /home
- Выделить том под /var - сделать в mirror
- /home - сделать том для снапшотов


## Уменьшить том под / до 8G

```
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   10G  0 disk
sdb                       8:16   0    2G  0 disk
sdc                       8:32   0    1G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0   40G  0 disk
├─sde1                    8:65   0    1M  0 part
├─sde2                    8:66   0    1G  0 part /boot
└─sde3                    8:67   0   39G  0 part
├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
└─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
```

Подготовим временный том для / раздела:

```
pvcreate /dev/sda && \
vgcreate vg_root /dev/sda && \
lvcreate -n lv_root -l +100%FREE /dev/vg_root
```

Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:

```
mkfs.xfs /dev/vg_root/lv_root && \
mount /dev/vg_root/lv_root /mnt
```

Скопировать все данные с / раздела в /mnt:

```
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```

Переконфигурация grub для того, чтобы при старте перейти в новый /
Сымитируем текущий root -> сделаем в него chroot и обновим grub:

```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
```

Обновить образ initrd

```
cd /boot
for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
```

чтобы при загрузке был смонтирован нужны root нужно в 
/boot/grub2/grub.cfg заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root

```
sed -i 's#rd.lvm.lv=VolGroup00/LogVol00#rd.lvm.lv=vg_root/lv_root#g' /boot/grub2/grub.cfg
exit
reboot
```

После перезагрузки

```
[root@lvm vagrant]# lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   10G  0 disk
└─vg_root-lv_root       253:0    0   10G  0 lvm  /
sdb                       8:16   0    2G  0 disk
sdc                       8:32   0    1G  0 disk
sdd                       8:48   0    1G  0 disk
sde                       8:64   0   40G  0 disk
├─sde1                    8:65   0    1M  0 part
├─sde2                    8:66   0    1G  0 part /boot
└─sde3                    8:67   0   39G  0 part
├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
└─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm
```

Теперь нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем
старый LV размеров в 40G и создаем новый на 8G:

```
lvremove /dev/VolGroup00/LogVol00
lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
```

Создаем файловую систему и монтируем
```
mkfs.xfs /dev/VolGroup00/LogVol00 && \
mount /dev/VolGroup00/LogVol00 /mnt
```

Скопировать все данные с / раздела в /mnt:

```
xfsdump -J - /dev/vg_root/lv_root | xfsrestore -J - /mnt
```

Так же как в первый раз переконфигурируем grub, за исключением правки /etc/grub2/grub.cfg

```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;s/.img//g"` --force; done
```

Пока не перезагружаемся и не выходим из под chroot - мы можем заодно перенести /var

## Выделить том под /var - сделать в mirrot

На свободных дисках создаем зеркало

```
pvcreate /dev/sdc /dev/sdd && \
vgcreate vg_var /dev/sdc /dev/sdd && \
lvcreate -L 950M -m1 -n lv_var vg_var
```

Создаем на нем ФС и перемещаем туда /var:

```
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/   # rsync -avHPSAX /var/ /mnt/
```

На всякий случай сохраняем содержимое старого var (или же можно его просто удалить):

```
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```

монтируем новый var в каталог /var:

```
umount /mnt && \
mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:

```
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```

Перезагрузка

```
exit
reboot
```

Удалить временную Volume Group:

```
lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
pvremove /dev/sda
```

```
[root@lvm vagrant]# lsblk
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   10G  0 disk
sdb                        8:16   0    2G  0 disk
sdc                        8:32   0    1G  0 disk
├─vg_var-lv_var_rmeta_0  253:3    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:4    0  952M  0 lvm  
└─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk
├─vg_var-lv_var_rmeta_1  253:5    0    4M  0 lvm  
│ └─vg_var-lv_var        253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:6    0  952M  0 lvm  
└─vg_var-lv_var        253:7    0  952M  0 lvm  /var
sde                        8:64   0   40G  0 disk
├─sde1                     8:65   0    1M  0 part
├─sde2                     8:66   0    1G  0 part /boot
└─sde3                     8:67   0   39G  0 part
├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
└─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
```

## Выделить том под /home

Выделяем том под /home по тому же принципу что делали для /var:

```
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/
```

Правим fstab для автоматического монтирования /home

```
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

## /home - сделать том для снапшотов

Сгенерируем файлы в /home/:

```
touch /home/vagrant/file{1..20}
```

Снять снапшот:

```
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
```

Удалить часть файлов:

```
rm -f /home/vagrant/file{11..20}
```

Процесс восстановления со снапшота:

```
umount /home
lvconvert --merge /dev/VolGroup00/home_snap
mount /home
```

```
[root@lvm vagrant]# lsblk
NAME                       MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                          8:0    0   10G  0 disk 
sdb                          8:16   0    2G  0 disk 
sdc                          8:32   0    1G  0 disk 
├─vg_var-lv_var_rmeta_0    253:3    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0   253:4    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sdd                          8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1    253:5    0    4M  0 lvm  
│ └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1   253:6    0  952M  0 lvm  
  └─vg_var-lv_var          253:7    0  952M  0 lvm  /var
sde                          8:64   0   40G  0 disk 
├─sde1                       8:65   0    1M  0 part 
├─sde2                       8:66   0    1G  0 part /boot
└─sde3                       8:67   0   39G  0 part 
  ├─VolGroup00-LogVol00    253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01    253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol_Home 253:2    0    2G  0 lvm  /home
```


