## nginx-php56

Docker image for running php56 and nginx (https://www.nginx.com) servers. This docker image is designed to be run as user www-data. So no root needed. Because of this it exposes port 8080. To run it on port 80 do something like this.

```docker run -d -p 80:8080 cloudmanic/nginx-php56```

## More on non-root launch.

* As you can see in the Dockerfile the user within the container is www-data (typical user for this type of thing). It has UID 33. Which happens to be the default user in most Ubuntu installs. This also matches up with www-data group which is GUID 33 as well. When mounting volumes make sure you have a user on your system with an UID 33 and GUID 33 (or update the Dockerfile to meet your needs).

* Here is a sample docker-compose.yml. Notice we pass in our own default.conf, this is common if you want to support deeper configurations. 

```
version: '2.1'

services:

  nginxphp:

    image: cloudmanic/nginx-php56
 
    volumes:
      - ./www:/www
      - ./logs:/logs
      - ./cache:/cache
      - ./nginx-default.conf:/etc/nginx/conf.d/default.conf
```


## Todo

* Maybe modify to do something like this (https://denibertovic.com/posts/handling-permissions-with-docker-volumes/)[https://denibertovic.com/posts/handling-permissions-with-docker-volumes/]

