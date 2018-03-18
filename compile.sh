#!/usr/bin/env bash

# install basic stuff required for compilation
sudo yum-config-manager --enable epel
sudo yum install git autoconf ccache nasm libffi-devel libmpc-devel mpfr-devel \
	gmp-devel libicu-devel icu python34-devel google-crosextra-caladea-fonts \
	google-crosextra-carlito-fonts liberation-serif-fonts liberation-sans-fonts \
	mesa-libGL-devel mesa-libGLU-devel libX11-devel libXext-devel libICE-devel \
	libSM-devel libXrender-devel libxslt-devel gperf fontconfig-devel libpng-devel libxslt-devel \
	expat-devel libcurl-devel nss-devel nspr-devel libSM-devel openssl-devel expat-devel.x86_64 -y
sudo yum groupinstall "Development Tools" -y

# clone libreoffice sources
git clone --depth=1 git://anongit.freedesktop.org/libreoffice/core libreoffice
cd libreoffice

# set this cache if you are going to compile several times
ccache --max-size 16 G && ccache -s

# the most important part. Run ./autogen.sh --help to see wha each option means
./autogen.sh --disable-report-builder --disable-lpsolve --disable-coinmp \
	--enable-mergelibs --disable-odk --disable-gtk --disable-systray --disable-cairo-canvas \
	--disable-dbus --disable-sdremote --disable-sdremote-bluetooth --disable-gio --disable-randr \
	--disable-gstreamer-1-0 --disable-cve-tests --disable-cups --disable-extension-update \
	--disable-postgresql-sdbc --disable-lotuswordpro --disable-firebird-sdbc --disable-scripting-beanshell \
	--disable-scripting-javascript --disable-largefile --without-helppack-integration \
	--without-system-dicts --without-java --disable-gtk3 --disable-dconf --disable-gstreamer-0-10 \
	--disable-firebird-sdbc --without-fonts --without-junit --with-theme="no" --disable-evolution2 \
	--disable-avahi --without-myspell-dicts --disable-ext-mariadb-connector --with-galleries="no" \
	--disable-kde4 --with-system-expat --with-system-libxml --with-system-nss \
	--disable-introspection --without-krb5 --disable-python --disable-pch \
	--with-system-openssl --with-system-curl --disable-ooenv --disable-dependency-tracking

# this will take 0-2 hours to compile, depends on your machine
make

# this will remove ~100 MB of symbols from shared objects
strip ./instdir/**/*

# remove unneeded stuff for headless mode
rm -rf ./instdir/share/gallery \
	./instdir/share/config/images_*.zip \
	./instdir/readmes \
	./instdir/CREDITS.fodt \
	./instdir/LICENSE* \
	./instdir/NOTICE

# archive
tar -zcvf lo.tar.gz instdir

# test if compilation was successful
echo "hello world" > a.txt
./instdir/program/soffice --headless --invisible --nodefault --nofirststartwizard \
	--nolockcheck --nologo --norestore --convert-to pdf --outdir $(pwd) a.txt

# download from EC2 to local machine
scp ec2-user@ec2-54-227-212-139.compute-1.amazonaws.com:/home/ec2-user/libreoffice/lo.tar.gz $(pwd)
