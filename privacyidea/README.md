privacyIDEA in docker
=====================

This is just a docker image for privacyIDEA. When started, you should be able to login to privacyIDEA at localhost:5000

Default user: admin, pass: test

Create data containers:
-----------------------
```
docker volume create --name privacyidea_config
docker volume create --name privacyidea_log
docker volume create --name privacyidea_data
docker volume create --name privacyidea_mysql_data
```

Run with http:
--------------
```
docker run -p 5000:80 --name privacyidea --restart=always -d -v privacyidea_config:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_data:/var/lib/privacyidea -v privacyidea_mysql_data:/var/lib/mysql -e PRIVACYIDEA_ADMIN_USER=admin -e PRIVACYIDEA_ADMIN_PASS=test pasientskyhosting/ps-privacyidea
```

Run with https:
---------------
```
docker run -p 5000:443 --name privacyidea --restart=always -d -v privacyidea_config:/etc/privacyidea -v privacyidea_log:/var/log/privacyidea -v privacyidea_data:/var/lib/privacyidea -v privacyidea_mysql_data:/var/lib/mysql -e PRIVACYIDEA_ADMIN_USER=admin -e PRIVACYIDEA_ADMIN_PASS=test pasientskyhosting/ps-privacyidea
```


Cleanup and retry:
------------------
```
docker volume rm $(docker volume ls -q | grep privacyidea_)
docker rm privacyidea
```
