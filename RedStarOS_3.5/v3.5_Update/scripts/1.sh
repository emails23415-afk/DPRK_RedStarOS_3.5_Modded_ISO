#!/bin/bash
kdialog --title "Install v3.5 Update Combo" --error "This tool will guide you through the installation process of the unofficial v3.5 update for Red Star OS 3.0. \n\nThis will upgrade the system kernel to 5.4 x86_64 along with updates to many other critical system components and libraries. \n\nThe process is fully automatic, do not touch anything except typing your login password when asked. \nYour device will reboot for a couple of times during the process, it's recommended to set up automatic login in \"System Preferences -> Accounts -> Login Options -> Automatic Login\" so the amount of times the password need to be typed can be reduced. \n\nClick 'OK' when ready... "
set -x
killall -9 -e artsd
source '/root/Desktop/v3.5 Update Combo/scripts/pkgutils.sh'
trap 'scripterror' ERR
set +e
MakeShortcut
WorkspaceCleanUp
trap 'yumerror' ERR
set +e
yum install @"Development Tools" "kernel*" -y -x "*PAE*"
trap 'scripterror' ERR
set +e
Install bc-1.07.1 gz --enable-shared
Install make-4.2.1 gz --with-libintl-prefix --with-libiconv-prefix --with-gnu-ld
Install gmp-4.3.2 bz2 --enable-cxx --enable-shared
Install mpfr-2.4.2 bz2 --enable-shared
Install mpc-0.8.1 gz --enable-shared
Install isl-0.14 bz2
Install zlib-1.2.11 xz
InstallRoot zlib-1.2.11 xz
Install gcc-6.5.0 xz --mandir=/usr/share/man --infodir=/usr/share/info \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release --with-system-zlib \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-languages=ada,c,c++,fortran,go,java,jit,lto,objc,obj-c++ \
--enable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify
Install gdb-7.12 xz --mandir=/usr/share/man --infodir=/usr/share/info \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release --with-system-zlib \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify
Install binutils-2.34 xz --mandir=/usr/share/man --infodir=/usr/share/info \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release --with-system-zlib \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify
Install ncurses-6.0 gz --with-ada --enable-ext-colors --enable-ext-mouse
Install gmp-6.2.1 bz2 --enable-cxx --enable-shared
Install mpfr-4.1.0 bz2 --enable-shared
Install mpc-1.2.1 gz --enable-shared
Install isl-0.24 bz2
Install nettle-3.4.1 gz --enable-shared --enable-threads
Install libtasn1-4.10 gz
Install libunistring-1.1 gz
Install libiconv-1.16 gz
Install cpio-2.13 gz
CustomInstall openssl-1.0.2u gz "For Host" "" \
"./config --openssldir=/usr/ssl" \
"make all -j$(grep -c ^processor /proc/cpuinfo)" \
"make install"
Install expat-2.2.10 xz
Install unbound-1.12.0 gz
Install libffi-3.3 gz
Install p11-kit-0.23.18.1 gz
Install gnutls-3.3.30 xz --enable-shared
Install wget-1.19.5 gz
Install m4-1.4.18 xz
Install libtool-2.4.6 xz --enable-shared=yes --enable-static=yes --with-gnu-ld
Install autoconf-2.69 xz
Install automake-1.15 xz
Install bison-3.5.4 xz 
Install gawk-4.2.1 xz
Install sed-4.4 xz
Install texinfo-6.8 xz --enable-dependency-tracking
rm -f /sbin/install-info
ln -sf /usr/bin/install-info /sbin/install-info
Install help2man-1.47.17 xz
Install Python-3.7.6 xz --enable-optimizations --with-pydebug
Cross64CleanUp
InstallCross64 binutils-2.34 xz --mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release --with-system-zlib \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify
title Installing Kernel 3.19.8 For Cross-x86_64 \[Extracting\]
cd /usr/src/kernels
tar xvf "/root/Desktop/v3.5 Update Combo/packages/linux-3.19.8.tar.xz"
cd /usr/src/kernels/linux-3.19.8
title Installing Kernel 3.19.8 For Cross-x86_64 \[Deploying Headers\]
make mrproper ARCH=x86_64
make headers_install ARCH=x86_64 INSTALL_HDR_PATH=/opt/NewRoot
rm -f '/opt/NewRoot/usr'
ln -sdf '/opt/NewRoot' '/opt/NewRoot/usr'
ln -sdf '/opt' '/opt/NewRoot/opt'
CustomInstall gcc-6.5.0 xz "For Cross-x86_64 (Bootstrap Stage 1)" "W0RK" \
"Extract gmp-4.3.2 bz2; \
Extract mpfr-2.4.2 bz2; \
Extract mpc-0.8.1 gz; \
Extract isl-0.14 bz2; \
ln -sdf '/workspace/gmp-4.3.2' '/workspace/gcc-6.5.0/gmp'; \
ln -sdf '/workspace/mpfr-2.4.2' '/workspace/gcc-6.5.0/mpfr'; \
ln -sdf '/workspace/mpc-0.8.1' '/workspace/gcc-6.5.0/mpc'; \
ln -sdf '/workspace/isl-0.14' '/workspace/gcc-6.5.0/isl'; \
cd /workspace/gcc-6.5.0/W0RK; \
../configure --target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 \
--mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--with-sysroot=/opt/NewRoot --without-headers \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release --enable-bootstrap \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-languages=c,c++,objc,obj-c++ \
--enable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify" \
"make all-gcc -j$(grep -c ^processor /proc/cpuinfo)" \
"make install-gcc; \
CleanUp gmp-4.3.2; \
CleanUp mpfr-2.4.2; \
CleanUp mpc-0.8.1; \
CleanUp isl-0.14"
CustomInstall glibc-2.23 xz "For Cross-x86_64 (Bootstrap Stage 1)" "W0RK" \
"../configure --prefix=/opt/NewRoot --mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--host=x86_64-pc-linux-gnu --with-sysroot=/opt/NewRoot \
--with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-shared --enable-profile --enable-multi-arch --enable-obsolete-rpc --disable-werror \
libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes" \
"nop" \
"make install-headers install-bootstrap-headers=yes"
CustomInstall glibc-2.23 xz "For Cross-x86_64 (Bootstrap Stage 1)" "W0RK" \
"../configure --prefix=/opt/NewRoot --mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--host=x86_64-pc-linux-gnu --with-sysroot=/opt/NewRoot \
--with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-shared --enable-profile --enable-multi-arch --enable-obsolete-rpc --disable-werror \
libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes" \
"make csu/subdir_lib -j$(grep -c ^processor /proc/cpuinfo)" \
"install csu/crt1.o csu/crti.o csu/crtn.o /opt/NewRoot/lib"
touch /opt/NewRoot/include/gnu/stubs.h
CustomInstall gcc-6.5.0 xz "For Cross-x86_64 (Bootstrap Stage 2)" "W0RK" \
"Extract gmp-4.3.2 bz2; \
Extract mpfr-2.4.2 bz2; \
Extract mpc-0.8.1 gz; \
Extract isl-0.14 bz2; \
ln -sdf '/workspace/gmp-4.3.2' '/workspace/gcc-6.5.0/gmp'; \
ln -sdf '/workspace/mpfr-2.4.2' '/workspace/gcc-6.5.0/mpfr'; \
ln -sdf '/workspace/mpc-0.8.1' '/workspace/gcc-6.5.0/mpc'; \
ln -sdf '/workspace/isl-0.14' '/workspace/gcc-6.5.0/isl'; \
cd /workspace/gcc-6.5.0/W0RK; \
../configure --target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 \
--mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--with-sysroot=/opt/NewRoot --with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-languages=c,c++,objc,obj-c++ \
--disable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify" \
"make all-target-libgcc -j$(grep -c ^processor /proc/cpuinfo)" \
"make install-target-libgcc; \
CleanUp gmp-4.3.2; \
CleanUp mpfr-2.4.2; \
CleanUp mpc-0.8.1; \
CleanUp isl-0.14"
CustomInstall gcc-6.5.0 xz "For Cross-x86_64 (Bootstrap Stage 3)" "W0RK" \
"Extract gmp-4.3.2 bz2; \
Extract mpfr-2.4.2 bz2; \
Extract mpc-0.8.1 gz; \
Extract isl-0.14 bz2; \
ln -sdf '/workspace/gmp-4.3.2' '/workspace/gcc-6.5.0/gmp'; \
ln -sdf '/workspace/mpfr-2.4.2' '/workspace/gcc-6.5.0/mpfr'; \
ln -sdf '/workspace/mpc-0.8.1' '/workspace/gcc-6.5.0/mpc'; \
ln -sdf '/workspace/isl-0.14' '/workspace/gcc-6.5.0/isl'; \
cd /workspace/gcc-6.5.0/W0RK; \
../configure --target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 \
--mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--with-sysroot=/opt/NewRoot --with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-languages=c,c++,objc,obj-c++ \
--disable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --disable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --disable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --disable-libmpx --disable-libobjc --enable-libsanitizer \
--disable-libquadmath --disable-libssp --disable-libstdcxx --disable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --disable-objc-gc --enable-vtable-verify" \
"make all -j$(grep -c ^processor /proc/cpuinfo)" \
"make install; \
CleanUp gmp-4.3.2; \
CleanUp mpfr-2.4.2; \
CleanUp mpc-0.8.1; \
CleanUp isl-0.14"
export CFLAGS="-O2 -g -fno-common -fno-stack-protector"
export CXXFLAGS="-O2 -g -fno-common -fno-stack-protector"
CustomInstall glibc-2.23 xz "For Cross-x86_64 (Bootstrap Stage 4)" "W0RK" \
"../configure --prefix=/opt/NewRoot --mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--host=x86_64-pc-linux-gnu --with-sysroot=/opt/NewRoot \
--with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-shared --enable-profile --enable-multi-arch --enable-obsolete-rpc --disable-werror \
libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes" \
"make all -j$(grep -c ^processor /proc/cpuinfo)" \
"make install"
unset CFLAGS
unset CXXFLAGS
CustomInstall gcc-6.5.0 xz "For Cross-x86_64 (Bootstrap Stage 4)" "W0RK" \
"Extract gmp-4.3.2 bz2; \
Extract mpfr-2.4.2 bz2; \
Extract mpc-0.8.1 gz; \
Extract isl-0.14 bz2; \
ln -sdf '/workspace/gmp-4.3.2' '/workspace/gcc-6.5.0/gmp'; \
ln -sdf '/workspace/mpfr-2.4.2' '/workspace/gcc-6.5.0/mpfr'; \
ln -sdf '/workspace/mpc-0.8.1' '/workspace/gcc-6.5.0/mpc'; \
ln -sdf '/workspace/isl-0.14' '/workspace/gcc-6.5.0/isl'; \
cd /workspace/gcc-6.5.0/W0RK; \
../configure --target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 \
--mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--with-sysroot=/opt/NewRoot --with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-languages=c,c++,objc,obj-c++ \
--enable-shared --enable-host-shared --disable-multiarch --disable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --disable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --disable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --disable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify" \
"make all-target -j$(grep -c ^processor /proc/cpuinfo)" \
"make install-target; \
CleanUp gmp-4.3.2; \
CleanUp mpfr-2.4.2; \
CleanUp mpc-0.8.1; \
CleanUp isl-0.14"
export CFLAGS="-O2 -g -fno-common"
export CXXFLAGS="-O2 -g -fno-common"
CustomInstall glibc-2.23 xz "For Cross-x86_64 (Final Stage)" "W0RK" \
"../configure --prefix=/opt/NewRoot --mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--host=x86_64-pc-linux-gnu --with-sysroot=/opt/NewRoot \
--with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-shared --enable-profile --enable-multi-arch --enable-obsolete-rpc --disable-werror \
libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes" \
"make all -j$(grep -c ^processor /proc/cpuinfo)" \
"make install"
unset CFLAGS
unset CXXFLAGS
export CFLAGS="-O2 -g -fno-common"
export CXXFLAGS="-O2 -g -fno-common"
CustomInstall glibc-2.23 xz "For Cross-x86_64 (multilib support)" "W0RK" \
"../configure --prefix=/opt/NewRoot --mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info --libdir=/opt/NewRoot/lib \
--host=i686-pc-linux-gnu --with-sysroot=/opt/NewRoot \
--with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-shared --enable-profile --enable-multi-arch --enable-obsolete-rpc --disable-werror \
libc_cv_forced_unwind=yes libc_cv_c_cleanup=yes" \
"make all -j$(grep -c ^processor /proc/cpuinfo)" \
"make install"
unset CFLAGS
unset CXXFLAGS
CustomInstall gcc-6.5.0 xz "For Cross-x86_64 (Final Stage)" "W0RK" \
"Extract gmp-4.3.2 bz2; \
Extract mpfr-2.4.2 bz2; \
Extract mpc-0.8.1 gz; \
Extract isl-0.14 bz2; \
ln -sdf '/workspace/gmp-4.3.2' '/workspace/gcc-6.5.0/gmp'; \
ln -sdf '/workspace/mpfr-2.4.2' '/workspace/gcc-6.5.0/mpfr'; \
ln -sdf '/workspace/mpc-0.8.1' '/workspace/gcc-6.5.0/mpc'; \
ln -sdf '/workspace/isl-0.14' '/workspace/gcc-6.5.0/isl'; \
cd /workspace/gcc-6.5.0/W0RK; \
../configure --target=x86_64-pc-linux-gnu --prefix=/opt/Cross64 \
--mandir=/opt/NewRoot/share/man --infodir=/opt/NewRoot/share/info \
--with-sysroot=/opt/NewRoot --with-headers=/opt/NewRoot/include --includedir=/opt/NewRoot/include \
--enable-ld=yes --enable-gold=no --enable-obsolete \
--enable-threads=posix --enable-checking=release \
--enable-__cxa_atexit --disable-libunwind-exceptions --with-tune=generic \
--enable-languages=ada,c,c++,fortran,go,java,jit,lto,objc,obj-c++ \
--enable-shared --enable-host-shared --enable-multiarch --enable-multilib --enable-tls --enable-cld --enable-nls \
--enable-libada --enable-libatomic --enable-libbacktrace --enable-libcc1 --enable-libcilkrts --enable-libcpp \
--enable-libdecnumber --enable-libffi --enable-libgcc --enable-libgfortran --enable-libgo --enable-libgomp \
--enable-libiberty --enable-libitm --enable-libjava --enable-libmpx --enable-libobjc --enable-libsanitizer \
--enable-libquadmath --enable-libssp --enable-libstdcxx --enable-libvtv --enable-libquadmath-support \
--enable-libgcj --enable-static-libjava=unicows --enable-lto --enable-tls --enable-objc-gc --enable-vtable-verify" \
"make all -j$(grep -c ^processor /proc/cpuinfo)" \
"make install; \
CleanUp gmp-4.3.2; \
CleanUp mpfr-2.4.2; \
CleanUp mpc-0.8.1; \
CleanUp isl-0.14"
InstallCross64Alt make-4.2.1 gz --with-libintl-prefix --with-libiconv-prefix --with-gnu-ld
scripterror
KernelInstall 3.19.8 gz
EnterStage 2
