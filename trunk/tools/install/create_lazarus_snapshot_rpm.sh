#!/usr/bin/env bash

set -x
set -e

#------------------------------------------------------------------------------
# parse parameters
#------------------------------------------------------------------------------
Usage="Usage: $0 <LazarusSrcDir>"

LazSrcDir=$1
shift
if [ "x$LazSrcDir" = "x" ]; then
  echo $Usage
  exit -1
fi

if [ ! -d $LazSrcDir/lcl ]; then
  echo "The directory $LazSrcDir does not look like a lazarus source directory"
  exit -1
fi

if [ ! -d $LazSrcDir/.svn ]; then
  echo "The directory $LazSrcDir does not look like a svn working directory"
  exit -1
fi



Date=`date +%Y%m%d`
# get fpc snapshot rpm
FPCRPM=~/rpmbuild/RPMS/i586/fpc-2.1.1-$Date.i586.rpm
if [ ! -f $FPCRPM ]; then
  echo ERROR: fpc rpm $FPCRPM not available
  exit
fi

User=`whoami`
TmpFPCDir=/tmp/$User/fpc
if [ -e $TmpFPCDir ]; then
  rm -rf $TmpFPCDir
fi 
mkdir -p $TmpFPCDir
cd $TmpFPCDir
rpm2cpio $FPCRPM | cpio -id 
FPCVersion=`usr/bin/fpc -iV`
usr/lib/fpc/$FPCVersion/samplecfg $TmpFPCDir/usr/lib/fpc/$FPCVersion .
FPCCfg=$TmpFPCDir/fpc.cfg
export FPCCfg
FPC=$TmpFPCDir/usr/bin/fpc
export FPC
cd -

# create a temporary copy of the lazarus sources for packaging
LazVersion=0.9.9
LazRelease=`echo $FPCRPM | sed -e 's/-/_/g'`
TmpDir=/tmp/lazarus

rm -rf $TmpDir
echo "extracting Lazarus source from local svn ..."
svn export $LazSrcDir $TmpDir

# create a source tar.gz
cd $TmpDir/..
tar -czf ~/rpmbuild/SOURCES/lazarus-$LazVersion-$Date.tar.gz lazarus

# remove the tempdir
cd -
rm -rf $TmpDir

# create spec file
SpecFile=~/rpmbuild/SPECS/lazarus-$LazVersion-$Date.spec
cat rpm/lazarus.spec.template | \
  sed -e "s/LAZVERSION/$LazVersion/g" \
      -e "s/LAZRELEASE/$Date/g" \
      -e "s/FPCVERSION/$FPCVersion/g" \
  > $SpecFile
#      -e "s/FPCSRCVERSION/$FPCRPMVersion/" \

# build rpm
rpmbuild -ba $SpecFile

rm -rf $TmpFpcDir

# end.

