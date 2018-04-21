#!/bin/bash

source 00-cfg

REQ=`jq -c . <<-EOF
{
  "tag_name": "v$VER",
  "target_commitish": "master",
  "name": "v$VER",
  "draft": true,
  "prerelease": false
}
EOF`

RN=tmp-release-notes.txt
cat >$RN <<EOF
### Raspbian root filesystem v$VER

This contains archive with recent Raspbian rootfs.

EOF

CFN=installed
DELNO=$(cat $WDIR/tmp-$CFN.del | wc -l)
DELNO=$[1*DELNO]
ADDNO=$(cat $WDIR/tmp-$CFN.add | wc -l)
ADDNO=$[1*ADDNO]

echo -e "There was $ADDNO added and $DELNO removed compared to previous release.\n" >>$RN

if [ -s "$WDIR/tmp-$CFN.add" ]; then
    echo -e "\n#### Packages added\n" >>$RN
    echo '```' >>$RN
    cat $WDIR/tmp-$CFN.add >>$RN
    echo '```' >>$RN
fi

if [ -s "$WDIR/tmp-$CFN.del" ]; then
    echo -e "\n#### Packages removed\n" >>$RN
    echo '```' >>$RN
    cat $WDIR/tmp-$CFN.del >>$RN
    echo '```' >>$RN
fi

cat >>$RN <<EOF
#### Installed packages

EOF

echo '```' >>$RN
cat $WDIR/$CFN.new >>$RN
echo '```' >>$RN

REQ=`( jq -sR '{ body: . }' $RN; echo $REQ ) | jq -s add`

echo "$REQ" | jq .

curl --output tmp-release-draft.json --data "$REQ" -sH "$AUTH" $GH_REPO/releases
