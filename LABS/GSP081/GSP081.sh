#!/bin/bash

# Prompt for user input
read -p "Enter your Google Cloud project ID: " PROJECT_ID
read -p "Enter the region (e.g., us-central1): " REGION


gcloud config set project $PROJECT_ID

# Create Cloud Function directory
mkdir GCFunction
cd GCFunction

# Create index.js file for Cloud Function
cat << EOF > index.js
/**
* Responds to any HTTP request.
*
* @param {!express:Request} req HTTP request context.
* @param {!express:Response} res HTTP response context.
*/
exports.helloWorld = (req, res) => {
let message = req.query.message || req.body.message || 'Hello World!';
res.status(200).send(message);
};
EOF

# Create package.json file for Cloud Function
cat << EOF > package.json
{
"name": "sample-http",
"version": "0.0.1"
}
EOF

# Deploy Cloud Function
gcloud functions deploy GCFunction \
    --gen2 \
    --trigger-http \
    --max-instances 5 \
    --min-instances 0 \
    --runtime nodejs18 \
    --entry-point helloWorld \
    --source .
    --member=serviceAccount:PROJECT_ID@appspot.gserviceaccount.com \
    --role=roles/artifactregistry.reader


# Test the function

gcloud functions call GCFunction --region=$REGION --data '{"message":"Hello World!"}'


# View Logs
gcloud functions logs read GCFunction
