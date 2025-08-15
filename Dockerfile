FROM opensuse/tumbleweed

RUN zypper up -y && zypper in -y ruby podman
COPY . /app
RUN ln -s /app/exe/* /usr/bin/
WORKDIR /app
