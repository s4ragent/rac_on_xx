#!/bin/bash
source ./common.sh
MyNumber=`getmynumber`
if [ "$MyNumber" = "1" ] ; then
	rm -rf $WORK/id_rsa*
	rm -rf $WORK/known_hosts
	ssh-keygen -t rsa -P "" -f $WORK/id_rsa

	CNT=1
	for i in $NODE_LIST; do
	      	nodename=`getnodename $CNT`
      		nodeip=`getip 0 real $CNT`

		while [ ! -e $WORK/$nodename ]
		do
			sleep 10
		done

      		ssh-keyscan -T 180 -t rsa $nodename >> $WORK/known_hosts
      		ssh-keyscan -T 180 -t rsa ${nodename}.${DOMAIN_NAME} >> $WORK/known_hosts
      		ssh-keyscan -T 180 -t rsa $nodeip >> $WORK/known_hosts
      		CNT=`expr $CNT + 1`
	done
	touch $WORK/ssheydone
else
	while [ ! -e $WORK/ssheydone ]
	do
		sleep 10
	done
fi

for user in oracle grid
do
	rm -rf /home/$user/.ssh
        mkdir /home/$user/.ssh
        cat $WORK/id_rsa.pub  >> /home/$user/.ssh/authorized_keys
        cp $WORK/id_rsa /home/$user/.ssh/id_rsa
        cp $WORK/known_hosts /home/$user/.ssh/known_hosts
        chown -R ${user}.oinstall /home/$user/.ssh
        chmod 700 /home/$user/.ssh
        chmod 600 /home/$user/.ssh/*
done
if [ ! -e  /root/.ssh/authorized_keys ]; then
  mkdir -p /root/.ssh
fi
cat $WORK/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
chmod 700 /root/.ssh
  
