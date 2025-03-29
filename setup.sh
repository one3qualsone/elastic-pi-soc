#!/bin/bash

# Elastic Stack on Raspberry Pi Setup Script

# Create necessary directories
echo "Creating directory structure..."
mkdir -p ./config/certs/ca
mkdir -p ./config/certs/es01
mkdir -p ./config/certs/es02
mkdir -p ./config/certs/kibana
mkdir -p ./config/packetbeat

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    curl -sSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "You may need to log out and back in for group changes to take effect."
    exit 1
fi

# Ensure user is in docker group
if ! groups | grep -q docker; then
    echo "Your user is not in the docker group. Try restarting your session or run:"
    echo "  sudo usermod -aG docker $USER"
    echo "  newgrp docker"
    exit 1
fi

# First run setup container only to generate certificates
echo "Generating certificates..."
docker-compose up setup

# Check if certificates were generated
if [ ! -f ./config/certs/es01/es01.crt ]; then
    echo "Certificate generation failed. Please check the output for errors."
    exit 1
fi

echo "Certificates generated successfully."

# Start the entire stack
echo "Starting Elastic Stack..."
docker-compose up -d

# Give Elasticsearch time to start
echo "Waiting for Elasticsearch to start (this may take a few minutes)..."
for i in {1..30}; do
    if docker ps | grep -q es01; then
        # Check if Elasticsearch is responding
        if docker exec es01 curl -s --cacert /usr/share/elasticsearch/config/ca/ca.crt https://localhost:9200 -u elastic:changeme > /dev/null; then
            echo "Elasticsearch is running!"
            break
        fi
    fi
    echo -n "."
    sleep 10
    if [ $i -eq 30 ]; then
        echo "Elasticsearch did not start in time. Check the logs with: docker-compose logs es01"
    fi
done

# Set elastic password
echo -e "\nSetting up elastic user password..."
docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic -i

# Set kibana_system password
echo "Setting kibana_system password to 'changeme'..."
docker exec es01 /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system -a -b -p changeme

echo -e "\nSetup complete! Access information:"
echo "Kibana: https://$(hostname -I | awk '{print $1}'):5601"
echo "Elasticsearch: https://$(hostname -I | awk '{print $1}'):9200"
echo "Username: elastic"
echo "Password: (the one you just set)"
echo -e "\nTo check the status of your containers, run: docker-compose ps"
echo "To view logs, run: docker-compose logs -f"
