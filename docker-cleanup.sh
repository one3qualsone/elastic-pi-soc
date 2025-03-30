#!/bin/bash
# Complete Docker cleanup script
# Warning: This will remove ALL Docker containers, images, volumes, and networks

echo "Stopping all running containers..."
docker stop $(docker ps -a -q) 2>/dev/null || true

echo "Removing all containers..."
docker rm $(docker ps -a -q) 2>/dev/null || true

echo "Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

echo "Removing all networks except default ones..."
docker network rm $(docker network ls | grep -v "bridge\|host\|none" | awk '{print $1}') 2>/dev/null || true

echo "Removing all images..."
docker rmi $(docker images -a -q) 2>/dev/null || true

echo "Pruning system to remove any leftovers..."
docker system prune -a -f --volumes

echo "Docker environment has been completely cleaned."