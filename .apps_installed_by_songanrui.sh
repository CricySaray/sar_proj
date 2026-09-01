# update and upgrade apt library
sudo apt update
# sudo apt upgrade

# install ripgrep
sudo apt install ripgrep

# install rust toolchain: rustc & cargo & std
sudo apt install rustup
rustup update
rustup default stable

# install du-dust
cargo install du-dust

# install duf
sudo apt install duf

# install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# install zellij (similiar with tmux)
# plz add cargo bin dir to PATH
cargo install --locked zellij

# install zoxied (using cmd: z) (similiar with autojump)
cargo install zoxide --locked

# install eza (similiar with ls)
cargo install eza

# install mcfly(advanced ctrl + R to search) note: not good to use
# cargo install mcfly --locked

# install sd(similiar with sed, but faster)
cargo install sd
