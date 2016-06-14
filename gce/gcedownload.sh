#!/bin/bash
source ../common.sh
mkdir -p $DOWNLOADPATH

yum -y install unzip
gsutil cp $GOOGLESTORAGE$DB_MEDIA1 $DOWNLOADPATH
gsutil cp $GOOGLESTORAGE$DB_MEDIA2 $DOWNLOADPATH
gsutil cp $GOOGLESTORAGE$GRID_MEDIA1 $DOWNLOADPATH
gsutil cp $GOOGLESTORAGE$GRID_MEDIA2 $DOWNLOADPATH
unzip /media/$DB_MEDIA1 -d $DOWNLOADPATH
unzip /media/$DB_MEDIA2 -d $DOWNLOADPATH
unzip /media/$GRID_MEDIA1 -d $DOWNLOADPATH
unzip /media/$GRID_MEDIA2 -d $DOWNLOADPATH
touch /root/downloaded


