#!/bin/bash

set -e
set -o pipefail

if [ "${AWS_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "You need to set the AWS_ACCESS_KEY_ID environment variable."
  exit 1
fi

if [ "${AWS_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "You need to set the AWS_SECRET_ACCESS_KEY environment variable."
  exit 1
fi

if [ "${AWS_BUCKET}" = "**None**" ]; then
  echo "You need to set the AWS_BUCKET environment variable."
  exit 1
fi

if [ "${PREFIX}" = "**None**" ]; then
  echo "You need to set the PREFIX environment variable."
  exit 1
fi

if [ -z "${MYSQL_ENV_MYSQL_USER}" ]; then
  echo "You need to set the MYSQL_ENV_MYSQL_USER environment variable."
  exit 1
fi

if [ -z "${MYSQL_ENV_MYSQL_PASSWORD}" ]; then
  echo "You need to set the MYSQL_ENV_MYSQL_PASSWORD environment variable."
  exit 1
fi

if [ -z "${MYSQL_PORT_3306_TCP_ADDR}" ]; then
  echo "You need to set the MYSQL_PORT_3306_TCP_ADDR environment variable or link to a container named MYSQL."
  exit 1
fi

if [ -z "${MYSQL_PORT_3306_TCP_PORT}" ]; then
  echo "You need to set the MYSQL_PORT_3306_TCP_PORT environment variable or link to a container named MYSQL."
  exit 1
fi

MYSQL_HOST_OPTS="-h $MYSQL_PORT_3306_TCP_ADDR --port $MYSQL_PORT_3306_TCP_PORT -u $MYSQL_ENV_MYSQL_USER -p$MYSQL_ENV_MYSQL_PASSWORD"
CMD="mysqladmin ${MYSQL_HOST_OPTS} status"

echo "=> Creating backup script"
rm -f /backup.sh
cat <<EOF >> /backup.sh
#!/bin/bash

echo "Wating for mysql to start"
until $CMD | grep Uptime | head -1; do
  printf '.'
  sleep 1
done

BACKUP_NAME=\$(date +\%Y.\%m.\%d.\%H\%M\%S)

echo "Starting dump of ${MYSQLDUMP_DATABASE} database(s) from ${MYSQL_PORT_3306_TCP_ADDR}..."

mysqldump ${MYSQL_HOST_OPTS} ${MYSQLDUMP_OPTIONS} ${MYSQLDUMP_DATABASE} | gzip | aws s3 cp - s3://${AWS_BUCKET}/${PREFIX}/\${BACKUP_NAME}.sql.gz

echo "Done!"

exit 0
EOF
chmod +x /backup.sh

touch /mysql_backup.log
tail -F /mysql_backup.log &

if [ -n "${INIT_BACKUP}" ]; then
    echo "=> Create a backup on the startup"
    /backup.sh
fi

echo "${CRON_TIME} /backup.sh >> /mysql_backup.log 2>&1" > /crontab.conf
crontab  /crontab.conf
echo "=> Running cron job"
exec cron -f