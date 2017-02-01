#!/bin/bash

usage()
{
    echo -e ""
    echo -e ${txtbld}"Usage:"${txtrst}
    echo -e "  build-deathly.sh [options] device"
    echo -e ""
    echo -e ${txtbld}"  Options:"${txtrst}
    echo -e "    -c# Cleanin options before build:"
    echo -e "        1 - make deathly"
    echo -e "        2 - make clean"
    echo -e "        3 - make dirty"
    echo -e "        4 - make magic"
    echo -e "        5 - make kernelclean"
    echo -e "    -d  Use dex optimizations"
    echo -e "    -i  Static Initlogo"
    echo -e "    -j# Set jobs"
    echo -e "    -p  Build using pipe"
    echo -e "    -z  create build log in 'build-logs'"
    echo -e ""
    echo -e ${txtbld}"  Example:"${txtrst}
    echo -e "    ./build-deathly.sh -p -o3 -j18 klimtlte"
    echo -e ""
#    sleep 10
#    exit 1
}

# colors
. ./vendor/ld/tools/colors

if [ ! -d ".repo" ]; then
    echo -e ${red}"No .repo directory found.  Is this an Android build tree?"${txtrst}
    exit 1
fi
if [ ! -d "vendor/ld" ]; then
    echo -e ${red}"No vendor/ld directory found.  Is this an Liquid Death build tree?"${txtrst}
    exit 1
fi

# figure out the output directories
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
thisDIR="${PWD##*/}"

findOUT() {
if [ -n "${OUT_DIR_COMMON_BASE+x}" ]; then
return 1; else
return 0
fi;}

findOUT
RES="$?"

if [ $RES = 1 ];then
    export OUTDIR=$OUT_DIR_COMMON_BASE/$thisDIR
    echo -e ""
    echo -e ${cya}"External out DIR is set ($OUTDIR)"${txtrst}
    echo -e ""
elif [ $RES = 0 ];then
    export OUTDIR=$DIR/out
    echo -e ""
    echo -e ${cya}"No external out, using default ($OUTDIR)"${txtrst}
    echo -e ""
else
    echo -e ""
    echo -e ${red}"NULL"${txtrst}
    echo -e ${red}"Error wrong results"${txtrst}
    echo -e ""
fi

# get OS (linux / Mac OS x)
IS_DARWIN=$(uname -a | grep Darwin)
if [ -n "$IS_DARWIN" ]; then
    CPUS=$(sysctl hw.ncpu | awk '{print $2}')
    DATE=gdate
else
    CPUS=$(grep "^processor" /proc/cpuinfo | wc -l)
    DATE=date
fi

export USE_CCACHE=1

opt_clean=0
opt_dex=0
opt_initlogo=0
opt_jobs="$CPUS"
opt_log=0
opt_pipe=0
opt_verbose=0

while getopts "c:dij:psfo:z" opt; do
    case "$opt" in
    c) opt_clean="$OPTARG" ;;
    d) opt_dex=1 ;;
    i) opt_initlogo=1 ;;
    j) opt_jobs="$OPTARG" ;;
    p) opt_pipe=1 ;;
    z) opt_log=1 ;;
    *) usage
    esac
done
shift $((OPTIND-1))
if [ "$#" -ne 1 ]; then
    usage
fi
device="$1"

# Current Version (FIXME so its automatic)
VERSION="v1.0-DROWNING-FOREVER"

echo -e ${cya}"Building ${ppl}Liquid Death OS ${bldylw}$VERSION"${txtrst}

if [ "$opt_clean" -eq 1 ]; then
    echo -e ""
    echo -e ${bldblu}"Building Liquid Death OS"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 2 ]; then
    make clean >/dev/null
    echo -e ""
    echo -e ${bldblu}"Out is clean"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 3 ]; then
    make dirty >/dev/null
    echo -e ""
    echo -e ${bldblu}"Out is dirty"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 4 ]; then
    make magic >/dev/null
    echo -e ""
    echo -e ${bldblu}"Enjoy your magical adventure"${txtrst}
    echo -e ""
elif [ "$opt_clean" -eq 5 ]; then
    make kernelclean >/dev/null
    echo -e ""
    echo -e ${bldblu}"All kernel components have been removed"${txtrst}
    echo -e ""
fi

rm -f $OUTDIR/target/product/$device/obj/KERNEL_OBJ/.version

# get time of startup
t1=$($DATE +%s)

# setup environment
echo -e ${bldblu}"Setting up environment"${txtrst}
. build/envsetup.sh

# Remove system folder (this will create a new build.prop with updated build time and date)
rm -f $OUTDIR/target/product/$device/system/build.prop
rm -f $OUTDIR/target/product/$device/system/app/*.odex
rm -f $OUTDIR/target/product/$device/system/framework/*.odex

# initlogo
if [ "$opt_initlogo" -ne 0 ]; then
    export BUILD_WITH_STATIC_INITLOGO=true
fi

# lunch device
echo -e ""
echo -e ${bldblu}"Lunching device"${txtrst}
lunch "ld_$device-userdebug";

echo -e ""
echo -e ${bldblu}"Starting compilation"${txtrst}

# start compilation
if [ "$opt_dex" -ne 0 ]; then
    export WITH_DEXPREOPT=true
fi

if [ "$opt_pipe" -ne 0 ]; then
    export TARGET_USE_PIPE=true
fi

# make deathly
if [ "$opt_log" -ne 0 ]; then
    echo -e ""
    echo -e ${bldgrn}"Creating 'build-logs' directory if one hasn't been created already"${txtrst}
    echo -e ""
    # create 'build-logs' directory if it hasn't already been created
    mkdir -p build-logs
    echo -e ""
    echo -e ${bldgrn}"Your build will be logged in 'build-logs'"${txtrst}
    echo -e ""
    # log build into 'build-logs'
    make -j"$opt_jobs" deathly 2>&1 | tee build-logs/ld_$device-$(date "+%Y%m%d").txt
else
    # build normally
    make -j"$opt_jobs" deathly
fi

# cleanup unused built
rm -f $OUTDIR/target/product/$device/LD_*-ota*.zip

# finished? get elapsed time
t2=$($DATE +%s)

tmin=$(( (t2-t1)/60 ))
tsec=$(( (t2-t1)%60 ))

echo -e ${bldgrn}"Total time elapsed:${txtrst} ${grn}$tmin minutes $tsec seconds"${txtrst}