#!/bin/bash
source ../common.sh
MyNumber=`getmynumber`
mkdir -p /media

yum -y install unzip
gsutil cp $GOOGLESTORAGE$DB_MEDIA1 /media
gsutil cp $GOOGLESTORAGE$DB_MEDIA2 /media
gsutil cp $GOOGLESTORAGE$GRID_MEDIA1 /media
gsutil cp $GOOGLESTORAGE$GRID_MEDIA2 /media
unzip /media/$DB_MEDIA1 -d /media
unzip /media/$DB_MEDIA2 -d /media
unzip /media/$GRID_MEDIA1 -d /media
unzip /media/$GRID_MEDIA2 -d /media
touch /root/downloaded


