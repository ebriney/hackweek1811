
TMPDIR=~/tmp-install
INSTALLDIR=/usr/local/bin
# download dependencies
rm -rf "${TMPDIR}"
mkdir "${TMPDIR}"
curl -fslL --retry 10 https://github.com/containerd/containerd/releases/download/v1.2.0/containerd-1.2.0.linux-amd64.tar.gz | tar xzf - -C "${TMPDIR}"
chmod +x "${TMPDIR}"/bin/*

curl -fslL --retry 10 -o "${TMPDIR}"/runc https://github.com/opencontainers/runc/releases/download/v1.0.0-rc5/runc.amd64
chmod +x "${TMPDIR}"/runc

sudo cp "${TMPDIR}"/runc "${INSTALLDIR}"
sudo cp "${TMPDIR}"/bin/* /usr/local/bin
