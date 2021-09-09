DATABASE_TO_BACKUP=database-name
DATE=`date +"%Y%m%d"`
SSH_HOST=host-ip
SSH_PORT=ssh-port

# constant for migration
FILENAME=${DATABASE_TO_BACKUP}-${DATE}
BACKUP_FILE_NAME=${FILENAME}.sql.gz

set -eux
INCLUDED_TABLES=(
table_1
table_2
table_3
...
)

INCLUDED_TABLES_STRING=''
for TABLE in "${INCLUDED_TABLES[@]}"
do :
   INCLUDED_TABLES_STRING+=" ${TABLE}"
done

echo ${INCLUDED_TABLES_STRING}

# add new user and key authorization
SSH_MIGRATION_USER=user-name
SSH_MIGRATION_IDENTITY=~/.ssh/id_rsa
MYSQL_HOST=mysql-host
MYSQL_PORT=3306

MYSQL_CLOUD_HOST=mysqlazure.mysql.database.azure.com #Azure Server name
MYSQL_CLOUD_USER=MySQLAdmin@mysqlazure #Server admin login name
MYSQL_CLOUD_PASS=MySQLpass

MYSQL_USER=database-user-name-with-dump-priviliges
MYSQL_PASSWORD=database-user-password-with-dump-priviliges

LOCK_FILE_PATH=~/migration
mkdir -p ${LOCK_FILE_PATH} || {
    printf "# cant create lock file\n"
    exit 1
}
create_lock_file()
{
    if [[ -f ${LOCK_FILE_PATH}/$1 ]]; then
        printf "\n`date +"%Y-%m-%d %H:%m:%S"`: [$1] migrating in progress... avoiding"
        exit 2
    fi
    touch ${LOCK_FILE_PATH}/$1 || {
        printf "Cannot create file $1\n"
        exit 3
    }
    printf "\n`date +"%Y-%m-%d %H:%m:%S"`: ## Lock file created: $1"
}
remove_lock_file()
{
    rm ${LOCK_FILE_PATH}/$1 || {
        printf "Cannot remove file $1\n"
        exit 10
    }
    printf "\n`date +"%Y-%m-%d %H:%m:%S"`: ## remove lock file: $1"
}
# main exec
printf "## Migration started\n"
printf "\n`date +"%Y-%m-%d %H:%m:%S"`: ## database: ${DATABASE_TO_BACKUP} tables: ${INCLUDED_TABLES_STRING} for date ${DATE} started\n"
create_lock_file ${FILENAME}
printf "\n`date +"%Y-%m-%d %H:%m:%S"`: ## database: ${DATABASE_TO_BACKUP} tables: ${INCLUDED_TABLES_STRING} send remote command to create backup\n"

ssh ${SSH_MIGRATION_USER}@${SSH_HOST} "mkdir -p ~/${DATABASE_TO_BACKUP}; mysqldump -h ${MYSQL_HOST} \
   -P ${MYSQL_PORT} \
   -u ${MYSQL_USER} \
   -p${MYSQL_PASSWORD} \
   ${DATABASE_TO_BACKUP} \
   ${INCLUDED_TABLES_STRING} 
   --create-options --extended-insert --add-drop-table --lock-tables --disable-keys --add-locks | gzip > ~/${DATABASE_TO_BACKUP}/${BACKUP_FILE_NAME};"


printf "\n`date +"%Y-%m-%d %H:%m:%S"`:## database: ${DATABASE_TO_BACKUP} create local folders to mount remote directory\n"
mkdir -p /mnt/${DATABASE_TO_BACKUP}
chmod 775 /mnt/${DATABASE_TO_BACKUP}
printf "\n`date +"%Y-%m-%d %H:%m:%S"`:## database: ${DATABASE_TO_BACKUP} mounting remote directory\n"
sshfs ${SSH_MIGRATION_USER}@${SSH_HOST}:/home/migration/${DATABASE_TO_BACKUP} /mnt/${DATABASE_TO_BACKUP} -p ${SSH_PORT} -o allow_other -o ro -o IdentityFile=${SSH_MIGRATION_IDENTITY}

pv /mnt/${DATABASE_TO_BACKUP}/${BACKUP_FILE_NAME} | \
gunzip | \
mysql -h ${MYSQL_CLOUD_HOST} -u ${MYSQL_CLOUD_USER} -p${MYSQL_CLOUD_PASS} ${DATABASE_TO_BACKUP}

umount /mnt/${DATABASE_TO_BACKUP}
remove_lock_file ${FILENAME}

echo "tables ${INCLUDED_TABLES_STRING} were refreshed, stored in ${MYSQL_CLOUD_HOST} database: ${DATABASE_TO_BACKUP}"