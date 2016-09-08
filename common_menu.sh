#!/bin/bash
case "$1" in
  "execansible" ) shift;common_execansible $*;;
  "preinstall" ) shift;common_preinstall $*;;
  "install_dbca" ) shift;common_install_dbca $*;;
  "run" ) shift;common_run $*;;
  "startall" ) shift;common_startall $*;;
  "start" ) shift;common_start $*;;
  "stop" ) shift;common_stop $*;;
  "stopall" ) shift;common_stopall $*;;
  "download") shift;common_download $*;;
  "heatrun") shift;common_heatrun $*;;
  "replaceinventory" ) shift;replaceinventory $*;;
  "runonly" ) shift;runonly $*;;
  "runall" ) shift;runall $*;;
  "delete" ) shift;delete $*;;
  "deleteall" ) shift;deleteall $*;;
  "buildimage" ) shift;buildimage $*;;
esac
