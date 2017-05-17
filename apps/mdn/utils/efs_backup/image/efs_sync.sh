#!/bin/bash

# shellcheck warns against using > 1 arg in the shebang
set -e
set -u

check_requirements() {
    if [[ -z $LOCAL_DIR || -z $REMOTE_DIR || -z $BUCKET || -z $PUSH_OR_PULL ]]; then
        echo "Not all environment variables are set"
        exit 1
    fi
}


fix_creds() {
    # use a ~/.aws/credentials file INSTEAD of k8s set environment vars.
    # Unset env vars after the file is written.
    # Creds containing a slash seem to break the AWS CLI when run inside k8s,
    # but running in docker is fine.
    #
    # example error:
    # fatal error: Invalid header value b'AWS AKIAXXXX\n:ri81t84+26rX0qzRAASDDDXXXy2B70='
    mkdir /root/.aws
    cat << EOF > /root/.aws/credentials
[default]
aws_access_key_id=${AWS_ACCESS_KEY_ID}
aws_secret_access_key=${AWS_SECRET_ACCESS_KEY}
EOF
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
}

push_to_s3() {
    echo "Pushing from ${LOCAL_DIR} to ${BUCKET}${REMOTE_DIR}"
    aws s3 sync "${LOCAL_DIR}" "${BUCKET}${REMOTE_DIR}"
    echo "Complete"
}

pull_from_s3() {
    echo "Pulling from ${BUCKET}${REMOTE_DIR} to ${LOCAL_DIR}"
    aws s3 sync "${BUCKET}${REMOTE_DIR}" "${LOCAL_DIR}"
    echo "Complete"
}

check_requirements
fix_creds

if [[ "${PUSH_OR_PULL}" == "PUSH" ]]; then
    push_to_s3
elif [[ "${PUSH_OR_PULL}" == "PULL" ]]; then
    pull_from_s3
else
    echo "Invalid PUSH_OR_PULL value"
    exit 1
fi



