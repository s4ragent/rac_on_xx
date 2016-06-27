#!/bin/bash
source ../common.sh
mkdir -p /media

if [ -e /etc/debian_version ]; then
  apt-get install -y unzip
elif [ -e /etc/redhat-release ]; then
  yum -y install unzip
fi


gsutil cp $GOOGLESTORAGE$DB_MEDIA1 /media
gsutil cp $GOOGLESTORAGE$DB_MEDIA2 /media
gsutil cp $GOOGLESTORAGE$GRID_MEDIA1 /media
gsutil cp $GOOGLESTORAGE$GRID_MEDIA2 /media
unzip /media/$DB_MEDIA1 -d /media
unzip /media/$DB_MEDIA2 -d /media
unzip /media/$GRID_MEDIA1 -d /media
unzip /media/$GRID_MEDIA2 -d /media
touch /root/downloaded


