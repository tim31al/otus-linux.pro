# Задание
1. Создать свой RPM пакет (можно взять свое приложение, либо собрать, например,апач с определенными опциями)
2. Создать свой репозиторий и разместить там ранее собранный RPM

## Создать свой RPM пакет

Для примера возþмем пакет NGINX и соберем его с поддержкой openssl
Загрузим SRPM пакет NGINX для дальнейшей работы над ним:
```
cd /root
wget https://nginx.org/packages/centos/8/SRPMS/nginx-1.20.2-1.el8.ngx.src.rpm
```

При установке такого пакета в домашней директории создается древо каталогов для сборки

```
rpm -i nginx-1.*
```

Также нужно скачать и разархивировать последний исходники для openssl - он потребуется при сборке

```
wget https://github.com/openssl/openssl/archive/refs/heads/OpenSSL_1_1_1-stable.zip
unzip OpenSSL*stable.zip
mv openssl* openssl
```

Заранее поставим все зависимости чтобы в процессе сборки не было ошибок

```
yum-builddep rpmbuild/SPECS/nginx.spec
```

Поправить сам spec файл чтобы NGINX собирался с необходимыми нам опциями.
Путь до openssl указываем ДО каталога "--with-openssl=/srv/rmp/openssl"

```
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}" \
    --with-openssl=/root/openssl
```


По этой [ссылке](https://nginx.org/ru/docs/configure.html) можно посмотреть все доступные опции для сборки.

Теперь можно приступить к сборке RPM пакета

```
rpmbuild -bb rpmbuild/SPECS/nginx.spec
```

Убедимся что пакеты создались
```
[root@localhost ~]# ll rpmbuild/RPMS/x86_64/
total 4452
-rw-r--r--. 1 root root 2059880 Jan 29 11:52 nginx-1.20.2-1.el8.ngx.x86_64.rpm
-rw-r--r--. 1 root root 2494748 Jan 29 11:52 nginx-debuginfo-1.20.2-1.el8.ngx.x86_64.rpm
```

Теперь можно установить наш пакет

```
yum localinstall -y \
rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm

systemct enable nginx
systemctl start nginx
```

и убедиться что nginx работает

```
[root@localhost ~]# systemctl status nginx
● nginx.service - nginx - high performance web server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2023-01-29 11:57:06 UTC; 2s ago
     Docs: http://nginx.org/en/docs/
  Process: 53865 ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx.conf (code=exited, status=0/SUCCESS)
 Main PID: 53866 (nginx)
    Tasks: 2 (limit: 5972)
   Memory: 2.0M
   CGroup: /system.slice/nginx.service
           ├─53866 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx.conf
           └─53867 nginx: worker process

```

## Создать свой репозиторий и разместить там ранее собранный RPM

Создадим там каталог repo и копируем туда наш собранный RPM и, например, RPM для установки репозитория
MySQL:

```
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/nginx-1.20.2-1.el8.ngx.x86_64.rpm /usr/share/nginx/html/repo/
cd /usr/share/nginx/html/repo/
wget https://dev.mysql.com/get/mysql80-community-release-fc35-3.noarch.rpm
```

Инициализируем репозиторий командой:

```
createrepo /usr/share/nginx/html/repo/
```

Для прозрачности настроим в NGINX доступ к листингу каталога (добавитьв location / autoindex on;)

```
vim /etc/nginx/conf.d/default.conf
nginx -t
nginx -s reload
```

Проверить

```
[root@localhost repo]# curl -a http://localhost/repo/
<html>
<head><title>Index of /repo/</title></head>
<body>
<h1>Index of /repo/</h1><hr><pre><a href="../">../</a>
<a href="repodata/">repodata/</a>                                          29-Jan-2023 12:51                   -
<a href="mysql80-community-release-fc35-3.noarch.rpm">mysql80-community-release-fc35-3.noarch.rpm</a>        24-Apr-2022 13:02               12211
<a href="nginx-1.20.2-1.el8.ngx.x86_64.rpm">nginx-1.20.2-1.el8.ngx.x86_64.rpm</a>                  29-Jan-2023 12:24             2059880
</pre><hr></body>
</html>


# из хостовой машины в браузере
http://localhost:8080/repo/
```

Добавим созданные репозиторий в /etc/yum.repos.d

```
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=Otus
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF
```

Убедимся что репозиторий подключился и посмотрим что в нем есть:

```
[root@localhost repo]# yum repolist enabled | grep otus
otus                               Otus

```
