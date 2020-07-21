#!/bin/bash

# shellcheck disable=SC2181

# INSTALLATION:
#
# Copy this script to ~/pc_iac_scan.sh
# Edit ~/pc_iac_scan.sh (API, USERNAME, PASSWORD) below
# Make ~/pc_iac_scan.sh executable

# USAGE:
#
# Select a Terraform template
# Select Terminal - Run Task - pc_iac_scan

#### BEGIN USER CONFIGURATION

# Prisma Cloud › Access URL: Prisma Cloud API URL
API=https://api.prismacloud.io

# Prisma Cloud › Login Credentials: Access Key
USERNAME=abcdefghijklmnopqrstuvwxyz

# Prisma Cloud › Login Credentials: Secret Key
PASSWORD=1234567890=

# https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin/prisma-cloud-devops-security/use-the-prisma-cloud-extension-for-vs-code.html

#### END USER CONFIGURATION

MODULE=$1

if [ -z "${MODULE}" ]; then
  echo "Error: Please specify a module"
  exit 1
fi

LOGIN=/tmp/prisma-login.json
TPLAN=/tmp/prisma-terraform-${MODULE}.plan
JPLAN=/tmp/prisma-terraform-${MODULE}.plan.json
PSCAN=/tmp/prisma-terraform-${MODULE}.scan.json

#### LOGIN OR USE ACTIVE LOGIN

# The login token is valid for 10 minutes, but could be refreshed instead of replaced.
# https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin/get-started-with-prisma-cloud/access-the-prisma-cloud-api.html

ACTIVELOGIN=$(find "${LOGIN}" -mmin -10 2>/dev/null)
if [ -z "${ACTIVELOGIN}" ]; then
  curl -f -s -X POST "${API}/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}" \
  > "${LOGIN}"
fi

if [ ! -s "${LOGIN}" ]; then
  rm -f "${LOGIN}"
  echo "Error: API Login Failed"
  exit 1
fi

#### EXTRACT TOKEN FROM LOGIN

TOKEN=$(jq -r '.token' < "${LOGIN}")
if [ -z "${TOKEN}" ]; then
  rm -f "${LOGIN}"
  echo "Error: API Login Token Missing"
  exit 1
fi

#### SAVE PLAN

rm -f "${TPLAN}" 
terraform plan -no-color -out="${TPLAN}" "${MODULE}" > /dev/null 2>&1
if [ $? -ne 0 ] || [ ! -s "${TPLAN}" ]; then
  echo "Error: 'terraform plan' Failed"
  exit 1
fi

#### CONVERT PLAN TO JSON

rm -f "${JPLAN}" 
terraform show -no-color -json "${TPLAN}" > "${JPLAN}"
if [ $? -ne 0 ] || [ ! -s "${JPLAN}" ]; then
  echo "Error: 'terraform show' Failed"
  exit 1
fi

#### UPLOAD JSON PLAN TO PRISMA CLOUD

curl -f -s -X POST "${API}/iac_scan" \
  -H "Content-Type: multipart/form-data" \
  -H "x-redlock-auth: ${TOKEN}" \
  -F "templateFile=@${JPLAN}" \
> "${PSCAN}"

if [ $? -ne 0 ]; then
  echo "Error: API Scan Failed"
  exit 1
fi

#### OUTPUT RESULT

cat "${PSCAN}" | jq '.result.rules_matched[] | {severity, name, description}'