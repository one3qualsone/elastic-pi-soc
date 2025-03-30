#!/bin/bash
# Optimize Raspberry Pi for Elasticsearch

echo "Applying Elasticsearch optimizations for Raspberry Pi..."

# Enable memory mapping
echo "Setting vm.max_map_count..."
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.d/99-elasticsearch.conf

# Enable cgroup memory limit capabilities
echo "Enabling cgroup memory..."
if ! grep -q "cgroup_enable=memory" /boot/cmdline.txt; then
  sudo cp /boot/cmdline.txt /boot/cmdline.txt.bak
  CMDLINE=$(cat /boot/cmdline.txt)
  echo "${CMDLINE} cgroup_enable=memory cgroup_memory=1" | sudo tee /boot/cmdline.txt
  echo "Added cgroup memory parameters to /boot/cmdline.txt"
  echo "You'll need to reboot your Raspberry Pi for these changes to take effect."
  echo "After rebooting, run this script again."
fi

# Check system memory
echo "Current memory usage:"
free -h

# Check available disk space
echo "Available disk space:"
df -h /

# Create necessary directories
mkdir -p filebeat_ingest_data logstash_ingest_data

echo "Optimization complete. If you added cgroup parameters, please reboot your Pi."
echo "After reboot, run 'docker-compose -f docker-compose-minimal.yml up -d' to start Elasticsearch and Kibana."