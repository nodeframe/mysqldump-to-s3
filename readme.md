# mysqldump-to-s3

This docker container will backup a MySQL database using mysqldump, stream it to gzip, and stream that to a file on S3.

There are options where you can run this container script as a cron job.

##Options
To use this container, specify those environment variables

Variables                  | Required? | Description
---------------------------|-----------|--------------
CRON_TIME                  |  F        | The crontab schedule time, Default is 0 0 * * *
INIT_BACKUP                |  F        | Set this to `true` to start the backup right after the container is initiated. (The cron job is still running as usual)
AWS_ACCESS_KEY_ID          |  T        | The AWS s3 key id [How to get it?](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSGettingStartedGuide/AWSCredentials.html)
AWS_SECRET_ACCESS_KEY      |  T        | The AWS s3 access key
AWS_BUCKET                 |  T        | The AWS s3 Bucket name
PREFIX                     |  T        | Named prefix for the backup file and directory
MYSQL_ENV_MYSQL_USER       |  T        | MySQL database credential username
MYSQL_ENV_MYSQL_PASSWORD   |  T        | MySQL database password
MYSQL_PORT_3306_TCP_ADDR   |  T        | MySQL Server host address
MYSQL_PORT_3306_TCP_PORT   |  T        | MySQL Server port
MYSQLDUMP_DATABASE         |  T        | MySQL database to be backed up

For example of how to start this container, see below on the developing section
_______
#Developing
Feel free to config the script as a fork of your project, to test your development or configuration, you can use the following script

###Run this MySQL server to be the source of the backup
This script help you to start the MySQL server as a docker container

    docker run --name mysql \
    -e MYSQL_ROOT_PASSWORD= \
    -e MYSQL_DATABASE= \
    -e MYSQL_USER= \
    -e MYSQL_PASSWORD= \
    mysql


## To build
To build this container, simply run this command on your project directory

    docker build -t mysql-s3 .


###Start the container
After built the docker image, you might want to run the container to see if the backup works fine

    docker run -d \
    -e AWS_ACCESS_KEY_ID= \
    -e AWS_SECRET_ACCESS_KEY= \
    -e AWS_BUCKET=db-to-backup \
    -e PREFIX=prefix-of-the-file \
    -e MYSQL_ENV_MYSQL_USER= \
    -e MYSQL_ENV_MYSQL_PASSWORD= \
    -e MYSQL_PORT_3306_TCP_ADDR=db \
    -e MYSQL_PORT_3306_TCP_PORT=3306 \
    -e MYSQLDUMP_DATABASE=db-name-to-dump \
    --link mysql:db \
    mysql-s3-backup
