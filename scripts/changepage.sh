#!/bin/bash

curl -X POST http://127.0.0.1:27003/api/lcd/profile -d '{  "deviceId": "04B6214001805",  "profile": "'$1'"}'