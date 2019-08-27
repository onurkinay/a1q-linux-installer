#!/bin/sh

#
# LINUX A1Q OS INSTALLER 
# WRITTEN BY ONUR KINAY
#

#
# TODO LIST

#
#DETECT ETHERNET AND MAKE ITS CONF FILE
#COMPARE THE OS TARBALL USING MD5
#

#BUGS
## kernel panic vfs unable to mount root fs
## "history -c" does not work


## BEGINNING
clear

if [ ! -f /etc/a1q-release  ];
then
	echo "THE INSTALLER CAN'T RUN. PLEASE RUN IT ON A1Q OS WITH INSTALLER"
	exit
else
	if [ $(</etc/a1q-release) != "alpha-x-installer"  ];
	then
		echo "THE INSTALLER CAN'T RUN. PLEASE RUN IT ON A1Q OS INSTALLER DISC"
		exit
	fi
fi

dialog --title 'Welcome to A1Q OS' --backtitle "A1Q OS INSTALLER" --msgbox 'Welcome to A1Q OS Installer\n\nThe installer will help you installing A1Q OS step by step\nIf you are ready for the procces, press ENTER' 10 75

clear

## !!BEGINNING

##SELECTING DISK
dialog --title 'Select a disk to install the system' --backtitle "A1Q OS INSTALLER" --msgbox 'The installer needs where to install the OS\nThe system will show disks connected to your computer\nPlease, select a disk you want to install the OS\n\nWARNING: The disk that will be selected is going to erase ALL DATA\nTo continue, press ENTER' 12 75

clear

dialog --title "Select a disk to install the system" --backtitle "A1Q OS INSTALLER" --menu "Please choose a disk:" 15 55 10 \
 $( fdisk -l | grep -e 'Disk /\|Disk model' | awk '{print $2 " " $3 $4}' | grep '/dev/\|model' | awk '{print $1 $2 $3}' | sed 's/:/\n/g' | sed 's/model//g' | sed 's/,//g' | sed '/^$/d' | paste - - - -d " |,"

  ) 2> /tmp/selected_disk

ret=$?

# make decision
case $ret in
  0)
	  ;; 
  1)
    echo "ABORTED THE PROCCESS"; exit;;
  255)
    echo "ABORTED THE PROCCESS"; exit;;
esac

DISK=$(cat /tmp/selected_disk)
rm /tmp/selected_disk

## !!SELECTING DISK
clear
## SETTING HOSTNAME

dialog --title "Setting The System" \
--backtitle "A1Q OS INSTALLER" \
--inputbox "Enter name of the computer" 8 50 2> /tmp/new_system_hostname

ret=$?

# make decision
case $ret in
  0)
          ;;
  1)
    echo "ABORTED THE PROCCESS"; exit;;
  255)
    echo "ABORTED THE PROCCESS"; exit;;
esac


HOSTNAMEOFSYSTEM=$(cat /tmp/new_system_hostname)
rm /tmp/new_system_hostname
# !!SETTING HOSTNAME


## SETTING PASSWORDS
clear

PASSOFROOT="00"
PASSOFROOTAGAIN="11"
PASSOFUSER="22"
PASSOFUSERAGAIN="33"

while [ $PASSOFROOT != $PASSOFROOTAGAIN ];
do

	dialog  --title "Setting up Users" \
		--backtitle "A1Q OS INSTALLER" \
		--passwordbox "Enter ROOT password" 8 50 2> /tmp/root_pass
	ret=$?

	# make decision
	case $ret in
  	0)
          ;;
  	1)
    		echo "ABORTED THE PROCCESS"; exit;;
  	255)
    		echo "ABORTED THE PROCCESS"; exit;;
	esac
	
	PASSOFROOT=$(cat /tmp/root_pass)
	rm /tmp/root_pass

	dialog  --title "Setting up Users" \
                --backtitle "A1Q OS INSTALLER" \
                --passwordbox "Enter ROOT password again" 8 50 2> /tmp/root_pass_a
	ret=$?

        # make decision
        case $ret in
        0)
          ;;
        1)
                echo "ABORTED THE PROCCESS"; exit;;
        255)
                echo "ABORTED THE PROCCESS"; exit;;
        esac  
	PASSOFROOTAGAIN=$(cat /tmp/root_pass_a)
	rm /tmp/root_pass_a
	
	if [ $PASSOFROOT != $PASSOFROOTAGAIN  ];then
		echo "Passwords you typed aren't same. Please type again"
		dialog  --title "Setting up Users" --backtitle "A1Q OS INSTALLER "\
		 	--msgbox "\nPasswords you typed aren't same. Please type again" 6 60
	fi
