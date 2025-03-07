#!/bin/bash

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Start dreamOS installation !!!!!!!!!!!!!"
echo "------------------------------------------------------------------------------------------------------------------------------------"

set -e

# Define file paths
SETUP_SCRIPT="/usr/local/bin/dreamos_setup.sh"
SERVICE_FILE="/etc/systemd/system/dreamos-setup.service"

echo "Creating dreamOS setup script..."

# Create the dreamOS setup script
cat << 'EOF' > $SETUP_SCRIPT
#!/bin/bash
set -e

# Configure CAN0
ip link set can0 type can bitrate 500000 sample-point 0.75 dbitrate 2000000 fd on
ip link set can0 up
ifconfig can0 txqueuelen 65536

# Configure CAN1
ip link set can1 type can bitrate 500000
ip link set can1 up
ifconfig can1 txqueuelen 65536
EOF

# Make the script executable
chmod +x $SETUP_SCRIPT
echo "dreamOS setup script created at $SETUP_SCRIPT"

echo "Creating systemd service file..."

# Create the systemd service file
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

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable dreamos-setup.service
systemctl start dreamos-setup.service

echo "dreamOS setup service installed and started successfully!"

# Check status
systemctl status dreamos-setup.service --no-pager
