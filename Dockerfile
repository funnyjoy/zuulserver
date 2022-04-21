FROM adoptopenjdk:11-jdk-hotspot
RUN apt update && apt upgrade -y && apt install -y curl && apt install -y wget
RUN adduser --home /home/appuser --shell /bin/sh appuser 
USER appuser 

WORKDIR /home/appuser 
ARG JAR_FILE 
COPY target/${JAR_FILE} app.jar 

ENV PROFILE=local 
ENV SPRING_CLOUD_CONFIG_URI=http://configserver:8888
ENV ZUUL_PORT=8080
ENV DATASOURCE_URL=jdbc:mariadb://jpetstoredb:13306/jpetstoredb
ENV EUREKA_DEFAULTZONE=http://eurekaserver:8761/eureka/,http://eurekaserver2:8762/eureka/
ENV ZIPKIN_URI=http://zipkin:9411/
ENV SCOUTER_SERVER=scouterserver
ENV SCOUTER_SERVER_PORT=6100

RUN wget https://github.com/scouter-project/scouter/releases/download/v2.17.1/scouter-min-2.17.1.tar.gz && tar xvfz scouter-min-2.17.1.tar.gz

RUN echo "net_collector_ip=${SCOUTER_SERVER}" >> scouter/agent.host/conf/scouter.conf \
    && echo "net_collector_udp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.host/conf/scouter.conf \
    && echo "net_collector_tcp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.host/conf/scouter.conf \
    && echo "net_collector_ip=${SCOUTER_SERVER}" >> scouter/agent.java/conf/scouter.conf \
    && echo "net_collector_udp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.java/conf/scouter.conf \
    && echo "net_collector_tcp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.java/conf/scouter.conf \
    && echo "cd /home/appuser/scouter/agent.host && ./host.sh" >> run.sh \
    && echo "cd /home/appuser && java -javaagent:/home/appuser/scouter/agent.java/scouter.agent.jar -Dscouter.config=/home/appuser/scouter/agent.java/conf/scouter.conf -Dobj_name=product_`hostname` -Djava.security.egd=file:/dev/./urandom -Dspring.profiles.active=\${PROFILE} -jar app.jar" >> run.sh

#ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom", "-Dspring.profiles.active=${PROFILE}","-jar","app.jar"]
ENTRYPOINT ["sh", "run.sh"]
