FROM google/dart:2.8 AS dart-runtime

RUN apt-get update

WORKDIR /code_tanks

COPY pubspec.* /code_tanks
RUN pub get

COPY . /code_tanks
RUN pub get --offline

# RUN dart2native /code_tanks/run.dart -o /code_tanks/run

# FROM frolvlad/alpine-glibc:alpine-3.11_glibc-2.31

# COPY --from=dart-runtime /code_tanks/run /code_tanks/run

# CMD []
# ENTRYPOINT ["/code_tanks/run"]

RUN chmod 777 /code_tanks/run.dart

ENTRYPOINT ["/usr/bin/dart", "/code_tanks/run.dart"]
