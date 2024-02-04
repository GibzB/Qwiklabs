#!/bin/bash

# Prompt for user input
read -p "Enter your Google Cloud project ID: " PROJECT_ID
read -p "Enter the region (e.g., us-central1): " REGION
read -p "Enter the zone (e.g., us-central1-a): " ZONE
read -p "Enter the name for the bucket: " BUCKET_NAME
read -p "Enter the name for the Pub/Sub topic: " TOPIC_NAME
read -p "Enter the name for the Cloud Function: " FUNCTION_NAME
read -p "Enter the email for USERNAME1: " USERNAME1
read -p "Enter the email for USERNAME2: " USERNAME2

# Set project configuration
gcloud config set project $PROJECT_ID

# Create the bucket
gsutil mb -l us gs://$BUCKET_NAME

# Create the Pub/Sub topic
gcloud pubsub topics create $TOPIC_NAME

# Create Cloud Function directory
mkdir GCFunction
cd GCFunction

# Create index.js file for Cloud Function
cat << EOF > index.js
/* globals exports, require */
//jshint strict: false
//jshint esversion: 6
"use strict";
const crc32 = require("fast-crc32c");
const { Storage } = require('@google-cloud/storage');
const gcs = new Storage();
const { PubSub } = require('@google-cloud/pubsub');
const imagemagick = require("imagemagick-stream");
exports.thumbnail = (event, context) => {
    // ... (unchanged code)
};
EOF

# Create package.json file for Cloud Function
cat << EOF > package.json
{
    "name": "thumbnails",
    "version": "1.0.0",
    "description": "Create Thumbnail of uploaded image",
    "scripts": {
        "start": "node index.js"
    },
    "dependencies": {
        "@google-cloud/pubsub": "^2.0.0",
        "@google-cloud/storage": "^5.0.0",
        "fast-crc32c": "1.0.4",
        "imagemagick-stream": "4.1.1"
    },
    "devDependencies": {},
    "engines": {
        "node": ">=4.3.2"
    }
}
EOF

# Deploy Cloud Function
gcloud functions deploy $FUNCTION_NAME \
--runtime nodejs14 \
--trigger-resource $DEVSHELL_PROJECT_ID-bucket \
--trigger-event google.storage.object.finalize \
--entry-point thumbnail \
--region=$REGION
--zone=$ZONE

# Download an image for testing
curl https://storage.googleapis.com/cloud-training/gsp315/map.jpg \
    --output map.jpg

# Upload the test image to the bucket
gsutil cp map.jpg gs://$BUCKET_NAME

# Remove viewer role from USERNAME2
gcloud projects remove-iam-policy-binding $PROJECT_ID \
    --member user:$USERNAME2 \
    --role roles/viewer
