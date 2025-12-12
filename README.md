# Тестовое задание: Развертывание инфраструктуры с балансировкой, бэкапами и мониторингом

# **Краткое описание**

1. Установка Docker

```markdown
apt update
apt install apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

1. Поднимаем балансировщик нагрузки HAProxy

```markdown
apt install haproxy
```

Настраиваем его добавляя в конец файла конфигурации /etc/haproxy/haproxy.cfg 

```markdown
frontend http
    bind *:80
    default_backend doku_backend

backend doku_backend
    balance roundrobin
    server doku1 127.0.0.1:8081 check
    server doku2 127.0.0.1:8082 check
```

1. Поднимаем два докера с DokuWiki

```markdown
docker run -d --name doku1 -p 8081:80 --restart=always linuxserver/dokuwiki
docker run -d --name doku2 -p 8082:80 --restart=always linuxserver/dokuwiki
```

1. **Резервное копирование**

Создаём файл /opt/backups/backup_doku.sh (ротация логов последних 7)

```markdown
#!/bin/bash
SRC="/var/lib/docker/volumes"
DST="/opt/backups/dokuwiki"
DATE=$(date +%Y-%m-%d_%H-%M)
mkdir -p $DST
rsync -a --delete $SRC "$DST/$DATE"
cd "$DST"
ls -1 | sort | head -n -7 | xargs rm -rf
```

Создаём крон задачу

```markdown
0 3 * * * root /opt/backups/backup_doku.sh
```

1. **Настройка Мониторинга (Zabbix + Grafana)**

Создаём Docker Compose: `/opt/zabbix/docker-compose.yml`

```markdown
services:
  zabbix-server:
    image: zabbix/zabbix-server-pgsql
    environment:
      DB_SERVER_HOST: postgres
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: zabbixpass
    ports:
      - "10051:10051"

  zabbix-web:
    image: zabbix/zabbix-web-nginx-pgsql
    environment:
      DB_SERVER_HOST: postgres
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: zabbixpass
      ZBX_SERVER_HOST: zabbix-server
    ports:
      - "8080:8080"

  postgres:
    image: postgres:14
    environment:
      POSTGRES_USER: zabbix
      POSTGRES_PASSWORD: zabbixpass
      POSTGRES_DB: zabbix
```

Далее устанавливаем **Zabbix Agent** на хосте и прописываем ему ip сервера. Также добавляем на сервере хост машыны.

Ставим **Grafana**

```markdown
docker run -d -p 3000:3000 grafana/grafana
```

Заходим в неё и добавляем плагин zabbix и добавляем метрики с него нужные.

1. **Пароли и доступы**

**DokuWiki:** [http://188.208.197.105](http://188.208.197.105/)
**Zabbix:** [http://188.208.197.105:8080/](http://188.208.197.105:8080/) Admin/89jJKNiu3fe4
Grafana: [http://188.208.197.105:3000](http://188.208.197.105:3000/) admin/klm309jiOKL

1. Тестирование

```markdown
for i in {1..10}; do curl -s -I http://188.208.197.105 | grep -E "(HTTP|Date|Content)"; echo "---"; don
```

Проверяем что сайт доступен, далее ложим главный докер сайта

```markdown
docker stop doku1
```

И снова проверяем доступность.

**Восстановление из бэкапа:**

```markdown
rsync -a /opt/backups/дата_нужного_бекапа/ /var/lib/docker/volumes/
```


