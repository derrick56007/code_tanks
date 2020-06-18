FROM google/dart:2.8 AS dart-runtime

RUN apt-get update

WORKDIR /app
COPY . /app

RUN pub get

RUN dart2native /app/custom.dart -o /app/custom

FROM frolvlad/alpine-glibc:alpine-3.11_glibc-2.31

COPY --from=dart-runtime /app/custom /custom

CMD []
ENTRYPOINT ["/custom"]
