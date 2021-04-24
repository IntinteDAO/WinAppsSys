#!/bin/bash

red=`tput setaf 1`
reset=`tput sgr0`

disclaimer () { echo "${red}Windows Server 2019 Trial is for non-commercial use only.${reset}"; echo "Read Terms here: https://www.microsoft.com/en-us/UseTerms/Retail/WindowsServer2019/DatacenterAndStandard/Useterms_Retail_WindowsServer2019_DatacenterAndStandard_English.htm"; sleep 5s; }
download_win () { echo "${red}Downloading Windows Server 2019 ISO${reset}"; wget https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso -O wsrv_clean.iso; }
download_drv () { echo "${red}Downloading VirtIO Drivers${reset}"; wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso -O drv.iso; }
unpack_win () { echo "${red}Unpack Windows ISO${reset}"; mkdir unpack; cd unpack; 7z x ../wsrv_clean.iso; cd ..; }
unpack_drv () { echo "${red}Unpack VirtIO Drivers${reset}"; mkdir unpack_drv; cd unpack_drv; 7z x ../drv.iso; cd ..; }
patch_iso () { echo "${red}Preparation WinServ Mod${reset}"; mkdir -p unpack/drivers/amd64/2k19; mkdir -p unpack/drivers/NetKVM/2k19/amd64; cp unpack_drv/amd64/2k19/* unpack/drivers/amd64/2k19; cp unpack_drv/NetKVM/2k19/amd64/* unpack/drivers/NetKVM/2k19/amd64; cp autounattend.xml unpack; }
creating_iso () { echo "${red}Building WinServ Mod ISO${reset}"; mkisofs -iso-level 4 -l -R -UDF -D -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 -hide boot.catalog -eltorito-alt-boot -eltorito-platform efi -no-emul-boot -b efi/microsoft/boot/efisys.bin -o wsrv_mod.iso unpack;  }
cleaning () { echo "${red}Cleaning${reset}"; rm -rf unpack; rm -rf unpack_drv; rm drv.iso; rm wsrv_clean.iso; }
create_vm () { 

echo "${red}Creating Virtual Machine ${reset}";
mkdir -p /home/$USER/.local/share/winapps

if (( $EUID != 0 )); then
	sudo virt-install -n RDPWindows --description "Winapps" --os-type=Windows --os-variant=win2k19 --ram=4096 --cpu host-model-only --vcpus=2 --disk path=/var/lib/libvirt/images/RDPWindows.img,bus=virtio,size=100 --graphics spice,listen=127.0.0.1 --cdrom $PWD/wsrv_mod.iso --network network=default,model=virtio --check disk_size=off --noreboot;
	sudo virsh change-media RDPWindows sda --eject
	sudo chown $USER:$USER /var/lib/libvirt/images/RDPWindows.img
	sudo virsh autostart RDPWindows;
	sudo virsh start RDPWindows;
else
	virt-install -n RDPWindows --description "Winapps" --os-type=Windows --os-variant=win2k19 --ram=4096 --cpu host-model-only --vcpus=2 --disk path=/var/lib/libvirt/images/RDPWindows.img,bus=virtio,size=100 --graphics spice,listen=127.0.0.1 --cdrom $PWD/wsrv_mod.iso --network network=default,model=virtio --check disk_size=off --noreboot;
	virsh change-media RDPWindows sda --eject
	chown $USER:$USER /var/lib/libvirt/images/RDPWindows.img
	virsh autostart RDPWindows;
	virsh start RDPWindows;
fi
 }

if [[ "$*" == *--autoinstall* ]]
then

disclaimer

if [ ! -f "wsrv_mod.iso" ]
then
	download_win
	download_drv
	unpack_win
	unpack_drv
	patch_iso
	creating_iso
	cleaning
fi

create_vm

elif [[ "$*" == *--create-iso* ]]
then
disclaimer

if [ ! -f "wsrv_mod.iso" ]
then
	download_win
	download_drv
	unpack_win
	unpack_drv
	patch_iso
	creating_iso
	cleaning
fi

elif [[ "$*" == *--version* ]]
then

echo "WinAppsSys is created by IntinteDAO as a complement to WinApps.

${red}The Trial version of Windows Server is for non-commercial use only.${reset}

The rights to Windows Server belong to Microsoft Corporation.

Use Wine if possible :-)";

else
    echo "WinAppsSys 1.1 : 2021 IntinteDAO";
    echo "";
    echo "Available options:";
    echo "--autoinstall : Creating WinServ ISO and install in KVM automatically";
    echo "--create-iso : Creating WinServ ISO ready to install in KVM for Winapps";
    echo "--version : Version and information about WinAppsSys";
fi
