#! /bin/bash


PLUGIN=NUFraw

gimplibdir=$(pkg-config --variable=gimplibdir gimp-2.0)
echo "gimplibdir: $gimplibdir"
if [ -z "$gimplibdir" ]; then exit 1; fi

export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH"


mkdir -p /work/build || exit 1
cd /work/build || exit 1


yum install -y gnome-common exiv2-devel lensfun-devel

if [ ! -e gtkimageview ]; then
	(git clone https://github.com/aferrero2707/gtkimageview.git) || exit 1
fi
(cd gtkimageview && patch -N -p0 < /sources/${PLUGIN}/gtkimageview-Werror.patch && \
 ./autogen.sh --prefix=/usr/local && make -j 2 install) || exit 1
 
if [ ! -e nufraw-0.42 ]; then
	(wget https://launchpad.net/~dhor/+archive/ubuntu/myway/+sourcefiles/nufraw/0.42-1dhor~xenial/nufraw_0.42.orig.tar.xz && \
	 tar xvf nufraw_0.42.orig.tar.xz) || exit 1
fi
(cd nufraw-0.42 && ./autogen.sh && \
./configure --enable-contrast --prefix=/usr/local && make -j 2 install) || exit 1

echo "xxxxxxxxxxxx" > /tmp/commit-${PLUGIN}-new.hash



source /work/appimage-helper-scripts/functions.sh

# copy the list of libraries that have to be excluded from the bundle
export APPROOT=/work/${PLUGIN}-plugin
export APP="${PLUGIN}"
export APPDIR="${APPROOT}/$APP.AppDir"
(rm -rf "${APPROOT}" && mkdir -p "${APPROOT}/$APP.AppDir") || exit 1
cp /work/appimage-helper-scripts/excludelist "${APPROOT}"


# enter the AppImage bundle
mkdir -p "$APPDIR/${PLUGIN}/plug-ins"
cd "$APPDIR/${PLUGIN}" || exit 1
cp -a /usr/local/lib/gimp/2.0/plug-ins/nufraw-gimp plug-ins
#cp -a "$gimplibdir/plug-ins"/nufraw-gimp plug-ins

copy_deps2; copy_deps2; copy_deps2;


# Remove unneeded libraries
delete_blacklisted2


cd "$APPDIR/${PLUGIN}" || exit 1
mkdir -p scripts || exit 1
cp -a "${STARTUP_SCRIPT}" scripts/startup.sh || exit 1

echo "export GIMP_NUFRAW_PLUGIN_EXISTS=1" > scripts/set_exists.sh
echo "if [ x\"${GIMP_NUFRAW_PLUGIN_EXISTS}\" = \"x1\" ]; then exit 1; fi; exit 0;" > scripts/check_exists.sh


cd "$APPDIR/${PLUGIN}/usr/lib" || exit 1
for L in $(find . -name "*.so*"); do

	echo "checking $GIMP_PREFIX/lib/$L"
	if [ -e "$GIMP_PREFIX/lib/$L" ]; then
		echo "rm -f $L"
		rm -f "$L"
	fi

done


cd "${APPDIR}" || exit 1
cp -a "${APPRUN_SCRIPT}" AppRun || exit 1
cp -a "${DESKTOP_FILE}" ${PLUGIN}.desktop || exit 1
cp -a "${ICON_FILE}" ${PLUGIN}.png || exit 1




# Go out of AppImage
cd ..

echo "Building AppImage..."
pwd
rm -rf ../out

export VERSION=0.1.0
export ARCH="x86_64"
export NO_GLIBC_VERSION=true
export DOCKER_BUILD=true
generate_type2_appimage

mkdir -p /sources/out
cp -a ../out/*.AppImage /sources/out/${PLUGIN}-Gimp-2.10-linux.AppImage
cp -a /tmp/commit-${PLUGIN}-new.hash /sources/out/${PLUGIN}-Gimp-2.10-linux.hash
