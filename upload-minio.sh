#!/bin/bash

# Usage: ./upload-minio s3-key s3-secret host my-bucket my-file.zip

s3_key=$1 
s3_secret=$2 
host=$3 #s3.ivan-b.com

bucket=$4
file=$5


resource="/${bucket}/${file}"
content_type="application/octet-stream"
date=`date -R`
_signature="PUT\n\n${content_type}\n${date}\n${resource}"
signature=`echo -en ${_signature} | openssl sha1 -hmac ${s3_secret} -binary | base64`

curl -X PUT -T "${file}" \
          -H "Host: ${host}" \
          -H "Date: ${date}" \
          -H "Content-Type: ${content_type}" \
          -H "Authorization: AWS ${s3_key}:${signature}" \
          https://${host}${resource}