#!/bin/bash

### Set initial time of file
LTIME=`stat -c %Z ./main.cpp ./camera.cpp ./events.cpp ./camera.h ./events.h ./vertex.glsl ./fragment.glsl`
echo "watching..."
while true    
do
   ATIME=`stat -c %Z ./main.cpp ./camera.cpp ./events.cpp ./camera.h ./events.h ./vertex.glsl ./fragment.glsl`

   if [[ "$ATIME" != "$LTIME" ]]
   then
      echo "change detected"
      LTIME=$ATIME
      ./compile.sh
      echo "compiled successfully"
   fi
   sleep 1
done