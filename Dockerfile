
# Stage 1: Build Neovim
FROM ubuntu:22.04 as neovim-build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y automake cmake curl g++ gettext git libtool-bin make pkg-config unzip

RUN git clone -b master --single-branch --depth 1 https://github.com/neovim/neovim.git

WORKDIR neovim

RUN make CMAKE_BUILD_TYPE=RelWithDebInfo && \
    make install

# Stage 2: Final image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/flutter
ENV PUB_HOSTED_URL=https://pub.flutter-io.cn
ENV FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

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

# Copy the installed Neovim from the build stage
COPY --from=neovim-build /usr/local/bin/nvim /usr/local/bin/nvim
COPY --from=neovim-build /usr/local/share/nvim /usr/local/share/nvim

# Copy LazyVim config from local machine
COPY --chown=flutter:flutter lazyvim-config /home/flutter/.config/nvim

# Append settings to options.lua
RUN mkdir -p /home/flutter/.config/nvim/lua/config && \
    echo 'local opt = vim.opt\nopt.clipboard = "unnamedplus"\n\nvim.g.clipboard = {\n\tname = "OSC 52",\n\tcopy = {\n\t\t["+"] = require("vim.ui.clipboard.osc52").copy("+"),\n\t\t["*"] = require("vim.ui.clipboard.osc52").copy("*"),\n\t},\n\tpaste = {\n\t\t["+"] = require("vim.ui.clipboard.osc52").paste("+"),\n\t\t["*"] = require("vim.ui.clipboard.osc52").paste("*"),\n\t},\n}' >> /home/flutter/.config/nvim/lua/config/options.lua

# Pre-install plugins and initialize Neovim
RUN nvim --headless "+Lazy! sync" +qa

# Set up a directory for Flutter projects
WORKDIR /home/flutter/projects

CMD ["/bin/bash"]
