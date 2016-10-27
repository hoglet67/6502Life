#!/bin/bash

build=build

name=BLIFE

rm -rf ${build}
mkdir -p ${build}

# Set the BEEBASM executable for the platform
BEEBASM=../tools/beebasm/beebasm.exe
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    BEEBASM=../tools/beebasm/beebasm
fi

# Assemble the code 
cd src
$BEEBASM -i atom_life.asm -o ../${build}/${name} -v 2>&1 > ../${build}/${name}.log
cd ..

# Check if ROM has been built, if not then fail
if [ ! -f ${build}/${name} ]
then
    cat ${build}/${name}.log
    echo "build failed to create ${name}"
    exit
fi

# Report build checksum
echo "    mdsum is "`md5sum <${build}/${name}`