done

clear

dialog --title "Setting up Users" \
--backtitle "A1Q OS INSTALLER" \
--inputbox "Enter name of new user" 8 50 2> /tmp/new_user
ret=$?

        # make decision
        case $ret in
        0)
          ;;
        1)
                echo "ABORTED THE PROCCESS"; exit;;
        255)
                echo "ABORTED THE PROCCESS"; exit;;
        esac  
NAMEOFUSER=$(cat /tmp/new_user)
rm /tmp/new_user


while [ $PASSOFUSER != $PASSOFUSERAGAIN ];
do
	 
        dialog  --title "Setting up Users" \
                --backtitle "A1Q OS INSTALLER" \
                --passwordbox "Enter $NAMEOFUSER password" 8 50 2> /tmp/user_pass

	ret=$?

        # make decision
        case $ret in
        0)
          ;;
        1)
                echo "ABORTED THE PROCCESS"; exit;;
        255)
                echo "ABORTED THE PROCCESS"; exit;;
        esac
        PASSOFUSER=$(cat /tmp/user_pass)
        rm /tmp/user_pass

        dialog  --title "Setting up Users" \
                --backtitle "A1Q OS INSTALLER" \
                --passwordbox "Enter $NAMEOFUSER password again" 8 50 2> /tmp/user_pass_a
        
	ret=$?

        # make decision
        case $ret in
        0)
          ;;
        1)
                echo "ABORTED THE PROCCESS"; exit;;
        255)
                echo "ABORTED THE PROCCESS"; exit;;
        esac  
	PASSOFUSERAGAIN=$(cat /tmp/user_pass_a)
        rm /tmp/user_pass_a

        if [ $PASSOFUSER != $PASSOFUSERAGAIN ]; then
                dialog  --title "Setting up Users" --backtitle "A1Q OS INSTALLER "\
                        --msgbox "\nPasswords you typed aren't same. Please type again" 6 60
        fi
done
## !!SETTING PASSWORDS


clear
dialog --title "Confirmation?" --backtitle "A1Q OS INSTALLER"  --yesno "Selected disk: $DISK\nHostname: $HOSTNAMEOFSYSTEM\nNew username: $NAMEOFUSER\nWant to install the system?" 10 70
READY=$?
if [ $READY == 1 ];
then
	clear
        echo "ABORTED THE PROCCESS"
        exit
fi

## STARTING INSTALLATION
(
echo o # Create a new empty DOS partition table
echo n # Add a new partition
echo p # Primary partition
echo 1 # Partition number
echo   # First sector (Accept default: 1)
echo   # Last sector (Accept default: varies)
echo w # Write changes
) | fdisk $DISK

DISKPART="$DISK"1 

RESULT_FORMAT=$(mkfs.ext4 $DISKPART)
RESULT_MKDIR=$(mkdir -v /mnt/theos)
RESULT_MOUNT=$(mount -v -t ext4 $DISKPART /mnt/theos)
clear
dialog --backtitle "A1Q OS INSTALLER" --infobox "The OS is installing on your selected disk. Please wait..." 3 65

RESULT_TAR=$(tar -xvpzf /root/the-os.tar.gz -C /mnt/theos --numeric-owner)
RESULT_NEWUSERFILE=$(tar -xC /mnt/theos/home -f /mnt/theos/newuser.tar)
rm /mnt/theos/newuser.tar
clear
dialog --backtitle "A1Q OS INSTALLER" --infobox "The OS has been installed on your computer. Now, the boot loader is installing..." 3 85

for f in dev dev/pts proc ; do mount --bind /$f /mnt/theos/$f ; done
chroot /mnt/theos /bin/bash -c "grub-install $DISK && grub-mkconfig -o /boot/grub/grub.cfg && 
	useradd -d /home/$NAMEOFUSER $NAMEOFUSER &&
	mv /home/test-user /home/$NAMEOFUSER &&
	echo 'root:$PASSOFROOT' | chpasswd &&
	echo '$NAMEOFUSER:$PASSOFUSER' | chpasswd &&
        echo $HOSTNAMEOFSYSTEM > /etc/hostname &&
	sed -i 's/a1q/$HOSTNAMEOFSYSTEM/g' /etc/hosts && 
	chown $NAMEOFUSER /home/$NAMEOFUSER/*   && history -c "

umount /mnt/theos

dialog --backtitle "A1Q OS INSTALLER" --infobox "A1Q OS is ready for use. To use it, type REBOOT and press enter." 3 70
read THELASTONE
