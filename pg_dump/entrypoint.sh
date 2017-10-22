#!/usr/bin/env bash
set -euo pipefail

echo "Starting pg_dump task..."
echo "Checking mandatory environment variables..."
PGHOST=${PGHOST}
PGDATABASE=${PGDATABASE}
PGUSER=${PGUSER}

echo "Checking optional environment variables..."
AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:="us-east-1"}
S3_KEYPREFIX=${S3_KEYPREFIX:="pg_dump"}
PGPORT=${PGPORT:="5432"}
PG_DUMP_OPTIONS=${PG_DUMP_OPTIONS:=""}
PG_DUMP_ALL_OPTIONS=${PG_DUMP_ALL_OPTIONS:="--globals-only"}


if [[ "$ENVIRONMENT" != "local" ]]; then
  echo "Fetching $PGPASSWORD_PARAMETER from Parameter Store in $AWS_DEFAULT_REGION"
  PGPASSWORD=$(aws ssm get-parameters \
    --names "$PGPASSWORD_PARAMETER" \
    --with-decryption \
    --query "Parameters[0].Value" \
    --output text)

  echo "Setting SSL mode..."
  export PGSSLMODE="verify-ca"
  export PGSSLROOTCERT="/setup/rds-combined-ca-bundle.pem"
fi

PGPASSWORD=${PGPASSWORD}

if [[ "$ENVIRONMENT" == "local" ]]; then
  echo "Giving Postgres a chance to spin up"
  until $(psql --no-psqlrc --command "SELECT 1;" 2> /dev/null | grep -q 1); do
    printf '.'
    sleep 5
  done
  printf '\n'
fi

echo "Verifying connectivity to $PGDATABASE database on $PGHOST using $PGUSER role and $PGPORT port..."
psql --no-psqlrc --command "SELECT 1;" 1> /dev/null && echo "Success."

echo "Dumping $PGDATABASE..."
pg_dump \
  $PG_DUMP_OPTIONS \
  --file=/pg_dump/dump.sql

echo "Dumping global objects..."
pg_dumpall \
  $PG_DUMP_ALL_OPTIONS \
  --file=/pg_dump/dump_all.sql

echo "All done."
sleep 1d
