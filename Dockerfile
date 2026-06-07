FROM ubuntu:22.04 

ARG PYTHON=python3.10

ENV PYTHON="$PYTHON" \ 
    TERM=xterm-256color \ 
    TZ=Europe/London \ 
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \ 
    LANGUAGE=en_US:en 

# Development Tools 
RUN apt-get update && \
    apt-get install -y \
        cmake \
        git \
        ninja-build \
        gdb \
        ${PYTHON} \
        ${PYTHON}-dev \
        ${PYTHON}-venv \
        python3-pip \
        tmux \
        zsh \
        tree \
        sed \
        screen \
        ripgrep && \
    rm -rf /var/lib/apt/lists/*

# Nodejs
# Install NVM dependencies
RUN apt-get update && apt-get install -y curl git build-essential

# Install NVM and Node.js 24
ENV NVM_DIR=/root/.nvm
RUN apt-get remove -y nodejs libnode-dev \
    && apt-get autoremove -y \
    && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs

# Make Node available in PATH
ENV PATH=$NVM_DIR/versions/node/v24.0.0/bin:$PATH


# LLVM tools
RUN apt-get update && \
    apt-get install -y wget software-properties-common gnupg && \
    wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 20
RUN apt-get install -y clang-20 clangd-20 clang-format-20 lldb-20 lld-20

# oh-my-zsh
RUN sh -c "$(wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone --depth=1 --single-branch https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions 

ENV SHELL=/usr/bin/zsh

# Python 
RUN python3 -m pip install pytest ruff uv pyright

# Setup gihub keys 
# When you rebuild the image, add contents of github.pub to a github key 
RUN rm -rf /root/.ssh/github 
RUN rm -rf /root/.ssh/github.pub 
RUN ssh-keygen -t rsa -C "Yussef Soudan yussefsoudan@gmail.com" -f ~/.ssh/github -P ""
RUN touch /root/.ssh/config 
RUN echo "Host github github.com" >> /root/.ssh/config 
RUN echo "Hostname github.com" >> /root/.ssh/config 
RUN echo "User git" >> /root/.ssh/config 
RUN echo "UserKnownHostsFile /dev/null" >> /root/.ssh/config 
RUN echo "StrictHostKeyChecking no" >> /root/.ssh/config 
RUN chmod 600 /root/.ssh/config

# Neovim 
## Setup latest neovim 
RUN git clone --depth 1 https://github.com/neovim/neovim /root/neovim
RUN cd /root/neovim && make CMAKE_BUILD_TYPE=Release
RUN cd /root/neovim && make install

COPY ./homefiles/ /root/homefiles/
RUN cp -a /root/homefiles/. .

RUN echo "Install all neovim plugins"
RUN rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
RUN nvim --headless "+Lazy! sync" +qa
RUN nvim --headless ":MasonUpdate" +qa
RUN nvim +"InstallPlugins" +qa

# Allow clangd to be accessible to neovim 
RUN cp -a /usr/lib/llvm-20/bin/. /usr/bin/


CMD ["/usr/bin/zsh"]
