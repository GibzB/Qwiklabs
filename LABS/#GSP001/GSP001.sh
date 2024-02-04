gcloud config set compute/region <YOUR REGION>

export ZONE=<YOUR ZONE>


gcloud compute instances create gcelab \
--zone=$ZONE \
--machine-type=e2-medium \
--image-project=debian-cloud \
--image-family=debian-11 \
--tags=http-server

gcloud compute firewall-rules create allow-http \
--action=ALLOW \
--direction=INGRESS \
--rules=tcp:80 \
--source-ranges=0.0.0.0/0 \
--target-tags=http-server

gcloud compute instances create gcelab2 \
--machine-type e2-medium \
--zone=$ZONE

#SSH to the VM
gcloud compute ssh gcelab --zone=$ZONE --quiet


sudo apt-get update
sudo apt-get install -y nginx
ps auwx | grep nginx
