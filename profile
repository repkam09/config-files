# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Bitwarden CLI variables
export BW_CLIENTID="EXAMPLE"
export BW_CLIENTSECRET="EXAMPLE"
export BW_SESSION="EXAMPLE"

# Added by Docker install script to user as non-root user
export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/1000/docker.sock

# To enable slightly better high dpi support in GTK and QT apps
export GDK_DPI_SCALE=1.5
export QT_SCALE_FACTOR=1.5

