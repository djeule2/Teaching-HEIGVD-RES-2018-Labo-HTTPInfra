##### Introduction

Ce gros laboratoire comprend 3 objectifs :

-  Se familiariser avec les outils logiciels qui nous permettront de construire une **infrastructure Web complète** en créant un environnement qui nous permettra de proposer un **contenu statique et dynamique** aux navigateurs Web. Pour ce faire, nous avons utilisé le fait qu'un **serveur Apache httpd** peut agir à la fois comme **serveur HTTP** et comme **reverse proxy**, ainsi que **express.js**, qui est un framework JavaScript qui facilite l'écriture d'applications Web dynamiques
- Mettre en œuvre une application web dynamique en créant des ressources **HTML**, **CSS** et **JavaScript** qui seront servies aux navigateurs et présentées aux utilisateurs. Le code JavaScript exécuté dans le navigateur envoie des requêtes HTTP asynchrones à notre infrastructure Web (requêtes AJAX) et récupère du contenu généré dynamiquement.
- Pratiquer Docker en encapsulant nos composants de notre infrastructure web dans des images Docker personnalisées.  

##### Etape 1 : Serveur HTTP statique avec apache httpd

Cette étape se réalise sur la branche **fb-apache-static**.

Le but de cette étape est d'installer et configuer un serveur httpd apache, d'encapsuler ce sevreur dans un container Docker et d'y ajouter du contenu statique HTML. Pour ce faire, nous avons trouvé sur Docker Hub une image contenant un serveur httpd de apache. Comme conseillé dans le webcast, nous avons utilisé une image apache particulière afin d'avoir PHP à disposition. Voici notre Dockerfile :

```bash
FROM php:7.0-apache

COPY content/ /var/www/html/
```

