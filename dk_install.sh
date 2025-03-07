#!/bin/bash

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Start dreamOS installation !!!!!!!!!!!!!"
echo "------------------------------------------------------------------------------------------------------------------------------------"

# Determine the user who ran the command
if [ -n "$SUDO_USER" ]; then
    # Command was run with sudo
    DK_USER=$SUDO_USER
else
    # Command was not run with sudo, fall back to current user
    DK_USER=$USER
fi
# Get the current directory path
CURRENT_DIR=$(pwd)
# Set Env Variables
HOME_DIR="/home/$DK_USER"
DOCKER_SHARE_PARAM="-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker"
LOG_LIMIT_PARAM="--log-opt max-size=10m --log-opt max-file=3"
DOCKER_HUB_NAMESPACE="phongbosch"

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Create dk directoties ..."
mkdir -p /home/$DK_USER/.dk/scripts

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Creating dreamOS setup script..."

# Define file paths
SETUP_SCRIPT="/home/$DK_USER/.dk/scripts/dreamos_setup.sh"
SERVICE_FILE="/etc/systemd/system/dreamos-setup.service"

# Create setup script only if it doesn't exist
if [ ! -f "$SETUP_SCRIPT" ]; then
    echo "Creating dreamOS setup script..."
    cat << 'EOF' > $SETUP_SCRIPT
#!/bin/bash

# Configure CAN0
ip link set can0 type can bitrate 500000 sample-point 0.75 dbitrate 2000000 fd on
ip link set can0 up
ifconfig can0 txqueuelen 65536

# Configure CAN1
ip link set can1 type can bitrate 500000
ip link set can1 up
ifconfig can1 txqueuelen 65536

EOF
else
    echo "dreamOS setup script already exists, skipping creation."
fi

# Make the script executable
chmod +x $SETUP_SCRIPT
echo "dreamOS setup script created at $SETUP_SCRIPT"

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Creating systemd service file..."
# Create service file only if it doesn't exist
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Creating systemd service file..."
    cat << EOF > $SERVICE_FILE
[Unit]
Description=Setup dreamOS on Boot
After=network.target

[Service]
Type=oneshot
ExecStart=$SETUP_SCRIPT
RemainAfterExit=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    echo "Systemd service file created at $SERVICE_FILE"
else
    echo "Systemd service file already exists, skipping creation."
fi

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable dreamos-setup.service
systemctl start dreamos-setup.service
# Check status
systemctl status dreamos-setup.service --no-pager

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "pull docker image: kuksa-client:0.4.2"
docker pull ghcr.io/eclipse/kuksa.val/kuksa-client:0.4.2

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Run dk_vrte"
docker kill dk_vrte
docker rm dk_vrte
docker pull $DOCKER_HUB_NAMESPACE/dk_vrte:latest
docker run  -d --name dk_vrte --network host --privileged --restart unless-stopped $LOG_LIMIT_PARAM -it $DOCKER_HUB_NAMESPACE/dk_vrte:latest

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
docker image prune -f
echo "dreamOS setup service installed successfully. Restart your machine !!!"