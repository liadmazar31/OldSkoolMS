#!/bin/bash
set -e

# Update system
yum update -y

# Install Docker
yum install -y docker

# Start and enable Docker service
systemctl start docker
systemctl enable docker

# Install Docker Compose (using stable version v2.24.5)
curl -L "https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Docker Buildx plugin (required for docker-compose build)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -L "https://github.com/docker/buildx/releases/latest/download/buildx-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m | sed 's/x86_64/amd64/')" -o /usr/local/lib/docker/cli-plugins/docker-buildx
chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

# Wait a moment for Docker to recognize the plugin
sleep 2

# Initialize buildx builder
docker buildx create --name builder --use 2>/dev/null || docker buildx use builder 2>/dev/null || true
docker buildx inspect --bootstrap || true

# Verify buildx is working
docker buildx version || true

# Install Git
yum install -y git

# Create directory for the application
mkdir -p /opt/cosmic
cd /opt/cosmic

# Clone the repository
git clone https://github.com/P0nk/Cosmic.git .

# Update config.yaml with the EC2 instance's public IP
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Backup original config
cp config.yaml config.yaml.backup

# Update HOST and LANHOST in config.yaml
sed -i "s/HOST: .*/HOST: $PUBLIC_IP/" config.yaml
sed -i "s/LANHOST: .*/LANHOST: $PUBLIC_IP/" config.yaml

# Remove obsolete version attribute from docker-compose.yml
sed -i '/^version:/d' docker-compose.yml

# Set database password if provided
if [ -n "${db_password}" ]; then
  sed -i "s/MYSQL_ROOT_PASSWORD: \"\"/MYSQL_ROOT_PASSWORD: \"${db_password}\"/" docker-compose.yml
  sed -i "s/MYSQL_ALLOW_EMPTY_PASSWORD: yes/MYSQL_ALLOW_EMPTY_PASSWORD: no/" docker-compose.yml
  sed -i "s/DB_PASS: \"\"/DB_PASS: \"${db_password}\"/" config.yaml
fi

# Create directory for MySQL data
mkdir -p ./database/docker-db-data

# Set proper permissions
chmod -R 755 /opt/cosmic

# Start Docker Compose services
# Try with buildkit first, fallback to legacy builder if it fails
set +e
COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose up -d --build
BUILDKIT_EXIT_CODE=$?
set -e

if [ $BUILDKIT_EXIT_CODE -ne 0 ]; then
  echo "Buildkit failed, trying with legacy builder..."
  set +e
  DOCKER_BUILDKIT=0 docker-compose up -d --build
  set -e
fi

# Create a systemd service to ensure Docker Compose starts on boot
cat > /etc/systemd/system/cosmic.service <<EOF
[Unit]
Description=Cosmic MapleStory Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/cosmic
Environment="COMPOSE_DOCKER_CLI_BUILD=1"
Environment="DOCKER_BUILDKIT=1"
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable cosmic.service

# Log completion
echo "Cosmic MapleStory server setup completed at $(date)" > /var/log/cosmic-setup.log
echo "Public IP: $PUBLIC_IP" >> /var/log/cosmic-setup.log
