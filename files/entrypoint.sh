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

    PARAMETRIZE JSON FILES "ON-FLY"

      You can add parametrization in json files using environment variables. All
      values found in files that match with {{ENV_VAR_NAME}} will be replaced by
      value of \${ENV_VAR_NAME} ONLY if ENV_VAR_NAME is defined (not empty).
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
  local ep_gcd_method="POST"
  if [ -n "$3" ]
  then
    ep_gcd_method="$3"
  fi
  local ep_gcd_url="${GRAFANA_ENDPOINT}$1"
  local ep_gcd_fileInput="$2"

  echo "       - curl -X$ep_gcd_method -d @${ep_gcd_fileInput} ${ep_gcd_url}"
  echo "       --------"

  if [ -n "${GRAFANA_AUTH_BEARER}" ]
  then
    # Curl with token
    curl \
      ${CURL_OPTIONS} \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -H 'Authorization: Bearer ${GRAFANA_AUTH_BEARER}' \
      -X "$ep_gcd_method" \
      --data "@${ep_gcd_fileInput}" \
      "${ep_gcd_url}" \
    | jq -C '.'
  elif [ -n "${GRAFANA_AUTH_USERPASSWD}" ]
  then
    # Curl with user password
    curl \
      ${CURL_OPTIONS} \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -u "${GRAFANA_AUTH_USERPASSWD}" \
      --data "@${ep_gcd_fileInput}" \
      -X "$ep_gcd_method" \
      "${ep_gcd_url}" \
    | jq -C '.'
  else
    # Curl without auth
    curl \
      ${CURL_OPTIONS} \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -X "$ep_gcd_method" \
      --data "@${ep_gcd_fileInput}" \
      "${ep_gcd_url}" \
    | jq -C '.'
  fi
  echo "       --------"
}

##
# Replace {{ENV_VAR_NAME}} strings with value of $ENV_VAR_NAME in a new copy of a file
##
# $1 file path
##
# Return new path of file if was changed or original file if was not changed
replaceEnvVarsInFile(){
  if [ -n "$1" ]
  then
    local ep_gcd_fileName="$1"
    # Extract var names {{XXXX}}, {{YYYY}}, etc
    local ep_gcd_findReplacements=$(cat "${ep_gcd_fileName}" | egrep -oe '\{\{[^\}]+\}\}')
    if [ -n "$ep_gcd_findReplacements" ]
    then
      local ep_gcd_newFile=$(mktemp)
      cat "${ep_gcd_fileName}" > "${ep_gcd_newFile}"
      for ep_gdc_cand in $ep_gcd_findReplacements
      do
        # Extract varName
        local ep_gdc_varName=$(echo -n "$ep_gdc_cand" | tr -d '}{')
        # Use eval to resolve $$ep_gdc_varName to $VALUE_OF_ep_gdc_varName
        eval "[ -n \"\$${ep_gdc_varName}\" ] \
          && sed -i \"s@{{${ep_gdc_varName}}}@\$${ep_gdc_varName}@\" ${ep_gcd_newFile}"
      done
      local ep_gdc_origSha=$(cat "${ep_gcd_fileName}" | md5sum)
      local ep_gdc_newSha=$(cat "${ep_gcd_newFile}" | md5sum)
      if [ "$ep_gdc_origSha" == "$ep_gdc_newSha" ]
      then
        echo -n "$ep_gcd_fileName"
        rm -f "$ep_gcd_newFile"
      else
        echo -n "$ep_gcd_newFile"
      fi
    else
      echo -n "$ep_gcd_fileName"
      rm -f "$ep_gcd_newFile"
    fi
  fi
}

newDatasources(){
  while [ -n "$1" ]
  do
    echo "+ Uploading datasource from file $1"
    ccurl "/api/datasources" "$1"
    shift
  done
}

importDashboards(){
  while [ -n "$1" ]
  do
    echo "+ Uploading dahsboard from file $1"
    ccurl "/api/dashboards/import" "$1"
    shift
  done
}

newUsers(){
  while [ -n "$1" ]
  do
    echo "+ Uploading user from file $1"
    ccurl "/api/admin/users" "$1"
    shift
  done
}

