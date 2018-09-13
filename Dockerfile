FROM openjdk:8-jdk
LABEL MAINTAINER="liu binbin <lotosbin@gmail.com>"

# ------------------------------------------
#setup timezone
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Ensure UTF-8 locale
#COPY locale /etc/default/locale
RUN apt-get update && apt-get install -y locales
RUN locale-gen zh_CN.UTF-8 &&\
  DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
RUN locale-gen zh_CN.UTF-8
ENV LANG zh_CN.UTF-8
ENV LANGUAGE zh_CN:zh
#ENV LC_ALL zh_CN.UTF-8


# Create a non-root user
ARG user=finger
RUN useradd -m $user -d /home/${user}
USER $user
WORKDIR /home/$user

#--------
USER root
RUN apt-get install -y unzip
USER $user


#--------------------------------------
# Set desired Android Linux SDK version
ENV ANDROID_SDK_VERSION 24.4.1

ENV ANDROID_SDK_ZIP android-sdk_r$ANDROID_SDK_VERSION-linux.tgz
ENV ANDROID_SDK_ZIP_URL https://dl.google.com/android/$ANDROID_SDK_ZIP
ENV ANDROID_HOME_BASE /home/$user/Android/environment/sdk
ENV ANDROID_HOME /home/$user/Android/environment/sdk/android-sdk-linux


RUN mkdir -p $ANDROID_HOME_BASE
WORKDIR $ANDROID_HOME_BASE

# Install gradle
ENV GRADLE_ZIP gradle-3.0-bin.zip
ENV GRADLE_ZIP_URL https://services.gradle.org/distributions/$GRADLE_ZIP
ADD $GRADLE_ZIP_URL $ANDROID_HOME_BASE/
#COPY ./gradle-3.0-bin.zip $ANDROID_HOME_BASE/
RUN cd $ANDROID_HOME_BASE/ && \
    unzip ${GRADLE_ZIP} -d ./  && \
    rm ${GRADLE_ZIP}

# Install Android SDK
ADD $ANDROID_SDK_ZIP_URL $ANDROID_HOME_BASE/
#COPY ./android-sdk_r24.4.1-linux.tgz $ANDROID_HOME_BASE/
RUN  cd $ANDROID_HOME_BASE/ && \
    tar xzvf ${ANDROID_SDK_ZIP} -C ./  && \
    rm ${ANDROID_SDK_ZIP}

ENV PATH $PATH:${ANDROID_HOME}/tools
ENV PATH $PATH:${ANDROID_HOME}/platform-tools
ENV PATH $PATH:${ANDROID_HOME_BASE}/gradle-3.0/bin

# Accept Licenses
#RUN yes | sdkmanager --licenses
RUN mkdir -p $ANDROID_HOME/licenses/ && \
    echo 8933bad161af4178b1185d1a37fbf41ea5269c55 >> $ANDROID_HOME/licenses/android-sdk-license && \
    echo 84831b9409646a918e30573bab4c9c91346d8abd >> $ANDROID_HOME/licenses/android-sdk-preview-license && \
    echo d975f751698a77b662f1254ddbeed3901e976f5a >> $ANDROID_HOME/licenses/intel-android-extra-license
#
#
## Install required build-tools
#RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-26,build-tools-26.0.0 && \
#	chmod -R 755 ${ANDROID_HOME}
#
#RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-25,build-tools-25.0.2,extra-android-m2repository,extra-android-support,extra-google-m2repository && chmod -R 755 $ANDROID_HOME
#
#RUN	echo "y" | android update sdk -u -a --filter platform-tools,android-26,build-tools-26.0.2,extra-android-m2repository,extra-android-support,extra-google-m2repository && chmod -R 755 $ANDROID_HOME
#
#RUN	echo "y" | android update sdk -u -a --filter build-tools-26.0.1
#RUN	echo "y" | android update sdk -u -a --filter android-23,build-tools-25.0.0
#RUN	echo "y" | android update sdk -u -a --filter android-21,android-22
RUN	echo "y" | android update sdk -u -a --filter android-27,build-tools-27.0.3
RUN	echo "y" | android update sdk -u -a --filter android-28,build-tools-28.0.2

# Install 32-bit compatibility for 64-bit environments
#RUN apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 -y

# Cleanup
USER root
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
USER $user


# ------------------------------------------------------------
# Download Android ndk

# android-ndk-r14b-linux-x86_64
ENV ANDROID_NDK_VERSION r14b
ENV ANDROID_NDK_HOME /home/finger/Android/environment/sdk/android-ndk-$ANDROID_NDK_VERSION
#COPY ./android-ndk-r14b-linux-x86_64.zip ${ANDROID_HOME_BASE}
RUN  cd ${ANDROID_HOME_BASE} \
  && curl -O https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip \
  && ls . \
  && unzip -q android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip \
  && rm android-ndk-${ANDROID_NDK_VERSION}-linux-x86_64.zip
ENV PATH ${PATH}:${ANDROID_NDK_HOME}




USER root
# ------------------------------------------------------------------------------------------------------
# add node npm
# reference https://github.com/nodejs/docker-node/blob/f131cc81c04968f1a60092c5efef54ea276d8b20/8.1/Dockerfile

# add node npm
# reference https://github.com/nodejs/docker-node/blob/f131cc81c04968f1a60092c5efef54ea276d8b20/8.1/Dockerfile
#USER root

# RUN groupadd --gid 1000 node \
  # && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    9554F04D7259F04124DE6B476D5A82AC7E37093B \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
  ; do \
    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
  done

ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 8.1.3

#COPY ./node-v${NODE_VERSION}-linux-x64.tar.xz /home/finger/
#COPY ./SHASUMS256.txt.asc /home/finger/
RUN cd /home/${user} \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs
#
#ENV YARN_VERSION 0.24.6
#
##&& curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
##  && curl -fSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
#COPY ./yarn-v$YARN_VERSION.tar.gz /home/finger/
#COPY ./yarn-v$YARN_VERSION.tar.gz.asc /home/finger/
#RUN set -ex \
#  && for key in \
#    6A010C5166006599AA17F08146C2130DFD2497F5 \
#  ; do \
#    gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
#    gpg --keyserver keyserver.pgp.com --recv-keys "$key" || \
#    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
#  done \
#  && cd /home/finger/
#  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
#  && mkdir -p /opt/yarn \
#  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/yarn --strip-components=1 \
#  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
#  && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarnpkg \
#  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz



#--------------
# install python 2.7
USER root
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
  build-essential \
  ca-certificates \
  gcc \
  git \
  libpq-dev \
  make \
  python-pip \
  python2.7 \
  python2.7-dev \
  ssh \
  && apt-get autoremove \
  && apt-get clean

RUN pip install -U "setuptools==3.4.1"
RUN pip install -U "pip==1.5.4"
RUN pip install -U "Mercurial==2.9.1"
RUN pip install -U "virtualenv==1.11.4"

USER $user

WORKDIR /home/$user
CMD []
ENTRYPOINT ["/usr/bin/python2.7"]


