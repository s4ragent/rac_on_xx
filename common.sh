#!/bin/bash
parse_yaml(){
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

getmynumber()
{
	MyIp=`ip a show eth0 | grep "inet " | awk -F '[/ ]' '{print $6}'`
	LIST=`cat /etc/vxlan/all.ip`
	CNT=1
	for i in $LIST ;
	do
	      	if [ $i == $MyIp ]; then
	      		echo $CNT
	      		break
	      	fi
	      	CNT=`expr $CNT + 1`
	done
}

getnodename ()
{
  echo "$NODEPREFIX"`printf "%.3d" $1`
}

## $1 network number, $2 real/vip/priv $3 nodenumber           ### 
## Ex.   network 192.168.0.0 , 192.168.100.0  and BASE_IP=50 >>>##
## getip 0 vip 2 >>> 192.168.0.52 ###
getip ()
{
	SEGMENT=`echo ${NETWORKS[$1]} | grep -Po '\d{1,3}\.\d{1,3}\.\d{1,3}\.'`
	if [ $2 == "real" ] ; then
  		IP=`expr $BASE_IP + $3`
		echo "${SEGMENT}${IP}"
	elif [ $2 == "vip" ] ; then
		IP=`expr $BASE_IP + 100 + $3`
		echo "${SEGMENT}${IP}"
	elif [ $2 == "host" ] ; then
		IP=`expr $BASE_IP - 10 + $3`
		echo "${SEGMENT}${IP}"
	elif [ $2 == "scan" ] ; then
    		echo "${SEGMENT}`expr $BASE_IP - 20 ` ${SCAN_NAME}.${DOMAIN_NAME} ${SCAN_NAME}"
    		echo "${SEGMENT}`expr $BASE_IP - 20 + 1` ${SCAN_NAME}.${DOMAIN_NAME} ${SCAN_NAME}"
    		echo "${SEGMENT}`expr $BASE_IP - 20 + 2` ${SCAN_NAME}.${DOMAIN_NAME} ${SCAN_NAME}"
	fi
}


case "$1" in
  "getnodename" ) shift;getnodename $*;;
  "getip" ) shift;getip $*;;
  "getmynumber" ) shift;getmynumber $*;;
esac
