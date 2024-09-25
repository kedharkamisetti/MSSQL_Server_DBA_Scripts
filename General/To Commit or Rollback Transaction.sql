--COMMIT saves all changes made in a transaction permanently, while ROLLBACK undoes those changes. For example, COMMIT finalizes a new record, while ROLLBACK discards it.
BEGIN TRAN;
INSERT INTO tablename VALUES ('value1');
COMMIT / ROLLBACK;