FROM postgres:9.6.5-alpine
LABEL maintainer "savchuk.a@gmail.com"

RUN apk --no-cache --verbose add \
  curl \
  python \
  py-pip \
  && pip install awscli \
  && apk --purge --verbose del py-pip

# download root RDS cert
WORKDIR /setup
RUN curl --location --silent --show-error 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem' \
  --output /setup/rds-combined-ca-bundle.pem

COPY ./entrypoint.sh /setup/entrypoint.sh

ENTRYPOINT ["/bin/bash", "-c", "/setup/entrypoint.sh"]
