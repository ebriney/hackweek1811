cat <<EOF >docker-profile
{
    "process": {
       "noNewPrivileges": false,
       "capabilities" : {
          "effective" : [
             "CAP_CHOWN",
             "CAP_DAC_OVERRIDE",
             "CAP_DAC_READ_SEARCH",
             "CAP_FOWNER",
             "CAP_FSETID",
             "CAP_KILL",
             "CAP_SETGID",
             "CAP_SETUID",
             "CAP_SETPCAP",
             "CAP_LINUX_IMMUTABLE",
             "CAP_NET_BIND_SERVICE",
             "CAP_NET_BROADCAST",
             "CAP_NET_ADMIN",
             "CAP_NET_RAW",
             "CAP_IPC_LOCK",
             "CAP_IPC_OWNER",
             "CAP_SYS_MODULE",
             "CAP_SYS_RAWIO",
             "CAP_SYS_CHROOT",
             "CAP_SYS_PTRACE",
             "CAP_SYS_PACCT",
             "CAP_SYS_ADMIN",
             "CAP_SYS_BOOT",
             "CAP_SYS_NICE",
             "CAP_SYS_RESOURCE",
             "CAP_SYS_TIME",
             "CAP_SYS_TTY_CONFIG",
             "CAP_MKNOD",
             "CAP_LEASE",
             "CAP_AUDIT_WRITE",
             "CAP_AUDIT_CONTROL",
             "CAP_SETFCAP",
             "CAP_MAC_OVERRIDE",
             "CAP_MAC_ADMIN",
             "CAP_SYSLOG",
             "CAP_WAKE_ALARM",
             "CAP_BLOCK_SUSPEND",
             "CAP_AUDIT_READ"
          ],
          "inheritable" : [
             "CAP_CHOWN",
             "CAP_DAC_OVERRIDE",
             "CAP_DAC_READ_SEARCH",
             "CAP_FOWNER",
             "CAP_FSETID",
             "CAP_KILL",
             "CAP_SETGID",
             "CAP_SETUID",
             "CAP_SETPCAP",
             "CAP_LINUX_IMMUTABLE",
             "CAP_NET_BIND_SERVICE",
             "CAP_NET_BROADCAST",
             "CAP_NET_ADMIN",
             "CAP_NET_RAW",
             "CAP_IPC_LOCK",
             "CAP_IPC_OWNER",
             "CAP_SYS_MODULE",
             "CAP_SYS_RAWIO",
             "CAP_SYS_CHROOT",
             "CAP_SYS_PTRACE",
             "CAP_SYS_PACCT",
             "CAP_SYS_ADMIN",
             "CAP_SYS_BOOT",
             "CAP_SYS_NICE",
             "CAP_SYS_RESOURCE",
             "CAP_SYS_TIME",
             "CAP_SYS_TTY_CONFIG",
             "CAP_MKNOD",
             "CAP_LEASE",
             "CAP_AUDIT_WRITE",
             "CAP_AUDIT_CONTROL",
             "CAP_SETFCAP",
             "CAP_MAC_OVERRIDE",
             "CAP_MAC_ADMIN",
             "CAP_SYSLOG",
             "CAP_WAKE_ALARM",
             "CAP_BLOCK_SUSPEND",
             "CAP_AUDIT_READ"
          ],
          "permitted" : [
             "CAP_CHOWN",
             "CAP_DAC_OVERRIDE",
             "CAP_DAC_READ_SEARCH",
             "CAP_FOWNER",
             "CAP_FSETID",
             "CAP_KILL",
             "CAP_SETGID",
             "CAP_SETUID",
             "CAP_SETPCAP",
             "CAP_LINUX_IMMUTABLE",
             "CAP_NET_BIND_SERVICE",
             "CAP_NET_BROADCAST",
             "CAP_NET_ADMIN",
             "CAP_NET_RAW",
             "CAP_IPC_LOCK",
             "CAP_IPC_OWNER",
             "CAP_SYS_MODULE",
             "CAP_SYS_RAWIO",
             "CAP_SYS_CHROOT",
             "CAP_SYS_PTRACE",
             "CAP_SYS_PACCT",
             "CAP_SYS_ADMIN",
             "CAP_SYS_BOOT",
             "CAP_SYS_NICE",
             "CAP_SYS_RESOURCE",
             "CAP_SYS_TIME",
             "CAP_SYS_TTY_CONFIG",
             "CAP_MKNOD",
             "CAP_LEASE",
             "CAP_AUDIT_WRITE",
             "CAP_AUDIT_CONTROL",
             "CAP_SETFCAP",
             "CAP_MAC_OVERRIDE",
             "CAP_MAC_ADMIN",
             "CAP_SYSLOG",
             "CAP_WAKE_ALARM",
             "CAP_BLOCK_SUSPEND",
             "CAP_AUDIT_READ"
          ],
          "bounding" : [
             "CAP_CHOWN",
             "CAP_DAC_OVERRIDE",
             "CAP_DAC_READ_SEARCH",
             "CAP_FOWNER",
             "CAP_FSETID",
             "CAP_KILL",
             "CAP_SETGID",
             "CAP_SETUID",
             "CAP_SETPCAP",
             "CAP_LINUX_IMMUTABLE",
             "CAP_NET_BIND_SERVICE",
             "CAP_NET_BROADCAST",
             "CAP_NET_ADMIN",
             "CAP_NET_RAW",
             "CAP_IPC_LOCK",
             "CAP_IPC_OWNER",
             "CAP_SYS_MODULE",
             "CAP_SYS_RAWIO",
             "CAP_SYS_CHROOT",
             "CAP_SYS_PTRACE",
             "CAP_SYS_PACCT",
             "CAP_SYS_ADMIN",
             "CAP_SYS_BOOT",
             "CAP_SYS_NICE",
             "CAP_SYS_RESOURCE",
             "CAP_SYS_TIME",
             "CAP_SYS_TTY_CONFIG",
             "CAP_MKNOD",
             "CAP_LEASE",
             "CAP_AUDIT_WRITE",
             "CAP_AUDIT_CONTROL",
             "CAP_SETFCAP",
             "CAP_MAC_OVERRIDE",
             "CAP_MAC_ADMIN",
             "CAP_SYSLOG",
             "CAP_WAKE_ALARM",
             "CAP_BLOCK_SUSPEND",
             "CAP_AUDIT_READ"
          ]
       }
    },
    "mounts" : [
       {
          "source" : "proc",
          "destination" : "/proc",
          "type" : "proc"
       },
       {
          "type" : "bind",
          "destination" : "/dev",
          "options" : [
             "rbind",
             "rw"
          ],
          "source" : "/dev"
       },
       {
          "source" : "sysfs",
          "options" : [
             "nosuid",
             "noexec",
             "nodev",
             "ro"
          ],
          "type" : "sysfs",
          "destination" : "/sys"
       },
       {
          "source" : "/tmp",
          "options" : [
             "rbind",
             "rw"
          ],
          "destination" : "/tmp",
          "type" : "bind"
       },
       {
          "options" : [
             "rbind",
             "rw"
          ],
          "source" : "/run",
          "destination" : "/run",
          "type" : "bind"
       },
       {
          "destination" : "/sys/fs/cgroup",
          "type" : "bind",
          "options" : [
             "rbind",
             "rw"
          ],
          "source" : "/sys/fs/cgroup"
       },
       {
          "destination" : "/lib/modules",
          "type" : "bind",
          "options" : [
             "rbind",
             "ro"
          ],
          "source" : "/lib/modules"
       },
       {
          "destination" : "/etc/resolv.conf",
          "type" : "bind",
          "source" : "/etc/resolv.conf",
          "options" : [
             "rbind",
             "ro"
          ]
       },
       {
          "options" : [
             "rbind",
             "ro"
          ],
          "source" : "/etc/hosts",
          "type" : "bind",
          "destination" : "/etc/hosts"
       },
       {
          "source" : "/etc/group",
          "options" : [
             "rbind",
             "ro"
          ],
          "type" : "bind",
          "destination" : "/etc/group"
       }
    ],
    "linux" : {
       "namespaces" : [
          {
             "type" : "mount"
          }
       ],
       "rootfsPropagation" : "rshared"
    }
 }
EOF

sudo mv -f docker-profile /etc/restartd/profiles/docker.json

cat <<EOF >dockerd-service
{
    "image": "docker.io/library/docker:18.09-dind",
    "profile": "docker",
    "process" : {
       "cwd" : "/",
       "args" : [
          "dockerd",
          "-s",
          "overlay2",
          "--containerd",
          "/run/containerd/containerd.sock",
          "--default-runtime",
          "containerd",
          "--add-runtime",
          "containerd=runc"
       ],
       "user" : {
          "gid" : 0,
          "uid" : 0
       },
       "env" : [
          "DOCKER_CHANNEL=edge",
          "DOCKER_VERSION=18.09.0",
          "DIND_COMMIT=3b5fac462d21ca164b3778647420016315289034"
       ]
    }
}
EOF

sudo restartd services add dockerd ./dockerd-service
sudo restartd services start dockerd
