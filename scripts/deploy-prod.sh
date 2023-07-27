#!/bin/bash
cd ..
git pull
mvn clean install -DskipTests
cd target
read -sp 'Password: ' pw
port2_used=true
port1=8843
port2=8943

export JASYPT_ENCRYPTOR_PASSWORD=$pw
if ls -A | fuser $port2/tcp ; then
    fuser -k $port1/tcp
    nohup java -XX:+HeapDumpOnOutOfMemoryError -Xmx128m -jar -Dfile.encoding=UTF-8 -Dspring.profiles.active=prod alovoa-1.0.0.jar &
else
    port2_used=false
    fuser -k $port2/tcp
    nohup java -XX:+HeapDumpOnOutOfMemoryError -Xmx128m -jar -Dfile.encoding=UTF-8 -Dspring.profiles.active=prod2 alovoa-1.0.0.jar &
fi
sleep 5
unset JASYPT_ENCRYPTOR_PASSWORD

sleep 55

if [ "$port2_used"=true ] ; then
    if ls -A | fuser $port1/tcp ; then
        cp ../scripts/root/etc/apache2/sites-available/alovoa.com.conf /etc/apache2/sites-available/alovoa.com.conf 
        systemctl reload apache2
        fuser -k $port2/tcp
    else
        "Spring Server failed to start in time"
    fi
else
    if ls -A | fuser $port2/tcp ; then
        cp ../scripts/root/etc/apache2/sites-available/port2/alovoa.com.conf /etc/apache2/sites-available/alovoa.com.conf 
        systemctl reload apache2
        fuser -k $port1/tcp
    else
        "Spring Server failed to start in time"
    fi
fi