#!/usr/bin/perl
# $Id: add_to_cfg_elite.pl 428 2006-08-30 02:00:57Z corrupt $

use Config::Elite;
my $c = Config::Elite->new(ConfigFile       =>      '/path/to/badnews.xml');

$c->create_config_table('config_elite_table');

# populate the data 

# just change the second arguements, the third true int value signifies that the 
# config is 'persistent' and won't be checked every time it's poll'd
$c->add_config_option('DSN', 'DBI:mysql:database=mike;host=localhost;port=3306', 1);
$c->add_config_option('DB_USER', 'yourdbuser', 1);
$c->add_config_option('DB_PASS', 'yourdbpass', 1);
$c->add_config_option('SESSION_TABLE', 'sessions', 1);
$c->add_config_option('COOKIE_DURATION', '3600', 1);
$c->add_config_option('APP_TITLE', 'your cms yadda yadda', 1);
$c->add_config_option('SYS_VERSION', '0.05', 1);
$c->add_config_option('COOKIE_DOMAIN', 'your.domain.com', 1);
$c->add_config_option('TEMPLATE_PATH', '/path/to/badnews/templates', 1);
$c->add_config_option('THEME_PATH', '/path/to/badnews/themes', 1);
$c->add_config_option('DEFAULT_THEME', 'mikey_g', 1);

# this isn't used yet
$c->add_config_option('CONF_TBL', 'usr_config', 1);

