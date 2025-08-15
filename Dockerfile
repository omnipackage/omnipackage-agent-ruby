FROM opensuse/tumbleweed

RUN zypper up -y && \
    zypper in -y ruby podman

COPY . /app
RUN ln -s /app/exe/* /usr/bin/
WORKDIR /app

#RUN bundle config --local without development test && \
#    bundle config set deployment true && \
#    bundle install

#RUN mkdir -p /etc/containers
#RUN cat <<'EOF' > /etc/containers/containers.conf
#[engine]
#cgroup_manager = "none"
#runtime = "runc"
#EOF


# docker build -t omnipackage-agent .

# docker run --rm -it --privileged --cgroupns=host -v /run/media/oleg/c3996ce0-a379-4403-9d64-7d4c0536463f/dev/omnipackage-build/:/tmp -v /home/oleg/projects/mpz:/project omnipackage-agent omnipackage build /project
