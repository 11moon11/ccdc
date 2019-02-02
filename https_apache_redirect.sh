#!/bin/bash
#
#

if [[ $EUID -ne 0 ]]
then
   echo "Use: sudo $0"
   exit 1
fi

read -p "enter host (ex: ecomm): " h
#
#
read -p "enter domain (ex: ccdc.com): " d
#
#
read -p "enter ip addr: " ip
#
#######
#

echo "Setting host to: $h.$d"

cat << EOF >> /etc/httpd/conf/httpd.conf 
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
