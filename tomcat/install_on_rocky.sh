dnf install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

JAVA_package=`rpm -qa | grep openjdk | grep -v devel | grep -v headless`
JAVA_HOME=`rpm -ql $JAVA_package | egrep "policytool$" | sed -e 's/\/jre\/bin\/policytool//g'`

echo "" >> /etc/profile
echo "# JAVA" >> /etc/profile
echo "JAVA_HOME=$JAVA_HOME" >> /etc/profile
echo "PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile
echo "CLASSPATH=\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib/tools.jar" >> /etc/profile

source /etc/profile

