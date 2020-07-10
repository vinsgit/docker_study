# Dockerize a Rails App with Postgres and Nginx
## Docker Basic Introduction
### The Three Elements of Docker
#### Docker Image
An image is a read-only template with instructions for creating a Docker container. Often, an image is based on another image, with some additional customization.  For example, my demo is based on the ruby2.6.6-alpine image, which builds on an alpine Linux image, but the ruby2.6.6-alpine image will install the software that the ruby development environment relies on. 

#### Docker Container
A docker container is a runnable instance of an image which is used to 
isolate itself from other containers and its host machine and run the environment, which is a bit like a simplified version of the Linux environment
We can use Docker Image to create a Docker Container, we can also stop it and delete it, etc

#### Docker Registry
A Docker registry stores Docker images. We can upload our Image
and we can also download these Docker Images on other machines.
Docker Hub is the most public registry stores that anyone can use，
Docker is configured to look for images on Docker Hub by default
### Docker configuration files

#### Dockerfile
Dockerfile is used to customize the image

#### docker-compose.yml
Compose is a tool that defines and runs multiple docker containers, and we can use docker-compose.yml to configure the services that our application needs. After all, settings are done,  we only need to remember 3 docker-compose commands.
Here they are:
1.  `docker-compose build`, which is to build the images based on the settings in docker-compose.yml.
2.  `docker-compose  up`, which  will attempt to automate several operations including building  images (if Compose didn't find the relative images, it will build images based on your settings in the docker-compose.yml just like what `docker-compose build'` does ), it will also creating  services, starting  services, and associating  services related containers
3.  `docker-compose  down`, it will stop and remove containers, networks, images, and volumes

## Dockerizing a Rails application
### Step 0: Simply build a Rails application
1. Create new a rails project
    ```ruby
    rails new docker_study -d postgresql
    ```

2. Edit `config/database.yml`
    ```ruby
    default: &default
      adapter: postgresql
      encoding: unicode
      username: docker_study
      password: root
      pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
      timeout: 5000
      host: localhost

    development:
      <<: *default
      database: docker_study_development

    test:
      <<: *default
      database: docker_study_test

    production:
      <<: *default
      database: docker_study_production
    ```
3. Generate a scaffold for the Post resource
    ```ruby
    rails generate scaffold Post name:string title:string content:text
    ```
    ![0](https://1.bp.blogspot.com/-IvYkZXB7h8I/XpW4V2VCaSI/AAAAAAAAADY/dczzPlRERs8-G00e19GIf_b_fVtYe7KjQCLcBGAsYHQ/w945-h600-p-k-no-nu/0.png)
4. Create database
    ```ruby
    rails db:create
    ```
5. Create tables
     ```ruby
    rails db:migrate
    ```
6. Run `rails s` and have a check on localhost:3000 to  make sure this Rails project works smoothly 
    ![1](https://1.bp.blogspot.com/-rHZ7jWDXSRs/XpW4WGZ2boI/AAAAAAAAADc/2QWLR6bM4qYcCQtw5JxrdS3LtpwPkN54ACLcBGAsYHQ/s1600/1.png)
    ![2](https://1.bp.blogspot.com/-pcmMnF0V7_Y/XpW4WP6-hsI/AAAAAAAAADg/CUfVgm24DCwsWdJ_Mkwtf01I9AHtRqI3ACLcBGAsYHQ/s1600/2.png)
    ![3](https://1.bp.blogspot.com/-x94O0wW8SM0/XpW4WrJ-F7I/AAAAAAAAADk/Gr7uH0IN2W0bifSJq6-06S6R499gV2VrwCLcBGAsYHQ/s1600/3.png)

### Step 1: Getting Started with docker
1.  Install Docker 
    ```bash
    sudo apt-get install docker-ce docker-ce-cli containerd.io
    ```
2.  Start Docker
    ```bash
    sudo systemctl enable docker
    sudo systemctl start docker
    ```
3.  Check if the docker installation was successful.
    ```bash
    sudo docker run hello-world
    ```
    ![4](https://1.bp.blogspot.com/-wMKcd9U8ICk/XpW4WxnD2iI/AAAAAAAAADo/5PGCZXPTqwMwG5Ocj5oR1noGrnSdFuIJQCLcBGAsYHQ/s1600/4.png)
4. Next we are about to set the dockerfile
   Dockerfile:
    ```ruby
    1    FROM ruby:2.6.6-alpine
    2    # Specify the maintainer of the image
    3    MAINTAINER rosevita <qs2811531808@gmail.com>
    4    # Update installation source for alpinelinux
    5    RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
    6    # Install the dependencies
    7    RUN apk --update add build-base libpq nodejs vim imagemagick postgresql-dev tzdata yarn
    8    # We use the command RUN on the Dockerfile to execute the commands we want to use in the image.
    9    RUN mkdir /app
    10   # Specify work directory
    11   WORKDIR /app
    12   # Copy the file to the target path on a image of new layer  
    13   COPY Gemfile /app/Gemfile
    14   COPY Gemfile.lock /app/Gemfile.lock
    15   ENV RAILS_ENV production
    16   RUN gem install bundler:2.1.4
    17   RUN bundler -v
    18   RUN bundle install
    19   COPY . /app
    20   CMD rake db:migrate assets:precompile && puma -C config/puma.rb
    ```
    * **Why we need to specify workdir**
    
      Here is an example to explain it: 
      > In the Linux terminal
      1.  I created a new directory called test_dockerfile
      2. I created a new Dockerfile in that directory, now I set it up like this   
            ```ruby
             1	FROM alpine
             2	RUN mkdir /app
             3	RUN cd /app
             4	RUN echo "hello" > hello.txt
             5	RUN cat /app/hello.txt
            ```
      3. We execute `docker build` command
        ![test_dockerfile](https://1.bp.blogspot.com/-no5r7eeC0PA/XpfKj1eC5RI/AAAAAAAAAEk/VFsts5GKQNknuzpCdVQTCJ9CJD9TBttKQCLcBGAsYHQ/s1600/1587006008%25281%2529.jpg)

            Now we can see the error there, which says it can't find the hello.txt. So It turns out the docker image works not like Shell. When we use Shell, several lines of commands are in the same process, therefore, the memory state which is modified by the previous command will directly affect the latter command. So in the shell, we can print out hello.txt  successfully following those commands, because they are in the one process. But it works differently when we build a docker image. When we build a docker image, we can imagine that we are playing lego, and each docker command in the Dockerfile is considered a layer of legos, so the image will be built layer by layer. The front layer is the foundation of the next layer. But If the build of the font layer is completed, then it won't change anymore, and any change on the latter layer affect only on its own. so every layer is separated from each other 
&emsp;
        So, in this example, we didn't create the hello.txt at the layer, in which we wanted to execute `cat /app/hello.txt` （cat->concatenate）. That way there is the error and that's why we should use WORKDIR command  when we want each layer to work with the same directory
&emsp;

    * **Why do I copy Gemfile and Gemfile.lock separately instead of copying all the files before the `RUN bundle install`** <br>
     Let me give an example: If I just modified an HTML file, now I want to rebuild my image, so what if I copy all local files to the app directory before I execute `RUN bundle install `command. Then when I build my image since I changed some code, the docker will execute all the remaining commands from the line where I copied all the files,  So the "RUN bundle install" command will be executed whether or not Gemfile and Gemfile.lock are changed.
&emsp;
     But according to my original configuration, as long as I don't modify Gemfile and Gemfile.lock, then `RUN bundle install` won't be executed. The commands in the dockerfile will be executed from line 19 onwards.

5. The settings in my docker-compose.yml
    ```ruby
     1	version: '3'
     2	services:
     3	  app:
     4	    build: /home/qs/Desktop/docker_study
     5	    ports:
     6	      - "3000:3000"
     7	    environment:
     8	      - DATABASE_URL=postgres://docker_study:root@db/postgres
     9	      - SECRET_KEY_BASE=147aebc025505a5a81bafe66b4ad58061c5717bdce89cea8c173296ef35bd5b8231fe61d00da218a7f4901c101a6abe2c0fd7b306de248f0a3e2c68c49361da8
    10	      - RAILS_SERVE_STATIC_FILES=true
    11	    depends_on:
    12	      - db
    13	  db:
    14	    image: postgres:10.12
    15	    environment:
    16	      - "POSTGRES_USER=docker_study"
    17	      - "POSTGRES_PASSWORD=root"
    ```
    Now we are going to run two containers at the same time, one is our Rails App and the other is the Postgres database,  the database part I will directly use image: postgres:9.6, which will be auto download from Dockerhub by docker, and the Rails App is generated from the Dockerfile of the current directory 

    Before the end of the Rails application's container launch, the command：rake db:migrate (set by the Dockerfile CMD) need to be run first, which means that the Container of the Rails App can be started only after the Container of the database is started, so you can see the following setting in` docker-compose.yml`
    ```ruby
    app:
      depends_on:
         - db
    ```
6. Execute docker-compose up to run the containers After adding these two settings to the docker-compose.yml. 
We can run docker-compose up on Terminal. 

7.  To Check if the containers work fine 
    * In the meantime, we can check if we have successfully run both containers by commanding: `docker ps`.
      ![6](https://1.bp.blogspot.com/-tsfUPpKrJZk/Xpa-TOfUwwI/AAAAAAAAAEE/oJ1O9nNXOiEI_63t4C8Q5VPs_KDq3X6EwCLcBGAsYHQ/s1600/6.jpg)r
    * Type  http://127.0.0.1:3000 on the browser. We can see the project running! 
      ![1](https://1.bp.blogspot.com/-rHZ7jWDXSRs/XpW4WGZ2boI/AAAAAAAAADc/2QWLR6bM4qYcCQtw5JxrdS3LtpwPkN54ACLcBGAsYHQ/s1600/1.png)

### Step 3: Puma with Nginx in docker 
> Goal: add Nginx settings to docker-compose.yml, let Nginx handle traffic with Puma.

1. To make Puma work with Nginx, we need to bind Puma on the Unix domain socket rather than bind it on  TCP/IP network socket, so we need note-off ENV.fetch("PORT") { 3000 } in the puma file

    Edit `config/puma.rb`
    ```ruby
    # port        ENV.fetch("PORT") { 3000 }
    bind "unix:///app/tmp/sockets/puma.sock"
    ```
2. Since we need to use Nginx as our reverse proxy server, so we need to create another Dockerfile, which path could be `docker/nginx/Dockerfile`。
Now we are going to build an Nginx image base on the official Nginx image and customize our Nginx for handling requests.
     * Create Dockerfile in a specified directory  
     * Since we need the Nginx to use our customized `default.conf`, so we should copy our local  `default.conf` to the Nginx directory in the image
     ` root directory/docker/nginx/Dockerfile `
        ```ruby
        FROM nginx
        COPY default.conf /etc/nginx/conf.d/default.conf
        ```
     * Customize `default.conf`
     * The fifth line is for Nginx to transport the request to Puma
        ```ruby
        1	server {
        2	    listen       80;
        3	    server_name  localhost;
        4	    location / {
        5	        proxy_pass http://unix:/app/tmp/sockets/puma.sock;
        6	        proxy_set_header X-Forwarded-Host localhost;
        7	    }
        8	}  
        ```

3. Modify docker-compose.yml to add Nginx service
    We need the Nginx container to share one puma.sock file with the web container .  So we need to use the `valumes` command  to make both of them share our local `/tmp/sockets` file
      ```ruby
    1	version: '3'
    2	services:
    3	  app:
    4	    build: .
    5	    ports:
    6	      - "3000:3000"
    7	    environment:
    8	      - DATABASE_URL=postgres://docker_study:root@db/postgres
    9	      - SECRET_KEY_BASE=147aebc025505a5a81bafe66b4ad58061c5717bdce89cea8c173296ef35bd5b8231fe61d00da218a7f4901c101a6abe2c0fd7b306de248f0a3e2c68c49361da8
    10	     - RAILS_SERVE_STATIC_FILES=true
    11	   depends_on:
    12	     - db
    13	   volumes:
    14	     - /tmp/sockets:/app/tmp/sockets
    15	 db:
    16	   image: postgres:10.12
    17	   environment:
    18	     - "POSTGRES_USER=docker_study"
    19	     - "POSTGRES_PASSWORD=root"
    20	nginx:
    21	   build: docker/nginx/.
    22	   ports:
    23	     - "80:80"
    24	   volumes:
    25	     - /tmp/sockets:/app/tmp/sockets
    26	   depends_on:
    27	     - app
    ```
    Since we modified the `config/puma.rb`, and added Nginx service to docker so we need to run `docker-compose build`  to update the images, after everything is done, we could run `docker-compose up` again.
   
    This time Nginx can work with Puma! Since Nginx is set to port 80, We can directly type 127.0.0.1 into our browser to see our website. , there is no need to add:3000 as the port number
    ![after nginx image is build up](https://1.bp.blogspot.com/-oQA9wcMB8pk/XpcRS0uDImI/AAAAAAAAAEQ/dFQ6FKWkY90IuYv7mcaU1ZCvD14Uq8XOACLcBGAsYHQ/s1600/7.png)
   
    Then try to use `docker ps`  to see the container we started.
    ![after nginx image is build up](https://1.bp.blogspot.com/-gEamn2-Eyf4/XpcRTCi7RoI/AAAAAAAAAEU/9DN_IaJF3xQiYwwHiR_rAOGctEehoCQZwCLcBGAsYHQ/s1600/1586958267%25281%2529.jpg)
    
If we wanna stop and delete the containers we need to execute `docker-compose down`
As you can see this  command  will stop and remove all the containers created from the docker-compose.yml  file
![docker compose down](https://1.bp.blogspot.com/-5RVL1R3tKoY/Xpxj-PdCPlI/AAAAAAAAAE8/H513j2Ecym8nOb86oZB4rzdI_mnC5JilQCLcBGAsYHQ/s1600/1587307464%25281%2529.jpg])
