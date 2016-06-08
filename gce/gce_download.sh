#!/bin/bash
source ../common.sh
MyNumber=`getmynumber`
mkdir -p /media
if [ "$MyNumber" = "1" ] ; then
  if [ ! -e /root/downloaded ] ; then
    yum -y install unzip
    gsutil cp $GoogleStorage$DB_MEDIA1 /media
    gsutil cp $GoogleStorage$DB_MEDIA2 /media
    gsutil cp $GoogleStorage$GRID_MEDIA1 /media
    gsutil cp $GoogleStorage$GRID_MEDIA2 /media
    unzip /media/$DB_MEDIA1 -d /media
    unzip /media/$DB_MEDIA2 -d /media
    unzip /media/$GRID_MEDIA1 -d /media
    unzip /media/$GRID_MEDIA2 -d /media
    touch /root/downloaded
  fi
fi

