# Elastic Pi Security SOC

This project sets up a home security monitoring system using the Elastic Stack (Elasticsearch, Kibana, and Beats) on either a Raspberry Pi or standard x86 Ubuntu server.

## Files Included

1. `docker-compose-x86.yml` - Docker Compose configuration for x86_64 (Ubuntu) systems
2. `docker-compose-arm.yml` - Docker Compose configuration for ARM64 (Raspberry Pi) systems
3. `env-sample.env` - Sample environment variables file
4. `setup.sh` - Setup script that detects your architecture and sets up the system
5. `config/packetbeat/packetbeat.yml` - Configuration for network packet monitoring

## Quick Start

1. Clone this repository
2. Run the setup script:
   ```
   chmod +x setup.sh
   ./setup.sh
   ```
3. Access Kibana at `https://your-ip:5601`
   - Username: `elastic`
   - Password: `changeme` (or the password you set in .env)

## Requirements

- Docker and Docker Compose
- Raspberry Pi with at least 4GB RAM (8GB recommended) or Ubuntu server
- At least 32GB free disk space (64GB+ recommended)

## Configuration

You can modify the `.env` file to change:
- Stack version
- Memory limits
- Passwords
- Port mappings
- License type

## Architecture

This setup includes:
- Elasticsearch - The search and analytics engine
- Kibana - The visualization dashboard
- Packetbeat - Network packet analyzer for security monitoring

All communications are secured with SSL/TLS using self-signed certificates.

## Troubleshooting

If you encounter issues:
1. Check the logs: `docker-compose logs`
2. Verify memory settings in .env
3. Ensure Docker has adequate permissions
4. Check your firewall settings

## Development vs. Production

The x86 configuration is ideal for development, while the ARM configuration is optimized for running on a Raspberry Pi in production.

## License

This project uses the Elastic Stack which is licensed under the Elastic License for the commercial features.