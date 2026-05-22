运行
```
docker compose up -d
```
安装
```
docker exec -it v2board php artisan v2board:install
```
重启
```
docker restart v2board
```

将持久化配置复制出来
```
docker cp v2board:/www/.env ./.env
```
迁移的时候需要在新机器映射到v2board容器
```
    volumes:
      - ./.env:/www/.env
```

---
宝塔部署文档

README.md