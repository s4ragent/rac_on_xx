FROM oraclelinux:6
MAINTAINER MASAKI OOSHIMA s4ragent
#install epel
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#installpackages
RUN yum -y groupinstall Xfce "Japanese Support" &&\
    yum -y install git\
                   traceroute\
                   unzip\
                   iperf\
                   oracle-rdbms-server-12cR1-preinstall\
                   screen\
                   nfs-utils\
                   dnsmasq\
                   tar\
                   net-tools\
                   expect\
                   bind-utils\
                   xrdp\
                   tigervnc-server\
                   firefox\
                   qemu-img
RUN yum -y reinstall glibc-common
RUN yum -y clean all
#xrdp
ADD https://raw.githubusercontent.com/s4ragent/rac_on_docker/master/Xclients /etc/skel/.Xclients
RUN chmod +x /etc/skel/.Xclients
ADD https://raw.githubusercontent.com/s4ragent/rac_on_docker/master/km-e0010411.ini /etc/xrdp/km-e0010411.ini
RUN cp /etc/xrdp/km-e0010411.ini /etc/xrdp/km-0411.ini &&\
    cp /etc/xrdp/km-e0010411.ini /etc/xrdp/km-e0200411.ini &&\
    cp /etc/xrdp/km-e0010411.ini /etc/xrdp/km-e0210411.ini &&\
    chkconfig xrdp on && chkconfig iptables off && chkconfig NetworkManager off
RUN mv /etc/init/tty.conf /etc/init/tty.bk; mv /etc/init/serial.conf /etc/init/serial.bk
CMD ["/sbin/init"]