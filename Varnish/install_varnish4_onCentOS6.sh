# Yum install
yum -y install autoconf automake jemalloc-devel libedit-devel libtool ncurses-devel pcre-devel pkgconfig python-docutils python-sphinx

# Install
cd /usr/local/src
wget -O Varnish-Cache-master.zip https://github.com/varnish/Varnish-Cache/archive/master.zip
unzip Varnish-Cache-master.zip
cd Varnish-Cache-master
chmod -R 755 *
./autogen.sh
./configure --prefix=/usr/local/varnish PKG_CONFIG_PATH=/usr/lib/pkgconfig
make
make install



# init.d
/bin/cp ./redhat/varnish.initrc /etc/init.d/varnish
sed -i 's/\/usr\//\/usr\/local\/varnish\//g' /etc/init.d/varnish

# varnish defaults
/bin/cp ./redhat/varnish.sysconfig /etc/sysconfig/varnish
sed -i 's/\/etc\/varnish\/default.vcl/\/usr\/local\/varnish\/conf\/default.vcl/g' /etc/sysconfig/varnish
sed -i 's/^# VARNISH_LISTEN_ADDRESS=/VARNISH_LISTEN_ADDRESS=0.0.0.0/g' /etc/sysconfig/varnish
sed -i 's/^VARNISH_LISTEN_PORT=6081/VARNISH_LISTEN_PORT=80/g' /etc/sysconfig/varnish

# loglotate
/bin/cp ./redhat/varnish.logrotate /etc/logrotate.d/varnish
/etc/init.d/logrotate restart






