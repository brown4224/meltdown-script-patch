#!/bin/bash
#  Sean McGlincy
# Version 1.2


# Check if Root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi
echo "Starting linux meltdown spectre script"
REBOOT=false


# Checks Minor Release
# Takes (Installed, Target)
function Version_Controle() {
    Major_Release_Installed=`echo "$1" | cut -d'-' -f1`
    Major_Release_Target=`echo "$2" | cut -d'-' -f1`

    Minor_Release_Installed=`echo "$1" | cut -d'-' -f2`
    Minor_Release_Target=`echo "$2" | cut -d'-' -f2`

    if [[ "$Major_Release_Installed" != "$Major_Release_Target"  ]]; then
      echo "[FAIL] $3 Major Versions Do Not Match.  Check Version Number   ==>  Patched version is $2"
    else
      if [[ "echo $Minor_Release_Installed | cut -d'.' -f1" < "echo $Minor_Release_Target | cut -d'.' -f1" ]]; then
        echo "[FAIL] $3 is NOT Patched"
      elif [[ "echo $Minor_Release_Installed | cut -d'.' -f2" < "echo $Minor_Release_Target | cut -d'.' -f2" ]]; then
        echo "[FAIL] $3 is NOT Patched"
      else
        if [[ ("echo $Minor_Release_Installed | cut -d'.' -f2" == "echo $Minor_Release_Target | cut -d'.' -f2") && ("echo $Minor_Release_Installed | cut -d'.' -f3" < "echo $Minor_Release_Target | cut -d'.' -f3") ]]; then
            echo "[FAIL] $3 is NOT Patched"
          else
            echo "[PASS] $3 is Patched"
        fi
      fi
  fi
}

function RHEL_CHECK() {
  if [[ -z "$3" ]]; then
    echo "[---] $2 is NOT installed"
  else
    Version_Controle $1 $2 $3

  fi
}


# RHEL and CENTOS
# Installs Kernal updates and reboots
# Target packages:  kernel  kernel-rt libvirt  qemu-kvm  dracut
# https://access.redhat.com/security/vulnerabilities/speculativeexecution
if [[ -f /etc/redhat-release ]]; then
  RHELVersion=`lsb_release -rs | cut -f1 -d.`
  Arch=`lscpu | grep Architecture |  sed 's/.*: //' | tr -d [:blank:]`
  RHELKernel=`uname -r | sed 's/.el7.*//' | tr -d [:blank:]`
  RHELlibvirt=`rpm -qi libvirt | grep "Source RPM"   |  sed 's/.*://' | tr -d [:blank:] | sed 's/libvirt-//' | sed 's/.el7.*//'`
  RHELqemukvm=`rpm -qi qemu-kvm | grep "Source RPM"   |  sed 's/.*://' | tr -d [:blank:] | sed 's/qemu-kvm-//' | sed 's/.el7.*//'`
  RHELdracut=`rpm -qi  dracut | grep "Source RPM" | grep dracut  |  sed 's/.*://' | tr -d [:blank:] | sed 's/dracut-//' | sed 's/.el7.*//'`


  if [[ "$RHELVersion" == 7 ]]; then
    echo "RHEL 7 Detected"
    echo "Checking for updates..."
    yum update kernel kernel-rt libvert qemu-kvm dracut  -y
    clear
    echo "Runing Check list #########################################"
    VERSION=`cat /etc/redhat-release `
    echo Detecting: $VERSION
    RHEL_CHECK $RHELKernel '3.10.0-693.11.6' 'kernel'
    RHEL_CHECK $RHELlibvirt '3.2.0-14' 'libvirt'
    RHEL_CHECK $RHELqemukvm '1.5.3-141' 'qemu-kvm'
    RHEL_CHECK $RHELdracut '033-502' 'dracut'
    # END RHEL 7
  fi
  if [[ "$RHELVersion" == 6 ]]; then
    VERSION=`cat /etc/redhat-release `
    echo Detecting: $VERSION
    echo "Checking for updates..."
    yum update kernel kernel-rt libvert qemu-kvm  -y
    clear
    echo "Runing Check list #########################################"
    RHEL_CHECK $RHELKernel '2.6.32-696.18.7' 'kernel'
    RHEL_CHECK $RHELlibvirt '0.10.2-62' 'sudo apt-get dist-upgrade'
    RHEL_CHECK $RHELqemukvm '0.12.1.2-2.503' 'qemu-kvm'
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
