# WebApollo
# VERSION 2.1.X
FROM tomcat:8-jre8
MAINTAINER Cory Maughmer <cory.maughmer@tamu.edu>
ENV DEBIAN_FRONTEND noninteractive 

RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install \
	git build-essential maven tomcat8 libpq-dev postgresql-common openjdk-8-jdk wget \
	postgresql postgresql-client xmlstarlet netcat libpng-dev \
	zlib1g-dev libexpat1-dev ant curl ssl-cert zip unzip

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get -qq update --fix-missing && \
	apt-get --no-install-recommends -y install nodejs && \
	apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cp /usr/lib/jvm/java-8-openjdk-amd64/lib/tools.jar /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/ext/tools.jar && \
	useradd -ms /bin/bash -d /apollo apollo

# use the TAMU-CPT Viral Annotation branch for Apollo
ENV WEBAPOLLO_VERSION 5a50be2546d840ad6b972022879e4bb00c911d80
RUN curl -L https://github.com/TAMU-CPT/Apollo/archive/${WEBAPOLLO_VERSION}.tar.gz | tar xzf - --strip-components=1 -C /apollo

# install grails
COPY build.sh /bin/build.sh
ADD apollo-config.groovy /apollo/apollo-config.groovy
ADD annot.json /apollo/annot.json
ADD AnnotTrack.js /apollo/AnnotTrack.js
ADD cpt.css /apollo/cpt.css

RUN chown -R apollo:apollo /apollo
USER apollo
RUN curl -s get.sdkman.io | bash
RUN /bin/bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && yes | sdk install grails 2.5.5"
RUN /bin/bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && yes | sdk install gradle 3.2.1"


RUN /bin/bash -c "source $HOME/.profile && source $HOME/.sdkman/bin/sdkman-init.sh && /bin/bash /bin/build.sh"

USER root
ENV CATALINA_HOME=/var/lib/tomcat8
RUN rm -rf ${CATALINA_HOME}/webapps/* && \
	cp /apollo/apollo*.war ${CATALINA_HOME}/apollo.war

ENV CONTEXT_PATH ROOT

# Download chado schema
RUN wget --quiet https://github.com/erasche/chado-schema-builder/releases/download/1.31-jenkins97/chado-1.31.sql.gz -O /chado.sql.gz && \
	gunzip /chado.sql.gz

ADD launch.sh /launch.sh
CMD "/launch.sh"


