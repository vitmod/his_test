#! /bin/bash
###############
ANDROID_NDK=android-ndk-r13b
API=21
###############
SOURCEDIR="sources"
[ ! -d $SOURCEDIR ] && mkdir -p $SOURCEDIR
dir=`pwd`
cd $SOURCEDIR
sources=`pwd`
export PATH=${sources}/arm-linux-androideabi/bin:$PATH
CROSS=${sources}/arm-linux-androideabi/bin/arm-linux-androideabi-
export CROSS_SYSROOT=${sources}/arm-linux-androideabi/sysroot
export PKG_CONFIG_PATH=${CROSS_SYSROOT}/usr/lib/pkgconfig
export CFLAGS="-Os -march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -D__ANDROID_API__=${API} -fPIE"
export LDFLAGS="-march=armv7-a -Wl,--fix-cortex-a8 -Wl,-s -fPIE -pie"
export HISDK_INCLUDE=$dir/u5sdk/include
export HISDK_LIBRARY=$dir/u5sdk/lib
############
oscam_new(){
#SVN_REVISION=$(date +"%Y-%m-%d")
SVN_REVISION=$(date +"%m-%d-%Y-%H-%M-%S")
[ ! -e $sources/oscam_new_test ] && svn co -r 1542 https://github.com/oscam-emu/oscam-patched/trunk oscam_new_test;
cd $sources/oscam_new_test
[ ! -e $sources/oscam_new_test/module-dvbapi-his.c ] && patch -p0 < $dir/patches/sky_new_test.patch;
make clean
make config
make android-arm-hisky -j16 \
		CROSS=${CROSS} \
		USE_LIBCRYPTO=1 \
		USE_HISKY=1 \
		CONF_DIR="/data/oscam" \
		HISKY_LIB="-L$HISDK_LIBRARY -lhi_msp -lhi_common" \
		HISKY_FLAGS="-D__ARMEL__ -I$HISDK_INCLUDE -DWITH_HISILICON=1 -DSDKV600 -DSDKV660 -DSDK3798C"\
		OSCAM_VERSION_NUMBER=$SVN_REVISION

echo SVN_REVISION:$SVN_REVISION
cp -af Distribution/oscam-1.20.sky.$SVN_REVISION $dir
### diff ###
# svn st
# svn add cscrypt/aes_ctx.c cscrypt/aes_ctx.h cscrypt/des_ssl.c cscrypt/des_ssl.h csctapi/ifd_hisky.c csctapi/ifd_hisky.h module-constcw.h module-dvbapi-his.c module-dvbapi-his.h
# svn diff > ../../sky_new_test_$(date +"%m-%d-%Y-%H-%M-%S").patch
cp $dir/oscam-1.20.sky.$SVN_REVISION $dir/oscam
zip -j $dir/oscam-armeabi-v7a.zip -xi $dir/oscam
rm -rf $dir/oscam
}
############
oscam_old(){
[ ! -e $sources/oscam_old_10670 ] && svn co -r 10670 http://www.streamboard.tv/svn/oscam/trunk oscam_old_10670;
cd $sources/oscam_old_10670
[ ! -e $sources/oscam_old_10670/module-dvbapi-his.c ] && patch -p0 < $dir/patches/sky_old_10670.patch;
make clean
make config
make android-arm-hisky -j16 \
		USE_HISKY=1 \
		CONF_DIR="/data/oscam" \
		HISKY_LIB="-L$HISDK_LIBRARY -lhi_msp -lhi_common" \
		HISKY_FLAGS="-D__ARMEL__ -I$HISDK_INCLUDE -DWITH_HISILICON=1 -DSDKV600 -DSDKV660 -DSDK3798C"

SVN_REVISION=`./config.sh --oscam-revision`
echo SVN_REVISION:$SVN_REVISION
cp -af Distribution/oscam-1.20.sky.$SVN_REVISION $dir
}
###################
### android ndk ###
if [ ! -d ${sources}/arm-linux-androideabi ] ; then
[ ! -e ${ANDROID_NDK}-linux-x86_64.zip ] && wget -c https://dl.google.com/android/repository/${ANDROID_NDK}-linux-x86_64.zip;
[ ! -d ${ANDROID_NDK} ] && unzip ${ANDROID_NDK}-linux-x86_64.zip;
#########################
### android toolchain ###
${sources}/${ANDROID_NDK}/build/tools/make-standalone-toolchain.sh --arch=arm --install-dir=${sources}/arm-linux-androideabi --platform=android-${API} --toolchain=arm-linux-androideabi-4.9
#################################
### toolchain patch oscam old ###
if [ ! -e ${sources}/arm-linux-androideabi/system_propertieso.h.patch  ] ; then
echo '@@ -48,7 +48,7 @@' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo ' ' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo ' /* Set a system property by name.' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo ' **/' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo '-int __system_property_set(const char *key, const char *value);' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo '+//int __system_property_set(const char *key, const char *value);' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo ' ' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo ' /* Return a pointer to the system property named name, if it' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
echo ' ** exists, or NULL if there is no such property.  Use ' >> ${sources}/arm-linux-androideabi/system_propertieso.h.patch 
patch -p1 < ${sources}/arm-linux-androideabi/system_propertieso.h.patch  ${sources}/arm-linux-androideabi/sysroot/usr/include/sys/system_properties.h
fi
###
rm -rf $ANDROID_NDK
fi
###########################
### libcrypto oscam new ###
if [ ! -e $PKG_CONFIG_PATH/openssl.pc ] ; then
[ ! -e openssl-1.1.0i.tar.gz ] && wget -c http://www.openssl.org/source/openssl-1.1.0i.tar.gz;
[ ! -d openssl-1.1.0i ] && tar -xf openssl-1.1.0i.tar.gz;
cd openssl-1.1.0i
CC=${CROSS}gcc LD=${CROSS}ld AR=${CROSS}ar STRIP=${CROSS}strip RANLIB=${CROSS}ranlib ./Configure android -march=armv7-a --prefix=${CROSS_SYSROOT}/usr -D__ANDROID_API__=${API}
make install
cd ../
rm -rf openssl-1.1.0i*
rm -rf $CROSS_SYSROOT/usr/lib/libssl.so*
rm -rf $CROSS_SYSROOT/usr/lib/libcrypto.so*
fi
#########
menu(){
selected=$(dialog --stdout --clear --colors --backtitle $0 --title "Hisilicon OSCam" --menu "" 6 40 10 \
	new	"OSCam test" \
	old	"OSCam 10670");
case $selected in
	new)oscam_new;; # patches/sky_new_test.patch
	old)oscam_old;; # patches/sky_old_10670.patch
	esac
#clear && exit;
}
#oscam_new
menu
#########
exit;
#################################################
#     https://github.com/dizzdizzy/HiOSCAM      #
#################################################
