#!/bin/bash

7za x Desktop_Qt_6_5_3_GCC_64bit-Debug.7z

cd Desktop_Qt_6_5_3_GCC_64bit-Debug

mkdir -p lib

cp ../libWorks/* lib/

chmod a+x ./RaccoonLine

echo "Script execution completed successfully."