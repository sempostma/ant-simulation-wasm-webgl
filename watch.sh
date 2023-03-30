#!/bin/bash

### Set initial time of file
LTIME=`stat -c %Z ./main.cpp ./camera.cpp ./events.cpp ./camera.h ./events.h ./vertex.glsl ./fragment.glsl`

while true    
do
   ATIME=`stat -c %Z ./main.cpp ./camera.cpp ./events.cpp ./camera.h ./events.h ./vertex.glsl ./fragment.glsl`

   if [[ "$ATIME" != "$LTIME" ]]
   then
      echo "run compiler"
      LTIME=$ATIME
      ./compile.sh
      echo "done"
   fi
   sleep 1
done