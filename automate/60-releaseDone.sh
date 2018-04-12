#!/bin/bash

source 00-cfg

REQ=`jq -c . <<-EOF
{
  "tag_name": "v$VER",
  "draft": false,
  "prerelease": false
}
EOF`

RESP=$(cat tmp-release-draft.json)

echo "$REQ" | jq .

ID=$(echo $RESP | jq -r .id)

[ "$ID" ] || { echo "Error: Failed to get release id for tag: $TAG"; echo "$RESP" | awk 'length($0)<100' >&2; exit 1; }

curl --output tmp-release-done.json --data "$REQ" -sH "$AUTH" $GH_REPO/releases/$ID
