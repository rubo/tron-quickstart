# Tron Quickstart

FROM ubuntu/redis

# Install OpenJDK 8
RUN apt update \
  && apt install -y openjdk-8-jre-headless --no-install-recommends

# Install Node.js
RUN NODE_VERSION=16.14.2 && ARCH=x64 \
  && set -ex \
  && apt install -y ca-certificates curl dirmngr gnupg libatomic1 wget xz-utils --no-install-recommends \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# Install PM2
RUN npm i -g pm2

# Prepare the work directory
RUN mkdir -p tron/conf
WORKDIR /tron

# Install proxy dependencies
RUN mkdir /tron/app
ADD app/package.json /tron/app/package.json
RUN cd app && npm i

# Configure full node
RUN mkdir FullNode
ADD conf/private_net_config.conf FullNode/private_net_config.conf
ADD conf/FullNode.jar FullNode/FullNode.jar

RUN mkdir BlockParser
ADD conf/run.sh BlockParser/run.sh
ADD conf/BlockParser.jar BlockParser/BlockParser.jar

RUN mkdir eventron
ADD conf/process.json eventron/process.json
ADD conf/eventron eventron/eventron

# Separating install from src speeds up the rebuilding
# if the node app is changed, but has the ADD app/version

ADD app/index.js app/index.js
ADD app/version.js app/version.js
ADD app/src app/src
ADD scripts scripts
RUN chmod +x scripts/accounts-generation.sh

ADD tronWeb tronWeb
RUN chmod +x tronWeb

ADD pre-approve.sh pre-approve.sh
ADD quickstart.sh quickstart.sh
RUN chmod +x quickstart.sh

ENTRYPOINT ["./quickstart.sh"]
