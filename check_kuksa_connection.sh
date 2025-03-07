#!/bin/bash

KUKSA_SERVER="192.168.56.48:8090"
CONTAINER_NAME="dk_vrte"
CHECK_INTERVAL=2  # Time (in seconds) between checks

echo "Starting monitoring for Kuksa server and $CONTAINER_NAME container..."

# Function to check Kuksa server connection
check_kuksa_connection() {
    OUTPUT=$(docker run --rm --network host ghcr.io/eclipse/kuksa.val/kuksa-client:0.4.2 ws://$KUKSA_SERVER 2>&1)
    echo "$OUTPUT" | grep -q "Websocket connected"
}

while true; do
    if check_kuksa_connection; then
        echo "$(date) - Connection to Kuksa server ($KUKSA_SERVER) is successful."

        # Check if the container is running
        if ! docker ps --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
            echo "$(date) - Container $CONTAINER_NAME is NOT running. Restarting..."
            docker restart $CONTAINER_NAME || docker run --name $CONTAINER_NAME --network host --privileged --restart unless-stopped phongbosch/dk_vrte:latest
        else
            echo "$(date) - Container $CONTAINER_NAME is running. Not execute restarting."
        fi
    else
        echo "$(date) - Cannot connect to Kuksa server ($KUKSA_SERVER). Stopping container..."
        docker kill $CONTAINER_NAME > /dev/null 2>&1 || echo "Container already stopped."
    fi

    sleep $CHECK_INTERVAL
done
