DROP TABLE IF EXISTS `url_words`;
DROP TABLE IF EXISTS `words`;
DROP TABLE IF EXISTS `url`;

SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `words` (
  `word_id` int(11) NOT NULL auto_increment,
  `word_str` varchar(128) NOT NULL,
  PRIMARY KEY  (`word_id`),
  UNIQUE KEY (`word_str`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `url` (
  `url_id` int(11) NOT NULL auto_increment,
  `url_str` varchar(2048) NOT NULL,
  `url_time` float default NULL,
  `url_size` float default NULL,
  `url_fetched` datetime default NULL,
  `url_age` datetime default NULL,
  PRIMARY KEY  (`url_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `url_words` (
  `url_words_id` int(11) NOT NULL auto_increment,
  `url_word_count` int(11) NOT NULL,
  `url_id` int(11) NOT NULL,
  `word_id` int(11) NOT NULL,
  PRIMARY KEY  (`url_words_id`),
  KEY `url_id` (`url_id`),
  KEY `word_id` (`word_id`),
  CONSTRAINT `url_words_ibfk_1` FOREIGN KEY (`url_id`) REFERENCES `url` (`url_id`),
  CONSTRAINT `url_words_ibfk_2` FOREIGN KEY (`word_id`) REFERENCES `words` (`word_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
SET character_set_client = @saved_cs_client;

