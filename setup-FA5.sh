#!/bin/bash

sudo apt-get -y update
sudo apt-get -y install apache2 php5 php5-curl wget curl git

sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/composer.json
sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/index.php
sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/result.php.gz
sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/design.css

sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/ressources/font/helvetica_neue_ultralight.eot
sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/ressources/font/helvetica_neue_ultralight.ttf
sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/ressources/images/background.jpg
sudo wget http://ec2-54-93-215-207.eu-central-1.compute.amazonaws.com/ressources/images/background_original.jpg

sudo mkdir /var/www/uploads
sudo chmod -R 777 /var/www/uploads/

sudo mkdir /var/www/html/ressources
sudo mkdir /var/www/html/ressources/font
sudo mkdir /var/www/html/ressources/images

sudo mv background.jpg /var/www/html/ressources/images/
sudo mv background_original.jpg /var/www/html/ressources/images/
sudo mv helvetica_neue_ultralight.eot /var/www/html/ressources/font/
sudo mv helvetica_neue_ultralight.ttf /var/www/html/ressources/font/

sudo mv composer.json /var/www/html
sudo mv index.php /var/www/html
sudo mv result.php.gz /var/www/html
sudo mv design.css /var/www/html

sudo gunzip /var/www/html/result.php.gz

sudo git clone https://github.com/awslabs/aws-php-sample.git
cd aws-php-sample/

curl -sS https://getcomposer.org/installer | sudo php
sudo php composer.phar install

sudo mv vendor/ /var/www/html

