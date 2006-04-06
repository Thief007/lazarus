#!/usr/bin/env bash

set -e

PPCARCH=ppcppc
SVN=/usr/local/bin/svn
FREEZE=/usr/bin/freeze
HDIUTIL=/usr/bin/hdiutil
UPDATELIST=~/tmp/updatelist

TEMPLATEDIR=~/src/lazarus/tools/install/macosx

FPCSVNDIR=~/src/fpc/build
FPCSOURCEDIR=$FPCSVNDIR/fpcsrc
PPC_RELEASE=/usr/local/lib/fpc/2.0.2/$PPCARCH
BUILDDIR=~/tmp/build
FPCBUILDDIR=$BUILDDIR/fpc
INSTALLDIR=~/tmp/fpc
INSTALLFPCDIR=~/fpc

DATESTAMP=`date +%Y%m%d`
FPCPACKPROJ=fpc.packproj

cd $FPCSVNDIR
$SVN update 

if [ ! -d $BUILDDIR ] ; then
  mkdir -p $BUILDDIR
else
  if [ -d $FPCBUILDDIR ] ; then
    rm -rf $FPCBUILDDIR 
  fi
fi

$SVN export $FPCSVNDIR $FPCBUILDDIR  
$SVN export $FPCSVNDIR/fpcsrc $FPCBUILDDIR/fpcsrc
$SVN export $FPCSVNDIR/fpcdocs $FPCBUILDDIR/fpcdocs

cd $FPCBUILDDIR
make distclean PP=$PPC_RELEASE
make build PP=$PPC_RELEASE

COMPILER=$FPCBUILDDIR/fpcsrc/compiler/$PPCARCH
FPCVERSION=`$COMPILER -iV`
FPCARCH=`$COMPILER -iSP`

# clean installdir: since I am not root and the install dir can contain files owned by root 
# created by a previous freeze, I just move it out of the way
if [ ! -d /tmp/vsnijders/trash ] ; then
  mkdir -p /tmp/vsnijders/trash
fi
rm -rf $INSTALLDIR
if [ -d $INSTALLDIR ]; then
  mv $INSTALLDIR /tmp/vsnijders/trash/
fi
mkdir -p $INSTALLDIR
make install PP=$COMPILER INSTALL_PREFIX=$INSTALLDIR

# create symlink using relative paths, make symlinkinstall uses absolute path, 
# which then ends up as link to the temporary build path
# on the user's machine after installation
ln -sf ../lib/fpc/$FPCVERSION/ppcppc $INSTALLDIR/bin/$PPCARCH

# install for use by lazarus
cd fpcsrc
make compiler_install rtl_install fcl_install packages_install utils_install \
  INSTALL_PREFIX=$INSTALLFPCDIR PP=$COMPILER FPCMAKE=$FPCBUILDDIR/fpcsrc/utils/fpcm/fpcmake
make -C compiler installsymlink PP=$COMPILER INSTALL_PREFIX=$INSTALLFPCDIR


# fill in packproj template.
OLDIFS=$IFS
IFS=.
FPCMAJORVERSION=`set $FPCVERSION;  echo $1`
FPCMINORVERSION=`set $FPCVERSION;  echo $2$3`
IFS=$OLDIFS
sed -e "s|_PPCARCH_|$PPCARCH|g" -e "s|_FPCSRCDIR_|$FPCSVNDIR|g" -e "s|_FPCVERSION_|$FPCVERSION|g" \
  -e "s|_DATESTAMP_|$DATESTAMP|g" -e s/_FPCMAJORVERSION_/$FPCMAJORVERSION/g -e s/_FPCMINORVERSION_/$FPCMINORVERSION/g \
  $TEMPLATEDIR/$FPCPACKPROJ.template  > $INSTALLDIR/$FPCPACKPROJ

# build package
$FREEZE -v $INSTALLDIR/$FPCPACKPROJ

DMGFILE=~/pkg/fpc-$FPCVERSION-$DATESTAMP-$FPCARCH-macosx.dmg
rm -rf $DMGFILE

$HDIUTIL create -anyowners -volname fpc-$FPCVERSION -imagekey zlib-level=9 -format UDZO -srcfolder $INSTALLDIR/build $DMGFILE

if [ -e $DMGFILE ]; then
#update lazarus snapshot web page
  echo "$DMGFILE fpc-*-*-$FPCARCH-macosx.dmg" >> $UPDATELIST
fi
