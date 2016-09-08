#!/bin/bash
case "$1" in
  "execansible" ) shift;common_execansible $*;;
  "preinstall" ) shift;common_preinstall $*;;
  "install_dbca" ) shift;common_install_dbca $*;;
  "startall" ) shift;common_startall $*;;
  "start" ) shift;common_start $*;;
  "stop" ) shift;common_stop $*;;
  "stopall" ) shift;common_stopall $*;;
  "download") shift;common_download $*;;
  "heatrun") shift;common_heatrun $*;;
  "runall" ) shift;common_runall $*;;
  "replaceinventory" ) shift;replaceinventory $*;;
  "run" ) shift;run $*;;
  "runonly" ) shift;runonly $*;;
  "deleteall" ) shift;deleteall $*;;
  "buildimage" ) shift;buildimage $*;;
esac
