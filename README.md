# Docker-flask-wkhtmltopdf-apache-mod-wsgi-tls
Dockerfile for a project that had an ember and flask app. The flask app made use of wkhtmltopdf. Running over https on apache with mod-wsgi. 

So I've had some trouble with a flask app running wkhtmltopdf and access and permission errors. I've also had issues with the image size

The enclosed `Dockerfile` is where Ive ended up. A working image with no permission errors thats about 2/3rds the size that it once was.
A couple of things:
 * This isnt ideal. Its still quite a big image
 * This isnt the latest version of apache or its config
 * The ownership as it is down isnt ideal
 * ...but it works. 

Certs are stored on the server. Docker image is run with the following command:  
```  
docker run -d -p 80:80   
              -p 443:443   
              -v $(pwd)/em3/certs:/etc/apache2/ssl   
              -v $(pwd)/em3/conf/app_conf.conf:/etc/apache2/sites-available/app_conf.conf   
              --name <name> <image_name>  
```
