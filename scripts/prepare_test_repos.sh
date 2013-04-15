#!/bin/bash

ls test/repos $1 | while read x
do
  rm -rf "test/repos/$x/.git"
  cp -R "test/repos/$x/git" "test/repos/$x/.git"
done
