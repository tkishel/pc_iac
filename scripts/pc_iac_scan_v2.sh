#!/bin/bash

# shellcheck disable=SC2181
# SC2181: Check exit code directly with e.g. 'if mycmd;', not indirectly with $?.

# INSTALLATION:
#
# Install jq and yq
# Copy this script to ~/pc_iac_scan.sh
# Edit [API, USERNAME, PASSWORD] below
# Make ~/pc_iac_scan.sh executable
# Calculon, compute!

# USAGE:
#
# ~/pc_iac_scan.sh <template_file_or_directory_to_scan> [-h 1 -m 2 -l 3 -o or]"

DEBUG=false


#### BEGIN USER CONFIGURATION

# Prisma Cloud › Access URL: Prisma Cloud API URL
API=https://api.prismacloud.io

# Prisma Cloud › Login Credentials: Access Key
USERNAME=abcdefghijklmnopqrstuvwxyz

# Prisma Cloud › Login Credentials: Secret Key
PASSWORD=1234567890=

#### END USER CONFIGURATION


#### UTILTIY FUNCTIONS

debug() {
  if $DEBUG; then
     echo
     echo "DEBUG: ${1}"
     echo
  fi
}

error_and_exit() {
  echo
  echo "ERROR: ${1}"
  echo
  exit 1
}

missing_item_in_list() {
  local item="${1}"
  shift
  local list=("$@")
  for i in "${list[@]}"; do
    [[ "${i}" == "${item}" ]] && return 1
  done
  return 0
}

is_numeric() {
  number_regex='^[0-9]+$'
  if [[ $1 =~ $number_regex ]]; then
    return 0
  else
    return 1    
  fi
}

