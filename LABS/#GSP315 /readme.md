# **Perform Foundational Infrastructure Tasks in Google Cloud: Challenge Lab # GSP315**

## **Walkthrough**

Command to create variables that change every lab

    export PROJECT_ID=<your project id>
    export BUCKET_NAME=<your bucket name>
    export TOPIC_NAME=<your topic name>
    export FUNCTION_NAME=<your cloud function name>
    export USERNAME1=<username 2 email>
    export USERNAME2=<username 2 email>

    gcloud config set project $PROJECT_ID

    gsutil mb -l us gs://$BUCKET_NAME

    gcloud pubsub topics create $TOPIC_NAME

    mkdir GCFunction
    cd GCFunction


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
        const fileName = event.name;
        const bucketName = event.bucket;
        const size = "64x64"
        const bucket = gcs.bucket(bucketName);
        const topicName = "$TOPIC_NAME";
        const pubsub = new PubSub();
        if ( fileName.search("64x64_thumbnail") == -1 ){
            // doesn't have a thumbnail, get the filename extension
            var filename_split = fileName.split('.');
            var filename_ext = filename_split[filename_split.length - 1];
            var filename_without_ext = fileName.substring(0, fileName.length - filename_ext.length );
            if (filename_ext.toLowerCase() == 'png' || filename_ext.toLowerCase() == 'jpg'){
            // only support png and jpg at this point
            console.log(`Processing Original: gs://${bucketName}/${fileName}`);
            const gcsObject = bucket.file(fileName);
            let newFilename = filename_without_ext + size + '_thumbnail.' + filename_ext;
            let gcsNewObject = bucket.file(newFilename);
            let srcStream = gcsObject.createReadStream();
            let dstStream = gcsNewObject.createWriteStream();
            let resize = imagemagick().resize(size).quality(90);
            srcStream.pipe(resize).pipe(dstStream);
            return new Promise((resolve, reject) => {
                dstStream
                .on("error", (err) => {
                    console.log(`Error: ${err}`);
                    reject(err);
                })
                .on("finish", () => {
                    console.log(`Success: ${fileName} → ${newFilename}`);
                    // set the content-type
                    gcsNewObject.setMetadata(
                    {
                        contentType: 'image/'+ filename_ext.toLowerCase()
                    }, function(err, apiResponse) {});
                    pubsub
                        .topic(topicName)
                        .publisher()
                        .publish(Buffer.from(newFilename))
                        .then(messageId => {
                        console.log(`Message ${messageId} published.`);
                        })
                        .catch(err => {
                        console.error('ERROR:', err);
                        });
                });
            });
            }
            else {
            console.log(`gs://${bucketName}/${fileName} is not an image I can handle`);
            }
        }
        else {
            console.log(`gs://${bucketName}/${fileName} already has a thumbnail`);
        }
    };
    EOF

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
    
    
    gcloud functions deploy $FUNCTION_NAME \
        --trigger-bucket $BUCKET_NAME \
        --runtime nodejs14 \
        --entry-point thumbnail \
        --source .

        curl https://storage.googleapis.com/cloud-training/gsp315/map.jpg \
        --output map.jpg

        gsutil cp map.jpg gs://$BUCKET_NAME
        
        
        gcloud projects remove-iam-policy-binding $PROJECT_ID \
        --member user:$USERNAME2 \
        --role roles/viewer


