FROM alpine:latest
# pulls the alpine linux from docker hub

# run update (to get the software list) and install it  
RUN mkdir -p /var/run/sshd \ 
&& apk update \
&& apk add curl \
&& apk add bash \
&& apk add nodejs \
&& apk add openssh \
&& apk add openrc \
&& apk add git \
&& apk add nano \
&& apk add rsync

# run installation of heroku cli in /opt
# to avoid automatically stopping the container after installation start the shell  
RUN cd /opt \ 
&& curl https://cli-assets.heroku.com/install.sh | sh \
&& /bin/sh

COPY ./entrypoint.sh /opt/entrypoint.sh 
RUN chmod +x /opt/entrypoint.sh 


# copy content of local path into containers path
# COPY ./entrypoint.sh /opt/entry/entrypoint.sh
# RUN chmod +rwx /opt/entry/entrypoint.sh

# if ENTRYPOINT is used in docker-compose.yml all CMD will be ignored
# there can be only one CMD command, the last one will be relevant  