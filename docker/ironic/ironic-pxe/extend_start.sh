#!/bin/bash


function bootstrap_pxe() {
    chown -R ironic: /tftpboot
    for pxe_file in /var/lib/tftpboot/pxelinux.0 /var/lib/tftpboot/chain.c32 /usr/lib/syslinux/pxelinux.0 \
                    /usr/lib/syslinux/chain.c32 /usr/lib/PXELINUX/pxelinux.0 \
                    /usr/lib/syslinux/modules/bios/chain.c32 /usr/lib/syslinux/modules/bios/ldlinux.c32; do
        if [[ -e "$pxe_file" ]]; then
            cp "$pxe_file" /tftpboot
        fi
    done
    exit 0
}

function bootstrap_ipxe() {
    if [[ "${KOLLA_BASE_DISTRO}" =~ debian|ubuntu ]]; then
        cp /usr/lib/ipxe/{undionly.kpxe,ipxe.efi} /tftpboot
        echo "NameVirtualHost *:80" > /etc/apache2/ports.conf
        echo "Listen 80" >> /etc/apache2/ports.conf
    elif [[ "${KOLLA_BASE_DISTRO}" =~ centos|oraclelinux|rhel ]]; then
        cp /usr/share/ipxe/{undionly.kpxe,ipxe.efi} /tftpboot
        sed -i '/Listen 80/s/^#//g' /etc/httpd/conf/httpd.conf
    fi
}

# Bootstrap and exit if KOLLA_BOOTSTRAP variable is set. This catches all cases
# of the KOLLA_BOOTSTRAP variable being set, including empty.
if [[ "${!KOLLA_BOOTSTRAP[@]}" ]]; then
    if [[ "${!KOLLA_BOOTSTRAP_IPXE[@]}" ]]; then
        bootstrap_ipxe
    else
        bootstrap_pxe
    fi
fi

# NOTE(pbourke): httpd will not clean up after itself in some cases which
# results in the container not being able to restart. (bug #1489676, 1557036)
if [[ "${KOLLA_BASE_DISTRO}" =~ debian|ubuntu ]]; then
    # Loading Apache2 ENV variables
    . /etc/apache2/envvars
    rm -rf /var/run/apache2/*
else
    rm -rf /var/run/httpd/* /run/httpd/* /tmp/httpd*
fi
