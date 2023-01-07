#!/usr/bin/env bash
set -exf

[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
ordinal=${BASH_REMATCH[1]}

if [[ $ordinal -eq 0 ]];  then
  # only initialize if this is a pod ending with -0
  echo "Starting initialisation"

  if [ "$DJANGO_MIGRATE" = "on" ]; then
    ./manage.py migrate --noinput
  fi

  if  [ "$DJANGO_CREATE_SUPERUSER" = "on" ] || [ "$DJANGO_LOAD_INITIAL_DATA" = "on"  ]; then
      user_count=$(./manage.py user_count)

      if [[ $user_count -eq 0 ]]; then

        if  [ "$DJANGO_CREATE_SUPERUSER" = "on" ]; then
          ./manage.py createsuperuser --noinput
        fi

        if [ "$DJANGO_LOAD_INITIAL_DATA" = "on" ]; then
          ./manage.py loaddata l10n_data app_roles roles browser_client_data
        fi

      fi
  fi
fi

# shellcheck disable=SC2068
exec $@
