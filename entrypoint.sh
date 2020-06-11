#!/usr/bin/env bash
mix do deps.get, compile

# Add local user with USER_NAME
# Either use the LOCAL_USER_ID if passed in at runtime or fallback to 9001
USER_NAME=$APP_USER
USER_ID=${LOCAL_USER_ID:-9001}

# Add user if it doesn't exist
useradd --uid $USER_ID \
	--shell /bin/bash \
	--non-unique \
	--comment "App user" \
	--create-home $USER_NAME \
	--home-dir /opt/app

# Change ownership of library directories
chown -R $USER_NAME. /opt/cache
chown -R $USER_NAME. $WORKDIR

# Run the command attached to the process with PID 1 so that signals get
# passed to the process/app being run
echo "Starting with USER=$USER_NAME UID=$USER_ID"
exec runuser -u $USER_NAME -g $USER_NAME -- "$@"
