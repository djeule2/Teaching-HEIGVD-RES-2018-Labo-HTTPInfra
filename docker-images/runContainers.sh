# kill and remove all containers
docker kill $(docker ps -qa)
docker rm $(docker ps -qa)

# build the 3 images
docker build -t res/apache_php ./apache-php-image/
docker build -t res/express_students ./express-image/
docker build -t res/apache_rp ./apache-reverse-proxy/

# run apache_static container
docker run -d res/apache_php 

# run dynamic express container
docker run -d res/express_students 

# run the apache_rp (reverse proxy) container 
docker run -p 8080:80 res/apache_rp