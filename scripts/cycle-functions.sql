USE cycles;
CREATE TABLE IF NOT EXISTS `Schedule` (
   `time` INT NOT NULL UNIQUE,
   `#t` INT NOT NULL,
   `op` CHAR(1) NOT NULL,
   `attr` CHAR(1) NOT NULL
);

CREATE TEMPORARY TABLE edge (
   id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
   source INT NOT NULL,
   target INT,
   visited BOOLEAN DEFAULT FALSE,
   CHECK (source <> target)
);

DROP FUNCTION IF EXISTS testeEquivalenciaPorConflito;
DELIMITER //
CREATE FUNCTION testeEquivalenciaPorConflito() RETURNS INT
BEGIN
   DECLARE done BOOLEAN DEFAULT FALSE;

   DECLARE timeJ INT;
   DECLARE idJ INT;
   DECLARE opJ CHAR(1);
   DECLARE attrJ VARCHAR(10);

   DECLARE timeI INT;
   DECLARE idI INT;
   DECLARE opI CHAR(1);
   DECLARE attrI VARCHAR(10);

   DECLARE edge_id INT;
   DECLARE edge_target INT;
   DECLARE edge_source INT;
   DECLARE edge_visited BOOLEAN;

   DECLARE has_cycle INT DEFAULT 0;
  
   -- select all the rows from the Schedule table and store them in some temporary table
   -- iterate over the rows in the temporary table and perform the operations
   DECLARE schedule_cursor CURSOR FOR SELECT * FROM Schedule ORDER BY `time`;
   DECLARE schedule_cursor_inner CURSOR FOR SELECT * FROM Schedule
      WHERE `#t` <> idJ AND
      `time` > timeJ
      ORDER BY `time`;
   DECLARE edge_cursor CURSOR FOR SELECT * FROM edge ORDER BY id;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   -- For each schedule
   OPEN schedule_cursor;
      read_loop: LOOP
         FETCH schedule_cursor INTO timeJ, idJ, opJ, attrJ;
         IF done THEN
            LEAVE read_loop;
         END IF;

         INSERT INTO edge (source, target)
            SELECT (`#t`, idJ AS t) FROM Schedule
               WHERE `#t` <> idJ AND
                  `attr` = attrJ AND
                  `time` > timeJ AND (
                     (opJ = 'W' AND (`op` = 'W' OR `op` = 'R')) OR -- CASE 1 & 3
                     (opJ = 'R' AND `op` = 'W') -- CASE 2
                  );
      END LOOP;
   CLOSE schedule_cursor;

   -- Checks for cycles on `edge`
   OPEN edge_cursor;
      SET done = FALSE;
      FETCH edge_cursor INTO edge_id, edge_source, edge_target, edge_visited;
      check_cycles: LOOP
         IF done THEN
            LEAVE check_cycles;
         END IF;

         -- Follow the edge until leaf or cycle is found
         IF edge_visited THEN
            -- There is a cycle
            SET has_cycle = 1;
            LEAVE check_cycles;
         ELSE
            -- Set visited
            UPDATE edge SET `visited` = TRUE WHERE id = edge_id;
         END IF;

         -- Step to target
         SELECT `id`, `source`, `target`, `visited`
         INTO edge_id, edge_source, edge_target, edge_visited
         FROM edge
         WHERE `id` = edge_target;

         IF edge_id IS NULL THEN
            SET done = TRUE;
         END IF;
      END LOOP;
   CLOSE edge_cursor;

   RETURN 1 - has_cycle;
END; //
-- Reset delimiter
DELIMITER ;

-- Testing

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- example_01 from spec (MySQL 5.7)
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1, 1,  'R',  'X'),
   (2, 2,  'R',  'X'),
   (3, 2,  'W',  'X'),
   (4, 1,  'W',  'X'),
   (5, 2,  'C',  '-'),
   (6, 1,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- example_02 from spec (MySQL 5.7)
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (7,   3,  'R',  'X'),
   (8,   3,  'R',  'Y'),
   (9,   4,  'R',  'X'),
   (10,  3,  'W',  'Y'),
   (11,  4,  'C',  '-'),
   (12,  3,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'W',  'X'),
   (3,   1,  'R',  'X');
SELECT * FROM `Schedule`;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'R',  'X'),
   (3,   2,  'C',  '-'),
   (4,   1,  'W',  'X'),
   (5,   1,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'R',  'X'),
   (2,   1,  'C',  '-'),
   (3,   2,  'W',  'X'),
   (4,   2,  'R',  'X'),
   (5,   2,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'W',  'X'),
   (2,   2,  'W',  'X'),
   (3,   2,  'C',  '-'),
   (4,   1,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'R',  'X'),
   (3,   1,  'R',  'X'),
   (4,   2,  'C',  '-'),
   (5,   1,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'R',  'X'),
   (4,   2,  'C',  '-'),
   (5,   1,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example, out of order
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (5,   1,  'C',  '-'),
   (1,   1,  'R',  'X'),
   (4,   2,  'C',  '-'),
   (2,   2,  'R',  'X');
SELECT * FROM `Schedule`;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up example
INSERT INTO `Schedule` (`time`, `#t`, `op`, `attr`) VALUES
   (1,   1,  'W',  'X'),
   (2,   3,  'R',  'X'),
   (3,   2,  'R',  'X'),
   (4,   6,  'R',  'X'),
   (5,   2,  'W',  'Y'),
   (6,   4,  'R',  'Y'),
   (7,   3,  'W',  'Z'),
   (8,   6,  'R',  'Z'),
   (9,   4,  'W',  'A'),
   (10,  3,  'R',  'A'),
   (11,  5,  'W',  'B'),
   (12,  1,  'R',  'A'),
   (13,  1,  'C',  '-'),
   (14,  2,  'C',  '-'),
   (15,  3,  'C',  '-'),
   (16,  4,  'C',  '-'),
   (17,  5,  'C',  '-'),
   (18,  6,  'C',  '-');
SELECT * FROM `Schedule`;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS `Output`;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
