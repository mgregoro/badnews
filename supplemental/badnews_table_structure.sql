-- MySQL dump 9.11
--
-- Host: localhost    Database: bndev
-- ------------------------------------------------------
-- Server version	4.0.22

--
-- Table structure for table `access_tree`
--

CREATE TABLE access_tree (
  id int(11) NOT NULL auto_increment,
  flag_name varchar(32) default NULL,
  flag_description varchar(255) default NULL,
  parent_flag_id int(11) default NULL,
  parent_flag_name varchar(32) default NULL,
  create_time datetime default NULL,
  modify_time timestamp(14) NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `app_config`
--

CREATE TABLE app_config (
  id int(11) NOT NULL auto_increment,
  c_id varchar(60) NOT NULL default '',
  value text NOT NULL,
  is_frozen tinyint(4) NOT NULL default '0',
  is_passive tinyint(4) NOT NULL default '0',
  modtime timestamp(14) NOT NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY C_ID (c_id)
) TYPE=MyISAM;

--
-- Table structure for table `article_categories`
--

CREATE TABLE article_categories (
  id int(11) NOT NULL auto_increment,
  category varchar(128) NOT NULL default '',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `articles`
--

CREATE TABLE articles (
  id int(11) NOT NULL auto_increment,
  subject varchar(255) default NULL,
  author varchar(128) default NULL,
  category varchar(128) default NULL,
  body mediumtext,
  published enum('0','1') default '0',
  create_time datetime default NULL,
  modify_time timestamp(14) NOT NULL,
  associated_files varchar(128) default NULL,
  associated_links varchar(128) default NULL,
  enable_comments enum('0','1') default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `comments`
--

CREATE TABLE comments (
  id int(11) NOT NULL auto_increment,
  article_id int(11) NOT NULL default '0',
  parent_id int(11) NOT NULL default '0',
  subject varchar(255) default NULL,
  name varchar(128) default NULL,
  url varchar(255) default NULL,
  comment text NOT NULL,
  create_time datetime default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `counter`
--

CREATE TABLE counter (
  id int(11) NOT NULL auto_increment,
  count int(11) NOT NULL default '0',
  modify_time timestamp(14) NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `event_log`
--

CREATE TABLE event_log (
  id bigint(20) NOT NULL auto_increment,
  username varchar(80) NOT NULL default '',
  timestamp datetime NOT NULL default '0000-00-00 00:00:00',
  action varchar(128) NOT NULL default '',
  details varchar(255) NOT NULL default '',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

CREATE TABLE event_places (
  id int(11) NOT NULL auto_increment,
  place varchar(255) NOT NULL default '',
  allow_overlap enum('0','1') default '1',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `event_types`
--

CREATE TABLE event_types (
  id int(11) NOT NULL auto_increment,
  type varchar(128) NOT NULL default '',
  allow_overlap enum('0','1') NOT NULL default '1',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `events`
--

CREATE TABLE events (
  id int(11) NOT NULL auto_increment,
  type varchar(128) default NULL,
  description text,
  summary varchar(255) default NULL,
  start_time datetime NOT NULL default '0000-00-00 00:00:00',
  end_time datetime NOT NULL default '0000-00-00 00:00:00',
  place varchar(255) default NULL,
  show_event enum('0','1') NOT NULL default '0',
  modify_time timestamp(14) NOT NULL,
  recurring_event enum('0','1') NOT NULL default '0',
  recur_interval varchar(8) default NULL,
  recur_until datetime NOT NULL default '0000-00-00 00:00:00',
  coordinator varchar(80) default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `files`
--

CREATE TABLE files (
  id int(11) NOT NULL auto_increment,
  added_date timestamp(14) NOT NULL,
  file_name varchar(255) default NULL,
  data longblob,
  file_type enum('generic','image','music','document') default NULL,
  size bigint(20) default NULL,
  description text,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `files_data`
--

CREATE TABLE files_data (
  id int(11) NOT NULL default '0',
  height int(11) default NULL,
  width int(11) default NULL,
  artist varchar(128) default NULL,
  time varchar(16) default NULL,
  album varchar(128) default NULL,
  track tinyint(4) default NULL,
  song_name varchar(128) default NULL,
  year smallint(6) default NULL,
  content text,
  media_type varchar(128) default NULL,
  PRIMARY KEY  (id),
  KEY artist (artist),
  KEY album (album),
  KEY song_name (song_name)
) TYPE=MyISAM;

--
-- Table structure for table `link_categories`
--

CREATE TABLE link_categories (
  id int(11) NOT NULL auto_increment,
  category varchar(128) default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `links`
--

CREATE TABLE links (
  id int(11) NOT NULL auto_increment,
  short_name varchar(128) default NULL,
  long_name varchar(255) default NULL,
  url text,
  category varchar(80) default NULL,
  published enum('0','1') NOT NULL default '1',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `r_banned_words`
--

CREATE TABLE r_banned_words (
  id int(11) NOT NULL auto_increment,
  word varchar(128) default NULL,
  create_time datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `recur_dates`
--

CREATE TABLE recur_dates (
  id int(11) NOT NULL auto_increment,
  event_id int(11) NOT NULL default '0',
  start_time datetime NOT NULL default '0000-00-00 00:00:00',
  end_time datetime NOT NULL default '0000-00-00 00:00:00',
  recur_number int(11) NOT NULL default '0',
  type varchar(128) default NULL,
  place varchar(255) NOT NULL default '',
  PRIMARY KEY  (id),
  KEY start_time (start_time),
  KEY end_time (end_time),
  KEY type (type),
  KEY place (place)
) TYPE=MyISAM;

--
-- Table structure for table `referrers`
--

CREATE TABLE referrers (
  id int(11) NOT NULL auto_increment,
  search_engine varchar(128) default NULL,
  query_string varchar(255) default NULL,
  full_href text,
  create_time datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `sessions`
--

CREATE TABLE sessions (
  id int(11) NOT NULL auto_increment,
  session_id varchar(100) NOT NULL default '',
  name varchar(25) NOT NULL default '',
  value text NOT NULL,
  expire_timestamp datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY  (id),
  KEY session_id (session_id),
  KEY expire_timestamp (expire_timestamp)
) TYPE=MyISAM;

--
-- Table structure for table `task_attributes`
--

CREATE TABLE task_attributes (
  id int(11) NOT NULL auto_increment,
  task_id int(11) default NULL,
  attribute_name varchar(255) default NULL,
  attribute_value varchar(255) default NULL,
  create_time datetime default NULL,
  modify_time timestamp(14) NOT NULL,
  PRIMARY KEY  (id),
  KEY task_attribs (attribute_name)
) TYPE=MyISAM;

--
-- Table structure for table `task_categories`
--

CREATE TABLE task_categories (
  id int(11) NOT NULL auto_increment,
  category varchar(128) default NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `tasks`
--

CREATE TABLE tasks (
  id int(11) NOT NULL auto_increment,
  parent int(11) default '0',
  name varchar(255) default NULL,
  category varchar(128) NOT NULL default 'General',
  creator varchar(128) NOT NULL default '',
  owner varchar(128) NOT NULL default '',
  description text,
  comment_log text,
  create_time datetime default NULL,
  modify_time timestamp(14) NOT NULL,
  due_time datetime default NULL,
  eta_time datetime default NULL,
  complete_time datetime default NULL,
  factor_likeness tinyint(4) default NULL,
  factor_satisfaction tinyint(4) default NULL,
  factor_stress tinyint(4) default NULL,
  factor_coop tinyint(4) default NULL,
  factor_difficulty tinyint(4) default NULL,
  completed enum('0','1') default '0',
  active enum('0','1') default '0',
  published enum('0','1') default '0',
  extended_attributes enum('0','1') default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `tags`
-- (MySQL 5)
--

DROP TABLE IF EXISTS `tags`;
CREATE TABLE `tags` (
  id int(11) NOT NULL auto_increment,
  name varchar(255) NOT NULL,
  type varchar(64) NOT NULL,
  ent_id int(11) NOT NULL,
  count int(11) NOT NULL default '1',
  modify_time timestamp NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table `user_attributes`
--

CREATE TABLE user_attributes (
  id int(11) NOT NULL auto_increment,
  user_id int(11) default NULL,
  attribute_name varchar(255) default NULL,
  attribute_value varchar(255) default NULL,
  create_time datetime default NULL,
  modify_time timestamp(14) NOT NULL,
  PRIMARY KEY  (id),
  KEY user_attribs (attribute_name)
) TYPE=MyISAM;

--
-- Table structure for table `users`
--

CREATE TABLE users (
  id int(11) NOT NULL auto_increment,
  username varchar(80) NOT NULL default '',
  password varchar(80) NOT NULL default '',
  common_name varchar(128) default NULL,
  create_time datetime default NULL,
  modify_time timestamp(14) NOT NULL,
  -- flags set('a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z') default 'u',
  flags text,
  rudiments text,
  extended_attributes enum('0','1') default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

INSERT INTO users (username, password, common_name, create_time, flags) VALUES ('admin', md5('temp123'), 'Administrator', now(), 'a,s,u');