real_path() {
    [[ $1 = /* ]] && echo "${1}" || echo "${PWD}/${1#./}"
}

find_recurse_parent() {
  local path
  path=$(real_path "${1}")
  local conf="${2}"
  while [[ "${path}" != "/" && ! -e "${path}/${conf}" ]]; do
    path=$(dirname "${path}")
  done
  if [ -e "${path}/${conf}" ]; then
    echo "${path}/${conf}"
  fi
}

read_yaml() {
  if [ -n "${1}" ]; then
    if $(yq --version | grep 'version 3'); then
      yq read -j "${1}"  
    else
      yq eval -j "${1}"  
    fi
  fi
}

#### PRISMA UTILTIY FUNCTIONS

prisma_usage() {
  echo ""
  echo "USAGE:"
  echo ""
  echo "  ${0} <template_file_or_directory_to_scan> [OPTIONS]"
  echo ""
  echo "OPTIONS:"
  echo ""
  echo "  --high, -h     The threshhold of high-severity violations that define a scan failure"
  echo "  --medium, -m   The threshhold of medium-severity violations that define a scan failure"
  echo "  --low, -l      The threshhold of low-severity violations that define a scan failure"
  echo "  --operator, -o The logic operator for high, medium, and low-severity failure threshholds"
  echo ""
}

prisma_cloud_config_template_type() {
  if [ -n "${1}" ]; then
    echo "${1}" | jq -r '.template_type' | tr '[:upper:]' '[:lower:]'
  fi
}

prisma_cloud_config_template_version() {
  if [ -n "${1}" ]; then
    terraform_version=$(echo "${1}" | jq -r '.terraform_version')
    if [ -n "${terraform_version}" ]; then
      echo "${terraform_version}"
    else
      template_version=$(echo "${1}" | jq -r '.template_version')
      if [ -n "${template_version}" ]; then
        echo "${template_version}"
      fi
    fi
  fi
}

prisma_cloud_config_tags() {
  if [ -n "${1}" ]; then
    # v1: array of strings
    # echo "${1}" | jq -r '.tags' | tr -d '\n\t' | tr -d '[:blank:]' | tr -d '\n\t[]' | sed 's/:/":"/g'
    # v2: key value pairs
    echo "${1}" | jq -r '.tags' | tr -d '\n\t'
  fi
}

#### PREREQUISITES

if ! type "jq" > /dev/null; then
  error_and_exit "jq not installed or not in execution path, jq is required for script execution."
fi

if ! type "yq" > /dev/null; then
  error_and_exit "yq not installed or not in execution path, yq is required for script execution."
fi

#### PARAMETERS AND VARIABLES

TEMPLATE=""
FAILURE_CRITERIA_HIGH=3
FAILURE_CRITERIA_MEDIUM=6
FAILURE_CRITERIA_LOW=9
FAILURE_CRITERIA_OPERATOR='or'

while (( "${#}" )); do
  case "${1}" in
    -h|--high)
      if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
        if ! is_numeric "${2}"; then
          prisma_usage
          error_and_exit "Argument for ${1} is not a number"
        fi
        FAILURE_CRITERIA_HIGH=$2
        shift 2
      else
        prisma_usage
        error_and_exit "Argument for ${1} not specified"
      fi
      ;;
    -m|--medium)
      if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
        if ! is_numeric "${2}"; then
          prisma_usage
          error_and_exit "Argument for ${1} is not a number"
        fi
        FAILURE_CRITERIA_MEDIUM=$2
        shift 2
      else
        prisma_usage
        error_and_exit "Argument for ${1} not specified"
      fi
      ;;
    -l|--low)
      if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
        if ! is_numeric "${2}"; then
          prisma_usage
          error_and_exit "Argument for ${1} is not a number"
        fi
        FAILURE_CRITERIA_LOW=$2
        shift 2
      else
        prisma_usage
        error_and_exit "Argument for ${1} not specified"
      fi
      ;;
    -o|--operator)
      if [ -n "${2}" ] && [ "${2:0:1}" != "-" ]; then
        FAILURE_CRITERIA_OPERATOR=$2
        shift 2
      else
        prisma_usage
        error_and_exit "Argument for ${1} not specified"
      fi
      ;;
    -*)
      # Unsupported flags.
      prisma_usage
      error_and_exit "Unsupported flag ${1}"
      ;;
    *)
      # Positional argument.
      TEMPLATE=$1
      if [ -z "${TEMPLATE}" ]; then
        error_and_exit "Please specify the file or directory to scan."
      fi
      if [ ! -e "${TEMPLATE}" ]; then
        error_and_exit "Template file or directory to scan does not exist: ${TEMPLATE}"
      fi
      shift
      ;;
  esac
done

TEMPLATE_DIRNAME=$(dirname "${TEMPLATE}")
TEMPLATE_BASENAME=$(basename "${TEMPLATE}")

CONF_PATH=".prismaCloud/config.yml"
CONF_FILE=$(find_recurse_parent "${TEMPLATE_DIRNAME}" "${CONF_PATH}")

if [ -z "${CONF_FILE}" ]; then
  error_and_exit "Configuration file does not exist."
fi

CONF_DATA=$(read_yaml "${CONF_FILE}")
CONF_TYPE=$(prisma_cloud_config_template_type "${CONF_DATA}")

if [ -z "${CONF_TYPE}" ]; then
  error_and_exit "Configuration file does not specify the template type [CFT, K8S, TF]"
fi

if [ "${CONF_TYPE}" == "tf" ]; then
  CONF_VERS=$(prisma_cloud_config_template_version "${CONF_DATA}")
fi

CONF_TAGS=$(prisma_cloud_config_tags "${CONF_DATA}")

PC_API_LOGIN_FILE=/tmp/prisma-api-login.json
PC_IAC_CREATE_FILE=/tmp/prisma-scan-create.json
PC_IAC_HISTORY_FILE=/tmp/prisma-scan-history.json
PC_IAC_UPLOAD_FILE=/tmp/prisma-scan-upload.json
PC_IAC_START_FILE=/tmp/prisma-scan-start.json
PC_IAC_STATUS_FILE=/tmp/prisma-scan-status.json
PC_IAC_RESULTS=/tmp/prisma-scan-results.json

#### MAIN

#### Use the active login, or login.
#
# https://api.docs.prismacloud.io/reference#login
#
# TODO:
#
# The login token is valid for 10 minutes.
# Refresh instead of replace, if it exists, as per:
# https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin/get-started-with-prisma-cloud/access-the-prisma-cloud-api.html

echo "Logging on and creating an API Token"

ACTIVELOGIN=$(find "${PC_API_LOGIN_FILE}" -mmin -10 2>/dev/null)
if [ -z "${ACTIVELOGIN}" ]; then
  rm -f "${PC_API_LOGIN_FILE}"
  curl --fail --silent \
    --request POST "${API}/login" \
    --header "Content-Type: application/json" \
    --data "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
    --output "${PC_API_LOGIN_FILE}"
fi

if [ $? -ne 0 ]; then
  error_and_exit "API Login Failed"
fi

# Check the output instead of checking the response code.

if [ ! -s "${PC_API_LOGIN_FILE}" ]; then
  rm -f "${PC_API_LOGIN_FILE}"
  error_and_exit "API Login Returned No Response Data"
fi

TOKEN=$(jq -r '.token' < "${PC_API_LOGIN_FILE}")
if [ -z "${TOKEN}" ]; then
  rm -f "${PC_API_LOGIN_FILE}"
  error_and_exit "Token Missing From 'API Login' Response"
fi

debug "Token: ${TOKEN}"

#### Create an IaC scan asset in Prisma Cloud.
#
# https://api.docs.prismacloud.io/reference#startasyncscan
# Incomplete (not started or no uploads) scan persist for 30 minutes until garbage collected.

echo "Creating Scan"

JSON_SINGLE_QUOTED="
{
  'data': {
    'type': 'async-scan',
    'attributes': {
      'assetName': '${TEMPLATE_BASENAME}',
      'assetType': 'IaC-API',
      'scanAttributes': {
        'scriptName': 'pc_iac_scan',
        'scriptVersion': '2.0.2'
      },
      'failureCriteria': {
        'high':     ${FAILURE_CRITERIA_HIGH},
        'medium':   ${FAILURE_CRITERIA_MEDIUM},
        'low':      ${FAILURE_CRITERIA_LOW},
        'operator': '${FAILURE_CRITERIA_OPERATOR}'
      }
    }
  }
}
"
JSON_DOUBLE_QUOTED=${JSON_SINGLE_QUOTED//\'/\"}

if [ -n "${CONF_TAGS}" ]; then
  JSON_DOUBLE_QUOTED=$(echo "${JSON_DOUBLE_QUOTED}" | jq ".data.attributes.tags = $CONF_TAGS")
fi

rm -f "${PC_IAC_CREATE_FILE}"
curl --silent --show-error \
  --request POST "${API}/iac/v2/scans" \
  --header "x-redlock-auth: ${TOKEN}" \
  --header "Accept: application/vnd.api+json" \
  --header "Content-Type: application/vnd.api+json" \
  --data-raw "${JSON_DOUBLE_QUOTED}" \
  --output "${PC_IAC_CREATE_FILE}"

# TODO: Use --fail and/or --write-out '{http_code}' ?
if [ $? -ne 0 ]; then
  error_and_exit "Create Scan Asset Failed"
fi

# Check the output instead of checking the response code.

if [ ! -s "${PC_IAC_CREATE_FILE}" ]; then
  error_and_exit "Create Scan Returned No Response Data"
fi

PC_IAC_ID=$(jq -r '.data.id' < "${PC_IAC_CREATE_FILE}")

if [ -z "${PC_IAC_ID}" ]; then
  error_and_exit "Scan ID Missing From 'Create Scan' Response"
fi

PC_IAC_URL=$(jq -r '.data.links.url' < "${PC_IAC_CREATE_FILE}")

if [ -z "${PC_IAC_URL}" ]; then
  error_and_exit "Scan URL Missing From 'Create Scan' Response"
fi

echo "$(date '+%F %T') ${PC_IAC_ID}" >> "${PC_IAC_HISTORY_FILE}"

debug "Scan ID: ${PC_IAC_ID}"

#### Use the pre-signed URL from the scan asset creation to upload the files to be scanned.
#
# After the scan is finished, uploaded files are deleted.

echo "Uploading Files"

TEMPLATE_ARCHIVE="/tmp/${TEMPLATE_BASENAME}.zip"

if [ -d "${TEMPLATE}" ] || [ -f "${TEMPLATE}" ] ; then
  cd "${TEMPLATE_DIRNAME}" || error_and_exit "Unable to change into ${TEMPLATE_DIRNAME}"
  rm -r -f "${TEMPLATE_ARCHIVE}"
  zip -r -q "${TEMPLATE_ARCHIVE}" "${TEMPLATE_BASENAME}" -x "*/.*" "*terraform.tfstate*"
else
  error_and_exit "Template file or directory to scan is not a file or directory: ${TEMPLATE}"
fi

rm -f "${PC_IAC_UPLOAD_FILE}"
curl --silent --show-error \
  --request PUT "${PC_IAC_URL}" \
  --upload-file "${TEMPLATE_ARCHIVE}" \
  --output "${PC_IAC_UPLOAD_FILE}"

# TODO: Use --fail and/or --write-out '{http_code}' ?
if [ $? -ne 0 ]; then
  error_and_exit "Upload Scan Asset Failed"
fi

debug "Uploaded: ${TEMPLATE_ARCHIVE}"

#### Start a job to perform a scan of the uploaded files.
#
# https://api.docs.prismacloud.io/reference#triggerasyncscan-1
#
# TODO:
#
# This API detects Terraform module structures and variable files automatically, in most cases.
# Review the use of variables, variableFiles, files, and folders attributes.

echo "Starting Scan"

JSON_SINGLE_QUOTED="
{
  'data': {
    'id': '${PC_IAC_ID}',
    'attributes': {
      'templateType': '${CONF_TYPE}'
    }
  }
}
"
JSON_DOUBLE_QUOTED=${JSON_SINGLE_QUOTED//\'/\"}

if [ -n "${CONF_VERS}" ]; then
  JSON_DOUBLE_QUOTED=$(echo "${JSON_DOUBLE_QUOTED}" | jq ".data.attributes.templateVersion = \"${CONF_VERS}\"")
fi

rm -f "${PC_IAC_START_FILE}"
curl --silent --show-error \
  --request POST "${API}/iac/v2/scans/${PC_IAC_ID}" \
  --header "x-redlock-auth: ${TOKEN}" \
  --header "Content-Type: application/vnd.api+json" \
  --data-raw "${JSON_DOUBLE_QUOTED}" \
  --output "${PC_IAC_START_FILE}"

# TODO: Use --fail and/or --write-out '{http_code}' ?
if [ $? -ne 0 ]; then
  error_and_exit "Start Scan Failed"
fi

#### Check the output instead of checking the response code.
#
# Note that there is no output upon success.

if [ -s "${PC_IAC_START_FILE}" ]; then
  START_STATUS=$(jq -r '.status' < "${PC_IAC_START_FILE}")

  if [ -z "${START_STATUS}" ]; then
    error_and_exit "Status Missing From 'Start Scan' Response"
  fi

  if [ "${START_STATUS}" -ne 200 ]; then
    error_and_exit "Start Scan Returned: ${START_STATUS}"
  fi

  START_STATUS="unknown"
else
  START_STATUS="success"
fi

debug "Start Scan Status: ${START_STATUS}"

#### Query scan status.

echo -n "Querying Scan Status "

SCAN_STATUS="processing"
while [ "${SCAN_STATUS}" == "processing" ]
do
  sleep 4

  rm -f "${PC_IAC_STATUS_FILE}"
  HTTP_CODE=$(curl --silent --write-out '%{http_code}' \
    --request GET "${API}/iac/v2/scans/${PC_IAC_ID}/status" \
    --header "x-redlock-auth: ${TOKEN}" \
    --header "Accept: application/vnd.api+json" \
    --output "${PC_IAC_STATUS_FILE}")

  # TODO: Use --fail ?
  if [ $? -ne 0 ]; then
    error_and_exit "Query Scan Status Failed"
  fi

  if [[ $HTTP_CODE == 5?? ]]; then
    echo -n " ${HTTP_CODE} "
  else
    SCAN_STATUS=$(jq -r '.data.attributes.status' < "${PC_IAC_STATUS_FILE}")
    if [ -z "${SCAN_STATUS}" ]; then
      error_and_exit "Status Missing From 'Query Scan Status' Response"
    fi
    echo -n "."
  fi

  debug "Scan Status: ${SCAN_STATUS}"

done

echo

#### Query scan results.
#
# https://api.docs.prismacloud.io/reference#getscanresult
# Scan results persist for 90 days until garbage collected.

echo "Querying Scan Results"

rm -f "${PC_IAC_RESULTS}"
curl --fail --silent --show-error \
  --request GET "${API}/iac/v2/scans/${PC_IAC_ID}/results" \
  --header "x-redlock-auth: ${TOKEN}" \
  --header "Accept: application/vnd.api+json" \
  --output ${PC_IAC_RESULTS}

if [ $? -ne 0 ]; then
  error_and_exit "Query Scan Results Failed"
fi

HIGH=$(  jq '.meta.matchedPoliciesSummary.high'   < "${PC_IAC_RESULTS}")
MEDIUM=$(jq '.meta.matchedPoliciesSummary.medium' < "${PC_IAC_RESULTS}")
LOW=$(   jq '.meta.matchedPoliciesSummary.low'    < "${PC_IAC_RESULTS}")

debug "Scan Results: ${PC_IAC_RESULTS}"

# TODO: Deeply parse the results with jq, and display the parsed results.

echo "Results:"
echo
jq '.data' < "${PC_IAC_RESULTS}"
echo
echo "Summary:"
echo
echo "High Severity Issues Found: ${HIGH}"
echo "Medium Severity Issues Found: ${MEDIUM}"
echo "Low Severity Issues Found: ${LOW}"
echo
echo "Scan ${SCAN_STATUS}!"
echo "(Based upon these thresholds: High: ${FAILURE_CRITERIA_HIGH}, Medium: ${FAILURE_CRITERIA_MEDIUM}, Low: ${FAILURE_CRITERIA_LOW}, with Operator: ${FAILURE_CRITERIA_OPERATOR})"

echo