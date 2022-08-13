-- example_01 (MySQL 5.7)
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
(1, 1,  'R',  'X'),
(2, 2,  'R',  'X'),
(3, 2,  'W',  'X'),
(4, 1,  'W',  'X'),
(5, 2,  'C',  '-'),
(6, 1,  'C',  '-');