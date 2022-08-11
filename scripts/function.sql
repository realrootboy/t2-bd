
-- TO RUN THIS SCRIPT JUST EXECUTE A BASH 
-- # mysql -uroot cycle < /scripts/function.sql

-- CREATE A EDGE TABLE IF NOT EXISTS
CREATE TABLE IF NOT EXISTS edge (
   id INT NOT NULL AUTO_INCREMENT,
   source INT NOT NULL,
   target INT NOT NULL,
   visited BOOLEAN DEFAULT FALSE,
   PRIMARY KEY (id)
);
-- DELETE FROM edge;

-- function signature (MySQL 5.7)
DELIMITER //
DROP FUNCTION IF EXISTS testeEquivalenciaPorConflito;
CREATE FUNCTION testeEquivalenciaPorConflito ()
RETURNS VARCHAR(255)
BEGIN
   DECLARE done INT DEFAULT FALSE;

   DECLARE timeA int;
   DECLARE idA int;
   DECLARE opA char(1);
   DECLARE attrA varchar(10);

   DECLARE timeB int;
   DECLARE idB int;
   DECLARE opB char(1);
   DECLARE attrB varchar(10);

   DECLARE edgeId int;
   DECLARE target int;
   DECLARE source int;
   DECLARE visited BOOLEAN;
  
   -- select all the rows from the Schedule table and store them in some temporary table
   -- iterate over the rows in the temporary table and perform the operations
   DECLARE tmp CURSOR FOR SELECT * FROM Schedule ORDER BY time;
   DECLARE edgetmp CURSOR FOR SELECT * FROM edge;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   OPEN tmp;

   DELETE FROM edge;

   -- SELECT THE FIRST ROW
   FETCH tmp INTO timeA, idA, opA, attrA;

   read_loop: LOOP
      IF done THEN
         LEAVE read_loop;
      END IF;
      FETCH tmp INTO timeB, idB, opB, attrB;

      -- if opA is R and opB is R then skip the loop
      IF opA = opB AND opA = "R" THEN
         ITERATE read_loop;
      END IF;

      -- if it is same transaction then skip the loop
      IF idB = idA THEN
         ITERATE read_loop;
      END IF;

      -- if it is different attribute then skip the loop
      IF attrA != attrB THEN
         ITERATE read_loop;
      END IF;

      -- checking if the transaction is conflicting
      -- rules: (R, W), (W, R), (W, W)
      IF opA = opB and opA = "W" THEN
         INSERT INTO edge (source, target) VALUES (idA, idB);
      END IF;

      IF opA = "W" and opB = "R" THEN
         INSERT INTO edge (source, target) VALUES (idA, idB);
      END IF;

      IF opA = "R" and opB = "W" THEN
         INSERT INTO edge (source, target) VALUES (idA, idB);
      END IF;

      -- making A = B
      SET timeA = timeB;
      SET idA = idB;
      SET opA = opB;
      SET attrA = attrB;

   END LOOP;

   CLOSE tmp;

   SET done = FALSE;

   
   -- DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   OPEN edgetmp;

   -- THIS STEP SHOULD BE DETECT A LOOP
   check_loop: LOOP
      IF done THEN
         LEAVE check_loop;
      END IF;
      FETCH edgetmp INTO edgeId, source, target, visited;

      IF NOT visited THEN
         UPDATE edge SET visited = TRUE WHERE id = edgeId;
      END IF;

     

   END LOOP;

   RETURN "Serializavel";
END; //

DELIMITER ;

-- calling functio
SELECT testeEquivalenciaPorConflito() AS resp;
SELECT * FROM `Schedule`;
SELECT source, target, visited FROM cycle.edge;