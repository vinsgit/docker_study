[toc]
# A tutorial on dockerizing a Rails application
## Docker Basic Introduction
### The Three Elements of Docker
#### Docker Image
An image is a read-only template with instructions for creating a Docker container. Often, an image is based on another image, with some additional customization.  For example, my demo is based on the ruby2.6.6-alpine image, which builds on an alpine Linux image,but ruby2.6.6-alphine image will install  the software that the ruby development environment relies on. 

#### Docker Container
A docker container is a runnable instance of an image which is used to 
solate itself from other containers and its host machine and run the enviroment, which is a bit like a simplified version of the Linux environment
We can use Docker Image to create a Docker Container, we can also stop it and delete it, etc

#### Docker Registry
A Docker registry stores Docker images. We can upload our Image
and we can also download these Docker Images on other machines.
Docker Hub is the most  public registry that anyone can use and 
Docker is configured to look for images on Docker Hub by default
### Docker configuration files
#### Dockerfile
Dockerfile is used to customize the image

#### docker-compose.yml

Compose is a tool that defines and runs multiple docker containers, and we can use docker-compose.yml to configure the services that our application needs. After all settings are done ,  we only need to remember 3 docker compose command .
Here they are:
1.  `docker-compose build`, which is to build the images based on the settings in docker-compose.yml.


2.  `docker-compose  up` ,which  will attempt to automate a number of operations including building  images (if Compose didnt find the relative images, it will build images based on your settings in the docker-compose.yml just like what `docker-compose build'` does ), it will also creating  services, starting  services, and associating  services related containers
3.  `docker-compose  down`  , it will stop and remove containers, networks, images, and volumes

## Dockerizing a Rails application
### Step 0: Simply build a Rails 
1. create new a rails project
    ```ruby
    rails new docker_study -d postgresql
    ```

2. edit `config/database.yml`
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
3. generating a scaffold for the Post resource
    ```ruby
    rails generate scaffold Post name:string title:string content:text
    ```
    ![1](https://1.bp.blogspot.com/-IvYkZXB7h8I/XpW4V2VCaSI/AAAAAAAAADY/dczzPlRERs8-G00e19GIf_b_fVtYe7KjQCLcBGAsYHQ/s1600/0.png)
4. create database
    ```ruby
    rails db:create
    ```
5. create tables
     ```ruby
    rails db:migrate
    ```
6. run `rails s` and have a check on localhost:3000 to  make sure this Rails project works smoothly 
![2](https://1.bp.blogspot.com/-rHZ7jWDXSRs/XpW4WGZ2boI/AAAAAAAAADc/2QWLR6bM4qYcCQtw5JxrdS3LtpwPkN54ACLcBGAsYHQ/s1600/1.png)
![3](https://1.bp.blogspot.com/-pcmMnF0V7_Y/XpW4WP6-hsI/AAAAAAAAADg/CUfVgm24DCwsWdJ_Mkwtf01I9AHtRqI3ACLcBGAsYHQ/s1600/2.png)
![4](https://1.bp.blogspot.com/-x94O0wW8SM0/XpW4WrJ-F7I/AAAAAAAAADk/Gr7uH0IN2W0bifSJq6-06S6R499gV2VrwCLcBGAsYHQ/s1600/3.png)

### Step 1: Getting Started with docker
1. Install Docker 
    ```bash
    sudo apt-get install docker-ce docker-ce-cli containerd.io
    ```
2.  Start Docker
    ```bash
    sudo systemctl enable docker
    sudo systemctl start docker
    ```
3. Verify that the installation was successful.
    ```bash
    sudo docker run hello-world
    ```
    ![5](https://1.bp.blogspot.com/-wMKcd9U8ICk/XpW4WxnD2iI/AAAAAAAAADo/5PGCZXPTqwMwG5Ocj5oR1noGrnSdFuIJQCLcBGAsYHQ/s1600/4.png)
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
        8    #We use the command RUN on the Dockerfile to execute the commands we want to use in the image.
        9    RUN mkdir /app
       10   #Specify work directory
       11   WORKDIR /app
       12   #Copy the file to the target path on a image of new layer  
       13   COPY Gemfile /app/Gemfile
       14   COPY Gemfile.lock /app/Gemfile.lock
       15   ENV RAILS_ENV production
      16    RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ \ && gem sources -l
       17   RUN gem install bundler:2.1.4
       18   RUN bundler -v
       19   RUN bundle install
       20   COPY . /app
       21   CMD rake db:migrate assets:precompile && puma -C config/puma.rb
    ```
    * Why we need to specify workdir
    
      ![6](https://1.bp.blogspot.com/-_x0hT7XeZgs/XpW4WwhDv6I/AAAAAAAAADs/jIAzW24AJSMONMV-xezpkkBnwG6rFSEmwCLcBGAsYHQ/s1600/5.png)  
    &nbsp;&nbsp;&nbsp;  It turns out  docker image works not like Shell. When we use Shell, several lines of commands are in the same process execution evironment, therefore , the memory state which is modified  by the previous command will directly affect the latter command. 
    &nbsp;&nbsp;&nbsp; But it works different with  docker image, when we build a docker image ,you can imagine that you are playing lego, the image will be build  layer by layer. The front layer is the fundation of the back layer. if the build of the font layer is completed, then it wont change anymore, and any change on the latter layer affect only on its own. 
    &nbsp;&nbsp;&nbsp; Therefore, in this example , we did create the hello.txt ,its just we didnt create it at the layer, in which we wanted to execute `cat /app/hello.txt`
    &nbsp;&nbsp;&nbsp; So when we need to change the  location of working directory in every layer, we should use WORKDIR command to specify the directory

    * Why i copy Gemfile and Gemfile.lock seperatly instead of copying all the files at the front 
    &nbsp;&nbsp;&nbsp;  Since we know image is built layer by layer , So let's assume that  i copied all the files at the front and i edited something on my program without changing my gemfile。 Then im ready to build my image. Since the code was changed by me , The docker will execute all remaining commands from the `COPY . /app ` on the Dockerfile. But according to my original configerations, if i didnt modify Gemfile and Gemfile.lock , then RUN bundle install wouldn't be executed. The commands in the dockerfile would be executed from line 20.

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
        13	    volumes:
        14	      - /tmp/sockets:/app/tmp/sockets
        15	
        16	  db:
        17	    image: postgres:10.12
        18	    environment:
        19	      - "POSTGRES_USER=docker_study"
        20	      - "POSTGRES_PASSWORD=root"
        21	
        22	  nginx:
        23	    build: docker/nginx/.
        24	    ports:
        25	      - "80:80"
        26	    volumes:
        27	      - /tmp/sockets:/app/tmp/sockets
        28	    depends_on:
        29	      - app
    ```
### Step 3: Puma with Nginx in docker 
