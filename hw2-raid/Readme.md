# Задание
1. добавить в Vagrantfile еще дисков
2. собрати R0/R5/R10 на выбор
3. прописати собранную рейд в конф, чтобы рейд собирался при загрузке
4. сломать/починить raid
5. создать GPT раздел и 5 партиций и смонтировать их на диск

## 
```
lshw -short | grep disk
/0/100/1.1/0.0.0    /dev/sda   disk        42GB VBOX HARDDISK
/0/100/d/0          /dev/sdb   disk        268MB VBOX HARDDISK
/0/100/d/1          /dev/sdc   disk        268MB VBOX HARDDISK
/0/100/d/2          /dev/sdd   disk        536MB VBOX HARDDISK
/0/100/d/3          /dev/sde   disk        536MB VBOX HARDDISK
/0/100/d/0.0.0      /dev/sdf   disk        268MB VBOX HARDDISK
```

## Собрать RAID0/1/5/10 - на выбор (5)

Занулить блоки
```
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
```
Создать raid
```
mdadm --create -l 5 -n 5 /dev/md0 /dev/sd{b,c,d,e,f}
```
Проверим RAID
```
cat /proc/mdstat

Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]
      1040384 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
      
unused devices: <none>
```
Или
```
mdadm -D /dev/md0
```

### Создание конфигурационного файла mdadm.conf
Проверить
```
mdadm --detail --scan --verbose
```
Создать
```
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```


## Сломать/починить RAID
```
mdadm /dev/md0 --fail /dev/sdf

cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5](F) sde[3] sdd[2] sdc[1] sdb[0]
      1040384 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/4] [UUUU_]
      
unused devices: <none>

mdadm /dev/md0 --remove /dev/sdf
mdadm: hot removed /dev/sdf from /dev/md0

mdadm --zero-superblock /dev/sdf

mdadm /dev/md0 --add /dev/sdf
mdadm: added /dev/sdf

cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid5 sdf[5] sde[3] sdd[2] sdc[1] sdb[0]
      1040384 blocks super 1.2 level 5, 512k chunk, algorithm 2 [5/5] [UUUUU]
      
unused devices: <none>
```

## Создать GPT раздел, пять партиций и смонтировать их на диск

Создаем раздел GPT на RAID
```
parted -s /dev/md0 mklabel gpt
```
Создаем партиции
```
parted /dev/md0 mkpart primary ext4 0% 20% && \
parted /dev/md0 mkpart primary ext4 20% 40% && \
parted /dev/md0 mkpart primary ext4 40% 60% && \
parted /dev/md0 mkpart primary ext4 60% 80% && \
parted /dev/md0 mkpart primary ext4 80% 100%
```
  
Далее можно создать на этих партициях
```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```
  
И смонтировать их по каталогам
```
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```






