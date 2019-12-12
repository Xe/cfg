FROM xena/go-mini:1.13.3 AS go
FROM xena/mdbook AS mdbook
FROM alpine:edge

# Base system
RUN apk upgrade --no-cache \
 && apk add --no-cache ca-certificates \
 && apk add --no-cache --virtual xe-alpine-base emacs curl fish git openssh-client \
      openssh-keygen sudo build-base luarocks5.3 lua5.3 lua5.3-sec lua5.3-socket lua5.3-yaml \
      lua5.3-moonscript lua5.3-dev gnupg libgcc gmp \
      -X https://xena.greedo.xeserv.us/pkg/alpine/edge/core/ --allow-untrusted \
      xeserv-repo \
 && wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
 && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk \
 && apk add glibc-2.29-r0.apk \
 && rm glibc-2.29-r0.apk \
 && ln -s /usr/lib/libncurses.so.5 /usr/lib/libtinfo.so.5

COPY --from=mdbook /usr/local/bin/mdbook /usr/local/bin/mdbook

# My user
ARG username=cadey
ARG uid=1000
ARG gid=1000
ARG gecos="Cadey Ratio"
ARG email="me@christine.website"

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
 && echo "$username ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/$username \
 && mkdir -p /home/$username \
 && chown -R $username:$username /home/$username

# Setup dependencies
USER $username

# test sudo
RUN sudo id

# Oh my fish!
RUN curl -L https://get.oh-my.fish > install.fish \
 && fish -l ./install.fish --noninteractive --yes \
 && fish -l -c "omf install kawasaki" \
 && mkdir -p /home/$username/.config/fish/conf.d \
 && rm install.fish
COPY --chown=$username:$username ./fish/ /home/$username/.config/fish/conf.d
COPY --chown=$username:$username fish_variables /home/$username/.config/fish/fish_variables

# Install go
ENV GO_VERSION 1.13.5
ENV GOPROXY https://cache.greedo.xeserv.us
COPY --from=go /usr/local/bin/go /usr/local/bin/go

# Go tools
RUN set -x \
 && go download \
 && GO111MODULE=on go get -v golang.org/x/tools/gopls@latest \
 && go get -v golang.org/x/tools/cmd/godoc \
 && go get -v golang.org/x/tools/cmd/goimports \
 && go get -v golang.org/x/tools/cmd/gorename \
 && go get -v golang.org/x/tools/cmd/guru \
 && go get -v github.com/cweill/gotests/... \
 && go get -v github.com/davidrjenni/reftools/cmd/fillstruct \
 && go get -v github.com/fatih/gomodifytags \
 && go get -v github.com/godoctor/godoctor \
 && go get -v github.com/golangci/golangci-lint/cmd/golangci-lint \
 && go get -v github.com/haya14busa/gopkgs/cmd/gopkgs \
 && go get -v github.com/josharian/impl \
 && go get -v github.com/rogpeppe/godef \
 && go get -v github.com/zmb3/gogetdoc \
 && go get -v github.com/stamblerre/gocode \
 && go get -v within.website/x/cmd/license \
 && go get -v within.website/x/cmd/prefix \
 && sudo rm -rf ~/go/pkg/mod \
 && go clean -cache

ENV GO111MODULE on

# bin
RUN mkdir bin
COPY --chown=$username:$username bin/ /home/$username/bin

# git
RUN git config --global user.name "$gecos" \
 && git config --global user.email "$email"

# Spacemacs
COPY --chown=$username:$username .spacemacs .spacemacs
RUN git clone https://github.com/syl20bnr/spacemacs /home/$username/.emacs.d \
 && emacs --insecure --daemon \
 && emacsclient --eval '(kill-emacs)' \
 && gpg --homedir ~/.emacs.d/elpa/gnupg --receive-keys 066DAFCB81E42C40 \
 && emacs --insecure --daemon \
 && emacsclient --eval '(kill-emacs)'

CMD ["fish", "-l"]
