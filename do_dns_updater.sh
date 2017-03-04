#!/bin/bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${DIR}"

function cleanup() {
  echo "An error occured, cleaning up, removing ${FILE}"
  rm -f "${FILE}"
}

trap cleanup ERR

source settings # Settings file name

FILE="${HOST}.ip"
touch "${FILE}"

IP=$(curl -s checkip.dyndns.org | grep -Eo '[0-9\.]+')

if grep -q "${IP}" "${FILE}"; then
  echo "IP unchanged (${IP}), exiting!"
  exit 0
fi

JSON=$(curl -X GET -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" "https://api.digitalocean.com/v3/domains/$DOMAIN/records" | python -m json.tool)

if echo "${JSON}" | grep -q "${IP}"; then
  echo "IP found from JSON, no need to update!"
else
  curl -s -X PUT -H 'Content-Type: application/json' -H "Authorization: Bearer $TOKEN" -d "{\"data\":\"$IP\"}" "https://api.digitalocean.com/v2/domains/$DOMAIN/records/$RECORD_ID" > /dev/null
fi

echo "Saving IP ${IP} to file ${FILE}"
echo "${IP}" > "${FILE}"

exit 0
