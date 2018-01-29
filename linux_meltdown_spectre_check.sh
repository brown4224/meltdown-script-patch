#!/bin/bash
# Check if Root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi
echo "Starting linux meltdown spectre script"
REBOOT=false

function RHEL_CHECK() {
  if [[ -z "$3" ]]; then
    echo "[---] $2 is NOT installed"
  elif [[ "$1" == "$2" ]]; then
    echo "[OK] $3 is Patched"
  else
    echo "[FAIL] $3 is NOT Patched"

  fi
}

# RHEL and CENTOS
# Installs Kernal updates and reboots
# Target packages:  kernel  kernel-rt libvirt  qemu-kvm  dracut
# https://access.redhat.com/security/vulnerabilities/speculativeexecution
if [[ -f /etc/redhat-release ]]; then
  RHELVersion=`lsb_release -rs | cut -f1 -d.`
  Arch=`lscpu | grep Architecture |  sed 's/.*: //' | tr -d [:blank:]`
  RHELKernel=`uname -r`
  RHELlibvirt=`rpm -qi libvirt | grep "Source RPM"  |  sed 's/.*://' | tr -d [:blank:]`
  RHELqemukvm=`rpm -qi qemu-kvm | grep "Source RPM" |  sed 's/.*://' | tr -d [:blank:]`
  RHELdracut=`rpm -qi rpm  dracut | grep "Source RPM" | grep dracut  |  sed 's/.*://' | tr -d [:blank:]`


  if [[ "$RHELVersion" == 7 ]]; then
    echo "RHEL 7 Detected"
    echo "Checking for updates..."
    yum update kernel kernel-rt libvert qemu-kvm dracut  -y
    clear
    echo "Runing Check list #########################################"
    RHEL_CHECK $RHELKernel "3.10.0-693.11.6.el7.$Arch" 'kernel'
    RHEL_CHECK $RHELlibvirt 'libvirt-3.2.0-14.el7_4.7.src.rpm' 'libvirt'
    RHEL_CHECK $RHELqemukvm 'qemu-kvm-1.5.3-141.el7_4.6.src.rpm' 'qemu-kvm'
    RHEL_CHECK $RHELdracut 'dracut-033-502.el7_4.1.src.rpm' 'dracut'
    # END RHEL 7
  fi
  if [[ "$RHELVersion" == 6 ]]; then
    echo "RHEL 6 Detected"
    echo "Checking for updates..."
    yum update kernel kernel-rt libvert qemu-kvm  -y
    clear
    echo "Runing Check list #########################################"
    RHEL_CHECK $RHELKernel `2.6.32-696.18.7.el6.$Arch` 'kernel'
    RHEL_CHECK $RHELlibvirt 'libvirt-0.10.2-62.el6_9.1.src.rpm' 'sudo apt-get dist-upgrade'
    RHEL_CHECK $RHELqemukvm 'qemu-kvm-0.12.1.2-2.503.el6_9.4.src.rpm' 'qemu-kvm'
    # END RHEL 6
  fi
# END RHEL

# Ubuntu and Debian
elif [ -f /etc/debian_version ]; then
  echo "Ubuntu Debian"
  apt-get update
  apt-get dist-upgrade
fi

# Reboot required
echo "A reboot is required to install the new Kernel"
echo "Would you like to reboot?  y/n [ENTER]"
read REBOOT
if [[ $REBOOT == y* || $REBOOT == Y*  ]]; then
  reboot now
fi
echo "End Script"
