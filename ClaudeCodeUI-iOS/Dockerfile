# Claude Code UI iOS - Cross-Platform Build Docker Image
FROM swift:5.9-jammy

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    libssl-dev \
    libcurl4-openssl-dev \
    uuid-runtime \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Xcode simulator tools (for Linux)
RUN curl -L https://github.com/swift-server/swift-xcode-build-tools/releases/latest/download/swift-xcode-build-tools.tar.gz | tar xz -C /usr/local/bin

# Set working directory
WORKDIR /app

# Copy project files
COPY . .

# Build the project
RUN swift build -c debug

# Run tests
CMD ["swift", "test"]