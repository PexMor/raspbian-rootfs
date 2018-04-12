#!/bin/bash

source 00-cfg

cd "$WDIR"
git tag -a v$VER -m "Release of version $VER"
git push --tags
