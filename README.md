
# docker-borgmatic

Docker image with [borg](https://github.com/borgbackup/borg) and
[borgmatic](https://github.com/witten/borgmatic). Also provides a script to
generate metrics for [Prometheus](https://prometheus.io/).


## Setup

### Prerequisites

To use this image, you will need :

- a borg repository
- a borgmatic config file, see [borgmatic configuration reference](https://torsion.org/borgmatic/docs/reference/configuration/)
- a `known_hosts` and ssh key file to access your borg repository
- the borg key or passphrase, whatever fit your setup
- a crontab file

### Crontab file

This image uses alpine's [dcron](http://www.jimpryor.net/linux/dcron.html).
Here is an example file :
```
# min hour   day month weekday command
  0   4-23/4 *   *     *       borgmatic --create --prune --stats
  0   5      *   *     2,4,6   borgmatic --check
```

When running in a swarm cluster, you way want to avoid triggering backup at the
same time by delaying borg execution. This can be done with multiple crontabs
and [service creation using
templates](https://docs.docker.com/engine/reference/commandline/service_create/#create-services-using-templates),
see the [Configuration example](#configuration-example).


## Metrics exporter

The image provides the script `borg_exporter`. The script reads from stdin the
output of `borg info ... --json` and generates metrics for prometheus. With no
options the script writes to stdout, to write in a file use `borg_exporter -o
target_file`. The `-e` option writes the metrics to the file determined by
`$IMAGE_METRICS_DIR/$IMAGE_METRICS_FILENAME` environment variables (see [Image
Variables](#image-variables)).

The easiest way to generate the metric in this image is to add the command
`borgmatic --info --json | borg_exporter -e` in the  `after_backup` hook of
your borgmatic configuration.

It is also possible to expose those metrics over http, by setting up the
variable `IMAGE_EXPORTER_PORT`. A simple http server will be listening at the
given port, serving the metrics on
`http://container_address:$IMAGE_EXPORTER_PORT/$IMAGE_METRICS_FILENAME`.

## Configuration example

Since this image does not embed any init program, and many subprocess will be
executed, it is highly recommended to use docker's `--init` option, or `init:
true` in docker-compose file.

By default, the image uses a `/borg` directory to store borg's data (cache,
security, ...).
The image also tries to read borg key and ssh key from docker secret files
(`/run/secrets/borg-key` and `/run/secrets/ssh-key`). To overide these
defaults, see [Image Variables](#image-variables)

```yaml

version: "3.7"

services:

  borgmatic:
    image: nicph/borgmatic:latest
    init: true

    deploy:
      mode: global

    hostname: '{{.Node.Hostname}}'

    volumes:
      - /path/to/data-to-backup:/data
      - /path/to/borg-volume:/borg

    configs:
      - source: borgmatic-config
        target: /etc/borgmatic/config.yaml
      - source: crontab-node_hostname_1
        target: /borg/crontab.node_hostname_1
      - source: crontab-node_hostname_2
        target: /borg/crontab.node_hostname_2
      - source: known_hosts
        target: /borg/known_hosts

    secrets:
      - source: ssh-key
        mode: 0400
      - source: borg-key
        mode: 0400

    environment:
      IMAGE_CRONTAB_FILE: '/borg/crontab.{{.Node.Hostname}}'
      IMAGE_EXPORTER_PORT: 9100


configs:
  borgmatic-config:
    file: /path/to/borgmatic/config.yaml
  crontab-node_hostname_1:
    file: /path/to/crontab.node_hostname_1
  crontab-node_hostname_2:
    file: /path/to/crontab.node_hostname_2
  known_hosts:
    file: /path/to/known_hosts

secrets:
   ssh-key:
     file: /path/to/ssh-key
   borg-key:
     file: /path/to/borg-key

```



## Variables

### Borg variables

Any borg variable can be used and defined as an environment variable for your
container. You can read about Borg's environment variables in [borg's
documentation](https://borgbackup.readthedocs.io/en/stable/usage/general.html#environment-variables).

For convenience, some of them are pre-defined in this image with a default value :

| Variable            | default value               |
| ---                 | ---                         |
| `BORG_BASE_DIR`     | `/borg`                     |
| `BORG_CACHE_DIR`    | `${BORG_BASE_DIR}/cache`    |
| `BORG_CONFIG_DIR`   | `${BORG_BASE_DIR}/config`   |
| `BORG_KEYS_DIR`     | `${BORG_BASE_DIR}/keys`     |
| `BORG_SECURITY_DIR` | `${BORG_BASE_DIR}/security` |
| `BORG_KEY_FILE`     | `/run/secrets/borg-key`     |

The default value of `BORG_KEY_FILE` is available for borg only if the file is
readable.

| Variable               | default value                  |
| ---                    | ---                            |
| `SSH_KNOWN_HOSTS_FILE` | `${BORG_BASE_DIR}/known_hosts` |
| `SSH_KEY_FILE`         | `/run/secrets/ssh-key`         |
| `SSH_OPTS`             | None                           |

If the content of `SSH_KNOWN_HOSTS_FILE` is a readable file, `-o
'UserKnownHostsFile=${SSH_KNOWN_HOSTS_FILE}'` will be appended to `SSH_OPTS`.

If the content of `SSH_KEY_FILE` is a readable file, `-i '${SSH_KEY_FILE}'`
will be appended to `SSH_OPTS`.

If `SSH_OPTS` is not empty, `BORG_RSH` will be set to `ssh ${SSH_OPTS}`, or
`${BORG_RSH} ${SSH_OPTS}` if `BORG_RSH` was not empty.


### Image Variables

| Variable                 | description                                 | default value              |
| ---                      | ---                                         | ---                        |
| `IMAGE_CRONTAB_FILE`     | Path to the crontab file to be loaded       | `/etc/borgmatic.d/crontab` |
| `IMAGE_EXPORTER_PORT`    | Port for the borg exporter service          | `None`                     |
| `IMAGE_METRICS_DIR`      | Dir into witch will be written borg metrics | `/prometheus`              |
| `IMAGE_METRICS_FILENAME` | Borg metrics filename                       | `metrics`                  |


## References

 - https://www.borgbackup.org
 - https://torsion.org/borgmatic
 - http://www.jimpryor.net/linux/dcron.html
 - https://prometheus.io

