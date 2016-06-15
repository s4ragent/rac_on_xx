FROM oraclelinux:7
MAINTAINER @s4r_agent
##enable epel
#RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
##installpackages
#RUN touch /var/lib/rpm/* && yum --enablerepo=ol7_addons -y install oracle-rdbms-server-12cR1-preinstall tar unzip dnsmasq nfs-utils vnc-server xrdp git
#RUN touch /var/lib/rpm/* && yum -y groupinstall "Server With GUI"
#RUN touch /var/lib/rpm/* && yum -y reinstall glibc-common
#RUN yum -y clean all
#RUN ln -s /dev/null /etc/systemd/system/getty@tty1.service &&\
#    ln -s /dev/null /etc/systemd/system/serial-getty@ttyS0.service
#VOLUME [ “/sys/fs/cgroup” ]
#CMD ["/sbin/init"]
ENV container docker
##enable epel
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
##installpackages
RUN touch /var/lib/rpm/* && yum --enablerepo=ol7_addons -y install oracle-rdbms-server-12cR1-preinstall tar unzip dnsmasq nfs-utils vnc-server xrdp git
RUN touch /var/lib/rpm/* && yum -y groupinstall "Server With GUI"
RUN touch /var/lib/rpm/* && yum -y reinstall glibc-common
RUN yum -y clean all
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;\
ln -s /usr/lib/systemd/system/systemd-user-sessions.service  /etc/systemd/system/multi-user.target.wants/systemd-user-sessions.service;\
chmod u+s /usr/bin/ping;\
ln -s /dev/null /etc/systemd/system/getty@tty1.service;\
ln -s /dev/null /etc/systemd/system/serial-getty@ttyS0.service
VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]
