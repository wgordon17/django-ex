#!/bin/bash

# Guess the number of workers according to the number of cores
function get_default_web_concurrency() {
  limit_vars=$(cgroup-limits)
  local $limit_vars
  if [ -z "${NUMBER_OF_CORES:-}" ]; then
    echo 1
    return
  fi

  local max=$((NUMBER_OF_CORES*2))
  # Require at least 43 MiB and additional 40 MiB for every worker
  local default=$(((${MEMORY_LIMIT_IN_BYTES:-MAX_MEMORY_LIMIT_IN_BYTES}/1024/1024 - 43) / 40))
  default=$((default > max ? max : default))
  default=$((default < 1 ? 1 : default))
  # According to http://docs.gunicorn.org/en/stable/design.html#how-many-workers,
  # 12 workers should be enough to handle hundreds or thousands requests per second
  default=$((default > 12 ? 12 : default))
  echo $default
}

if [[ -z "$APP_MODULE" ]]; then
    # Look only in the directory specified by APP_HOME, or the current directory
    # replace all "/" with ".", remove leading "." and ".py" suffix
    APP_MODULE=$(find $APP_HOME -maxdepth 1 -type f -name 'wsgi.py' | sed 's:/:.:g;s:^\.\+::;s:\.py$::')
fi

export WEB_CONCURRENCY=${WEB_CONCURRENCY:-$(get_default_web_concurrency)}

pyagent run -c ${PWD}/appdynamics.cfg -- gunicorn "$APP_MODULE" -b '0.0.0.0:8080' --access-logfile=- --config "$APP_CONFIG"
