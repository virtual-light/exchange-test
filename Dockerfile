FROM elixir:1.10.1

ARG WORKDIR=/opt/app
ARG MIX_ENV=prod
ARG APP_USER=user

ENV MIX_ENV=${MIX_ENV}
ENV WORKDIR=$WORKDIR
ENV APP_USER=$APP_USER
ENV CACHE_DIR=/opt/cache
ENV MIX_HOME=$CACHE_DIR/mix
ENV HEX_HOME=$CACHE_DIR/hex
ENV BUILD_PATH=$CACHE_DIR/_build
ENV REBAR_CACHE_DIR=$CACHE_DIR/rebar

WORKDIR $WORKDIR

# Set entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash", "-c", "while true; do sleep 10; done;"]