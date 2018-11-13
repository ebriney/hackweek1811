
TMPDIR=~/tmp-install
INSTALLDIR=/usr/local/bin
# download dependencies
rm -rf "${TMPDIR}"
mkdir "${TMPDIR}"
curl -fslL --retry 10 https://github.com/containerd/containerd/releases/download/v1.2.0/containerd-1.2.0.linux-amd64.tar.gz | tar xzf - -C "${TMPDIR}"
curl -fslL --retry 10 -o "${TMPDIR}"/bin/runc https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64
curl -fslL --retry 10 -o "${TMPDIR}"/bin/restartd https://download-stage.docker.com/win/restartd
curl -fslL --retry 10 -o "${TMPDIR}"/bin/docker https://download-stage.docker.com/win/docker-cli
chmod +x "${TMPDIR}"/bin/*

# install dependencies
sudo cp -f "${TMPDIR}"/bin/* /usr/local/bin

#install services
sudo cp systemd/* /lib/systemd/system
sudo systemctl daemon-reload
