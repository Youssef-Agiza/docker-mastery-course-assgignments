FROM node:6-alpine



RUN apk add --no-cache tini \
    && mkdir -p /usr/src/app,

WORKDIR /usr/src/app 
COPY package.json /usr/src/app/

RUN npm install \
    && npm cache clean -f

COPY . /usr/src/app/

EXPOSE 3000

CMD [ "/sbin/tini","--","node" ,"./bin/www"]

