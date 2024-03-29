timezone Europe/Moscow
auth --useshadow --enablemd5
selinux --disabled
firewall --enabled
firstboot --enabled
part / --size 8692

services --enabled=acpid,alsa,atd,avahi-daemon,prefdm,haldaemon,irqbalance,mandi,dbus,netfs,network,network-up,partmon,resolvconf,rpcbind,rsyslog,sound,udev-post,cups,mandrake_everytime,crond
services --disabled=sshd,pptp,pppoe,ntpd,iptables,ip6tables,shorewall,nfs-server,network,network-up,mysql,samba,abrtd

#repo --name=Main       --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/main/release/
#repo --name=MainT     --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/main/testing/
#repo --name=MainU      --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/main/updates
#repo --name=Contrib       --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/contrib/release/                                                                                                     
#repo --name=ContribU    --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/contrib/updates
#repo --name=Non-free        --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/non-free/release/  
#repo --name=Non-freeU --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/non-free/release
# for 32bit stuff on 64bits arch
#repo --name=Main2       --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/main/release/                                                                                                           
#repo --name=Contrib2       --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/contrib/release/                                                                                                     
#repo --name=Non-free2        --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/non-free/release/

#repo --name=Rosa.add    --baseurl=file://ROSA.Repo2/i586/

##FOR KERNEL3.0
#repo --name=TEST --baseurl=file:///iso/repository/rpm/external/TEST/i586/

#repo --name=Main       --baseurl=file:///BACKUPrepo/2011/i586/media/main/release/                                                                                                          
#repo --name=MainT     --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/main/testing/                                                                                                           
#repo --name=MainU      --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/main/updates                                                                                                           
#repo --name=Contrib       --baseurl=file:///BACKUPrepo/2011/i586/media/contrib/release/                                                                                                    
#repo --name=ContribU    --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/contrib/updates                                                                                                       
#repo --name=Non-free        --baseurl=file:///BACKUPrepo/2011/i586/media/non-free/release/                                                                                                 
#repo --name=Non-freeU --baseurl=file:///iso/repository/rpm/external/mdv/2011/i586/media/non-free/release
repo --name=External --baseurl=http://old.rosalab.ru/repo/ROSA.Desktop/ROSA.Desktop.2011.beta/REPOS.Sorted/i586/main/

%packages
%include /opt//ROSA.2011.CERT/i586kde.lst
%end

%post
echo "ROSA Linux release 2011.0" > /etc/redhat-release                                                                                                                                                             
echo "ROSA Linux release 2011.0" > /etc/issue                                                                                                                                                                      
echo "ROSA Linux release 2011.0" > /etc/issue.net                                                                                                                                                                  
echo "ROSA Linux release 2011.0" > /etc/system-release                                                                                                                                                             
                                                      
# adding messagebus user to workaround rpm ordering (eugeni)
/usr/share/rpm-helper/add-user dbus 1 messagebus / /sbin/nologin
/usr/share/rpm-helper/add-group dbus 1 messagebus

/bin/chown root:messagebus /lib*/dbus-1/dbus-daemon-launch-helper
/bin/chmod u+s,g-s /lib*/dbus-1/dbus-daemon-launch-helper

echo ""
/bin/ls -l /boot/
echo ""
echo "###################################### Make initrd symlink >> "
echo ""

/usr/sbin/update-alternatives --set mkinitrd /sbin/mkinitrd-dracut
rm -rf /boot/initrd-*

# adding life user
/usr/sbin/adduser live
/usr/bin/passwd -d live
/bin/mkdir -p /home/live
/bin/cp -rfT /etc/skel /home/live/
/bin/chown -R live:live /home/live

# enable live user autologin
if [ -f /usr/share/config/kdm/kdmrc ]; then
	/bin/sed -i -e 's/.*AutoLoginEnable.*/AutoLoginEnable=true/g' -e 's/.*AutoLoginUser.*/AutoLoginUser=live/g' /usr/share/config/kdm/kdmrc
fi

# ldetect stuff
/usr/sbin/update-ldetect-lst

# setting up network manager by default
# don't forget to change it

