#!/bin/bash

## setup_tomcat_upload.sh

set -e

TOMCAT_VER=9.0.85
TOMCAT_USER=tomcat
INSTALL_DIR=/opt/tomcat
UPLOAD_DIR=/data/uploads
AJP_PORT=7019


MIRROR="https://archive.apache.org/dist/tomcat/"
DOWNLOAD_DIR="/path/to/download/directory"


echo "[Tomcat] Java-openjdk1.8 and tomcat user add..."
yum install -y java-1.8.0-openjdk-devel wget unzip
useradd -r -m -U -d $INSTALL_DIR -s /bin/false $TOMCAT_USER || true

echo "[Tomcat] Tomcat install..."
TOMCAT_VER_MAJOR=`echo ${TOMCAT_VER} | awk -F\. '{print$1}'`
cd /tmp
wget https://downloads.apache.org/tomcat/tomcat-${TOMCAT_VER_MAJOR}/v$TOMCAT_VER/bin/apache-tomcat-$TOMCAT_VER.tar.gz
tar -xzf apache-tomcat-$TOMCAT_VER.tar.gz
mv apache-tomcat-$TOMCAT_VER $INSTALL_DIR
chown -R $TOMCAT_USER:$TOMCAT_USER $INSTALL_DIR

echo "[Tomcat] server.xml AJP config insert..."
sed -i "/<Service name=\"Catalina\">/a \\
    <Connector protocol=\"AJP/1.3\" \\
            port=\"$AJP_PORT\" \\
            address=\"0.0.0.0\" \\
            maxThreads=\"500\" \\
            secretRequired=\"false\" \\
            maxPostSize=\"21474836480\" \\
            packetSize=\"65536\" \\
            maxSwallowSize=\"-1\" \\
            connectionTimeout=\"7200000\" \\
            />" server.xml

echo "[Tomcat] upload test page make..."
cat <<EOF > $INSTALL_DIR/webapps/ROOT/upload.jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head><title>Upload Form</title></head>
<body>
    <h2>File Upload test</h2>
    <form method="POST" action="uploadResult.jsp" enctype="multipart/form-data">
        <input type="file" name="file" /><br><br>
        <input type="submit" value="Upload">
    </form>
</body>
</html>
EOF


cat <<EOF > $INSTALL_DIR/webapps/ROOT/uploadResult.jsp
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="java.io.*" %>
<html>
<head><title>Upload Result</title></head>
<body>
<%
    InputStream inputStream = request.getInputStream();
    FileOutputStream fileOut = new FileOutputStream("${UPLOAD_DIR}/upload_debug.raw");

    byte[] buffer = new byte[8192];
    int len;

    while ((len = inputStream.read(buffer)) > 0) {
        fileOut.write(buffer, 0, len);
    }

    fileOut.close();
    out.println("<h3>File Save Finish!</h3>");
%>
</body>
</html>
EOF



mkdir -p $UPLOAD_DIR
chown -R $TOMCAT_USER:$TOMCAT_USER $UPLOAD_DIR

echo "[Tomcat] server start..."
su - $TOMCAT_USER -s /bin/bash -c "$INSTALL_DIR/bin/startup.sh"

echo "[ Tomcat config finish] AJP port: $AJP_PORT, upload path: $UPLOAD_DIR"
