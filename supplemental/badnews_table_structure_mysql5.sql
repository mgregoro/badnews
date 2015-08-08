-- MySQL dump 10.10
--
-- Host: localhost    Database: bndev_mg2_o_epZs
-- ------------------------------------------------------
-- Server version	5.0.27

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `access_tree`
--

DROP TABLE IF EXISTS `access_tree`;
CREATE TABLE `access_tree` (
  `id` int(11) NOT NULL auto_increment,
  `flag_name` varchar(32) default NULL,
  `flag_description` varchar(255) default NULL,
  `parent_flag_id` int(11) default NULL,
  `parent_flag_name` varchar(32) default NULL,
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `app_config`
--

DROP TABLE IF EXISTS `app_config`;
CREATE TABLE `app_config` (
  `id` int(11) NOT NULL auto_increment,
  `c_id` varchar(60) NOT NULL default '',
  `value` text NOT NULL,
  `is_frozen` tinyint(4) NOT NULL default '0',
  `is_passive` tinyint(4) NOT NULL default '0',
  `modtime` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `C_ID` (`c_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `article_categories`
--

DROP TABLE IF EXISTS `article_categories`;
CREATE TABLE `article_categories` (
  `id` int(11) NOT NULL auto_increment,
  `category` varchar(128) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Table structure for table `articles`
--

DROP TABLE IF EXISTS `articles`;
CREATE TABLE `articles` (
  `id` int(11) NOT NULL auto_increment,
  `subject` varchar(255) default NULL,
  `author` varchar(128) default NULL,
  `category` varchar(128) default NULL,
  `body` mediumtext,
  `published` enum('0','1') default '0',
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `associated_files` varchar(128) default NULL,
  `associated_links` varchar(128) default NULL,
  `enable_comments` enum('0','1') default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `article_id` int(11) NOT NULL default '0',
  `parent_id` int(11) NOT NULL default '0',
  `subject` varchar(255) default NULL,
  `name` varchar(128) default NULL,
  `url` varchar(255) default NULL,
  `comment` text NOT NULL,
  `create_time` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=38 DEFAULT CHARSET=latin1;

--
-- Table structure for table `c_banned_words`
--

DROP TABLE IF EXISTS `c_banned_words`;
CREATE TABLE `c_banned_words` (
  `id` int(11) NOT NULL auto_increment,
  `word` varchar(128) default NULL,
  `create_time` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

--
-- Table structure for table `copy`
--

DROP TABLE IF EXISTS `copy`;
CREATE TABLE `copy` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `lang` varchar(12) NOT NULL default 'en',
  `name` varchar(255) default NULL,
  `copy` mediumtext,
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

--
-- Table structure for table `counter`
--

DROP TABLE IF EXISTS `counter`;
CREATE TABLE `counter` (
  `id` int(11) NOT NULL auto_increment,
  `count` int(11) NOT NULL default '0',
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `event_log`
--

DROP TABLE IF EXISTS `event_log`;
CREATE TABLE `event_log` (
  `id` bigint(20) NOT NULL auto_increment,
  `username` varchar(80) NOT NULL default '',
  `timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  `action` varchar(128) NOT NULL default '',
  `details` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=54 DEFAULT CHARSET=latin1;

--
-- Table structure for table `event_places`
--

DROP TABLE IF EXISTS `event_places`;
CREATE TABLE `event_places` (
  `id` int(11) NOT NULL auto_increment,
  `place` varchar(255) NOT NULL default '',
  `allow_overlap` enum('0','1') default '1',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `event_types`
--

DROP TABLE IF EXISTS `event_types`;
CREATE TABLE `event_types` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(128) NOT NULL default '',
  `allow_overlap` enum('0','1') NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
CREATE TABLE `events` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(128) default NULL,
  `description` text,
  `summary` varchar(255) default NULL,
  `start_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `end_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `place` varchar(255) default NULL,
  `show_event` enum('0','1') NOT NULL default '0',
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `recurring_event` enum('0','1') NOT NULL default '0',
  `recur_interval` varchar(8) default NULL,
  `recur_until` datetime NOT NULL default '0000-00-00 00:00:00',
  `coordinator` varchar(80) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `files`
--

DROP TABLE IF EXISTS `files`;
CREATE TABLE `files` (
  `id` int(11) NOT NULL auto_increment,
  `added_date` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `file_name` varchar(255) default NULL,
  `data` longblob,
  `file_type` enum('generic','image','music','document') default NULL,
  `size` bigint(20) default NULL,
  `description` text,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

--
-- Table structure for table `files_data`
--

DROP TABLE IF EXISTS `files_data`;
CREATE TABLE `files_data` (
  `id` int(11) NOT NULL default '0',
  `height` int(11) default NULL,
  `width` int(11) default NULL,
  `artist` varchar(128) default NULL,
  `time` varchar(16) default NULL,
  `album` varchar(128) default NULL,
  `track` tinyint(4) default NULL,
  `song_name` varchar(128) default NULL,
  `year` smallint(6) default NULL,
  `content` text,
  `media_type` varchar(128) default NULL,
  PRIMARY KEY  (`id`),
  KEY `artist` (`artist`),
  KEY `album` (`album`),
  KEY `song_name` (`song_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `link_categories`
--

DROP TABLE IF EXISTS `link_categories`;
CREATE TABLE `link_categories` (
  `id` int(11) NOT NULL auto_increment,
  `category` varchar(128) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `links`
--

DROP TABLE IF EXISTS `links`;
CREATE TABLE `links` (
  `id` int(11) NOT NULL auto_increment,
  `short_name` varchar(128) default NULL,
  `long_name` varchar(255) default NULL,
  `url` text,
  `category` varchar(80) default NULL,
  `published` enum('0','1') NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `r_banned_words`
--

DROP TABLE IF EXISTS `r_banned_words`;
CREATE TABLE `r_banned_words` (
  `id` int(11) NOT NULL auto_increment,
  `word` varchar(128) default NULL,
  `create_time` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `recur_dates`
--

DROP TABLE IF EXISTS `recur_dates`;
CREATE TABLE `recur_dates` (
  `id` int(11) NOT NULL auto_increment,
  `event_id` int(11) NOT NULL default '0',
  `start_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `end_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `recur_number` int(11) NOT NULL default '0',
  `type` varchar(128) default NULL,
  `place` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`),
  KEY `start_time` (`start_time`),
  KEY `end_time` (`end_time`),
  KEY `type` (`type`),
  KEY `place` (`place`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `referrers`
--

DROP TABLE IF EXISTS `referrers`;
CREATE TABLE `referrers` (
  `id` int(11) NOT NULL auto_increment,
  `search_engine` varchar(128) default NULL,
  `query_string` varchar(255) default NULL,
  `full_href` text,
  `create_time` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `session_id` varchar(100) NOT NULL default '',
  `name` varchar(25) NOT NULL default '',
  `value` text NOT NULL,
  `expire_timestamp` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  KEY `session_id` (`session_id`),
  KEY `expire_timestamp` (`expire_timestamp`)
) ENGINE=MyISAM AUTO_INCREMENT=19923 DEFAULT CHARSET=latin1;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `type` varchar(64) NOT NULL,
  `count` int(11) NOT NULL default '1',
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `ent_id` int(11) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;

--
-- Table structure for table `task_attributes`
--

DROP TABLE IF EXISTS `task_attributes`;
CREATE TABLE `task_attributes` (
  `id` int(11) NOT NULL auto_increment,
  `task_id` int(11) default NULL,
  `attribute_name` varchar(255) default NULL,
  `attribute_value` varchar(255) default NULL,
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `task_attribs` (`attribute_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `task_categories`
--

DROP TABLE IF EXISTS `task_categories`;
CREATE TABLE `task_categories` (
  `id` int(11) NOT NULL auto_increment,
  `category` varchar(128) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
CREATE TABLE `tasks` (
  `id` int(11) NOT NULL auto_increment,
  `parent` int(11) default '0',
  `name` varchar(255) default NULL,
  `category` varchar(128) NOT NULL default 'General',
  `creator` varchar(128) NOT NULL default '',
  `owner` varchar(128) NOT NULL default '',
  `description` text,
  `comment_log` text,
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `due_time` datetime default NULL,
  `eta_time` datetime default NULL,
  `complete_time` datetime default NULL,
  `factor_likeness` tinyint(4) default NULL,
  `factor_satisfaction` tinyint(4) default NULL,
  `factor_stress` tinyint(4) default NULL,
  `factor_coop` tinyint(4) default NULL,
  `factor_difficulty` tinyint(4) default NULL,
  `completed` enum('0','1') default '0',
  `active` enum('0','1') default '0',
  `published` enum('0','1') default '0',
  `extended_attributes` enum('0','1') default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `user_attributes`
--

DROP TABLE IF EXISTS `user_attributes`;
CREATE TABLE `user_attributes` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `attribute_name` varchar(255) default NULL,
  `attribute_value` varchar(255) default NULL,
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  PRIMARY KEY  (`id`),
  KEY `user_attribs` (`attribute_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `username` varchar(80) NOT NULL default '',
  `password` varchar(80) NOT NULL default '',
  `common_name` varchar(128) default NULL,
  `create_time` datetime default NULL,
  `modify_time` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
  `flags` text,
  `rudiments` text,
  `extended_attributes` enum('0','1') default '0',
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2006-12-10  6:19:35

INSERT INTO users (username, password, common_name, create_time, flags) VALUES ('admin', md5('temp123'), 'Administrator', now(), 'a,s,u');
