#!/bin/bash
set -e

# Remote connection details
REMOTE_USER="apps"
REMOTE_GUP_HOST="nomad-client-3.ub.gu.se"
REMOTE_GUPEA_HOST="nomad-client-2.ub.gu.se"
REMOTE_BACKUP="/tmp/gup.sql"
REMOTE_GUPEA_DIR="/mnt/backups/databases/gupea-gupeadb-1"
GUPEA_FILE_PATTERN="dspace_*.sql"
LOGFILE=run.log
SRC=sql
DEST=res

mkdir -p ${SRC} ${DEST}

echo "" >> "$LOGFILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') Starting." >> $LOGFILE

# Check if any containers are not running
if ! docker compose ps | grep -q "Up"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Some containers are not running. Start them and rerun script." >> $LOGFILE
    echo "Some containers are not running. Start them and rerun script."
    exit 1;
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') All containers are running." >> $LOGFILE
fi

# Get a backup-copy of GUP
if [ -f "gup.sql" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Local GUP-file exists. Using it." >> $LOGFILE
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Backing up GUP on ${REMOTE_GUP_HOST}..." >> $LOGFILE
    #ssh ${REMOTE_USER}@${REMOTE_GUP_HOST} "cd /apps/gup/ && ./docker-compose-release.sh exec db pg_dump -U gup_user -d gup_db > ${REMOTE_BACKUP}"
    ssh ${REMOTE_USER}@${REMOTE_GUP_HOST} "cd /apps/gup/ && ./docker-compose-release.sh exec db pg_dump -U gup_user -d gup_db" > gup.sql
    echo "$(date '+%Y-%m-%d %H:%M:%S') Backup created on remote server: ${REMOTE_BACKUP}" >> $LOGFILE

    #echo "$(date '+%Y-%m-%d %H:%M:%S') Downloading ${REMOTE_BACKUP}..." >> $LOGFILE
    #rsync --progress ${REMOTE_USER}@${REMOTE_GUP_HOST}:${REMOTE_BACKUP} gup.sql
    #echo "$(date '+%Y-%m-%d %H:%M:%S') Backup transferred to local machine." >> $LOGFILE

    #ssh ${REMOTE_USER}@${REMOTE_GUP_HOST} "rm -f ${REMOTE_BACKUP}" >> $LOGFILE
    #echo "$(date '+%Y-%m-%d %H:%M:%S') Backup file removed from remote server." >> $LOGFILE
    echo "$(date '+%Y-%m-%d %H:%M:%S') GUP downloaded" >> $LOGFILE
fi

# Get last backup-copy of GUPEA

if [ -f "gupea.sql" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Local GUPEA-file exists. Using it." >> $LOGFILE
else

    LATEST_FILE=$(ssh ${REMOTE_USER}@${REMOTE_GUPEA_HOST} "ls -t ${REMOTE_GUPEA_DIR}/${GUPEA_FILE_PATTERN} | head -n 1")

    if [ -z "$LATEST_FILE" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') No file found matching pattern ${GUPEA_FILE_PATTERN}" >> $LOGFILE
        exit 1
    fi

    echo "$(date '+%Y-%m-%d %H:%M:%S') Fetching ${LATEST_FILE}" >> $LOGFILE
    scp ${REMOTE_USER}@${REMOTE_GUPEA_HOST}:"${LATEST_FILE}" gupea.sql
    echo "$(date '+%Y-%m-%d %H:%M:%S') GUPEA downloaded" >> $LOGFILE

fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Restore the databases" >> $LOGFILE
docker compose exec db psql -U postgres -c "DROP DATABASE IF EXISTS gup_db;"
docker compose exec db psql -U postgres -c "DROP DATABASE IF EXISTS dspace;"
docker compose exec db psql -U postgres -c "DROP ROLE IF EXISTS dspace;"
docker compose exec db psql -U postgres -c "DROP ROLE IF EXISTS gup_user;"

docker compose exec db psql -U postgres -c "CREATE ROLE dspace WITH LOGIN;"
docker compose exec db psql -U postgres -c "ALTER ROLE dspace WITH SUPERUSER;"
docker compose exec db psql -U postgres -c "ALTER ROLE dspace WITH CREATEDB CREATEROLE;"

docker compose exec db psql -U postgres -c "CREATE ROLE gup_user WITH LOGIN;"
docker compose exec db psql -U postgres -c "ALTER ROLE gup_user WITH SUPERUSER;"
docker compose exec db psql -U postgres -c "ALTER ROLE gup_user WITH CREATEDB CREATEROLE;"

docker compose exec db psql -U postgres -c "CREATE DATABASE gup_db OWNER gup_user;"
docker compose exec db psql -U postgres -c "CREATE DATABASE dspace OWNER dspace;"

docker compose exec -T db psql -U dspace   -d dspace -AF ';' < gupea.sql
docker compose exec -T db psql -U gup_user -d gup_db -AF ';' < gup.sql

if [ "$1" == "remove" ]; then
    rm gup.sql gupea.sql
    echo "$(date '+%Y-%m-%d %H:%M:%S') Temporary backup files removed." >> $LOGFILE
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') Keeping temporary backup files." >> $LOGFILE
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') Creating extensions" >> $LOGFILE
docker compose exec db psql -U postgres -d gup_db -c "CREATE EXTENSION pg_trgm;"
docker compose exec db psql -U postgres -d gup_db -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;"

echo "$(date '+%Y-%m-%d %H:%M:%S') Creating indexes" >> $LOGFILE
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX ON publication_versions USING gin (title gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX ON publication_versions USING gin (issn gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX ON publication_versions USING gin (sourcevolume gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX ON publication_versions USING gin (sourcepages gin_trgm_ops);"

docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_versions_common_fields ON publication_versions (pubyear, publication_type_id);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_versions_title ON publication_versions USING gin (title gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_versions_issn ON publication_versions USING gin (issn gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_versions_sourcevolume ON publication_versions USING gin (sourcevolume gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_versions_sourcepages ON publication_versions USING gin (sourcepages gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publications_current_version ON publications (current_version_id, deleted_at, process_state);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_types_id ON publication_types (id);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_pub_identifiers_version ON publication_identifiers (publication_version_id);"

docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publications_current_version_id ON publications (current_version_id);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_versions_id ON publication_versions (id);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_versions_issn ON publication_versions (issn);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_versions_sourcevolume ON publication_versions (sourcevolume);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_versions_sourcepages ON publication_versions (sourcepages);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_versions_title ON publication_versions (title);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_issn_sourcevolume ON publication_versions (issn, sourcevolume);"

docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publications_process_state ON publications (process_state, deleted_at);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_versions_type_id ON publication_versions (publication_type_id);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_publication_identifiers_version_id ON publication_identifiers (publication_version_id);"

docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_sourcetitle_trgm ON publication_versions USING gin (sourcetitle gin_trgm_ops);"
docker compose exec db psql -U postgres -d gup_db -c "CREATE INDEX idx_title_trgm ON publication_versions USING gin (title gin_trgm_ops);"

echo "$(date '+%Y-%m-%d %H:%M:%S') Run the scripts" >> $LOGFILE

# Avhandlingar som finns i GUP men inte i GUPEA
echo "$(date '+%Y-%m-%d %H:%M:%S') Doing GUPEA" >> $LOGFILE
docker compose exec -T db psql -U gup_user -d gup_db -AF ';' < $SRC/gupea1.sql > $DEST/gupea1.txt
docker cp $DEST/gupea1.txt gup-check-duplicates-db-1:/gupea1.txt
docker compose exec -T db psql -U dspace -d dspace -c "CREATE TABLE already_in_gup (handle VARCHAR(255));"
docker compose exec -T db psql -U dspace -d dspace -c "\copy already_in_gup FROM '/gupea1.txt' DELIMITER ';' CSV"
docker compose exec -T db psql -U dspace -d dspace -AF '¤' < $SRC/gupea2.sql > $DEST/gupea.csv
docker compose exec -T db rm /gupea1.txt
docker compose exec -T db psql -U dspace -d dspace -c "DROP TABLE already_in_gup;"
rm $DEST/gupea1.txt

# The rest
echo "$(date '+%Y-%m-%d %H:%M:%S') Doing Articles"  >> $LOGFILE
docker compose exec -T db psql -U gup_user -d gup_db -AF '¤' < $SRC/articles.sql > $DEST/articles.csv

echo "$(date '+%Y-%m-%d %H:%M:%S') Doing Delayed Posts" >> $LOGFILE 
docker compose exec -T db psql -U gup_user -d gup_db -AF '¤' < $SRC/delayed_posts.sql > $DEST/delayed_posts.csv

echo "$(date '+%Y-%m-%d %H:%M:%S') Doing External id" >> $LOGFILE 
docker compose exec -T db psql -U gup_user -d gup_db -AF '¤' < $SRC/external_id.sql > $DEST/external_id.csv

echo "$(date '+%Y-%m-%d %H:%M:%S') Doing Books"  >> $LOGFILE
docker compose exec -T db psql -U gup_user -d gup_db -AF '¤' < $SRC/books.sql > $DEST/books.csv

echo "$(date '+%Y-%m-%d %H:%M:%S') Done" >> $LOGFILE
