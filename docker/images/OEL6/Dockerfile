FROM oraclelinux:6
MAINTAINER MASAKI OOSHIMA s4ragent
#install epel
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#installpackages
RUN yum -y install git\
                   traceroute\
                   unzip\
                   iperf\
                   oracle-rdbms-server-12cR2-preinstall\
                   screen\
                   nfs-utils\
                   dnsmasq\
                   tar\
                   net-tools\
                   expect\
                   bind-utils\
                   qemu-img
RUN yum -y reinstall glibc-common
RUN yum -y clean all
RUN chkconfig iptables off && chkconfig NetworkManager off
RUN mv /etc/init/tty.conf /etc/init/tty.bk; mv /etc/init/serial.conf /etc/init/serial.bk
CMD ["/sbin/init"]