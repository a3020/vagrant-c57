#!/usr/bin/env bash

cd /vagrant

mkdir public
chown vagrant:vagrant public

apt-get update
apt-get dist-upgrade


echo "## Install utilities"
apt-get -y install unzip


echo "## Install Apache"
# Assume yes, do not prompt
apt-get install -y apache2

if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi

# Enable mod_rewrite, allow .htaccess
a2enmod rewrite

# Allow overriding of the Apache config on a per directory basis.
rm -f /etc/apache2/sites-enabled/000-default.conf
cat > /etc/apache2/sites-enabled/000-default.conf <<EOL 
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	DocumentRoot /var/www/public

	<Directory /var/www/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
	</Directory>
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL


echo "## Run Apache as vagrant user"
sed -i 's/www-data/vagrant/g' /etc/apache2/envvars 


echo "## Install PHP 5.6"
add-apt-repository ppa:ondrej/php5-5.6
sudo apt-get update
apt-get install -y php5 php5-gd libapache2-mod-php5 php5-mysql php5-mcrypt php5-curl


echo "## Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin


echo "## Install MySQL and create database (password is 'root')"
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -q -y install mysql-server mysql-client

mysql -u root -proot -e "CREATE DATABASE c57"

echo "## Download latest concrete5 release"
wget -q -O concrete5.base.zip http://www.concrete5.org/download_file/-/view/93075/

echo "## Unpack concrete5 ZIP"
apt-get -y install unzip

su vagrant -c 'unzip -q concrete5.base.zip'

mv concrete5.*/* public
rm -rf concrete5.*/*
rm concrete5.base.zip
rmdir concrete5.*
cd public


echo "## Restart Apache"
/etc/init.d/apache2 restart


echo "## Make PHP session path writable"
chown vagrant:vagrant /var/lib/php5/sessions -R


echo "## Install concrete5"
chmod +x concrete/bin/concrete5
concrete/bin/concrete5 c5:install --db-server=localhost --db-username=root --db-password=root --db-database=c5 \
	--admin-email=admin@example.com --admin-password=admin \
	--starting-point=elemental_blank

cat > .htaccess <<EOL
# -- concrete5 urls start --
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME}/index.html !-f
RewriteCond %{REQUEST_FILENAME}/index.php !-f
RewriteRule . index.php [L]
</IfModule>
# -- concrete5 urls end --
EOL


echo "## Done"
