#!/bin/bash

set -euo pipefail

make_tmp_dir() {
  mktemp -d -t sys-bootstrap.XXXXXX
}

existing_cache_dir=( /tmp/sys-bootstrap.* )

if [[ $* == *--reset-cache* ]]; then
  rm -rf $existing_cache_dir
fi

if [[ -d $existing_cache_dir ]]; then
  cache_dir=$existing_cache_dir
else
  cache_dir=$(make_tmp_dir)
fi

echo "DEBUG: temp folder location: $cache_dir"

cache_func_call() {
  eval "
    _inner_$(typeset -f "$1")
    $1"'() {
      local func_tmp_file="$cache_dir/'"$1"'"
      if [[ -f $func_tmp_file ]]; then
        echo >&2 "Ran previously, skipping..."
        return 0
      else
        _inner_'"$1"' "$@"
        touch $func_tmp_file
        return $? # Added for completeness, but negated by set -e
      fi
    }'
}

update_apt() {
  sudo apt update
} && cache_func_call update_apt

install_git() {
  sudo apt install curl git
} && cache_func_call install_git

configure_git() {
  read -p "Enter name for git global config and press [ENTER]: " git_config_name
  read -p "Enter email for git global config and press [ENTER]: " git_config_email
  git config --global user.name "$git_config_name"
  git config --global user.email "$git_config_email"
  
  # From: https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
  echo "Generating SSH keypair"
  private_key_filename="$HOME/.ssh/ed25519"
  ssh-keygen -t ed25519 -f $private_key_filename -C "$git_config_email" || echo "ssh-keygen exited with code $?"
  eval "$(ssh-agent -s)"
  # ssh-add $private_key_filename

  echo ""
  echo "Public key contents:"
  cat "$private_key_filename.pub"

  echo ""
  read -p "Add public key to Github, then press any button to continue" -n 1
} && cache_func_call configure_git

install_neovim() {
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage
  ./nvim.appimage --appimage-extract > /dev/null 2>&1
  cp ./squashfs-root/AppRun /usr/bin/nvim
} && cache_func_call install_neovim

install_thefuck_alias() {
  sudo apt install python3-dev python3-pip python3-setuptools
  pip3 install thefuck --user
} && cache_func_call install_thefuck_alias

install_zsh() {
  sudo apt install zsh
  zsh --version
  chsh -s $(which zsh)
} && cache_func_call install_zsh

install_ohmyzsh() {
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
} && cache_func_call install_ohmyzsh

configure_ohmyzsh() {
  cp .zshrc $HOME/.zshrc
} && cache_func_call configure_ohmyzsh

install_asdf() {
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2
} && cache_func_call install_asdf

install_asdf_python() {
  asdf plugin-add python
  sudo apt-get install make build-essential libssl-dev zlib1g-dev \
                            libbz2-dev libreadline-dev libsqlite3-dev llvm \
                            libncursesw5-dev xz-utils tk-dev libxml2-dev \
                            libxmlsec1-dev libffi-dev liblzma-dev\
  read -p "Enter python version and press [ENTER]: " asdf_python_version
  asdf install python $asdf_python_version
  asdf global python $asdf_python_version
} && cache_func_call install_asdf_python

install_asdf_nodejs() {
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  read -p "Enter Node.js version and press [ENTER]: " asdf_nodejs_version
  asdf install nodejs $asdf_nodejs_version
  asdf global nodejs $asdf_nodejs_version
} && cache_func_call install_asdf_nodejs

install_asdf_rust() {
  plugin-add rust https://github.com/asdf-community/asdf-rust.git
  read -p "Enter Rust version and press [ENTER]: " asdf_rust_version
  asdf install rust $asdf_rust_version
  asdf global rust $asdf_rust_version
} && cache_func_call install_asdf_rust

install_kde_plasma() {
  sudo apt install kde-plasma-desktop
} && cache_func_call install_kde_plasma

echo ""
echo "Lift yourself up by your bootstraps"

echo ""
echo "Updating apt"
update_apt

echo ""
echo "Installing git"
install_git

echo ""
echo "Configuring git"
configure_git

echo ""
echo "Installing neovim"
install_neovim

echo ""
echo "Installing thefuck alias"
install_thefuck_alias

echo ""
echo "Installing zsh and setting as default shell (requires logout)"
install_zsh

echo ""
echo "Installing OhMyZsh"
install_ohmyzsh

echo ""
echo "Configuring OhMyZsh"
configure_ohmyzsh

echo ""
echo "Installing asdf package manager"
install_asdf

echo ""
echo "Installing python via asdf"
install_asdf_python

echo ""
echo "Installing Node.js via asdf"
install_asdf_nodejs

echo ""
echo "Installing Rust via asdf"
install_asdf_rust

echo ""
echo "Installing KDE Plasma"
install_kde_plasma

# TODO: install lunarvim
# TODO: prompt for reboot y/n

echo ""
echo "Done"
