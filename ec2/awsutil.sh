#!/bin/bash
aws ec2 create-key-pair --key-name ${KEY_NAME}  --query 'KeyMaterial' --output text $SSH_KEYFILE
chmod 400 ${SSH_KEYFILE}
