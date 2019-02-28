#!/usr/bin/env bash

# install basic stuff required for compilation
sudo yum-config-manager --enable epel
sudo yum install git autoconf ccache nasm libffi-devel libmpc-devel mpfr-devel \
	gmp-devel libicu-devel icu python34-devel google-crosextra-caladea-fonts \
	google-crosextra-carlito-fonts liberation-serif-fonts liberation-sans-fonts \
	mesa-libGL-devel mesa-libGLU-devel libX11-devel libXext-devel libICE-devel \
	libSM-devel libXrender-devel libxslt-devel gperf fontconfig-devel libpng-devel \
	expat-devel libcurl-devel nss-devel nspr-devel openssl-devel expat-devel.x86_64 \
	perl-Digest-MD5 -y
sudo yum groupinstall "Development Tools" -y

# clone libreoffice sources
git clone --depth=1 git://anongit.freedesktop.org/libreoffice/core libreoffice
cd libreoffice
git fetch --tags
git checkout libreoffice-6.2.1.2

# set this cache if you are going to compile several times
ccache --max-size 16 G && ccache -s

# the most important part. Run ./autogen.sh --help to see wha each option means
./autogen.sh \
    --disable-avahi \
    --disable-cairo-canvas \
    --disable-coinmp \
	--disable-cups \
	--disable-cve-tests \
	--disable-dbus \
	--disable-dconf \
	--disable-dependency-tracking \
	--disable-evolution2 \
	--disable-extension-update \
	--disable-firebird-sdbc \
	--disable-firebird-sdbc \
	--disable-gio \
	--disable-gstreamer-0-10 \
	--disable-gstreamer-1-0 \
	--disable-gtk \
	--disable-gtk3 \
	--disable-introspection \
	--disable-kde4 \
	--disable-largefile \
	--disable-lotuswordpro \
	--disable-lpsolve \
	--disable-odk \
	--disable-ooenv \
	--disable-pch \
	--disable-postgresql-sdbc \
	--disable-python \
	--disable-randr \
	--disable-report-builder \
	--disable-scripting-beanshell \
	--disable-scripting-javascript \
	--disable-sdremote \
	--disable-sdremote-bluetooth \
	--enable-mergelibs \
	--with-galleries="no" \
	--with-system-curl \
	--with-system-expat \
	--with-system-libxml \
	--with-system-nss \
	--with-system-openssl \
	--with-theme="no" \
	--without-fonts \
	--without-helppack-integration \
	--without-java \
	--without-junit \
	--without-krb5 \
	--without-myspell-dicts \
	--without-system-dicts

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
