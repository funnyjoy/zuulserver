FROM adoptopenjdk/openjdk8:x86_64-alpine-jre8u222-b10 
RUN apk --no-cache add curl 
RUN adduser -D -s /bin/sh appuser 
USER appuser 

WORKDIR /home/appuser 
ARG JAR_FILE 
COPY target/${JAR_FILE} app.jar 

ENV PROFILE=local 
ENV SPRING_CLOUD_CONFIG_URI=http://configserver:8888
ENV ZUUL_PORT=8080
ENV DATASOURCE_URL=jdbc:mariadb://jpetstoredb:13306/jpetstoredb
ENV EUREKA_DEFAULTZONE=http://eurekaserver:8761/eureka/,http://eurekaserver2:8762/eureka/

ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom", "-Dspring.profiles.active=${PROFILE}","-jar","app.jar"]
