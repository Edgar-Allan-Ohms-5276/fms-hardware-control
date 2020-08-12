#!/bin/sh

DATA=`cat $DIR/resources/login.json`
DEREF_DATA=`eval echo $DATA`
echo "$DEREF_DATA"