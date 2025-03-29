#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${2}${1}${NC}"
}

# Create necessary directories
print_message "Creating directory structure..." "$BLUE"
mkdir -p ./config/packetbeat

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    print_message "Docker is not installed. Installing Docker..." "$YELLOW"
    curl -sSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    print_message "You may need to log out and back in for group changes to take effect." "$YELLOW"
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_message "docker-compose is not installed. Please install it first." "$RED"
    print_message "For Ubuntu: sudo apt install docker-compose" "$YELLOW"
    print_message "For Raspberry Pi: sudo apt install docker-compose-plugin" "$YELLOW"
    exit 1
fi

# Detect architecture and choose appropriate compose file
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    print_message "Detected x86_64 architecture (standard PC/server)" "$GREEN"
    cp docker-compose.yml docker-compose.yml.bak
    cp docker-compose-x86.yml docker-compose.yml
    print_message "Using standard x86_64 Docker images" "$BLUE"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    print_message "Detected ARM64 architecture (Raspberry Pi)" "$GREEN"
    cp docker-compose.yml docker-compose.yml.bak
    cp docker-compose-arm.yml docker-compose.yml
    print_message "Using ARM64 Docker images" "$BLUE"
else
    print_message "Unsupported architecture: $ARCH" "$RED"
    print_message "This script supports x86_64 and arm64/aarch64 only." "$RED"
    exit 1
fi

# Check if environment variables are set
if [ ! -f .env ]; then
    print_message "No .env file found, creating default .env file..." "$BLUE"
    cp env-sample.env .env
    print_message "Default .env file created. Review and modify if needed." "$YELLOW"
fi

# Copy the packetbeat config
mkdir -p config/packetbeat
if [ ! -f config/packetbeat/packetbeat.yml ]; then
    cp packetbeat-config.yml config/packetbeat/packetbeat.yml
fi

# Start the stack
print_message "Starting Elastic Stack..." "$BLUE"
docker-compose down -v
docker-compose up -d

print_message "Waiting for setup to complete (this may take a few minutes)..." "$YELLOW"
for i in {1..30}; do
    if docker-compose ps | grep -q "setup.*Exit 0"; then
        print_message "Setup completed successfully!" "$GREEN"
        break
    fi
    if docker-compose ps | grep -q "setup.*Exit [1-9]"; then
        print_message "Setup failed. Checking logs:" "$RED"
        docker-compose logs setup
        exit 1
    fi
    echo -n "."
    sleep 10
    if [ $i -eq 30 ]; then
        print_message "\nSetup is taking longer than expected. Check the logs with: docker-compose logs setup" "$YELLOW"
    fi
done

# Wait for Elasticsearch to be ready
print_message "Waiting for Elasticsearch to be ready..." "$YELLOW"
for i in {1..30}; do
    if docker-compose ps | grep -q "es01.*healthy"; then
        print_message "Elasticsearch is running!" "$GREEN"
        break
    fi
    echo -n "."
    sleep 10
    if [ $i -eq 30 ]; then
        print_message "\nElasticsearch is taking longer than expected. Check the logs with: docker-compose logs es01" "$YELLOW"
    fi
done

# Set kibana_system password
print_message "Setting kibana_system password..." "$BLUE"
docker-compose exec -T es01 bash -c "bin/elasticsearch-reset-password -u kibana_system -b -p ${KIBANA_PASSWORD:-changeme}"

# Print access information
print_message "\nElastic Stack setup complete!" "$GREEN"
print_message "Kibana: https://$(hostname -I | awk '{print $1}'):5601" "$YELLOW"
print_message "Elasticsearch: https://$(hostname -I | awk '{print $1}'):9200" "$YELLOW"
print_message "Username: elastic" "$YELLOW"
print_message "Password: ${ELASTIC_PASSWORD:-changeme}" "$YELLOW"
print_message "\nTo check the status of your containers, run: docker-compose ps" "$BLUE"
print_message "To view logs, run: docker-compose logs -f" "$BLUE"
print_message "\nNote: You'll need to accept the self-signed certificate in your browser when accessing Kibana." "$YELLOW"