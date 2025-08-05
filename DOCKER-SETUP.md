# Docker-Based iOS Development Setup

## Overview
This project uses Docker with dockurr/macos to enable iOS development on Linux systems. The macOS environment runs inside a Docker container with Xcode installed.

## Prerequisites
- Linux system with KVM support
- Docker and Docker Compose installed
- At least 16GB RAM (8GB allocated to container)
- 128GB+ free disk space

## Quick Start

### 1. Start the macOS Container
```bash
docker-compose up -d
```

### 2. Access macOS Environment
Open your web browser and navigate to:
```
http://localhost:8006
```

This will show you the macOS desktop through a web-based VNC viewer.

### 3. Initial macOS Setup (First Time Only)
1. Complete macOS installation wizard in the web interface
2. Open App Store and install Xcode (this will take 30-60 minutes)
3. Launch Xcode and accept license agreements
4. Install iOS 17+ simulators through Xcode preferences

### 4. Build the iOS App
```bash
./docker-build.sh
```

### 5. Run the iOS App
```bash
./docker-run.sh
```

## Helper Scripts

- `docker-build.sh` - Builds the iOS app in the Docker container
- `docker-run.sh` - Runs the app in the iPhone 16 Pro Max simulator
- `docker-compose.yml` - Container configuration

## Viewing the Simulator
The iOS simulator will be visible in the web interface at http://localhost:8006

## Troubleshooting

### Container won't start
- Check KVM is available: `ls -la /dev/kvm`
- Ensure you're in the kvm group: `groups`
- Verify Docker is running: `systemctl status docker`

### Build fails
- Ensure Xcode is installed in the container
- Check that iOS 17 SDK is installed
- Verify project files are properly mounted

### Performance issues
- Allocate more CPU cores in docker-compose.yml
- Increase RAM allocation if available
- Use a faster disk (SSD recommended)

## Development Workflow

1. **Edit code** on your Linux host using your preferred editor
2. **Build** using `./docker-build.sh`
3. **View** results in web browser at http://localhost:8006
4. **Test** functionality in the simulator
5. **Commit** only after successful build and test

## Important Notes

- The container needs to download and install macOS on first run (requires internet)
- Xcode installation is manual and takes significant time
- All builds must be done through Docker, not directly on Linux
- Use the web interface to interact with macOS and the iOS simulator

## Task Tracking

See `ios-development-tasks.md` for the complete list of 500+ development tasks that must be completed using this Docker workflow.