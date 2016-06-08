FROM oraclelinux:7
MAINTAINER @s4r_agent
#enable epel
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
#installpackages
RUN yum --enablerepo=ol7_addons -y install oracle-rdbms-server-12cR1-preinstall tar unzip dnsmasq nfs-utils
RUN yum -y reinstall glibc-common
RUN yum -y clean all
RUN ln -s /dev/null /etc/systemd/system/getty@tty1.service &&\
    ln -s /dev/null /etc/systemd/system/serial-getty@ttyS0.service
VOLUME [ “/sys/fs/cgroup” ]
CMD ["/sbin/init"]
