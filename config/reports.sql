-- MySQL dump 10.13  Distrib 5.5.43, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: reports
-- ------------------------------------------------------
-- Server version	5.5.43-0ubuntu0.14.04.1

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
-- Table structure for table `final_reports`
--

DROP TABLE IF EXISTS `final_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `final_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cancelled` tinyint(1) NOT NULL DEFAULT '0',
  `old_report` tinyint(1) NOT NULL DEFAULT '0',
  `patient_id` varchar(15) COLLATE utf8_unicode_ci DEFAULT NULL,
  `patient_name` text COLLATE utf8_unicode_ci,
  `patient_dob` date DEFAULT NULL,
  `patient_sex` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `patient_class` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `accession_number` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `diag` text COLLATE utf8_unicode_ci,
  `procedure_name` text COLLATE utf8_unicode_ci,
  `procedure_id` varchar(128) COLLATE utf8_unicode_ci DEFAULT NULL,
  `requesting` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `dept` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `site` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `technologist` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `assisting` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `assisting_id` varchar(8) COLLATE utf8_unicode_ci DEFAULT NULL,
  `attending` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `attending_id` varchar(8) COLLATE utf8_unicode_ci DEFAULT NULL,
  `mrn` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `report` text COLLATE utf8_unicode_ci,
  `timestamp` datetime DEFAULT NULL,
  `examtime` datetime DEFAULT NULL,
  `date` date DEFAULT NULL,
  `examdate` date DEFAULT NULL,
  `status` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `service` varchar(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `transcriptionist` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `order_number` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `charge_number` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `some_id` (`patient_id`),
  KEY `accession_number` (`accession_number`),
  KEY `order_charge` (`order_number`,`charge_number`),
  KEY `time_index` (`timestamp`),
  KEY `date_index` (`date`),
  KEY `examtime_index` (`examtime`),
  KEY `examdate_index` (`examdate`),
  KEY `mod_index` (`modified`)
) ENGINE=InnoDB AUTO_INCREMENT=1088600 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-07-06 11:16:05
