CREATE TABLE customers (id number(9,0) primary key, name varchar2(50));
INSERT INTO customers VALUES (1001, 'Salles Thomas');
INSERT INTO customers VALUES (1002, 'George Bailey');
INSERT INTO customers VALUES (1003, 'Edward Walker');
INSERT INTO customers VALUES (1004, 'Anne Kretchmar');

ALTER TABLE customers ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
COMMIT;