pushd /etc/sysconfig/network-scripts
for iface in eth0 wlan0; do
	cat > ifcfg-$iface << EOF
DEVICE=$iface
ONBOOT=yes
NM_CONTROLLED=yes
EOF
done
popd

systemctl enable networkmanager.service
systemctl enable getty@.service


# default background
pushd /usr/share/mdk/backgrounds/
ln -s rosa-background.jpg default.jpg 
popd

# 

#####workaround for time###                                                                                                                                                                                        
rm -rf /etc/sysconfig/clock                                                                                                                                                                                        
rm -rf /etc/adjtime                                                                                                                                                                                                
rm -rf /etc/localtime                                                                                                                                                                                              
##### 
###chkconfig###                                                                                                                                                                                                    
/sbin/chkconfig --add checkflashboot                                                                                                                                                                               
#####                 

#
# DKMS
#

echo
echo
echo Rebuilding DKMS drivers
echo
echo

export PATH=/bin:/sbin:/usr/bin:/usr/sbin

#build arch import for vboxadditions dkms + flash workaround###

export BUILD_TARGET_ARCH=x86
XXX=`file /bin/rpm |grep -c x86-64`                                                                                                                                                                                
if [ "$XXX" = "1" ];  then  
export BUILD_TARGET_ARCH=amd64
fi

echo " ###DKMS BUILD### "                                                                                                                                                                                          
kernel_ver=`ls /boot | /bin/grep vmlinuz | /bin/sed 's/vmlinuz-//'`   
for module in broadcom-wl vboxadditions r8192se; do                                                                                                                              
module_version=`rpm --qf '%{VERSION}\n' -q dkms-$module`                                                                                                                                                           
module_release=`rpm --qf '%{RELEASE}\n' -q dkms-$module`                                                                                                                                                           
/usr/sbin/dkms -k $kernel_ver -a i586 --rpm_safe_upgrade add -m $module -v $module_version-$module_release
/usr/sbin/dkms -k $kernel_ver -a i586 --rpm_safe_upgrade build -m $module -v $module_version-$module_release                                                                                  
/usr/sbin/dkms -k $kernel_ver -a i586 --rpm_safe_upgrade install -m $module -v $module_version-$module_release --force                                                                        
done                                                                                                                                                                                                               
echo "END OF IT" 
#/bin/bash
#
# kernel
#

#
# Sysfs must be mounted for dracut to work!
#
mount -t sysfs /sys /sys

pushd /lib/modules/
KERNEL=$(echo *)
popd
echo
echo Generating kernel. System kernel is `uname -r`, installed kernels are:
rpm -qa kernel-*
echo Detected kernel version: $KERNEL

/sbin/dracut --add-drivers "sr-mod xhci-hcd" /boot/initramfs-$KERNEL.img $KERNEL
ls -l /boot/
echo ""
echo "###################################### Build ISO >> "
echo ""

%post --nochroot

    cp -rfT 	/opt//ROSA.2011.CERT/extraconfig/etc $INSTALL_ROOT/etc/
    cp -rfT     /opt//ROSA.2011.CERT/extraconfig/etc/skel $INSTALL_ROOT/home/live/
#    echo "ASDASD"
#    /bin/bash
    chmod -R 0777 $INSTALL_ROOT/home/live/.local
    chmod -R 0777 $INSTALL_ROOT/home/live/.kde4
    cp -rfT     /opt//ROSA.2011.CERT/.counter $INSTALL_ROOT/etc/isonumber 

    cp -f 		/opt//ROSA.2011.CERT/root/GPL $LIVE_ROOT/
    mkdir -p 	$LIVE_ROOT/Addons
    cp 	  		/usr/bin/livecd-iso-to-disk			$LIVE_ROOT/Addons/
    chmod +x 	$LIVE_ROOT/Addons/livecd-iso-to-disk
    rpm --root $INSTALL_ROOT -qa | sort > $LIVE_ROOT/rpm.lst
    ./total_sum_counter.pl -r 640 -h 10 -w $INSTALL_ROOT/ -o $INSTALL_ROOT/etc/minsysreqs

%end
