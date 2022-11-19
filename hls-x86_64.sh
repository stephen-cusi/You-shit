#!/bin/sh

mkdir $HOME/.android && cp debug.keystore $HOME/.android

sudo apt-get update
sudo apt install -y make unzip python3 ccache imagemagick openjdk-8-jdk openjdk-8-jre ant-contrib sshpass python3-websocket python3-pip
pip install vpk
wget https://dl.google.com/android/repository/android-ndk-r10e-linux-x86_64.zip -o /dev/null
unzip android-ndk-r10e-linux-x86_64.zip > /dev/null
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/clang+llvm-11.1.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz -o /dev/null
tar xvf clang+llvm-11.1.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz > /dev/null
mv clang+llvm-11.1.0-x86_64-linux-gnu-ubuntu-16.04 clang/
export PATH=$(pwd)/clang/bin:$PATH

mv android-ndk-r10e ndk/
export ANDROID_NDK_HOME=$(pwd)/ndk

git clone --depth 1 https://github.com/nillerusr/source-engine/ --recursive
git clone --depth 1 https://gitlab.com/LostGamer/android-sdk
export ANDROID_HOME=$(pwd)/android-sdk/
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/

mkdir -p libs/ apks/
git clone --depth 1 https://github.com/nillerusr/srceng-mod-launcher

#build()
#{
	MOD_NAME=hl1
	MOD_VER=1
	APP_NAME=Half-life Source
	VPK_NAME=extras_dir.vpk
	VPK_VERSION=1

	cd source-engine/
	./waf configure -T release --android=x86_64,host,21 -8 --prefix=android/ --togles --build-game=hl1 --use-ccache --disable-warns || (cat build/config.log;exit)
	./waf install --target=client,server || exit
	mkdir -p ../libs/hl1

	cp android/lib/arm64-v8a/libserver.so ../libs/hl1/
	cp android/lib/arm64-v8a/libclient.so ../libs/hl1/
	rm -rf android/

	cd ../srceng-mod-launcher/
	git checkout .
	sed -e "s/MOD_REPLACE_ME/hl1/g" -i AndroidManifest.xml src/me/nillerusr/LauncherActivity.java
	sed -e "s/APP_NAME/Half-life Source/g" -i res/values/strings.xml
	sed -e "s/1.05/1/g" -i AndroidManifest.xml
#	sed -e 's/"com.valvesoftware.source"/"com.valvesoftware.source64"/g' -i src/me/nillerusr/LauncherActivity.java

	scripts/conv.sh ../resources/hl1/ic_launcher.png

	mkdir -p libs/arm64-v8a/
	cp ../libs/hl1/libserver.so ../libs/hl1/libclient.so libs/arm64-v8a

	if ! [ -z extras_dir.vpk ];then
		mkdir -p assets
		vpk -c ../resources/hl1/vpk assets/extras_dir.vpk
#		cp ../resources/hl1/extras_dir.vpk assets/
		sed -e "s/PACK_NAME/extras_dir.vpk/g" -i src/me/nillerusr/ExtractAssets.java
		sed -e "s/1337/1/g" -i src/me/nillerusr/ExtractAssets.java
	fi

	ant debug &&