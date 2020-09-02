#!/bin/bash
#
# AUTOR: Patrick Ernandes
# EMAIL: patrickernandes@gmail.com
#
# Script para criar uma image ISO de seu sistema Slackware instalado.
# *Necessário estar conectado a internet.
# *Testado com "Slackware64-current".
# *Todo o sistema deve estar instalado em uma única partição.
# *Pacotes kernel-generic e kernel-huge devem estar instalados.
# *No momento, sem suporte a boot com UEFI.
# *Lembrando, quanto maior seu sistema, mais tempo vai levar para o livecd subir por completo.
#
#


#VARS:
VER='20200910'
LOG='/iso/log.txt'
OPT=$1
KERNEL=$(uname -r)
ROOTDEV=$(findmnt -n / | awk '{print $2}')
OS=$(grep '^VERSION_CODENAME' /etc/os-release | cut -d '=' -f 2 | sed 's/"//g')
ISONAME='Slack Linux'
ISOFILE='linux.iso'


#FUNCTIONS:
quit() {
    
    [ $? -ne 0 ] && { clear; exit; }
}


is_root() {

    if [ "$EUID" -ne 0 ]; then
        echo "ERROR - Somente executar como super usuario; como root!"
        echo
        exit 1
    fi
}


help() {
    
    cat <<EOF
================ AJUDA ================
-help      -> menu de ajuda.
-clean     -> limpeza das pastas e arquivos criados.
-create    -> gerar ISO com o sistema.

EOF

    exit 0
}


clean() {

    if mountpoint -q /iso/chroot
    then
        umount -f /iso/chroot
    fi

    if [ -d "/iso" ]; then
        rm -rf "/iso"
    fi
}


create() {
    
    is_root
    clean

    echo "Iniciando os trabalhos na pasta /iso.."
    echo

    if [ ! -d "/iso" ]; then
        mkdir "/iso"
    fi

    pushd /iso &>/dev/null  ##vai para a pasta inicial.
    mkdir chroot
    mkdir initrd
    mkdir media
    mkdir -p media/{boot,isolinux,live}

    mkinitrd -s initrd -c -k $KERNEL -m mptbase:mptscsih:mptspi:jbd2:mbcache:ext4:ehci-pci:overlay:xhci-pci:xhci-hcd:ehci-hcd:nls_iso8859_1:uhci-hcd:uas:sr_mod:usbcore:usb-common:usb-storage:loop:cdrom:squashfs:isofs:vfat:fat:nls_cp437 -u -o media/boot/initrd.gz

    rm initrd/command_line
    rm initrd/init
    rm initrd/initrd-name
    rm initrd/keymap
    rm initrd/load_kernel_modules
    rm initrd/luks*
    rm initrd/resumedev
    rm initrd/rootdev
    rm initrd/rootfs
    rm initrd/wait-for-root
    
    cd initrd
    wget --timeout=2 --waitretry=1 --tries=3 -c https://raw.githubusercontent.com/patrickernandes/slackware/master/src/init
    if [ -f init ]; then 
        chmod +x init
    else
        echo 'ERROR - arquivo init não encontrado!'
        echo
        exit 1
    fi

    find . | cpio -o -H newc --quiet | gzip -9 > /iso/media/boot/initrd.gz
    if [ -f /boot/vmlinuz-generic-$KERNEL ]; then 
        cp /boot/vmlinuz-generic-$KERNEL /iso/media/boot/vmlinuz
    else
        echo 'ERROR - pacote kernel-generic não encontrado!'
        echo
        exit 1
    fi  
    cd ..

    mount $ROOTDEV chroot
    if [ -f media/live/root.sfs ]; then
        rm -f media/live/root.sfs
    fi
    
    mksquashfs chroot media/live/root.sfs -e iso
    umount -f chroot

    cd media/isolinux/
    echo 'Linux' > live
    wget --timeout=2 --waitretry=1 --tries=3 -c https://raw.githubusercontent.com/patrickernandes/slackware/master/src/isolinux.cfg
    if [ ! -f isolinux.cfg ]; then 
        echo 'ERROR - arquivo isolinux.cfg não encontrado!'
        echo
        exit 1
    fi

    cp /usr/share/syslinux/chain.c32 .
    cp /usr/share/syslinux/isohdpfx.bin .
    cp /usr/share/syslinux/linux.c32 .
    cp /usr/share/syslinux/menu.c32 .
    cp /usr/share/syslinux/reboot.c32 .
    for i in {efiboot.img,iso.sort,isolinux.bin}; do
        wget --timeout=2 --waitretry=1 --tries=3 -c  https://mirrors.slackware.com/slackware/slackware64-current/isolinux/$i
    done        
    cd ..
    
    if [ -f /iso/$ISOFILE ]; then 
        rm /iso/$ISOFILE
    fi
    #cd media
    mkisofs -o /iso/$ISOFILE -R -J -A "$ISONAME" -hide-rr-moved -v -d -N -no-emul-boot -boot-load-size 4 -boot-info-table -sort isolinux/iso.sort -b isolinux/isolinux.bin -c isolinux/isolinux.boot -V "Linux" .
    cd ..

    popd &>/dev/null  #volta da pasta inicial.
    echo
    echo "Image '$ISOFILE' criado na pasta /iso.."
    echo

}


#START Menu:
#============================================================
echo

if [ $OPT ]; then
    case $OPT in
    -help)
        help
        ;;
    -clean)
        clean
        ;;
    -create)
        create
        echo
        ;;
    *)
        echo "[ $OPT ] ERROR - Comando não encontrado!"
        echo
        ;;
    esac
fi


##FIM:
exit 0

