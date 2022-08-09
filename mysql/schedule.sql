-- Schedule (MySQL 5.7)
CREATE TABLE `Schedule` (
  `time` int NOT NULL,
  `#t` int NOT NULL,
  `op` char(1) NOT NULL,
  `attr` varchar(10) NOT NULL,
  UNIQUE (`time`)
);
