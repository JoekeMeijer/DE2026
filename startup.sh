#!/bin/bash
set -e


echo "Step 1/6: Initialising parameters..."
# Dynamically retrieve the GCP VM instance name (fallback to hostname)
INSTANCE_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
if [ -z "$INSTANCE_NAME" ]; then
    INSTANCE_NAME=$(hostname)
fi

# Extract just the username (e.g., j_h_meijer) from $HOME for the .env file :)
USER_NAME=$(basename "$HOME")
REPO_DIR="${HOME}/DE2026"
DEPLOY_DIR="/home/${REPO_DIR}/lab6/deployment"
ENV_FILE="${DEPLOY_DIR}/.env"

echo "Step 2/6: Pulling latest changes from Git repository..."
cd "${REPO_DIR}"
# Discard local changes to .env so git pull doesn't fail due to conflicts
git checkout -- lab6/deployment/.env 2>/dev/null || true
git pull

echo "Step 3/6. Retrieving current external IP for ${INSTANCE_NAME}..."
# Queries the GCP internal metadata server directly (fastest when run inside the VM)
EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)

# Fallback to gcloud CLI if the metadata server returns empty
if [ -z "$EXTERNAL_IP" ]; then
    EXTERNAL_IP=$(gcloud compute instances list --filter="name=${INSTANCE_NAME}" --format="value(EXTERNAL_IP)")
fi

if [ -z "$EXTERNAL_IP" ]; then
    echo "Error: Could not retrieve the external IP. :("
    exit 1
fi

echo "Found external IP: ${EXTERNAL_IP}"

echo "Step 4/6: Updating ${ENV_FILE} with external IP..."
cat <<EOF > "${ENV_FILE}"
EXTERNAL_IP=${EXTERNAL_IP}
USER_HOME=${USER_HOME}
EOF

echo "Updated .env contents! Value:"
cat "${ENV_FILE}"

echo "Step 5/6: Building and starting the Docker Compose cluster..."
cd "${DEPLOY_DIR}"
sudo docker compose down
sudo docker compose up -d --build

echo "Step 6/6: Waiting 10 seconds for JupyterLab to initialize, please hold on thight..."
sleep 10
echo "--------------------------------------------------------"
echo "Cluster started! Your JupyterLab URL with token:"
sudo docker logs spark-driver-app 2>&1 | grep -E "http://(127\.0\.0\.1|localhost):8888/lab\?token=" | tail -n 1 | sed "s/127.0.0.1/${EXTERNAL_IP}/g; s/localhost/${EXTERNAL_IP}/g"
echo "--------------------------------------------------------"
eco "Good luck with the assignment! :) -Joeke"
