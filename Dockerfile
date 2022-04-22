FROM adoptopenjdk:11-jdk-hotspot
RUN apt update && apt upgrade -y && apt install -y curl && apt install -y wget
RUN adduser --home /home/appuser --shell /bin/sh appuser 

ENV LOG_PATH=/logs
RUN mkdir ${LOG_PATH} && chown appuser:appuser ${LOG_PATH} 

USER appuser 

WORKDIR /home/appuser 
ARG JAR_FILE 
COPY target/${JAR_FILE} app.jar 

ENV PROFILE=local 
ENV SPRING_CLOUD_CONFIG_URI=http://configserver:8888
ENV ZUUL_PORT=8080
ENV DATASOURCE_URL=jdbc:mariadb://jpetstoredb:13306/jpetstoredb
ENV EUREKA_DEFAULTZONE=http://eurekaserver:8761/eureka/,http://eurekaserver2:8762/eureka/
ENV ELASTICSEARCH_HOSTS=elasticsearch:9200
ENV KIBANA_HOST=kibana:5601
ENV ZIPKIN_URI=http://zipkin:9411/
ENV SCOUTER_SERVER=scouterserver
ENV SCOUTER_SERVER_PORT=6100

RUN wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.13.0-linux-x86_64.tar.gz && tar xvfz filebeat-7.13.0-linux-x86_64.tar.gz
COPY filebeat.yml /home/appuser/filebeat-7.13.0-linux-x86_64/filebeat.yml

RUN wget https://github.com/scouter-project/scouter/releases/download/v2.17.1/scouter-min-2.17.1.tar.gz && tar xvfz scouter-min-2.17.1.tar.gz

RUN echo "===== Scouter Configuration =====" \
    && echo "net_collector_ip=${SCOUTER_SERVER}" >> scouter/agent.host/conf/scouter.conf \
    && echo "net_collector_udp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.host/conf/scouter.conf \
    && echo "net_collector_tcp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.host/conf/scouter.conf \
    && echo "net_collector_ip=${SCOUTER_SERVER}" >> scouter/agent.java/conf/scouter.conf \
    && echo "net_collector_udp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.java/conf/scouter.conf \
    && echo "net_collector_tcp_port=${SCOUTER_SERVER_PORT}" >> scouter/agent.java/conf/scouter.conf \
    && echo "===== Run Script Shell =====" \
    && echo "/home/appuser/filebeat-7.13.0-linux-x86_64/filebeat --path.home /home/appuser/filebeat-7.13.0-linux-x86_64 &" >> run.sh \
    && echo "cd /home/appuser/scouter/agent.host && ./host.sh" >> run.sh \
    && echo "cd /home/appuser && java -javaagent:/home/appuser/scouter/agent.java/scouter.agent.jar -Dscouter.config=/home/appuser/scouter/agent.java/conf/scouter.conf -Dobj_name=zuulserver_`hostname` -Djava.security.egd=file:/dev/./urandom -Dspring.profiles.active=\${PROFILE} -jar app.jar" >> run.sh

#ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom", "-Dspring.profiles.active=${PROFILE}","-jar","app.jar"]
ENTRYPOINT ["sh", "run.sh"]
