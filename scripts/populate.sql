USE cycle;
SET GLOBAL log_bin_trust_function_creators = 1;
-- Schedule (MySQL 5.7)
CREATE TABLE `Schedule` (
  `time` int NOT NULL,
  `#t` int NOT NULL,
  `op` char(1) NOT NULL,
  `attr` varchar(10) NOT NULL,
  UNIQUE (`time`)
);


-- example_01 (MySQL 5.7)
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
(1, 1,  'R',  'X'),
(2, 2,  'R',  'X'),
(3, 2,  'W',  'X'),
(4, 1,  'W',  'X'),
(5, 2,  'C',  '-'),
(6, 1,  'C',  '-');

