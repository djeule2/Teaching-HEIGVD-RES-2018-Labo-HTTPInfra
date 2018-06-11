# kill and remove all containers
docker kill $(docker ps -qa)
docker rm $(docker ps -qa)

# build the 3 images
docker build -t res/apache_php ./apache-php-image/
docker build -t res/express_students ./express-image/
docker build -t res/apache_rp ./apache-reverse-proxy/

# run apache_static containers
docker run -d res/apache_php 
docker run -d res/apache_php 
docker run -d res/apache_php 
docker run -d --name apache_static1 res/apache_php
docker run -d --name apache_static2 res/apache_php

# run dynamic express containers
docker run -d res/express_students 
docker run -d res/express_students
docker run -d --name express_dynamic1 res/express_students
docker run -d --name express_dynamic2 res/express_students

# get the IP address of the static and the dynamic container
static_app1=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static1`
static_app2=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static2`
dynamic_app1=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic1`
dynamic_app2=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic2`

# run the apache_rp (reverse proxy) container 
docker run -d -p 8080:80 -e STATIC_APP1=$static_app1:80 -e STATIC_APP2=$static_app2:80 -e DYNAMIC_APP1=$dynamic_app1:3000 -e DYNAMIC_APP2=$dynamic_app2:3000 --name apache_rp res/apache_rp