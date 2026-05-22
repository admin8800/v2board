### wyx2685-v2board
```
services:
  v2board:
    image: ghcr.io/admin8800/v2board
    container_name: v2board
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:5.7
    container_name: v2board-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: root_password
      MYSQL_DATABASE: v2board
      MYSQL_USER: v2board
      MYSQL_PASSWORD: v2board
    volumes:
      - ./mysql:/var/lib/mysql

  redis:
    image: redis:7-alpine
    container_name: v2board-redis
    restart: always
    command: redis-server --appendonly yes
    volumes:
      - ./redis:/data
```

- 启动容器
```
docker compose up -d
```
- 安装数据库
```
docker exec -it v2board php artisan v2board:install
```
- 重启容器
```
docker restart v2board
```

- 将持久化配置复制出来
```
docker cp v2board:/www/.env ./.env
```

---

迁移的时候需要在新机器映射到v2board容器
```
    volumes:
      - ./.env:/www/.env
```

---

**[宝塔部署文档](docs/README.md)**
