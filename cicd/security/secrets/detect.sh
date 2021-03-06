#!/usr/bin/env bash

# scan whole repository and compare to baseline
_date=$(date +%s)
detect-secrets scan | jq '.results | del(.|.["secrets.baseline.json"]) | del(.[] | .[].line_number)' > ${_date}_secrets.scan.json
cat secrets.baseline.json | jq '. | del(.[] | .[].line_number)' > noLineNumbers.secrets.baseline.json
diff noLineNumbers.secrets.baseline.json ${_date}_secrets.scan.json >/dev/null
if [[ $? -ne 0 ]]
then
  echo -e "\e[91m* ALERT: Detected new secrets violating the secrets baseline!\e[39m"
  echo "  detected secrets:"
  diff -ruN noLineNumbers.secrets.baseline.json ${_date}_secrets.scan.json
  echo
  # exit 1 to abort/fail CI pipeline
  rm -f ${_date}_secrets.scan.json noLineNumbers.secrets.baseline.json
  [[ "$ENFORCE" == 0 ]] || exit 1
else
  # file are the same
  echo -e "\e[92m* PASS: No violation of secrets baseline found.\e[39m"
fi

rm -f ${_date}_secrets.scan.json noLineNumbers.secrets.baseline.json
