FROM alpine:latest
ENV AKTUALIZR_SRCREV 896ca2a38aa497c47599b2e3b16b518ae0e8eccf
WORKDIR /root/

RUN apk add --no-cache cmake git g++ make curl-dev libarchive-dev libsodium-dev dpkg-dev doxygen graphviz sqlite-dev glib-dev autoconf automake libtool python3 \
	&& wget https://sourceforge.net/projects/boost/files/boost/1.57.0/boost_1_57_0.tar.gz \
	&& tar -xzf boost_1_57_0.tar.gz \
	&& cd boost_1_57_0 \
	&& ./bootstrap.sh --with-libraries="log,filesystem,program_options,system" \
	&& ./b2 -j`getconf _NPROCESSORS_ONLN` install \
	&& cd ../ \
	&& git clone https://github.com/vlm/asn1c \
	&& cd asn1c \
	&& autoreconf -iv \
	&& ./configure \
	&& make -j`getconf _NPROCESSORS_ONLN` install \
	&& cd ../ \
	&& git clone https://github.com/advancedtelematic/aktualizr.git \
	&& cd aktualizr \
	&& git checkout $AKTUALIZR_SRCREV \
	&& git submodule update --init --recursive \
	&& mkdir build-git \
	&& cd build-git \
	&& sed -i '/GLOB_PERIOD/a #define GLOB_TILDE 4096' /usr/include/glob.h \
	&& cmake -DWARNING_AS_ERROR=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_SOTA_TOOLS=ON -DBUILD_SYSTEMD=OFF .. \
	&& make -C src/sota_tools -j`getconf _NPROCESSORS_ONLN`

## Stage 2
FROM docker:dind
WORKDIR /root/

RUN apk add --no-cache bash glib libarchive libcurl libsodium nss openjdk8-jre-base ostree python3 py3-requests
COPY ota-publish.sh /usr/bin/ota-publish
COPY ota-dockerapp.py /usr/bin/ota-dockerapp
COPY --from=0 /root/aktualizr/build-git/src/sota_tools/garage-check /usr/bin/
COPY --from=0 /root/aktualizr/build-git/src/sota_tools/garage-deploy /usr/bin/
COPY --from=0 /root/aktualizr/build-git/src/sota_tools/garage-push /usr/bin/
COPY --from=0 /root/aktualizr/build-git/src/sota_tools/garage-sign/bin/garage-sign /usr/bin/
COPY --from=0 /root/aktualizr/build-git/src/sota_tools/garage-sign/lib/ /usr/lib/
RUN wget -O /tmp/docker-app.tgz https://github.com/docker/app/releases/download/v0.9.0-beta1/docker-app-linux.tar.gz \
	&& tar xf "/tmp/docker-app.tgz" -C /tmp/ \
	&& mkdir -p ~/.docker/cli-plugins && cp "/tmp/docker-app-plugin-linux" ~/.docker/cli-plugins/docker-app \
	&& rm /tmp/docker-app*

ENV DOCKER_CLI_EXPERIMENTAL enabled
CMD bash
