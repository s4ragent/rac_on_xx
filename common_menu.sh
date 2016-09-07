#!/bin/bash
case "$1" in
  "execansible" ) shift;execansible $*;;
  "replaceinventory" ) shift;replaceinventory $*;;
  "runonly" ) shift;runonly $*;;
  "runall" ) shift;runall $*;;
  "preinstall" ) shift;preinstall $*;;
  "install_dbca" ) shift;install_dbca $*;;
  "run" ) shift;run $*;;
  "startall" ) shift;startall $*;;
  "start" ) shift;start $*;;
  "delete" ) shift;delete $*;;
  "deleteall" ) shift;deleteall $*;;
  "stop" ) shift;stop $*;;
  "stopall" ) shift;stopall $*;;
  "download") shift;download $*;;
  "heatrun") shift;heatrun $*;;
esac