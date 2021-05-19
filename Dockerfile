FROM amazonlinux:2.0.20190508 as lobuild

# see https://stackoverflow.com/questions/2499794/how-to-fix-a-locale-setting-warning-from-perl
ENV LC_CTYPE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

ENV LIBREOFFICE_VERSION=6.2.1.2

# install basic stuff required for compilation
RUN yum install -y yum-utils \
    && yum-config-manager --enable epel \
    && yum install -y \
    google-crosextra-caladea-fonts \
    autoconf \
    ccache \
    expat-devel \
    expat-devel.x86_64 \
    fontconfig-devel \
    git \
    gmp-devel \
    google-crosextra-caladea-fonts \
    google-crosextra-carlito-fonts \
    gperf \
    icu \
    libcurl-devel \
    liberation-sans-fonts \
    liberation-serif-fonts \
    libffi-devel \
    libICE-devel \
    libicu-devel \
    libmpc-devel \
    libpng-devel \
    libSM-devel \
    libX11-devel \
    libXext-devel \
    libXrender-devel \
    libxslt-devel \
    mesa-libGL-devel \
    mesa-libGLU-devel \
    mpfr-devel \
    nasm \
    nspr-devel \
    nss-devel \
    openssl-devel \
    perl-Digest-MD5 \
    python34-devel \
    which # Used by autogen.sh

RUN yum groupinstall -y "Development Tools"

# fetch the LibreOffice source
RUN cd /tmp \
    && curl -L https://github.com/LibreOffice/core/archive/libreoffice-${LIBREOFFICE_VERSION}.tar.gz | tar -xz \
    && mv core-libreoffice-${LIBREOFFICE_VERSION} libreoffice

WORKDIR /tmp/libreoffice

# see https://ask.libreoffice.org/en/question/72766/sourcesver-missing-while-compiling-from-source/
RUN echo "lo_sources_ver=${LIBREOFFICE_VERSION}" >> sources.ver

# install liblangtag (not available in Amazon Linux or EPEL repos)
# paste repo info from https://unix.stackexchange.com/questions/433046/how-do-i-enable-centos-repositories-on-rhel-red-hat
COPY config/centos.repo /etc/yum.repos.d/
RUN yum repolist && yum install -y liblangtag && cp -r /usr/share/liblangtag /usr/local/share/liblangtag/

RUN ./autogen.sh \
    --disable-avahi \
    --disable-cairo-canvas \
    --disable-coinmp \
    --disable-cups \
    --disable-cve-tests \
    --disable-dbus \
    --disable-dconf \
    --disable-dependency-tracking \
    --disable-evolution2 \
    --disable-dbgutil \
    --disable-extension-integration \
    --disable-extension-update \
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
    --without-export-validation \
    --without-fonts \
    --without-helppack-integration \
    --without-java \
    --without-junit \
    --without-krb5 \
    --without-myspell-dicts \
    --without-system-dicts

# Disable flaky unit test failing on macos (and for some reason on Amazon Linux as well)
# find the line "void PdfExportTest::testSofthyphenPos()" (around 600)
# and replace "#if !defined MACOSX && !defined _WIN32" with "#if defined MACOSX && !defined _WIN32"
RUN sed -i '609s/#if !defined MACOSX && !defined _WIN32/#if defined MACOSX \&\& !defined _WIN32/' vcl/qa/cppunit/pdfexport/pdfexport.cxx

# this will take 30 minutes to 2 hours to compile, depends on your machine
RUN make

# this will remove ~100 MB of symbols from shared objects
# strip will always return exit code 1 as it generates file warnings when hitting directories
RUN strip ./instdir/**/* || true

# remove unneeded stuff for headless mode
RUN rm -rf ./instdir/share/gallery \
    ./instdir/share/config/images_*.zip \
    ./instdir/readmes \
    ./instdir/CREDITS.fodt \
    ./instdir/LICENSE* \
    ./instdir/NOTICE

# test if compilation was successful
RUN echo "hello world" > a.txt \
    && ./instdir/program/soffice --headless --invisible --nodefault --nofirststartwizard \
        --nolockcheck --nologo --norestore --convert-to pdf --outdir $(pwd) a.txt

RUN tar -cvf /tmp/lo.tar instdir/

FROM amazonlinux:2.0.20190508 as brotli

ENV BROTLI_VERSION=1.0.7

WORKDIR /tmp

# Compile Brotli
RUN yum install -y make zip unzip bc autoconf automake libtool \
    && curl -LO https://github.com/google/brotli/archive/v${BROTLI_VERSION}.zip \
    && unzip v${BROTLI_VERSION}.zip \
    && cd brotli-${BROTLI_VERSION} \
    && ./bootstrap \
    && ./configure \
    && make \
    && make install

COPY --from=lobuild /tmp/lo.tar .

RUN brotli --best /tmp/lo.tar && zip -r layers.zip lo.tar.br

FROM amazonlinux:2.0.20190508

COPY --from=brotli /tmp/layers.zip /tmp
