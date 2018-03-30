FROM oraclelinux:6
MAINTAINER MASAKI OOSHIMA s4ragent
#install epel
RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#installpackages
RUN yum -y install git\
                   gcc\
                   bison\
                   flex\
                   libdb-devel\
                   db4-devel\
                   make\
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
RUN chkconfig NetworkManager off ; chkconfig iptables off
RUN mv /etc/init/tty.conf /etc/init/tty.bk; mv /etc/init/serial.conf /etc/init/serial.bk
RUN git clone git://git.kernel.org/pub/scm/linux/kernel/git/shemminger/iproute2.git
WORKDIR iproute2
RUN git checkout v3.17.0 && ./configure && make && make DESTDIR=/usr/share install
CMD ["/sbin/init"]