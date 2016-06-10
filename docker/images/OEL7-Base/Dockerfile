FROM s4ragent/rac_on_xx:OEL7-init
MAINTAINER @s4r_agent
##enable epel
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
##installpackages
RUN touch /var/lib/rpm/* && yum --enablerepo=ol7_addons -y install oracle-rdbms-server-12cR1-preinstall tar unzip dnsmasq nfs-utils vnc-server xrdp git
RUN touch /var/lib/rpm/* && yum -y groupinstall "Server With GUI"
RUN touch /var/lib/rpm/* && yum -y reinstall glibc-common
RUN yum -y clean all
VOLUME [ “/sys/fs/cgroup” ]
CMD ["/sbin/init"]
