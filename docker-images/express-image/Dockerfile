FROM node:8.11.2

RUN apt-get update && \
	apt-get install -y vim
	
COPY src /opt/app

CMD ["node", "/opt/app/index.js"]