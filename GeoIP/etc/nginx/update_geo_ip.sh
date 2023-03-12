#bin/bash

# https://gist.github.com/fffonion/44e5fb59e2a8f0efba5c1965c6043584

wget -q  http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz -O - |gzip -d > /usr/share/GeoIP/GeoIPASNum.dat.new && mv /usr/share/GeoIP/GeoIPASNum.dat{.new,}
wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz -O - |gzip -d > /usr/share/GeoIP/GeoLiteCity.dat.new && mv /usr/share/GeoIP/GeoLiteCity.dat{.new,}
wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz -O - |gzip -d > /usr/share/GeoIP/GeoIP.dat.new && mv /usr/share/GeoIP/GeoIP.dat{.new,}

wget -q  http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNumv6.dat.gz -O - |gzip -d > /usr/share/GeoIP/GeoIPASNumv6.dat.new && mv /usr/share/GeoIP/GeoIPASNumv6.dat{.new,}
wget -q http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz -O - |gzip -d > /usr/share/GeoIP/GeoLiteCityv6.dat.new && mv /usr/share/GeoIP/GeoLiteCityv6.dat{.new,}
wget -q http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz -O - |gzip -d > /usr/share/GeoIP/GeoIPv6.dat.new && mv /usr/share/GeoIP/GeoIPv6.dat{.new,}
