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
   target INT NOT NULL,
   visited BOOLEAN DEFAULT FALSE
);

DROP FUNCTION IF EXISTS isEquivalentConflict;
DELIMITER //
CREATE FUNCTION isEquivalentConflict() RETURNS BOOLEAN
BEGIN
   DECLARE done BOOLEAN DEFAULT FALSE;

   DECLARE timeA INT;
   DECLARE idA INT;
   DECLARE opA CHAR(1);
   DECLARE attrA VARCHAR(10);

   DECLARE timeB INT;
   DECLARE idB INT;
   DECLARE opB CHAR(1);
   DECLARE attrB VARCHAR(10);

   DECLARE edgeId INT;
   DECLARE target INT;
   DECLARE source INT;
   DECLARE visited BOOLEAN;

   DECLARE has_cycle BOOLEAN DEFAULT FALSE;
  
   -- select all the rows from the Schedule table and store them in some temporary table
   -- iterate over the rows in the temporary table and perform the operations
   DECLARE tmp CURSOR FOR SELECT * FROM Schedule ORDER BY time;
   DECLARE edgetmp CURSOR FOR SELECT * FROM edge;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   OPEN tmp;

   -- SELECT THE FIRST ROW
   FETCH tmp INTO timeA, idA, opA, attrA;

   read_loop: LOOP
      IF done THEN
         LEAVE read_loop;
      END IF;
      -- Makes it quadratic on reads
      FETCH tmp INTO timeB, idB, opB, attrB;

      -- if both operations are reads 'R'
      -- if it is the same transaction OR
      -- if it is different attributes
      -- Skip the loop
      IF (opA = "R" AND opB = "R") OR
         (idA = idB) OR
         (attrA != attrB) THEN
         ITERATE read_loop;
      END IF;

      -- checking if the transaction is conflicting
      -- rules: (R, W), (W, R), (W, W)
      IF (opA = "W" AND opB = "W") OR 
         (opA = "W" AND opB = "R") OR 
         (opA = "R" AND opB = "W") THEN
         INSERT INTO edge (source, target) VALUES (idA, idB);
      END IF;

      -- making A = B
      SET timeA = timeB;
      SET idA = idB;
      SET opA = opB;
      SET attrA = attrB;
   END LOOP;
   CLOSE tmp;

   OPEN edgetmp;
   SET done = FALSE;
   -- Checks for cycles
   check_cycles: LOOP
      IF done THEN
         LEAVE check_cycles;
      END IF;
      FETCH edgetmp INTO edgeId, source, target, visited;

      IF NOT visited THEN
         UPDATE edge SET visited = TRUE WHERE id = edgeId;
      ELSE 
         SET has_cycle = TRUE;
         LEAVE check_cycles;
      END IF;
   END LOOP;
   CLOSE edgetmp;

   RETURN has_cycle;
END; //
-- Reset delimiter
DELIMITER ;

-- Testing
TRUNCATE TABLE Schedule;

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
SELECT isEquivalentConflict() AS resp;

TRUNCATE TABLE Schedule;
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
SELECT isEquivalentConflict() AS resp;