Comme décrit dans notre Dockerfile, nous copions les fichiers que se trouvent sur notre machine dans le dossier *src* et les mettons dans le dossier */var/www/html/* de notre container. Pour nos fichiers dans *content*, on a copié un template Bootstrap afin que notre page soit plus jolie et reponsive.

Pour tester cette étape, on peut contruire une image puis lancer un container avec les commandes suivantes :

```bash
docker build -t res/apache_php .
docker run -p 9090:80 res/apache_php
```

Si on va ensuite dans notre navigateur web préféré et que l'on entre : http://192.168.99.100:9090/, on se rend compte que notre navigateur communique bien avec le container au travers de la machine virtuelle.

Pour ouvrir un bash sur un container existant, on peut entrer la commande suivante :

```bash
docker exec -it <nom_du_container> /bin/bash
```

Le dossier *etc* contient les fichiers de configuration dans les systèmes UNIX. 

##### Etape 2 : Server HTTP dynamique avec express.js

Le travail fourni pour cette étape se trouve sur la branche **fb_express_dynamic**.

Le but de cette étape est d'écrire une application web dynamique qui va retourner des données JSON en utilisant Node.js. On a travaillé avec **express.js** afin de facilement répondre à des requêtes qui arrivent et renvoyer un payload JSON.

Voici notre Dockerfile : 

```bash
FROM node:8.11.2

COPY src /opt/app

CMD ["node", "/opt/app/index.js"]
```

Nous avons créer le fichier *package.json* dans le dossier *src* grâce à la commande *npm init*. On a utilisé ensuite le module npm chance en lançant la commande *npm install --save chance*, qui crée le dossier *node_modules* et qui ajoute une dépendance sur le package chance dans *package.json*.

En utilisant express.js, on a ensuite créé le fichier *index.js* qui permet de générer des animaux ayant un nom, le type d'animal dont il s'agit ainsi que leur date de naissance lorsqu'on reçoit une requête HTTP de type GET et que la ressource visée est le "/". Voici le code de *index.js* :

```javascript
var Chance = require('chance');
var chance = new Chance();

const express = require('express')
const app = express()

app.get('/', function (req, res) {
  res.send(generateAnimals());
})

app.listen(3000, function () {
  console.log('Accepting HTTP requests on port 3000.')
})

function generateAnimals() {
	var numberOfAnimals = chance.integer({
		min: 0,
		max: 10
	});
	console.log(numberOfAnimals);
	var animals = [];
	for(var i = 0; i < numberOfAnimals; i++){
		var birthYear = chance.year({
			min: 1986,
			max: 1996
		});
		animals.push({
			name: chance.first(),
			animalType: chance.animal(),
			birthday: chance.birthday({
				year: birthYear
			})
		});
	};
	console.log(animals);
	return animals;
}
```

Contruire et runner notre container :

```bash
docker build -t res/express_students .
docker run -p 9091:3000 res/express_students
```

On peut ensuite entrer http://192.168.99.100:9091/ dans notre navigateur web ou encore utiliser Postman (en lui donnant l'URL). Possibilité de travailler avec des environnements ou d'enregistrer les requêtes dans des collections afin de les partager.

##### Etape 3 : Reverse proxy avec apache (configuration statique)

Le travail pour cette étape se trouve sur la branche **fb-apache-reverse-proxy**.

Le but de cette étape est de déployer un reverse proxy qui va devenir notre point d'entrée unique dans l'infrastructure (on ne pourra plus accéder directement aux web serveurs statiques et dynamiques). On utilise à nouveau le serveur httpd de apache.

Les requête AJAX permettent d'obtenir des données d'un serveur dynamique de manière asynchrone afin de mettre à jour le contenu statique. Pour pouvoir utiliser les requêtes AJAX, on passe généralement par un reverse proxy (same-origin policy : un script qui vient d'un certain nom de domaine ne peut faire des requêtes que vers le même nom de domaine).

On peut obtenir l'adresse IP d'un container avec la commande : **docker inspect <nom du container> | grep -i ipaddress**.

Dans cette étape, on va lancer deux containers (httpd + node) puis créer une nouvelle image Docker pour notre reverse proxy en hard-codant les adresses IP des deux premiers containers (ce qui est une mauvaise idée en général, car cette adresse IP est définie dynamiquement par Docker).

On va poser une convention pour orienter les requêtes vers le bon container.

- Si l'URL est "/", on redirige vers le server web statique.
- Si l'URL est "/api/students", on redirige vers le serveur web dynamique.

Le dossier *apache2* dans *etc* contient la configuration du serveur apache. Nous avons créé un fichier *001-revers-proxy.conf* suivant :

```bash
<VirtualHost *:80>
	ServerName demo.res.ch
	
	ProxyPass "/api/students/" "http://172.17.0.3:3000/"
	ProxyPassReverse "/api/students/" "http://172.17.0.3:3000/"
	
	ProxyPass "/" "http://172.17.0.2:80/"
	ProxyPassReverse "/" "http://172.17.0.2:80/"
</VirtualHost>
```

ProxyPass et ProxyPassReverse permettent de définir un mapping.

Notre Dockerfile est le suivant :

```bash
FROM php:7.0-apache

COPY conf/ /etc/apache2

RUN a2enmod proxy proxy_http
RUN a2ensite 000-* 001-*
```

Nous avons défini sur nos machines que le nom DNS **demo.res.ch** soit résolu dans l'adresse IP 192.168.99.100.

Pour vérifier notre implémentation, on a créé le script suivant qui lance 3 containers (serveur statique, serveur dynamique et reverse proxy) :

```bash
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
```

Pour vérifier le bon fonctionnement, on peut entrer dans notre navigateur web :

-  http://demo.res.ch:8080 pour accéder au serveur statique
-  http://demo.res.ch:8080/api/students/ pour accéder au serveur dynamique

##### Etape 4: AJAX requests avec JQuery

Le travail pour cette étape se trouve sur **fb-ajax-jquery**.

Premièrement, on a modifié nos Dockerfile afin de mettre à jour la liste des paquetages et installer vi avec les commandes :

```bash
RUN apt-get update && \ apt-get install -y vim
```

On lance ensuite les containers dans le bon ordre, les adresses étant toujours hard-codées.

Dans le fichier index.html de notre serveur apache statique, on ajoute les lignes suivantes : 

```javascript
 <!-- Custom script to load animals-->
 <script src="js/students.js"></script>
```

Dans le sous-dossier *js*, nous avons donc crée un fichier qui s'appelle *students.js* (qui devrait plutôt s'appeler *animals.js*) suivant :

```javascript
$(function() {
        console.log("Loading animals");

        function loadAnimals() {
                $.getJSON( "/api/students/", function( animals ) {
                        console.log(animals);
                        var message = "No animal here";
                        if( animals.length > 0 ) {
                                message = animals[0].name + " " + animals[0].animalType;
                        }
                        $(".intro-lead-in").text(message);
                });
        };

        loadAnimals();
        setInterval( loadAnimals, 2000 );
});
```

La fonction loadAnimals est appelée tous les 2000 ms. Cette fonction change le texte du contenu statique en prenant le nom et le type du premier animal dans le payload.

##### Etape 5: Configuration du reverse proxy dynamique

Cette étape se trouve sur la branche **fb-dynamic-configuration**.

Comme expliqué dans les webcasts, on peut passer des variables d'environnement lorsqu'on démarre un container avec le paramètre **-e**.

On a créé un fichier *apache2-foreground* au même niveau que le Dockerfile en copiant le fichier original trouvé sur : https://github.com/docker-library/php/blob/master/7.0/stretch/apache/apache2-foreground. On copie cette version dans notre Dockerfile dans /usr/local/bin/.

On a ensuite créé un fichier *config-template.php* suivant dans *templates* :

```php
<?php
  $dynamic_app = getenv('DYNAMIC_APP');
  $static_app = getenv('STATIC_APP');
?>

<VirtualHost *:80>
  ServerName demo.res.ch
  
  ProxyPass '/api/students/' 'http://<?php print "$dynamic_app"?>/'
  ProxyPassReverse '/api/students/' 'http://<?php print "$dynamic_app"?>/'

  ProxyPass "/" "http://<?php print "$static_app"?>/"
  ProxyPassReverse "/" "http://<?php print "$static_app"?>/"

</VirtualHost>
```

- getenv : permet d'obtenir une variable d'environnement

On ajoute également la ligne suivante à notre Dockerfile :

```
COPY templates /var/apache2/templates
```

Dans *apache2-foreground*, on ajoute la ligne suivante qui met le résultat de l'exécution du script dans le fichier de configuration :

```
php /var/apache2/templates/config-template.php > /etc/apache2/sites-available/001-reverse-proxy.conf
```

Pour la vérification finale, nous avons créé le script suivant :

```bash
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
docker run -d --name apache_static res/apache_php

# run dynamic express containers
docker run -d res/express_students 
docker run -d res/express_students
docker run -d --name express_dynamic res/express_students

# get the IP address of the static and the dynamic container
static_app=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' apache_static`
dynamic_app=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' express_dynamic`

# run the apache_rp (reverse proxy) container 
docker run -d -p 8080:80 -e STATIC_APP=$static_app:80 -e DYNAMIC_APP=$dynamic_app:3000 --name apache_rp res/apache_rp
```

##### Load balacing : multiple server nodes

Cette partie se trouve sur la branche **fb-load-balancing**. Nous nous sommes appuyés sur le lien : https://httpd.apache.org/docs/2.4/mod/mod_proxy_balancer.html.

Afin  de supporter la répartition de charge, nous avons adapté notre script *runContainer.sh* en doublant le nombre de serveurs dynamiques et statiques. 

Nous avons aussi adapté de la façon suivante le fichier *Dockerfile* de notre reverse proxy afin que le load-balancing soit opérationnel :

```bash
RUN a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
```

Le module *proxy_balancer* permet la mise en oeuvre de la répartition de charge et le module *lbmethod_byrequets* fournis l'algorithme de planification de la répartition de charge dans le serveur, qui se base sur le comptage des requêtes.

En suivant le lien ci-dessus, on a également modifié le fichier *config-template.php* de la manière suivante :

```php
<?php
  $dynamic_app1 = getenv('DYNAMIC_APP1');
  $dynamic_app2 = getenv('DYNAMIC_APP2');
  $static_app1 = getenv('STATIC_APP1');
  $static_app2 = getenv('STATIC_APP2');
?>

<VirtualHost *:80>
  ServerName demo.res.ch
  
  # répartition de charge pour les serveurs dynamiques
  <Proxy "balancer://dynamic_app">
    BalancerMember 'http://<?php print "$dynamic_app1"?>'
    BalancerMember 'http://<?php print "$dynamic_app2"?>'
  </Proxy>
  
  # répartition de charge pour les serveurs statiques
  <Proxy "balancer://static_app">
    BalancerMember 'http://<?php print "$static_app1"?>/'
    BalancerMember 'http://<?php print "$static_app2"?>/'
  </Proxy>

  ProxyPass '/api/students/' 'balancer://dynamic_app/'
  ProxyPassReverse '/api/students/' 'balancer://dynamic_app/'

  ProxyPass '/' 'balancer://static_app/'
  ProxyPassReverse '/' 'balancer://static_app/'

</VirtualHost>
```

Dans notre script *runContainers.sh*, on lance le reverse proxy de la manière suivante :

```bash
docker run -d -p 8080:80 -e STATIC_APP1=$static_app1:80 -e STATIC_APP2=$static_app2:80 -e DYNAMIC_APP1=$dynamic_app1:3000 -e DYNAMIC_APP2=$dynamic_app2:3000 --name apache_rp res/apache_rp
```

Note : ici nous avons 2 serveurs statiques ainsi que 2 serveurs dynamiques, on pourrait bien sûr en avoir plus que cela. 

##### Load balancing : sticky session

Cette partie se trouve sur la branche **fb-load-balancing-sticky-session**. Dans cette partie, nous voulons que notre load balancer distribue des requêtes HTTP :

- D'une manière round-robin pour les serveurs dynamiques (containers *express_students*).
- En utilisant les sticky sessions  pour les serveurs statiques (containers *apache_php*).

Pour ce faire, nous avons modifié une fois de plus notre fichier *config-template.php* en s'inspirant du lien donné à l'étape *Load balacing : multiple server nodes*. Voici la nouvelle version de notre fichier *config-template.php* :

```bash
<?php
  $dynamic_app1 = getenv('DYNAMIC_APP1');
  $dynamic_app2 = getenv('DYNAMIC_APP2');
  $static_app1 = getenv('STATIC_APP1');
  $static_app2 = getenv('STATIC_APP2');
?>

<VirtualHost *:80>
  Header add Set-Cookie "ROUTEID=.%{BALANCER_WORKER_ROUTE}e; path=/" env=BALANCER_ROUTE_CHANGED
  
  ServerName demo.res.ch
  
  # répartition de charge pour les serveurs dynamiques
  <Proxy "balancer://dynamic_app">
    BalancerMember 'http://<?php print "$dynamic_app1"?>'
    BalancerMember 'http://<?php print "$dynamic_app2"?>'
  </Proxy>
 

  # répartition de charge pour les serveurs statiques
  <Proxy "balancer://static_app">
    BalancerMember 'http://<?php print "$static_app1"?>/' route=1
    BalancerMember 'http://<?php print "$static_app2"?>/' route=2
	ProxySet stickysession=ROUTEID
  </Proxy>

  ProxyPass '/api/students/' 'balancer://dynamic_app/'
  ProxyPassReverse '/api/students/' 'balancer://dynamic_app/'

  ProxyPass '/' 'balancer://static_app/'
  ProxyPassReverse '/' 'balancer://static_app/'

</VirtualHost>
```

L'abonnement à une session s'appuie sur un cookie.

Pour tester notre sticky session pour le contenu statique, on a crée un contenu HTML différent pour chacun des noeud statique. On peut voir en rafraichissant la page à mainte reprise que l'on parle toujours au même noeud. Si l'on supprime les cookies, l'abonnement à un noeud particulier prend fin et on se réabonne à un nouveau noeud. Cela semble montrer que l'on a bien une sticky session pour le contenu statique.

Pour prouver que notre load balancer peut distribuer des requêtes HTTP dans un mode round-robin, nous avons modifié notre application node *index.js* de notre contenu statique afin d'avoir un compteur que l'on incrémente à chaque nouvelle requête envoyée et que l'on transmet au travers de notre payload JSON. En analysant les payloads dans notre navigateur, on se rend compte que l'on ne parle pas toujours au même noeud, donc que l'on a bien du round-robin.

#####  Management UI

Pour cette étape, nous avons utilisé l'interface Portainer comme nous l'a suggéré notre très cher camarade Olivier Nicole. Cette interface permet de gérer facilement notre environnement Docker. Pour la lancer, nous avons ajouté les deux commandes suivantes à notre script :

```
# deploy Portainer on port 9000
docker volume create portainer_data
docker run -d -p 9000:9000 -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```

En entrant http://192.168.99.100:9000 dans notre navigateur web, on obtient une interface permettant de gérer nos containers.