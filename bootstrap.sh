#!/bin/bash

set -euo pipefail

cache_dir=.cache

if [[ $* == *--no-cache* ]]; then
  rm -rf $cache_dir
fi

if [[ ! -d $cache_dir ]]; then
  mkdir $cache_dir
fi

cache_func_call() {
  eval "
    _inner_$(typeset -f "$1")
    $1"'() {
      local func_cache_file="$cache_dir/'"$1"'"
      if [[ -f $func_cache_file ]]; then
        echo >&2 "Ran previously, skipping..."
        return 0
      else
        _inner_'"$1"' "$@"
	inner_return_code=$?
        touch $func_cache_file
        return $inner_return_code # Added for completeness, but negated by set -e
      fi
    }'
}

update_apt() {
  sudo apt update
} && cache_func_call update_apt

install_git() {
  sudo apt install -y curl git
} && cache_func_call install_git

configure_git() {
  read -p "Enter name for git global config and press [ENTER]: " git_config_name
  read -p "Enter email for git global config and press [ENTER]: " git_config_email
  git config --global user.name "$git_config_name"
  git config --global user.email "$git_config_email"
  
  # From https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
  echo ""
  echo "Generating SSH keypair"
  private_key_filename="ed25519"
  private_key_path="$HOME/.ssh/$private_key_filename"
  ssh-keygen -t ed25519 -f $private_key_path -C "$git_config_email" || echo "ssh-keygen exited with code $?"
  echo "IdentityFile ~/.ssh/$private_key_filename" >> $HOME/.ssh/config
  chmod 600 $HOME/.ssh/config

  echo ""
  echo "Public key contents:"
  cat "$private_key_path.pub"

  echo ""
  read -p "Add public key to Github, then press any button to test SSH connection" -n 1

  # Will return with exit code 1 when successfully authenticated
  while ssh -T git@github.com; [[ $? -ne 1 ]]; do
    echo ""
    echo "Connection failed, would you like to try again?"

    select yn in "Yes" "No"; do
      case $yn in
        Yes ) echo "Attempting connection..."; break;;
        No ) break;;
      esac
    done

    if [[ $yn = "No" ]]; then
      break
    fi
  done

  echo ""
  echo "SSH connection to Github was successful"
} && cache_func_call configure_git

install_docker() {
  # From https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
  sudo apt install -y \
    ca-certificates \
    gnupg \
    lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
  echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.gpg # Added in case default umask doesn't provide read permissions
  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

  echo ""
  echo "Verifying docker installation"
  sudo service docker start
  sudo docker run hello-world

  sudo systemctl enable docker.service
  sudo systemctl enable containerd.service

  # From https://docs.docker.com/engine/install/linux-postinstall/
  sudo getent group docker || sudo groupadd docker
  sudo usermod -aG docker $(whoami)
  # allow nonroot access to docker and suppress errors about .docker directory not existing
  docker_dotdir=/home/"$(whoami)"/.docker
  sudo chown -R "$(whoami)":"$(whoami)" $docker_dotdir || echo "$docker_dotdir does not exist"
  sudo chmod -R g+rwx $docker_dotdir || echo "$docker_dotdir does not exist"
} && cache_func_call install_docker

install_neovim() {
  workdir=$(pwd)
  cd /tmp
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  sudo chmod u+x nvim.appimage
  sudo ./nvim.appimage --appimage-extract > /dev/null
  sudo mv squashfs-root /
  sudo ln -s /squashfs-root/AppRun /usr/bin/nvim
  rm -f nvim.appimage
  cd $workdir
} && cache_func_call install_neovim

install_zsh() {
  sudo apt install -y zsh
  zsh --version
  sudo chsh -s $(which zsh) $(whoami)
} && cache_func_call install_zsh

install_ohmyzsh() {
  # Force ohmyzsh to not switch shells during script execution
  yes no | sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || ohmyzsh_ret=$?
  if [[ $ohmyzsh_ret -ne 141 ]]; then
    exit $ohmyzsh_ret
  fi
} && cache_func_call install_ohmyzsh

configure_ohmyzsh() {
  cp .zshrc $HOME/.zshrc
} && cache_func_call configure_ohmyzsh

install_asdf() {
  # git clone https://github.com/asdf-vm/asdf.git ~/.asdf
  echo ". $HOME/.asdf/asdf.sh" | tee -a $HOME/.bashrc 1>/dev/null
  source ~/.bashrc
} && cache_func_call install_asdf

install_asdf_python() {
  asdf plugin-add python || echo ""
  sudo apt install -y make build-essential libssl-dev zlib1g-dev \
                            libbz2-dev libreadline-dev libsqlite3-dev llvm \
                            libncursesw5-dev xz-utils tk-dev libxml2-dev \
                            libxmlsec1-dev libffi-dev liblzma-dev
  read -p "Enter python version and press [ENTER]: " asdf_python_version
  asdf install python $asdf_python_version
  asdf global python $asdf_python_version
} && cache_func_call install_asdf_python

install_asdf_nodejs() {
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git || echo ""
  read -p "Enter Node.js version and press [ENTER]: " asdf_nodejs_version
  asdf install nodejs $asdf_nodejs_version
  asdf global nodejs $asdf_nodejs_version
} && cache_func_call install_asdf_nodejs

install_asdf_rust() {
  asdf plugin-add rust https://github.com/asdf-community/asdf-rust.git || echo ""
  read -p "Enter Rust version and press [ENTER]: " asdf_rust_version
  asdf install rust $asdf_rust_version
  asdf global rust $asdf_rust_version
} && cache_func_call install_asdf_rust

install_thefuck_alias() {
  pip install thefuck --user
} && cache_func_call install_thefuck_alias

install_kde_plasma() {
  sudo apt install -y kde-plasma-desktop
} && cache_func_call install_kde_plasma

install_vscode() {
  pushd /tmp
  curl -Lo vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  sudo dpkg -i vscode.deb
  rm -rf vscode.deb
  popd
} && cache_func_call install_vscode

install_neofetch() {
  sudo apt install -y neofetch
  [ -z "$(cat $HOME/.zshrc | grep 'neofetch' 2>&1)" ] && echo "neofetch" >> $HOME/.zshrc
} && cache_func_call install_neofetch

echo ""
echo "Lift yourself up by your bootstraps."

echo ""
echo "Updating apt."
update_apt

echo ""
echo "Installing git."
install_git

echo ""
echo "Configuring git."
configure_git

echo ""
echo "Installing docker."
install_docker

echo ""
echo "Installing neovim."
install_neovim

echo ""
echo "Installing zsh and setting as default shell (requires logout)."
install_zsh

echo ""
echo "Installing OhMyZsh."
install_ohmyzsh

echo ""
echo "Configuring OhMyZsh."
configure_ohmyzsh

echo ""
echo "Installing asdf package manager."
install_asdf

echo ""
echo "Installing python via asdf."
install_asdf_python

echo ""
echo "Installing Node.js via asdf."
install_asdf_nodejs

echo ""
echo "Installing Rust via asdf."
install_asdf_rust

echo ""
echo "Installing thefuck alias."
install_thefuck_alias

echo ""
echo "Installing KDE Plasma."
install_kde_plasma

echo ""
echo "Installing VS Code"
install_vscode

echo ""
echo "Installing neofetch"
install_neofetch

# TODO: install lunarvim

echo ""
echo "Done bootstrapping. Please reboot."
