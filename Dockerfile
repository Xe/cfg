FROM xena/go-mini:1.13.3 AS go
FROM alpine:edge

# Base system
RUN apk upgrade --no-cache \
 && apk add --no-cache ca-certificates wget emacs curl fish git \
 && apk add --no-cache --virtual xe-alpine-base \
      -X https://xena.greedo.xeserv.us/pkg/alpine/edge/core/ --allow-untrusted \
      xeserv-repo \
 && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
 && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk \
 && apk add glibc-2.29-r0.apk \
 && rm glibc-2.29-r0.apk \
 && ln -s /usr/lib/libncurses.so.5 /usr/lib/libtinfo.so.5

# My user
ARG username=cadey
ARG uid=1000
ARG gid=1000
ARG gecos="Cadey Ratio"

WORKDIR /home/$username

RUN set -x \
 && addgroup --gid "$gid" "$username" \
 && adduser \
    --disabled-password \
    --gecos "$gecos" \
    --home "$(pwd)" \
    --ingroup "$username" \
    --no-create-home \
    --uid "$uid" \
    "$username" \
 && mkdir -p /home/$username \
 && chown -R $username:$username /home/$username

# Install go
ENV GO_VERSION 1.13.4
ENV GOPROXY https://cache.greedo.xeserv.us
COPY --from=go /usr/local/bin/go /usr/local/bin/go

# Setup dependencies
USER $username

# Oh my fish!
RUN curl -L https://get.oh-my.fish > install.fish \
 && fish -l ./install.fish --noninteractive --yes \
 && fish -l -c "omf install kawasaki" \
 && mkdir -p /home/$username/.config/fish/conf.d

COPY --chown=$username:$username ./fish/ /home/$username/.config/fish/conf.d

# Go tools
RUN set -x \
 && go download \
 && go get github.com/rogpeppe/godef \
 && go get golang.org/x/tools/cmd/guru \
 && go get golang.org/x/tools/cmd/gorename \
 && go get golang.org/x/tools/cmd/goimports \
 && go get github.com/stamblerre/gocode

# bin
RUN mkdir bin
COPY --chown=$username:$username bin/ /home/$username/bin

# Spacemacs
COPY --chown=$username:$username .spacemacs .spacemacs
RUN git clone https://github.com/syl20bnr/spacemacs /home/$username/.emacs.d \
 && emacs --daemon \
 && emacsclient --eval '(kill-emacs)' \
 && emacs --daemon \
 && emacsclient --eval '(kill-emacs)'

CMD ["fish", "-l"]
