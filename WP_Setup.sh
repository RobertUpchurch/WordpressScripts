#######################
### User Variable  ####
#######################
read -p "Whats the domain name? https://" domain_name
read -p "What's the admin email address? " email
read -p "Client Name / Site Name? " client
read -p "What's the client slug? " client_slug
read -p "Whats the client phrase? " client_phrase

read -p "Enter new admin username: " admin_username
read -p "Enter new admin email: " admin_email
read -p "Enter new admin password: " admin_password
# read -p "What's the SES region? " -i "us-west-2" SES_region
# read -p "Enter the SES username: " SES_user
# read -p "Enter the SES password: " SES_pass
# read -p "Enter the Imagify API Key: " ImagifyApiKey

#################
### Clean Up ####
#################

#Remove All Users
wp user delete user --yes
#Remove all posts
wp post delete $(wp post list --post_type='posts' --format=ids) --force
#Remove All Pages
wp post delete $(wp post list --post_type='page' --format=ids) --force
#Remove all Plugins
wp plugin deactivate --all
wp plugin delete --all
# Deletes all default themes
wp theme delete --all

########################
### Default Creation ###
########################

# Users
wp user create $admin_username $admin_email --role=administrator --user_pass=$admin_password

# Themes
wp theme update --all

# PERMISSIONS
sudo chown -R bitnami:daemon ~/apps/wordpress/htdocs


# Child Theme
wp theme install hello-elementor
wp scaffold child-theme $client_slug --parent_theme=hello-elementor --theme_name="$client Theme" --author="Axia Labs" --author_uri="https://axialabs.com" --activate

# Pages
homeId=$(wp post create --post_type="page" --post_title="Home" --post_status="publish" --post_author="2" --porcelain)
blogId=$(wp post create --post_type="page" --post_title="Blog" --post_status="publish" --post_author="2" --porcelain)
aboutId=$(wp post create --post_type="page" --post_title="About Us" --post_status="publish" --post_author="2" --porcelain)
contactId=$(wp post create --post_type="page" --post_title="Contact Us" --post_status="publish" --post_author="2" --porcelain)
termsId=$(wp post create --post_type="page" --post_title="Terms & Conditions" --post_status="publish" --post_author="2" --porcelain)
privacyId=$(wp post create --post_type="page" --post_title="Privacy Statement" --post_status="publish" --post_author="2" --porcelain)

#Menus
wp menu create "header-menu"
wp menu item add-post header-menu $homeId --title="Home"
wp menu item add-post header-menu $blogId --title="Blog"
wp menu item add-post header-menu $aboutId --title="About Us"
wp menu item add-post header-menu $contactId --title="Contact Us"

wp menu create "support-menu"
wp menu item add-post support-menu $termsId --title="Terms & Conditions"
wp menu item add-post support-menu $privacyId --title="Privacy Statement"

# Plugins
wp plugin install elementor --activate
wp plugin install ele-custom-skin --activate
wp plugin install advanced-custom-fields --activate
wp plugin install fakerpress --activate
wp plugin install filebird --activate
wp plugin install imagify --activate
wp plugin install wps-hide-login --activate
wp plugin install antispam-bee --activate
wp plugin install wp-mail-smtp --activate
wp plugin install wordfence

########################
### Settings  ##########
########################

# Read Settings
wp option update show_on_front 'page'
wp option update page_on_front $homeId
wp option update page_for_posts $blogId


# Wordpress
wp option update blogname "$client"
wp option update blogdescription "$client_phrase"
wp option update admin_email "$email"
wp option update permalink_structure '/%postname%/'
wp option update wp_page_for_privacy_policy $privacyId
wp option update uploads_use_yearmonth_folders 0

#UPDATE TO USE HTTPS
sudo sed -i 's/http:/https:/' apps/wordpress/htdocs/wp-config.php

# Mail SMTP
# echo "contact@$domain_name" | wp option patch insert wp_mail_smtp mail from_email
# echo "$client"              | wp option patch insert wp_mail_smtp mail from_name
# echo "smtp"                 | wp option patch insert wp_mail_smtp mail mailer
# echo "false"                | wp option patch insert wp_mail_smtp mail from_email_force
# echo "email-smtp.$SES_region.amazonaws.com" | wp option patch insert wp_mail_smtp smtp host
# echo "$SES_user"            | wp option patch insert wp_mail_smtp smtp user
# echo "$SES_pass"            | wp option patch insert wp_mail_smtp smtp pass
# echo "tls"                  | wp option patch insert wp_mail_smtp smtp encryption
# echo "587"                  | wp option patch insert wp_mail_smtp smtp port

# Imagify 
# echo "$ImagifyApiKey" | wp option patch update imagify_settings api_key
# echo 1 | wp option patch update imagify_settings display_webp

# BITNAMI
sudo /opt/bitnami/apps/wordpress/bnconfig --disable_banner 1
sudo /opt/bitnami/ctlscript.sh restart apache

# ASK FOR WOOCOMMERCE
while true; do
    read -p "Do you wish to install Woocommerce? (y/n) " yn
    case $yn in
        [Yy]* ) curl https://raw.githubusercontent.com/AxiaLabs/WordpressScripts/main/WC_Setup.sh -o /home/bitnami/apps/wordpress/htdocs/WC_Setup.sh && sudo chmod 700 /home/bitnami/apps/wordpress/htdocs/WC_Setup.sh && /home/bitnami/apps/wordpress/htdocs/WC_Setup.sh; break;;
        [Nn]* ) echo "Skipping WooCommerce"; break;;
        * ) echo "Please answer yes or no.";;
    esac
done

###############################
### Remove Script  ###
###############################
sudo rm ~/apps/wordpress/htdocs/WP_Setup.sh

###############################
### Set Correct Permission  ###
###############################
sudo chown -R bitnami:daemon ~/apps/wordpress/htdocs

########################
### SSL  ###############
########################
sudo /opt/bitnami/bncert-tool
echo "Configuration Complete: Set Up SSL with the following command"
echo
echo "sudo /opt/bitnami/bncert-tool"
echo
