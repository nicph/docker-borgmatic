export PATH="/app/bin:${PATH}"

# set some default values for convenience.
# BORG_* are borg variables, see
# https://borgbackup.readthedocs.io/en/stable/usage/general.html#environment-variables
#
# SSH_KEY_FILE, SSH_KNOWN_HOSTS_FILE and SSH_OPTS are convenience variables
# used to build BORG_RSH

export BORG_BASE_DIR="${BORG_BASE_DIR:-/borg}"

export BORG_CACHE_DIR="${BORG_CACHE_DIR:-${BORG_BASE_DIR}/cache}"
export BORG_CONFIG_DIR="${BORG_CONFIG_DIR:-${BORG_BASE_DIR}/config}"
export BORG_KEYS_DIR="${BORG_SECURITY_DIR:-${BORG_BASE_DIR}/keys}"
export BORG_SECURITY_DIR="${BORG_SECURITY_DIR:-${BORG_BASE_DIR}/security}"

BORG_KEY_FILE="${BORG_KEY_FILE:-/run/secrets/borg-key}"
if [ -r "$BORG_KEY_FILE" ]; then
  export BORG_KEY_FILE
fi


SSH_KEY_FILE="${SSH_KEY_FILE:-/run/secrets/ssh-key}"
if [ -r "$SSH_KEY_FILE" ]; then
  SSH_OPTS="${SSH_OPTS} -i '${SSH_KEY_FILE}'"
fi

SSH_KNOWN_HOSTS_FILE="${SSH_KNOWN_HOSTS_FILE:-${BORG_BASE_DIR}/known_hosts}"
if [ -r "$SSH_KNOWN_HOSTS_FILE" ]; then
  SSH_OPTS="${SSH_OPTS} -o 'UserKnownHostsFile=${SSH_KNOWN_HOSTS_FILE}'"
fi

if [ -n "$SSH_OPTS" ]; then
  export BORG_RSH="${BORG_RSH:-ssh} ${SSH_OPTS}"
fi

export IMAGE_CRONTAB_FILE="${IMAGE_CRONTAB_FILE:-/etc/borgmatic.d/crontab}"

# IMAGE_EXPORTER_PORT=   # no default value, defining it enables the exporter service
export IMAGE_METRICS_DIR=${IMAGE_METRICS_DIR:-/prometheus}
export IMAGE_METRICS_FILENAME=${IMAGE_METRICS_FILENAME:-metrics}
