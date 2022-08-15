/*

Cycle Detection using MySQL 5.7
Autores: Henrique Coutinho Layber e Renan Moreira Gomes

Para executar o script, execute esse .sql em um banco de dados MySQL 5.7

O script criará as tabelas necessárias para o funcionamento do algoritmo.
Para cada exemplo, o script limpará as tabelas e inserirá os dados do exemplo.

O script irá executar o algoritmo e retornará 0 se o algoritmo detectar um ciclo e 1 caso contrário.

Temos ciência de que o algoritmo pode não funcionar em 100% dos casos,
porém tentamos resolver o problema tanto como possível, tanto em MySQL quanto em PostgreSQL.

Na submissão do trabalho, temos que:
- Renan Moreira Gomes enviará o código em MySQL.
- Henrique Coutinho Layber enviará o código em PostgreSQL.

*/

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
   visited BOOLEAN DEFAULT FALSE,
   CHECK (source <> target)
);

DROP FUNCTION IF EXISTS testeEquivalenciaPorConflito;
DELIMITER //
CREATE FUNCTION testeEquivalenciaPorConflito() RETURNS INT
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

   DECLARE edge_id INT;
   DECLARE edge_target INT;
   DECLARE edge_source INT;
   DECLARE edge_visited BOOLEAN;

   DECLARE has_cycle INT DEFAULT 0;
  
   -- select all the rows from the Schedule table and store them in some temporary table
   -- iterate over the rows in the temporary table and perform the operations
   DECLARE schedule_cursor CURSOR FOR SELECT * FROM Schedule ORDER BY `time`;
   DECLARE edge_cursor CURSOR FOR SELECT * FROM edge ORDER BY id;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   OPEN schedule_cursor;
   read_loop: LOOP
      IF done THEN
         LEAVE read_loop;
      END IF;

      FETCH schedule_cursor INTO timeA, idA, opA, attrA;

      -- Case 1 & 3 (mixed): 
      IF opA = 'W' OR opA = 'R' THEN
         -- Select the first `W` op from a different schedule
         SELECT `#t` INTO edge_source FROM Schedule 
            WHERE `#t` <> idA AND `op` = 'W' AND `time` > timeA
            ORDER BY `time`;
         IF edge_source IS NOT NULL THEN
            INSERT INTO edge (`source`, `target`) VALUES (edge_source, idA);
         END IF;
      END IF;
      -- Case 2
      IF opA = 'W' THEN
         SELECT `#t` INTO edge_source FROM Schedule 
            WHERE `#t` <> idA AND `op` = 'R' AND `time` > timeA
            ORDER BY `time`;
          IF edge_source IS NOT NULL THEN
            INSERT INTO edge (`source`, `target`) VALUES (edge_source, idA);
         END IF;
      END IF;
   END LOOP;
   CLOSE schedule_cursor;

   OPEN edge_cursor;
   SET done = FALSE;
   FETCH edge_cursor INTO edge_id, edge_source, edge_target, edge_visited;
   -- Checks for cycles
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