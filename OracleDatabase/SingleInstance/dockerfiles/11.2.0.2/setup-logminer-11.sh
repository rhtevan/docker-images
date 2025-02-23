#!/bin/sh

su -p oracle -c "mkdir /u01/app/oracle/oradata/recovery_area"

# Set archive log mode and enable GG replication
ORACLE_SID=XE
export ORACLE_SID

su -p oracle -c "sqlplus / as sysdba <<-EOF
	alter system set db_recovery_file_dest_size = 10G;
	alter system set db_recovery_file_dest = '/u01/app/oracle/oradata/recovery_area' scope=spfile;
	shutdown immediate
	startup mount
	alter database archivelog;
	alter database open;
        -- Should show "Database log mode: Archive Mode"
	archive log list
	exit;
EOF"

# Enable LogMiner required database features/settings
sqlplus sys/$ORACLE_PWD@//localhost:1521/XE as sysdba <<-EOF
  ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
  ALTER PROFILE DEFAULT LIMIT FAILED_LOGIN_ATTEMPTS UNLIMITED;
  exit;
EOF

# Create Log Miner Tablespace and User
sqlplus sys/$ORACLE_PWD@//localhost:1521/XE as sysdba <<-EOF
  CREATE TABLESPACE LOGMINER_TBS DATAFILE '/u01/app/oracle/oradata/XE/logminer_tbs.dbf' SIZE 25M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;
  exit;
EOF

sqlplus sys/$ORACLE_PWD@//localhost:1521/XE as sysdba <<-'EOF'
  CREATE USER dbzuser IDENTIFIED BY dbz DEFAULT TABLESPACE LOGMINER_TBS QUOTA UNLIMITED ON LOGMINER_TBS;

  GRANT CREATE SESSION TO dbzuser;
  GRANT SELECT ON V_$DATABASE TO dbzuser;
  GRANT FLASHBACK ANY TABLE TO dbzuser;
  GRANT SELECT ANY TABLE TO dbzuser;
  GRANT SELECT_CATALOG_ROLE TO dbzuser;
  GRANT EXECUTE_CATALOG_ROLE TO dbzuser;
  GRANT SELECT ANY TRANSACTION TO dbzuser;
  GRANT SELECT ANY DICTIONARY TO dbzuser;

  GRANT CREATE TABLE TO dbzuser;
  GRANT LOCK ANY TABLE TO dbzuser;
  GRANT CREATE SEQUENCE TO dbzuser;

  GRANT EXECUTE ON DBMS_LOGMNR TO dbzuser;
  GRANT EXECUTE ON DBMS_LOGMNR_D TO dbzuser;
  GRANT SELECT ON V_$LOGMNR_LOGS to dbzuser;
  GRANT SELECT ON V_$LOGMNR_CONTENTS TO dbzuser;
  GRANT SELECT ON V_$LOGFILE TO dbzuser;
  GRANT SELECT ON V_$ARCHIVED_LOG TO dbzuser;
  GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO dbzuser;

  exit;
EOF

sqlplus sys/$ORACLE_PWD@//localhost:1521/XE as sysdba <<-EOF
  CREATE USER debezium IDENTIFIED BY dbz DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;
  GRANT CONNECT TO debezium;
  GRANT CREATE SESSION TO debezium;
  GRANT CREATE TABLE TO debezium;
  GRANT CREATE SEQUENCE to debezium;
  ALTER USER debezium QUOTA 100M on users;
  exit;
EOF
