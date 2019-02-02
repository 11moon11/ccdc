#!/bin/bash
#
#

if [[ $EUID -ne 0 ]]
then
   echo "Use: sudo $0"
   exit 1
fi

echo "enter host (ex: ecomm):"
Read $h
#
#
Echo
Echo "enter domain (ex: ccdc.com):"
Read $d
#
#
Echo
Echo "enter ip addr:"
Read $ip
#
#######
#
cat << EOF >> /etc/httpd/conf/httpd.com 
NameVirtualHost *:80
<VirtualHost *:80>
   ServerName $h.$d
   Redirect / https://$h.$d
</VirtualHost>

<VirtualHost _default_:443>
   ServerName $h.$d
   DocumentRoot /usr/local/apache2/htdocs
   SSLEngine On
</VirtualHost>
EOF
#
#
systemctl restart httpd
#
#
echo "HOSTNAME=$h.$d" > /etc/sysconfig/network
#
#
echo "$ip	$h.$d	$h" >> /etc/hosts
#
#
hostnamectl set-hostname $h.$d
#
#
/etc/init.d/network restart