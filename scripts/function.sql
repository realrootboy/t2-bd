-- function signature (MySQL 5.7)
DELIMITER //
DROP FUNCTION IF EXISTS testeEquivalenciaPorConflito;
CREATE FUNCTION testeEquivalenciaPorConflito ()
RETURNS INT
BEGIN
   -- table to store the result
   
   RETURN 1;
END; //

DELIMITER ;

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;
