#!/bin/bash

#variables
name="mavia"
s3_bucket="upgrad-mavia"

#update packages
apt update -y

#check for apache2 installation
if [[ apache2 != $(dpkg --get-selections apache2 | awk '{print $1}') ]]; then
	
	apt install apache2 -y
fi

#check if apache2 is running
running=$(systemctl status apache2 | grep active | awk '{print $3}' | tr -d '()')
if [[ running != ${running} ]]; then
	systemctl start apache2
fi

#To check is apache2 service is enabled
enabled=$(systemctl is-enabled apache2 | grep "enabled")
if [[ enabled != ${enabled} ]]; then
	systemctl enable apache2
fi

#creating file

timestamp=$(date '+%d%m%Y-%H%M%S')

#create tar archive

cd /var/log/apache2
tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar *.log

#copy logs to s3 bucket
if [[ -f /tmp/${name}-httpd-logs-${timestamp}.tar ]]; then
	aws s3 cp /tmp/${name}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar
fi

docroot="/var/www/html"

#tocheck if the file exists
if [[ ! -f ${docroot}/inventory.html ]]; then
	echo -e 'Log Type\t-\tTime Created\t-\tType\t-\tSize' > ${docroot}/inventory.html
fi

#insert logs to file
if [[ -f ${docroot}/inventory.html ]]; then
	size=$(du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}')
	echo -e "httpd-logs\t-\t${timestamp}\t-\ttar\t-\t${size}" >> ${docroot}/inventory.html
fi

#creating cronjob
if [[ ! -f /etc/cron.d/automation ]]; then
	echo "* * * * * root /root/Automation_Project/automation.sh" >> /etc/cron.d/automation
fi
