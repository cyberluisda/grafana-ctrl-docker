#!/bin/bash
set -e

ME=$(basename $0)
CURL_OPTIONS="${CURL_OPTIONS:--sLk}"
PATH_FIND_PATTERN="${PATH_FIND_PATTERN:-.*\\.json}"

usage(){
  cat <<EOD

$ME COMMAND_1 OPTIONS_1 ... COMMAND_N OPTIONS_N

    Where COMMAND_X is command and OPTIONS_X are the options for COMMAND_X
    respectively.

    Allowed COMMANDS are:

    import-dashboards OPTIONS: Import one or more dashboards.
      Valid OPTIONS are:
        --json JSON_BODY: Use value of JSON_BODY as payload of dashboard
          specification.

        --file JSON_FILE: Similar to --json option but load payload from
          JSON_FILE

        --path PATH. similar to --file but search for all files in a path that
          match with \$PATH_FIND_PATTERN egrep pattern ($PATH_FIND_PATTERN)

        You can set any of these options multiple times to import more than one
        dashboard in one-shoot.

    new-datasources OPTIONS: Create one or more new datasources.
      Valid OPTIONS are:
        --json JSON_BODY: Use value of JSON_BODY as payload of datasource
          specification.

        --file JSON_FILE: Similar to --json option but load payload from
          JSON_FILE

        --path PATH. similar to --file but search for all files in a path that
          match with \$PATH_FIND_PATTERN egrep pattern ($PATH_FIND_PATTERN)

        You can set any of these options multiple times to create more than one
        datasource in one-shoot.

    new-users OPTIONS: create one or more new users.
      Valid OPTIONS are:
        --json JSON_BODY: Use value of JSON_BODY as payload of user
          specification with id USER_ID.

        --file JSON_FILE: Similar to --json option but load payload from
          JSON_FILE.

        --path PATH. similar to --file but search for all files in a path that
          match with \$PATH_FIND_PATTERN egrep pattern ($PATH_FIND_PATTERN)

        You can set any of these options multiple times to crete more than one
        user in one-shoot.

    ENVIRONMENT VARIABLES:

      GRAFANA_ENDPOINT: Mandatory variable with grafana protocol, host and port.
        For example: 'http://grafana:3000'

      GRAFANA_AUTH_BEARER  Token used to authenticate to grafana.
        See [Grafana API auth docs](http://docs.grafana.org/http_api/auth/)
        for more info.

        Use of this configuration has preference over GRAFANA_AUTH_USERPASSWD

      GRAFANA_AUTH_USERPASSWD: User and password to connect with grafana. This
        will works only if grafana has enable basic auth. Default value 'admin:admin'

        This variable has not effect if GRAFANA_AUTH_BEARER is defined.

      GRAFANA_WAIT_TIMEOUT: If defined wait up to this value in seconds to get
        connection from grafana (TCP check). See
        https://github.com/vishnubob/wait-for-it/ for more informatio

      CURL_OPTIONS: Common options to use with curl. By default ${CURL_OPTIONS}

      PATH_FIND_PATTERN: egrep pattern to apply filter when find for files with
        '--path' and similar options: Default value ${PATH_FIND_PATTERN}
EOD

}

##
# $1 URI (end_point is added from GLOBAL_VAR). Mandatory
# $2 file path: PATH of file tu upload. Mandatory
# $3 Optional Method. Default POST
##
# Global vars
#  GRAFANA_ENDPOINT: Entry point of grafana. For example (http://localhost:3000)
#    It is mandatory
#  GRAFANA_AUTH_BEARER. If defined use this value astoken to authenticate
#  GRAFANA_AUTH_USERPASSWD. If defined use user:password as basic authentication with Grafana

ccurl(){
  local method="POST"
  if [ -n "$3" ]
  then
    method="$3"
  fi
  local url="${GRAFANA_ENDPOINT}$1"
  local fileInput="$2"

  echo "       - curl -X$method -d @${fileInput} ${url}"
  echo "--------"

  if [ -n "${GRAFANA_AUTH_BEARER}" ]
  then
    # Curl with token
    curl \
      ${CURL_OPTIONS} \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ${GRAFANA_AUTH_BEARER}' \
      -X "$method" \
      --data "@${fileInput}" \
      "${url}" \
    | jq -C '.'
  elif [ -n "${GRAFANA_AUTH_USERPASSWD}" ]
  then
    # Curl with user password
    curl \
      ${CURL_OPTIONS} \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -u "${GRAFANA_AUTH_USERPASSWD}" \
      --data "@${fileInput}" \
      -X "$method" \
      "${url}" \
    | jq -C '.'
  else
    # Curl without auth
    curl \
      ${CURL_OPTIONS} \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -X "$method" \
      --data "@${fileInput}" \
      "${url}" \
    | jq -C '.'
  fi
  echo "--------"
}

newDatasources(){
  while [ -n "$1" ]
  do
    echo "* Uploading datasource from file $1"
    ccurl "/api/datasources" "$1"
    shift
  done
}

importDashboards(){
  while [ -n "$1" ]
  do
    echo "* Uploading dahsboard from file $1"
    ccurl "/api/dashboards/import" "$1"
    shift
  done
}

newUsers(){
  while [ -n "$1" ]
  do
    echo "* Uploading user from file $1"
    ccurl "/api/admin/users" "$1"
    shift
  done
}

#Global vars based on environment
if [ -z "${GRAFANA_ENDPOINT}" ]
then
  echo "ERROR: GRAFANA_ENDPOINT empty"
  usage
  exit 1
fi

if [ -n "${GRAFANA_WAIT_TIMEOUT}" ]
then
  # Get host port
  hostPort=$(echo "$GRAFANA_ENDPOINT" | sed -Ee 's@https?://@@')
  wait-for-it -t ${GRAFANA_WAIT_TIMEOUT} "$hostPort"
fi

while [ -n "$1" ]
do
  case $1 in
    -h|--help)
      usage
      exit 0
      ;;
    new-datasources )
      # Parsing options for this command and execute
      if [ -z "$2" ]
      then
        echo "Command 'new-datasources' without options"
        usage
        exit 1
      fi
      shift

      # Initialize (and clean) array
      unset fileList
      declare -a fileList
      index=0
      stop=no
      while [ "$stop" == "no"  ]
      do
        case $1 in
          --json )
            if [ -z "$2" ]
            then
              echo "Option --json in new-datasources command without payload"
              usage
              exit 1
            fi
            fileTemp="$(mktemp)"
            echo "$2" > "$fileTemp"
            fileList[$index]="$fileTemp"
            ;;
          --file )
            if [[ -z "$2" || ! -f "$2" ]]
            then
              echo "Option --file in new-datasources command without valid filename"
              usage
              exit 1
            fi
            fileList[$index]="$2"
            ;;
          --path )
            if [[ -z "$2" || ! -d "$2" ]]
            then
              echo "Option --path in new-datasources command without valid directory name ($2)"
              usage
              exit 1
            fi
            echo "* Scanning $2 with ${PATH_FIND_PATTERN} wildcard for new-datasources definition files"
            # for XXXX in XXXX splited by line
            OLD_IFS=$IFS
            IFS=$'\n'
            for file in $(find $2 -type f -maxdepth 1 | egrep -e "${PATH_FIND_PATTERN}")
            do
              echo "       - $file"
              fileList[$index]="${file}"
              index=$((index + 1))
            done
            IFS=$OLD_IFS
            ;;
        esac
        shift 2
        index=$((index + 1))
        if [[ -z "$1" || "$1" != "--json" && "$1" != "--file" && "$1" != "--path" ]]
        then
          stop="yes"
        fi
      done

      # Run command
      newDatasources "${fileList[@]}"
      echo "+ new-users block end (next $1)"
      ;;
    import-dashboards )
      # Parsing options for this command and execute
      if [ -z "$2" ]
      then
        echo "Command 'import-dashboards' without options"
        usage
        exit 1
      fi
      shift

      # Initialize (and clean) array
      unset fileList
      declare -a fileList
      index=0
      stop=no
      while [ "$stop" == "no"  ]
      do
        case $1 in
          --json )
            if [ -z "$2" ]
            then
              echo "Option --json in import-dashboards command without payload"
              usage
              exit 1
            fi
            fileTemp="$(mktemp)"
            echo "$2" > "$fileTemp"
            fileList[$index]="$fileTemp"
            ;;
          --file )
            if [[ -z "$2" || ! -f "$2" ]]
            then
              echo "Option --file in import-dashboards command without valid filename"
              usage
              exit 1
            fi
            fileList[$index]="$2"
            ;;
          --path )
            if [[ -z "$2" || ! -d "$2" ]]
            then
              echo "Option --path in import-dashboards command without valid directory name ($2)"
              usage
              exit 1
            fi
            echo "* Scanning $2 with ${PATH_FIND_PATTERN} wildcard for import-dashboards definition files"
            # for XXXX in XXXX splited by line
            OLD_IFS=$IFS
            IFS=$'\n'
            for file in $(find $2 -type f -maxdepth 1 | egrep -e "${PATH_FIND_PATTERN}")
            do
              echo "       - $file"
              fileList[$index]="${file}"
              index=$((index + 1))
            done
            IFS=$OLD_IFS
            ;;
        esac
        shift 2
        index=$((index + 1))
        if [[ -z "$1" || "$1" != "--json" && "$1" != "--file" && "$1" != "--path" ]]
        then
          stop="yes"
        fi
      done

      # Run command
      importDashboards "${fileList[@]}"
      echo "+ new-users block end (next $1)"
      ;;
    new-users )
      # Parsing options for this command and execute
      if [ -z "$2" ]
      then
        echo "Command 'new-users' without options"
        usage
        exit 1
      fi
      shift

      # Initialize (and clean) array
      unset fileList
      declare -a fileList
      index=0
      stop=no
      while [ "$stop" == "no"  ]
      do
        case $1 in
          --json )
            if [ -z "$2" ]
            then
              echo "Option --json in new-users command without payload"
              usage
              exit 1
            fi
            fileTemp="$(mktemp)"
            echo "$2" > "$fileTemp"
            fileList[$index]="$fileTemp"
            ;;
          --file )
            if [[ -z "$2" || ! -f "$2" ]]
            then
              echo "Option --file in new-users command without valid filename"
              usage
              exit 1
            fi
            fileList[$index]="$2"
            ;;
          --path )
            if [[ -z "$2" || ! -d "$2" ]]
            then
              echo "Option --path in new-users command without valid directory name ($2)"
              usage
              exit 1
            fi
            echo "* Scanning $2 with ${PATH_FIND_PATTERN} egrep filter for new-users definition files"
            # for XXXX in XXXX splited by line
            OLD_IFS=$IFS
            IFS=$'\n'
            for file in $(find $2 -type f -maxdepth 1 | egrep -e "${PATH_FIND_PATTERN}")
            do
              echo "       - $file"
              fileList[$index]="${file}"
              index="$((index + 1))"
            done
            IFS=$OLD_IFS
            ;;
        esac
        shift 2
        index=$((index + 1))

        if [[ -z "$1" || "$1" != "--json" && "$1" != "--file" && "$1" != "--path" ]]
        then
          stop="yes"
        fi
      done

      # Run command
      newUsers "${fileList[@]}"
      echo "+ new-users block end (next $1)"
      ;;
    *)
      # Optionst without command or unknown command
      echo "$1 is an unknown command"
      usage
      exit 1
      ;;
  esac
done