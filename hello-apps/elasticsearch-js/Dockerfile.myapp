FROM node

EXPOSE 80

WORKDIR /app

ONBUILD ADD ./ /app/
ONBUILD RUN npm install

CMD [ "npm", "start" ]
