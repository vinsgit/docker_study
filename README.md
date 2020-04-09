# README
*  dockerfile 里的 from
   from 指定基础镜像，比如 alphine slim 之类的
* 根据dockerfile设置打包镜像 命令
  docker build -t 文件名
* 创建启动服务 docker-compose up   
  1.  如果之前没有执行 docker build， 它会根据dockerfile的内容尝试自动完成   包括构建镜像，创建服务，启动服务
  2. docker-compose up  -d 就是后台运行
* docker-compose run 服务名 命令
  因为项目启动起来过后还没有创建过数据库之类的
  所以需要运行： 
  1. docker-compose run website rake db:create
  2. docker-compose run website rake db:migrate
* docker-compose down 终止所有服务，并删除容器
* 项目里 redis的服务名称是 redis
  所以在项目里要连接redis， host 就需要天 redis
  REDIS_DB = Redis.new(host: 'redis', port: 6379, db: 0)
* 项目里 mysql的服务名称是 db
  所以项目里，database.yml设置中， host就应该设置为'db'