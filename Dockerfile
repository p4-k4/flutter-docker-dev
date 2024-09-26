# Stage 1: Build Neovim
FROM ubuntu:22.04 as neovim-build

ARG BRANCH=master
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y automake cmake curl g++ gettext git libtool-bin make pkg-config unzip && \
    git clone -b ${BRANCH} --single-branch --depth 1 https://github.com/neovim/neovim.git

WORKDIR neovim

RUN make CMAKE_BUILD_TYPE=RelWithDebInfo && \
    make install

# Stage 2: Final image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# Copy Neovim from build stage
COPY --from=neovim-build /usr/local /usr/local

# Update and install essential packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    curl \
    git \
    wget \
    unzip \
    python3 \
    software-properties-common \
    build-essential \
    gcc \
    clang \
    xclip \
    ripgrep \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Zig
RUN curl -sSL https://ziglang.org/download/0.10.1/zig-linux-x86_64-0.10.1.tar.xz | tar -xJ --strip-components=1 -C /usr/local

# Create a non-root user
RUN useradd -ms /bin/bash flutter
USER flutter
WORKDIR /home/flutter

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /home/flutter/flutter

# Set flutter path
ENV PATH="/home/flutter/flutter/bin:/home/flutter/.pub-cache/bin:/usr/local/bin:${PATH}"

# Run flutter doctor
RUN flutter doctor

# Enable flutter web
RUN flutter channel master && \
    flutter upgrade && \
    flutter config --enable-web

# Install and initialize LazyVim
RUN git clone https://github.com/LazyVim/starter /home/flutter/.config/nvim
COPY config/nvim/lua/config/options.lua /home/flutter/.config/nvim/lua/config/options.lua

# Pre-install plugins and initialize LazyVim
RUN nvim --headless "+Lazy! sync" +qa

# Set up a directory for Flutter projects
WORKDIR /home/flutter/projects

CMD ["/bin/bash"]
