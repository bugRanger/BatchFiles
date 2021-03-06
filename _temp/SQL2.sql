﻿DECLARE @tableName NVARCHAR(MAX);
SET @tableName = 'Competition';
DECLARE @query NVARCHAR(MAX);
SET @query = '';

--REGION FOREING KEYS
DECLARE @FKeyName NVARCHAR(MAX)
       ,@FKeyColumn NVARCHAR(MAX)
       ,@FKeyRefTable NVARCHAR(MAX)
       ,@FKeyRefColumn NVARCHAR(MAX)
       ,@FKeyRuleDEL NVARCHAR(MAX)
       ,@FKeyRuleUPD NVARCHAR(MAX);
DECLARE foreingKeyCursor CURSOR FOR SELECT
  C.CONSTRAINT_NAME
 ,KCU.COLUMN_NAME
 ,C2.TABLE_NAME
 ,KCU2.COLUMN_NAME
 ,RC.DELETE_RULE
 ,RC.UPDATE_RULE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS C
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
  ON C.CONSTRAINT_SCHEMA = KCU.CONSTRAINT_SCHEMA
  AND C.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS RC
  ON C.CONSTRAINT_SCHEMA = RC.CONSTRAINT_SCHEMA
  AND C.CONSTRAINT_NAME = RC.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS C2
  ON RC.UNIQUE_CONSTRAINT_SCHEMA = C2.CONSTRAINT_SCHEMA
  AND RC.UNIQUE_CONSTRAINT_NAME = C2.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU2
  ON C2.CONSTRAINT_SCHEMA = KCU2.CONSTRAINT_SCHEMA
  AND C2.CONSTRAINT_NAME = KCU2.CONSTRAINT_NAME
  AND KCU.ORDINAL_POSITION = KCU2.ORDINAL_POSITION
WHERE C.CONSTRAINT_TYPE = 'FOREIGN KEY'
AND C.TABLE_NAME = @tableName
ORDER BY C.CONSTRAINT_NAME
-- Открываем курсор.
OPEN foreingKeyCursor;
-- Двигаем курсор.
FETCH foreingKeyCursor INTO @FKeyName, @FKeyColumn, @FKeyRefTable, @FKeyRefColumn, @FKeyRuleDEL, @FKeyRuleUPD;
WHILE (@@FETCH_STATUS = 0)
BEGIN
-- Формируем инструкции.
SET @query = 'IF OBJECT_ID(''' + @FKeyName + ''') IS NULL ALTER TABLE [' + @tableName + '] ADD CONSTRAINT '
+ @FKeyName + ' FOREIGN KEY ([' + @FKeyColumn + ']) REFERENCES [' + @FKeyRefTable + '] ([' + @FKeyRefColumn + '])'
+
CASE
  WHEN @FKeyRuleDEL IS NOT NULL AND
    @FKeyRuleDEL != 'NO ACTION' THEN ' ON DELETE ' + @FKeyRuleDEL
  ELSE ''
END
+
CASE
  WHEN @FKeyRuleUPD IS NOT NULL AND
    @FKeyRuleUPD != 'NO ACTION' THEN ' ON UPDATE ' + @FKeyRuleUPD
  ELSE ''
END
+ ';';
PRINT @query;
SET @query = '';
-- Двигаем курсор.
FETCH foreingKeyCursor INTO @FKeyName, @FKeyColumn, @FKeyRefTable, @FKeyRefColumn, @FKeyRuleDEL, @FKeyRuleUPD;
END
-- Завершаем работу с курсором.
CLOSE foreingKeyCursor;
DEALLOCATE foreingKeyCursor;
--ENDREGION FOREING KEYS