###
# Function to avoid copy+paste code for commands wich allowe options are
# --json, --file and --path. Suported commands are new-datasources,
# new-users and import-dashboards
##
# $1 command to be executed (new-datasource, new-users, import-dashboards)
# $2 .. $n-m compatible options: --json JSON_BODY, --file JSON_FILE, --path
# $n-m+1 .. $n Other optiosn to ignore
##
# Global variables (Read):
#   PATH_FIND_PATTERN: Pattern to filter files in --path option
# Global variables (SAVE):
#   N_ARGS_USED: Set number of argumentes used (n-m), this can be usefull if you
#   are using this function in a loop iterating over args and you need shift
#   argumentes procesed
parseAndRunJFP(){
  local ep_gcd_commandName="$1"
  echo "* ${ep_gcd_commandName} block begin"
  # Parsing options for this command and execute
  if [ -z "$2" ]
  then
    echo ""
    echo "ERROR: Command '${ep_gcd_commandName}' without options"
    echo ""
    echo "Run with -h option for help"
    exit 1
  fi
  shift


  # Initialize vars
  N_ARGS_USED=1 # 1 because whe skip $1, ep_gcd_commandName
  declare -a ep_gcd_fileList
  local ep_gdc_index=0
  local ep_gdc_stop=no
  while [ "$ep_gdc_stop" == "no"  ]
  do
    case $1 in
      --json )
        if [ -z "$2" ]
        then
          echo ""
          echo "ERROR: Option --json in ${ep_gcd_commandName} command without payload"
          echo ""
          echo "Run with -h option for help"
          exit 1
        fi
        fileTemp="$(mktemp)"
        echo "$2" > "$fileTemp"
        ep_gcd_fileList[$ep_gdc_index]="$fileTemp"
        ;;
      --file )
        if [[ -z "$2" || ! -f "$2" ]]
        then
          echo ""
          echo "ERROR: Option --file in ${ep_gcd_commandName} command without valid filename ($2)"
          echo ""
          echo "Run with -h option for help"
          exit 1
        fi
        ep_gcd_fileList[$ep_gdc_index]="$2"
        ;;
      --path )
        if [[ -z "$2" || ! -d "$2" ]]
        then
          echo ""
          echo "ERROR: Option --path in ${ep_gcd_commandName} command without valid directory name ($2)"
          echo ""
          echo "Run with -h option for help"
          exit 1
        fi
        echo "+ Scanning $2 with ${PATH_FIND_PATTERN} wildcard for ${ep_gcd_commandName} definition files"
        # for XXXX in XXXX splited by line
        OLD_IFS=$IFS
        IFS=$'\n'
        for ep_gdc_file in $(find $2 -type f -maxdepth 1 | egrep -e "${PATH_FIND_PATTERN}")
        do
          echo "       - $ep_gdc_file"
          ep_gcd_fileList[$ep_gdc_index]="${ep_gdc_file}"
          ep_gdc_index=$((ep_gdc_index + 1))
        done
        IFS=$OLD_IFS
        ;;
    esac
    shift 2
    N_ARGS_USED=$((N_ARGS_USED + 2))
    ep_gdc_index=$((ep_gdc_index + 1))
    if [[ -z "$1" || "$1" != "--json" && "$1" != "--file" && "$1" != "--path" ]]
    then
      ep_gdc_stop="yes"
    fi
  done

  # Replace env vars in files
  declare -a ep_gdc_fileListEdited
  for ((ep_gdc_i=0;ep_gdc_i<${#ep_gcd_fileList[@]};ep_gdc_i++))
  do
    ep_gdc_fileListEdited[$ep_gdc_i]=$(replaceEnvVarsInFile "${ep_gcd_fileList[$ep_gdc_i]}")
    if [ "${ep_gcd_fileList[$ep_gdc_i]}" != "${ep_gdc_fileListEdited[$ep_gdc_i]}" ]
    then
      echo "       + Values of environment variables replaced: ${ep_gcd_fileList[$ep_gdc_i]} -> ${ep_gdc_fileListEdited[$ep_gdc_i]}"
    fi

  done
  # Run command
  case ${ep_gcd_commandName} in
    new-datasources )
      newDatasources "${ep_gdc_fileListEdited[@]}"
      ;;
    new-users )
      newUsers "${ep_gdc_fileListEdited[@]}"
      ;;
    import-dashboards )
      importDashboards "${ep_gdc_fileListEdited[@]}"
      ;;
    *)
      echo "WARN: command ${ep_gcd_commandName} is not supported in parseAndRunJFP. IGNORED"
      ;;
  esac

  local ep_gdc_nextBlock="(last)"
  if [ -n "$1" ]
  then
    ep_gdc_nextBlock="(next $1)"
  fi
  echo "* ${ep_gcd_commandName} block end $ep_gdc_nextBlock"
}

###
# MAIN BODY
###

#Global vars based on environment
if [ -z "${GRAFANA_ENDPOINT}" ]
then
  echo ""
  echo "ERROR: GRAFANA_ENDPOINT empty"
  echo ""
  echo "Run with -h option for help"
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
    new-datasources|import-dashboards|new-users )
      parseAndRunJFP "$@"
      shift ${N_ARGS_USED}
      ;;
    *)
      # Optionst without command or unknown command
      echo ""
      echo "ERROR: $1 is an unknown command"
      echo ""
      echo "Run with -h option for help"
      exit 1
      ;;
  esac
done
