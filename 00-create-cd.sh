#!/bin/bash
set -x
set -e

function usage {
    set +x
    echo >&2 "usage: $0"
    echo >&2 "          [--help] print this message"
    echo >&2 "          [--debug] debug mode "
    echo >&2 "          [--local-repo] keep deb as local repo "
    echo >&2 "          [--rosdistro (hydro|indigo)] "
    exit 0
}

OPT=`getopt -o hdlr: -l help,debug,local-repo,rosdistro: -- $*`
if [ $? != 0 ]; then
    usage
fi

ROSDISTRO=indigo
eval set -- $OPT
while [ -n "$1" ] ; do
    echo $1
    case $1 in
        -h| --help) usage; shift;;
        -d| --debug) DEBUG=TRUE; shift;;
        -l| --local-repo) ENABLE_LOCAL_REPOSITORY=TRUE; shift;;
        -r| --rosdistro) ROSDISTRO=$2; shift 2;;
        --) shift; break;;
    esac
done

case $ROSDISTRO in
    indigo) ISO=ubuntu-14.04.5-desktop-amd64.iso;;
    kinetic) ISO=ubuntu-16.04.3-desktop-amd64.iso;;
    *) echo "[ERROR] Unsupported ROSDISTRO $ROSDISTRO"; exit;;
esac
REV=`echo ${ISO} | sed "s/ubuntu-\([0-9]*.[0-9]*\).*/\\1/"`

DATE=`date +%Y%m%d_%H%M%S`

# init stuff
if [ ! ${DEBUG} ]; then
    sudo uck-remaster-clean
    if [ ! -e /tmp/${ISO} ]; then
        wget -q http://releases.ubuntu.com/${REV}/${ISO} -O /tmp/${ISO}
    fi
    sudo uck-remaster-unpack-iso /tmp/${ISO}
    sudo uck-remaster-unpack-rootfs
fi

# setup custom disk
cat <<EOF | sudo uck-remaster-chroot-rootfs
set -x
set -e

umask 022

# first install boot-repair repository
sudo add-apt-repository ppa:yannubuntu/boot-repair

if [ ! ${DEBUG} ]; then
whoami
if [ \`grep universe /etc/apt/sources.list | wc -l\` -eq 0 ]; then
  echo "
#
deb http://archive.ubuntu.com/ubuntu/ \`lsb_release -cs\` main universe
deb http://security.ubuntu.com/ubuntu/ \`lsb_release -cs\`-security main universe
deb http://archive.ubuntu.com/ubuntu/ \`lsb_release -cs\`-updates main universe
#
deb http://archive.ubuntu.com/ubuntu/ \`lsb_release -cs\` main multiverse
deb http://security.ubuntu.com/ubuntu/ \`lsb_release -cs\`-security main multiverse
deb http://archive.ubuntu.com/ubuntu/ \`lsb_release -cs\`-updates main multiverse
" >> /etc/apt/sources.list;
fi
cat /etc/apt/sources.list
([ -e /etc/apt/sources.list~ ] && rm -f /etc/apt/sources.list~; ls /etc/apt/)

# install ros
sh -c 'echo "deb http://packages.ros.org/ros/ubuntu \`lsb_release -cs\` main" > /etc/apt/sources.list.d/ros-latest.list'
apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
# apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
# apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
apt-get update
echo "hddtemp hddtemp/daemon boolean false" | sudo debconf-set-selections
apt-get -y -q install ros-$ROSDISTRO-desktop-full ros-$ROSDISTRO-catkin  ros-$ROSDISTRO-rosbash
apt-get -y -q install python-wstool python-rosdep python-catkin-tools

# vim and boot-repair
apt-get -y -q install vim
apt-get -y -q boot-repair

# rosdep
rosdep init;  rosdep update || echo "ok"


# # fix resolve conf (https://github.com/tork-a/live-cd/issues/8)
# rm -fr /etc/resolv.conf
# apt-get -y -q install debconf-utils
# echo "resolvconf resolvconf/linkify-resolvconf boolean true" | debconf-set-selections -
# dpkg-reconfigure -fnoninteractive resolvconf

fi # ( [ ! ${DEBUG} ] )

EOF

if [ ! ${DEBUG} ]; then
     # pack file system
    sudo uck-remaster-pack-rootfs

    # create local repository
    if [ ${ENABLE_LOCAL_REPOSITORY} ]; then
      sudo mkdir -p ~/tmp/remaster-iso/repository
      sudo cp -r ~/tmp/remaster-apt-cache/archives ~/tmp/remaster-iso/repository/binary
      sudo chmod a+rx ~/tmp/remaster-iso/repository/binary/
      sudo su -c "cd ${HOME}/tmp/remaster-iso/repository/; dpkg-scanpackages binary /dev/null | gzip -9c > binary/Packages.gz"
   fi

    ## update boot option
    sudo su -c "cd ${HOME}/tmp/remaster-iso/isolinux; sed -i 's/quiet splash//' txt.cfg"
    sudo su -c "cd ${HOME}/tmp/remaster-iso/isolinux; sed -i 's/^/#/' isolinux.cfg"
    sudo su -c "cd ${HOME}/tmp/remaster-iso/isolinux; echo 'include txt.cfg' >> isolinux.cfg"


    # create iso
    if [ ${ENABLE_LOCAL_REPOSITORY} ]; then
        FILENAME=baoxian-ubuntu-ros-${REV}-local-repo-amd64-${DATE}.iso
    else
        FILENAME=baoxian-ubuntu-ros-${REV}-amd64-${DATE}.iso
    fi
    DATE=`date +%m%d`
                                              #1234 56789012345 678901 2 3 456789012
    sudo uck-remaster-pack-iso $FILENAME -g -d=BAO\ Ubuntu/ROS\ Linux\ \(${DATE}\)
    sudo cp -f ~/tmp/remaster-new-files/$FILENAME .
    sudo chown zhangbaoxian.zhangbaoxian $FILENAME
fi





