#!/bin/bash

export NDK_ROOT=/home/dev/android-ndk
export BUILD_DIR=$(pwd)

function setup_toolchain() {
	printf '\nBuilding NDK cross-compiler toolchain for "'$PLATFORM'"...\n'
	
	export TOOLCHAIN=$BUILD_DIR/toolchain'_'$PLATFORM
	export ANDROID_SYSROOT=$TOOLCHAIN/sysroot
	export CROSS_COMPILE="$CROSS_COMPILE-"
	export CFLAGS="--sysroot=$ANDROID_SYSROOT -I$ANDROID_SYSROOT/usr/include -I$TOOLCHAIN/include"
	export LDFLAGS="--sysroot=$ANDROID_SYSROOT -L$ANDROID_SYSROOT/usr/lib -L$TOOLCHAIN/lib"
	export CFLAGS="$CFLAGS -O3 -DNDEBUG -fPIC -static"
	export LDFLAGS="$LDFLAGS -fPIC -pie -static"
	export CPPFLAGS="$CFLAGS"
	export CXXFLAGS="$CFLAGS"		
	
	export CC=$TOOLCHAIN/bin/$CROSS_TOOL-clang
	export CPP=$TOOLCHAIN/bin/$CROSS_TOOL-cpp
	export AR=$TOOLCHAIN/bin/$CROSS_TOOL-ar
	export AS=$TOOLCHAIN/bin/$CROSS_TOOL-as
	export NM=$TOOLCHAIN/bin/$CROSS_TOOL-nm
	export CXX=$TOOLCHAIN/bin/$CROSS_TOOL-clang++
	export LD=$TOOLCHAIN/bin/$CROSS_TOOL-ld.gold
	export RANLIB=$TOOLCHAIN/bin/$CROSS_TOOL-ranlib
	export NM=$TOOLCHAIN/bin/$CROSS_TOOL-nm	
	
	cd $NDK_ROOT/build/tools
	./make_standalone_toolchain.py --arch $PLATFORM --api 21 --install-dir $TOOLCHAIN	
}

function remove_toolchains(){
	printf '\nRemoving all toolchains from '$BUILD_DIR'...\n'
	rm -dfr $BUILD_DIR/toolchain_*
}

function build_zlib() {
	printf '\nBuilding zlib...\n'
	cd $BUILD_DIR
	cd zlib-1.2.11
	./configure --prefix=$TOOLCHAIN/sysroot/usr
	make clean
	make
	make install
	make clean
}

function build_openssl() {
	printf '\nBuilding openssl...\n'
	cd $BUILD_DIR
	cd openssl-1.1.0j
	./Configure linux-generic32 no-dso no-shared no-unit-test no-hw no-engine --prefix=$TOOLCHAIN/sysroot/usr --sysroot=$ANDROID_SYSROOT --openssldir=$TOOLCHAIN/sysroot/usr
	make clean 
	make depend build_libs
	make install_dev
	make clean
}

function build_curl(){
	printf '\nBuilding curl...\n'
	cd $BUILD_DIR
	cd curl-7.59.0
	./configure --prefix=$TOOLCHAIN/sysroot/usr --target=$CROSS_TOOL --host=$CROSS_TOOL --with-zlib=$TOOLCHAIN/sysroot/usr --with-ssl=$TOOLCHAIN/sysroot/usr
	make clean
	make
	make install
	make clean
}

function build_libevent(){
	printf '\nBuilding libevent...\n'
	cd $BUILD_DIR
	cd libevent-2.1.8-stable
	./configure --host=$CROSS_TOOL --prefix=$TOOLCHAIN/sysroot/usr --enable-function-sections --enable-shared=no --disable-openssl --disable-debug-mode --disable-libevent-regress --disable-samples --disable-clock-gettime
	make clean
	make
	make install
	make clean
}

function build_transmission(){
	printf '\nBuilding transmission...\n'
	cd $BUILD_DIR/..
	./configure --host=$CROSS_TOOL --prefix=$TOOLCHAIN/sysroot/usr --without-gtk --disable-libnotify --disable-mac --disable-wx --disable-beos --enable-utp --disable-nls --enable-inotify --enable-lightweight --enable-cli --enable-daemon --with-zlib=$TOOLCHAIN/sysroot/usr PKG_CONFIG="/usr/bin/pkg-config" PKG_CONFIG_PATH="$TOOLCHAIN/sysroot/usr/lib/pkgconfig"
	make clean
	make
	make install
	make clean
	readelf -d $ANDROID_SYSROOT/usr/bin/transmission-daemon
}

function pause(){
	read -n1 -r -p "Operation is finished, press any key to continue..."
}

function show_build_menu(){
	while true; do
		tput reset
		printf 'PLATFORM : '$PLATFORM'\n'
		printf 'CROSS_COMPILER : '$CROSS_TOOL'\n'
		printf 'NDK_ROOT : '$NDK_ROOT'\n'
		printf 'BUILD_DIR : '$BUILD_DIR'\n\n'
		printf '  [1] Build all (dependencies + transmission)\n'
		printf '  [2] Build only zlib\n'
		printf '  [3] Build only openssl\n'
		printf '  [4] Build only curl\n'
		printf '  [5] Build only libevent\n'
		printf '  [6] Build only transmission\n'
		printf '  [0] Back\n\n'
		read -n1 -r -p "Select option : " key

		if [ "$key" = '1' ]; then
			build_zlib
			build_openssl
			build_curl
			build_libevent
			build_transmission
			pause
		elif [ "$key" = '2' ]; then
			build_zlib
			pause
		elif [ "$key" = '3' ]; then
			build_openssl
			pause
		elif [ "$key" = '4' ]; then
			build_curl
			pause
		elif [ "$key" = '5' ]; then
			build_libevent
			pause
		elif [ "$key" = '6' ]; then
			build_transmission
			pause
		elif [ "$key" = '0' ]; then
			break
		fi
	done	
}

while true; do
	tput reset
	printf 'NDK_ROOT : '$NDK_ROOT'\n'
	printf 'BUILD_DIR : '$BUILD_DIR'\n\n'
	printf '  [1] Build toolchain for ARM\n'
	printf '  [2] Build toolchain for X86\n'
	printf '  [3] Remove all toolchains\n'
	printf '  [0] Exit\n\n'
	read -n1 -r -p "Select option : " key

	if [ "$key" = '1' ]; then
		export PLATFORM=arm
		export CROSS_TOOL=arm-linux-androideabi
		setup_toolchain
		pause
		show_build_menu

	elif [ "$key" = '2' ]; then
		export PLATFORM=x86
		export CROSS_TOOL=i686-linux-android
		setup_toolchain
		pause
		show_build_menu
		
	elif [ "$key" = '3' ]; then
		remove_toolchains
		pause	

	elif [ "$key" = '0' ]; then
		tput reset
		exit 1
	fi
done

tput reset
