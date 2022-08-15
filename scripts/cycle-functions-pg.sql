-- \c cycles;
CREATE TABLE IF NOT EXISTS Schedule (
   "time" INT PRIMARY KEY,
   "#t" INT NOT NULL,
   "op" CHAR(1) NOT NULL,
   "attr" CHAR(1) NOT NULL
);

CREATE TEMPORARY TABLE edge (
   "id" SERIAL,
   "source" INT,
   "target" INT,
   "visited" BOOLEAN DEFAULT FALSE,
   CHECK (source <> target),
   PRIMARY KEY (source, target)
);

-- Iterate through rows in the 
CREATE OR REPLACE FUNCTION initEdgeTable () 
RETURNS void AS $$
    DECLARE current record;
    BEGIN
    	FOR current IN SELECT * FROM Schedule ORDER BY "time" LOOP -- For each current action of (Ti)
    		IF current."op" = 'W' THEN -- If the operation is a write and there is another "R" or "W" op on the same attr from another transaction, case 1 and 3 of the algorithm
                INSERT INTO edge(source, target) (
                    SELECT current."#t" AS source, "#t" AS target FROM Schedule WHERE 
                        "#t" <> current."#t" AND
                        "time" > current."time" AND
                        ("op" = 'W' OR "op" = 'R') AND 
                        "attr" = current."attr")
                    ON CONFLICT DO NOTHING;
            ELSEIF current."op" = 'R' THEN -- Case 2
                INSERT INTO edge(source, target) (
                    SELECT current."#t" AS source, "#t" AS target FROM Schedule WHERE 
                        "#t" <> current."#t" AND
                        "time" > current."time" AND
                        "op" = 'W' AND 
                        "attr" = current."attr")
                    ON CONFLICT DO NOTHING;
     		END IF;
    	END LOOP;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION DFS () 
RETURNS INTEGER AS $$
    -- Pushes all edges with no incoming edge into the stack
    DECLARE stack INTEGER[] = (SELECT array_agg(id) FROM edge LIMIT 1);
    DECLARE current INTEGER;
    BEGIN
        LOOP
            -- If array is empty, transversal is done
            IF stack IS NULL THEN
                RETURN 0;
            END IF;
            -- RAISE NOTICE 'STACK %', stack;
            -- Set current to the first element of the array
            current = stack[1];
            RAISE NOTICE 'Current %', current;
            -- IF current IS NULL THEN
            --     RETURN 0;
            -- END IF;
            -- If current is visited, there is a cycle
            IF (SELECT visited FROM edge WHERE id = current) THEN
                RETURN 1;
            END IF;
            -- Set every vertex from current's source as visited
            UPDATE edge SET visited = true WHERE source = (
               SELECT source FROM edge WHERE id = current
            ) AND target = (
               SELECT target FROM edge WHERE id = current
            );
            -- Remove self from stack (pop)
            -- RAISE NOTICE 'Stack before %', stack;
            stack = stack[2:array_length(stack, 1)];
            -- RAISE NOTICE 'Stack after %', stack;
            -- Queues all targets of current edge (nonvisited first)
            stack = (SELECT array_agg(id) FROM edge WHERE source = (
               SELECT target FROM edge
                  WHERE id = current ORDER BY visited ASC)) || stack;
            IF stack IS NULL THEN
               -- Enqueues a remaining unvisited edge
               stack = (SELECT array_agg(id) FROM edge WHERE visited = false) LIMIT 1;
            END IF;
        END LOOP;
    END;
$$ LANGUAGE plpgsql;

-- function signature (PostgreSQL 10)
CREATE OR REPLACE FUNCTION testeEquivalenciaPorConflito () 
RETURNS integer AS $$
    BEGIN
        PERFORM initEdgeTable();
        -- Currently only checks in a single random forest
        RETURN DFS();
    END;
$$ LANGUAGE plpgsql;

-- calling function
SELECT testeEquivalenciaPorConflito() AS resp;

-- TESTING

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- example_01 from spec (MySQL 5.7)
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1, 1,  'R',  'X'),
   (2, 2,  'R',  'X'),
   (3, 2,  'W',  'X'),
   (4, 1,  'W',  'X'),
   (5, 2,  'C',  '-'),
   (6, 1,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- example_02 from spec (MySQL 5.7)
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (7,   3,  'R',  'X'),
   (8,   3,  'R',  'Y'),
   (9,   4,  'R',  'X'),
   (10,  3,  'W',  'Y'),
   (11,  4,  'C',  '-'),
   (12,  3,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'W',  'X'),
   (3,   1,  'R',  'X');
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'R',  'X'),
   (3,   2,  'C',  '-'),
   (4,   1,  'W',  'X'),
   (5,   1,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,   1,  'R',  'X'),
   (2,   1,  'C',  '-'),
   (3,   2,  'W',  'X'),
   (4,   2,  'R',  'X'),
   (5,   2,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,   1,  'W',  'X'),
   (2,   2,  'W',  'X'),
   (3,   2,  'C',  '-'),
   (4,   1,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'R',  'X'),
   (3,   1,  'R',  'X'),
   (4,   2,  'C',  '-'),
   (5,   1,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,   1,  'R',  'X'),
   (2,   2,  'R',  'X'),
   (4,   2,  'C',  '-'),
   (5,   1,  'C',  '-');
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up simple example, out of order
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (5,   1,  'C',  '-'),
   (1,   1,  'R',  'X'),
   (4,   2,  'C',  '-'),
   (2,   2,  'R',  'X');
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
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
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,  1,  'W',   'X'),
   (2,  3,  'R',   'X'),
   (3,  2,  'R',   'X'),
   (4,  6,  'R',   'X'),
   (5,  2,  'W',   'Y'),
   (6,  4,  'R',   'Y'),
   (7,  3,  'W',   'Z'),
   (8,  6,  'R',   'Z'),
   (9,  4,  'W',   'A'),
   (10, 3,  'R',   'A'),
   (11, 5,  'W',   'B'),
   (12, 1,  'R',   'B'),
   (13, 6,  'W',   'C'),
   (14, 2,  'R',   'C'),
   (15, 1,  'C',   '-'),
   (16, 2,  'C',   '-'),
   (17, 3,  'C',   '-'),
   (18, 4,  'C',   '-'),
   (19, 5,  'C',   '-'),
   (20, 6,  'C',   '-');
SELECT * FROM Schedule;
-- resp should be 1
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;

TRUNCATE TABLE Schedule;
TRUNCATE TABLE edge;
-- Made up example
INSERT INTO Schedule (time, "#t", op, attr) VALUES
   (1,  1,  'W',   'X'),
   (2,  3,  'R',   'X'),
   (3,  2,  'R',   'X'),
   (4,  6,  'R',   'X'),
   (5,  2,  'W',   'Y'),
   (6,  4,  'R',   'Y'),
   (7,  3,  'W',   'Z'),
   (8,  6,  'R',   'Z'),
   (9,  4,  'W',   'A'),
   (10, 3,  'R',   'A'),
   (11, 5,  'W',   'B'),
   (12, 1,  'R',   'B'),
   (13, 6,  'R',   'C'),
   (14, 2,  'R',   'C'),
   (15, 1,  'C',   '-'),
   (16, 2,  'C',   '-'),
   (17, 3,  'C',   '-'),
   (18, 4,  'C',   '-'),
   (19, 5,  'C',   '-'),
   (20, 6,  'C',   '-');
SELECT * FROM Schedule;
-- resp should be 0
SELECT testeEquivalenciaPorConflito() AS Output;
SELECT * FROM edge;
