#!/bin/bash

source 00-cfg


# Validate token.
curl -o /dev/null -sH "$AUTH" $GH_REPO || { echo "Error: Invalid repo, token or network issue!";  exit 1; }

# Read asset tags.
#RESP=$(curl -sH "$AUTH" $GH_TAGS)
RESP=$(cat tmp-release-draft.json)

echo $RESP | jq .

ID=$(echo $RESP | jq -r .id)

[ "$ID" ] || { echo "Error: Failed to get release id for tag: $TAG"; echo "$RESP" | awk 'length($0)<100' >&2; exit 1; }

cd "$WDIR"

# Upload asset
echo "Uploading asset... "

# Construct url
BN=$(basename "$FN")
GH_ASSET="https://uploads.github.com/repos/$OWNER/$REPO/releases/$ID/assets"
GH_ASSET="$GH_ASSET?name=$BN"

curl --output tmp-release-upload.json --data-binary @"$FN" \
    -H "$AUTH" \
    -H "Content-Type: application/octet-stream" \
    $GH_ASSET
