FROM centos/postgresql-10-centos7

USER root
RUN yum groupinstall -y "Development Tools"
RUN yum install centos-release-scl-rh
RUN yum install -y rh-postgresql10-postgresql-devel which

# Install query_log extension
ENV PATH="/opt/rh/rh-postgresql10/root/usr/bin:${PATH}"
COPY query_log /usr/src/query_log
RUN set -ex \
    && cd /usr/src/query_log \
    && make install

# Don't change the entrypoint/cmd stuff
USER 26
ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]