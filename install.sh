TMPDIR=~/tmp-install
BINDIR="${TMPDIR}"/bin
SYSDDIR="${TMPDIR}"/systemd
INSTALLDIR=/usr/local/bin
# download dependencies
rm -rf "${TMPDIR}"
mkdir -p "${BINDIR}"
curl -fslL --retry 10 https://github.com/containerd/containerd/releases/download/v1.2.0/containerd-1.2.0.linux-amd64.tar.gz | tar xzf - -C "${TMPDIR}"
curl -fslL --retry 10 -o "${BINDIR}"/runc https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64
curl -fslL --retry 10 -o "${BINDIR}"/restartd https://download-stage.docker.com/win/restartd
curl -fslL --retry 10 -o "${BINDIR}"/docker https://download-stage.docker.com/win/docker-cli
chmod +x "${TMPDIR}"/bin/*

mkdir -p "${SYSDDIR}"
cat <<EOF >"${SYSDDIR}"/containerd.service
[Unit]
Description=Containerd Service
After=network.target

[Service]
ExecStart=/usr/local/bin/containerd

[Install]
WantedBy=multi-user.target
Alias=containerd.service
EOF

cat <<EOF >"${SYSDDIR}"/restartd.service
[Unit]
Description=Restartd Service
After=containerd.service

[Service]
ExecStart=/usr/local/bin/restartd

[Install]
WantedBy=multi-user.target
EOF

# install binaries
sudo cp -f "${TMPDIR}"/bin/* /usr/local/bin

#install services
sudo cp "${SYSDDIR}"/* /lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl start containerd.service
sudo systemctl start restartd.service
sudo systemctl enable containerd.service
sudo systemctl enable restartd.service
