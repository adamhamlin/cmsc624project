FROM centos/postgresql-10-centos7

USER root
RUN yum groupinstall -y "Development Tools"
RUN yum install centos-release-scl-rh
RUN yum install -y rh-postgresql10-postgresql-devel which

# Install source_tracking_fdw extension
ENV PATH="/opt/rh/rh-postgresql10/root/usr/bin:${PATH}"
COPY ./source_tracking_fdw /usr/src/source_tracking_fdw
RUN set -ex \
    && cd /usr/src/source_tracking_fdw \
    && make install

# Don't change the entrypoint/cmd stuff
USER 26
# Copy over init scripts as user postgres
COPY ./init /opt/app-root/src

ENTRYPOINT ["container-entrypoint"]
CMD ["run-postgresql"]