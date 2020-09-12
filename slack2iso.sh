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
# *Lembrando, quanto maior seu sistema, mais tempo vai levar para o livecd subir por completo.
#
#


#VARS:
LOG='/iso/log.txt'
OPT=$1
KERNEL=$(uname -r)
ROOTDEV=$(findmnt -n / | awk '{print $2}')
OS=$(grep '^VERSION_CODENAME' /etc/os-release | cut -d '=' -f 2 | sed 's/"//g')
ISONAME='Slack Linux'
ISOFILE='slack.iso'


#FUNCTIONS:
quit() {
    
    #sair do script:
    [ $? -ne 0 ] && { clear; exit; }
}


is_root() {

    #verifica se você é usuário root:
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR - Somente executar como super usuário; como root!"
        echo
        exit 1
    fi
}


help() {
    
    #apresentar ajuda:
    cat <<EOF
================ AJUDA ================
-help      -> menu de ajuda.
-clean     -> limpeza das pastas e arquivos criados.
-create    -> gerar ISO com o sistema.

EOF

    exit 0
}


clean() {

    #limpeza do ambiente de trabalho:
    if mountpoint -q /iso/chroot
    then
        umount -f /iso/chroot
    fi

    if [ -d "/iso" ]; then
        rm -rf "/iso"
    fi
}


create() {
    
    #início do processo:
    echo "Iniciando os trabalhos na pasta /iso.."
    sleep 2
    echo

    is_root
    clean

    if [ ! -d "/iso" ]; then
        mkdir "/iso"
    fi

    pushd /iso &>/dev/null  ##vai para a pasta inicial.
    mkdir chroot
    mkdir initrd
    mkdir media
    mkdir -p media/{boot,isolinux,live,EFI/BOOT}


    #criar o initrd:
    echo "Iniciando a criacao do initrd customizado.."
    sleep 2
    echo

    mkinitrd -s initrd -c -k $KERNEL -m mptbase:mptscsih:mptspi:jbd2:mbcache:ext4:ehci-pci:overlay:xhci-pci:xhci-hcd:ehci-hcd:nls_iso8859_1:uhci-hcd:uas:sr_mod:usbcore:usb-common:usb-storage:loop:cdrom:squashfs:isofs:vfat:fat:nls_cp437 -u -o media/boot/initrd.gz

    cd initrd/
    for i in {command_line,init,initrd-name,keymap,load_kernel_modules,luks*,resumedev,rootdev,rootfs,wait-for-root}; do
        rm $i
    done

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
    
    
    #criar o sistema de arquivos em squashfs:
    echo "Iniciando o processo de compressao do sistema para squashfs.."
    sleep 2
    echo

    mount $ROOTDEV chroot
    if [ -f media/live/root.sfs ]; then
        rm -f media/live/root.sfs
    fi
    
    mksquashfs chroot media/live/root.sfs -e iso
    umount -f chroot
    echo

    
    #criar bios boot:
    echo "Iniciando a criacao do sistema de boot via bios.."
    sleep 2
    echo

    cd media/isolinux/
    echo 'Linux' > live
    wget --timeout=2 --waitretry=1 --tries=3 -c https://raw.githubusercontent.com/patrickernandes/slackware/master/src/isolinux.cfg
    if [ ! -f isolinux.cfg ]; then 
        echo 'ERROR - arquivo isolinux.cfg não encontrado!'
        echo
        exit 1
    fi

    for i in {chain.c32,isohdpfx.bin,linux.c32,menu.c32,reboot.c32}; do
        cp /usr/share/syslinux/$i .
    done

    for i in {efiboot.img,iso.sort,isolinux.bin}; do
        wget --timeout=2 --waitretry=1 --tries=3 -c https://mirrors.slackware.com/slackware/slackware64-current/isolinux/$i
    done        
    cd ..


    #criar efi boot:
    echo "Iniciando a criacao do sistema de boot efi.."
    sleep 2
    echo

    cd EFI/BOOT
    cp /iso/media/boot/initrd.gz .
    cp /iso/media/boot/vmlinuz .

    wget --timeout=2 --waitretry=1 --tries=3 -c https://raw.githubusercontent.com/patrickernandes/slackware/master/src/grub.cfg
    if [ ! -f grub.cfg ]; then 
        echo 'ERROR - arquivo grub.cfg não encontrado!'
        echo
        exit 1
    fi

    wget --timeout=2 --waitretry=1 --tries=3 -c https://mirrors.slackware.com/slackware/slackware64-current/EFI/BOOT/bootx64.efi
    if [ ! -f bootx64.efi ]; then 
        echo 'ERROR - arquivo bootx64.efi não encontrado!'
        echo
        exit 1
    fi
    cd ../../


    #criar o arquivo iso:
    echo "Iniciando a criacao da image iso.."
    sleep 2
    echo

    mkisofs -o /iso/$ISOFILE \
        -R -J -V "Linux" -A "$ISONAME" \
        -preparer "My slack livecd" \
        -hide-rr-moved -hide-joliet-trans-tbl \
        -v -d -N -no-emul-boot -boot-load-size 4 -boot-info-table \
        -sort isolinux/iso.sort \
        -b isolinux/isolinux.bin \
        -c isolinux/isolinux.boot \
        -eltorito-alt-boot -no-emul-boot -eltorito-platform 0xEF -eltorito-boot isolinux/efiboot.img .
    cd ..

    popd &>/dev/null  #volta da pasta inicial.
    echo
    echo "Image '$ISOFILE' criado na pasta /iso.."
    sleep 2
    echo

    exit 0

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

