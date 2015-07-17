yum -y install autoconf automake jemalloc-devel libedit-devel libtool ncurses-devel pcre-devel pkgconfig python-docutils python-sphinx

cd /usr/local/src
wget -O Varnish-Cache-master.zip https://github.com/varnish/Varnish-Cache/archive/master.zip
unzip Varnish-Cache-master.zip
cd Varnish-Cache-master
chmod -R 755 *
./autogen.sh
./configure --prefix=/usr/local/varnish PKG_CONFIG_PATH=/usr/lib/pkgconfig
make
make install

