#!/bin/bash

build=build

rm -rf ${build}
mkdir -p ${build}

# Set the BEEBASM executable for the platform
BEEBASM=beebasm.exe
if (uname -s | egrep -q "Linux|Darwin" ); then
    BEEBASM=beebasm
fi

ssd=life.ssd

# Create a blank SSD image
tools/mmb_utils/blank_ssd.pl build/${ssd}
echo

cd src
for top in  `ls top_*.asm`
do
    name=`echo ${top%.asm} | cut -c5-`
    echo "Building $name..."

    # Assember the ROM
    $BEEBASM \
        -i ${top} \
        -o ../${build}/${name} \
        -v \
        -dd \
        -labels ../${build}/${name}.labels \
        >& ../${build}/${name}.log

    # Check if ROM has been build, otherwise fail early
    if [ ! -f ../${build}/${name} ]
    then
        cat ../${build}/${name}.log
        echo "build failed to create ${name}"
        exit
    fi

    # Create the .inf file
    echo -e "\$."${name}"\t0400\t0400" > ../${build}/${name}.inf

    # Add into the SSD
    ../tools/mmb_utils/putfile.pl ../${build}/${ssd} ../${build}/${name}

    # Report end of code
    grep "code ends at" ../${build}/${name}.log

    # Report build checksum
    echo "    mdsum is "`md5sum <../${build}/${name}`
done
cd ..

# Add the patterns
cd patterns
for pattern in `ls *`
do
    # Copy the pattern into the R directory
    cp ${pattern} ../${build}/R.${pattern}

    # Create the .inf file
    echo -e "R."${pattern}"\t0000\t0000" > ../${build}/R.${pattern}.inf

    # Add into the SSD
    ../tools/mmb_utils/putfile.pl ../${build}/${ssd} ../${build}/R.${pattern}

done
cd ..


# Create the !boot file
echo -e -n "*RUN BLIFE\r" > ${build}/\!BOOT

# Add into the SSD
tools/mmb_utils/putfile.pl ${build}/${ssd} ${build}/\!BOOT

# Add a title
tools/mmb_utils/title.pl ${build}/${ssd} "Co Pro Life"

# Make bootable
tools/mmb_utils/opt4.pl ${build}/${ssd} 3

# List the disk
tools/mmb_utils/info.pl ${build}/${ssd}
