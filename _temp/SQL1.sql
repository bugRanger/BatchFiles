DECLARE @tableName NVARCHAR(MAX);
SET @tableName = 'tDefaultValue';
DECLARE @query NVARCHAR(MAX);
SET @query = '';



--REGION INDEXES
DECLARE @IndexObjectID INT
       ,@IndexID INT
       ,@IndexName NVARCHAR(MAX)
       ,@IndexType NVARCHAR(MAX)
       ,@IndexUnique BIT;
DECLARE indexesCursor CURSOR FOR SELECT
  i.object_id
 ,i.index_id
 ,i.name
 ,i.type_desc
 ,i.is_unique
FROM sys.indexes i
JOIN sys.objects o
  ON i.object_id = o.object_id
WHERE i.type = 2
AND i.is_primary_key = 0
AND o.type = 'U'
AND o.object_id = OBJECT_ID(@tableName)
ORDER BY o.[name], i.[name];
-- Открываем курсор.
OPEN indexesCursor;
-- Двигаем курсор.
FETCH indexesCursor INTO @IndexObjectID, @IndexID, @IndexName, @IndexType, @IndexUnique;
WHILE (@@FETCH_STATUS = 0)
BEGIN
-- Формируем инструкции.
SET @query = '
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name=''' + @IndexName + ''' AND object_id = OBJECT_ID(''' + @tableName + '''))
BEGIN
    CREATE ' +
-- Уникальность.
CASE @IndexUnique
  WHEN 1 THEN 'UNIQUE '
  ELSE ''
END
-- Кластерный/Некластерный.
+ ISNULL(@IndexType, '') + ' '
-- Наименование.
+ 'INDEX ' + ISNULL(@IndexName, '') + ' ON ' + ISNULL(@tableName, '') + ' (' +
--region Столбцы индекса.
(SELECT -- 2ой уровнь.
    STUFF((SELECT
        ',' + ISNULL(c.name, '') + ' ' +
        CASE ic.is_descending_key
          WHEN 1 THEN 'DESC'
          ELSE 'ASC'
        END
      FROM sys.index_columns ic
      JOIN sys.COLUMNS c
        ON c.OBJECT_ID = ic.OBJECT_ID
        AND c.column_id = ic.column_id
      WHERE ic.OBJECT_ID = @IndexObjectID
      AND ic.index_id = @IndexID
      AND ic.is_included_column = 0
      ORDER BY ic.is_included_column, ic.key_ordinal
      FOR XML PATH (''))
    , 1, 1, ''))
--endregion Столбцы индекса.
+ ') '
--region Включеные столбцы.
+ ISNULL((SELECT
    'INCLUDE(' + -- 2ой уровнь().
    STUFF((SELECT
        ',' + ISNULL(c.name, '')
      FROM sys.index_columns ic
      JOIN sys.COLUMNS c
        ON c.OBJECT_ID = ic.OBJECT_ID
        AND c.column_id = ic.column_id
      WHERE ic.OBJECT_ID = @IndexObjectID
      AND ic.index_id = @IndexID
      AND ic.is_included_column = 1
      ORDER BY ic.is_included_column, ic.key_ordinal
      FOR XML PATH (''))
    , 1, 1, '') + ') ')
, '')
--endregion Включеные столбцы.
--region [NotUsed] Опции: ...
-- Фильтрация.
--      CASE i.has_filter
--        WHEN 1 THEN 'WHERE ' + i.filter_definition + ' '
--        ELSE ''
--      END
--      + 'WITH(' +
--      -- Разредить индекс.
--      'PAD_INDEX = ' +
--      CASE i.is_padded
--        WHEN 1 THEN 'ON'
--        ELSE 'OFF'
--      END +
--      -- Пропускать повторяющиеся значения.
--      ', IGNORE_DUP_KEY = ' +
--      CASE i.ignore_dup_key
--        WHEN 1 THEN 'ON'
--        ELSE 'OFF'
--      END +
--      -- Разрешить блокировку строк.
--      ', ALLOW_ROW_LOCKS = ' +
--      CASE i.allow_row_locks
--        WHEN 1 THEN 'ON'
--        ELSE 'OFF'
--      END +
--      -- Разрешить блокировку страниц.
--      ', ALLOW_PAGE_LOCKS = ' +
--      CASE i.allow_page_locks
--        WHEN 1 THEN 'ON'
--        ELSE 'OFF'
--      END +
--      -- Коэффицент заполнения.
--      CASE  
--        WHEN i.fill_factor > 0 THEN ', FILLFACTOR = ' + CAST(i.fill_factor AS NVARCHAR(MAX))
--        ELSE ''
--      END 
--      -- ???: Неопределенно.      
--      --    STATISTICS_NORECOMPUTE = ON, 
--      --    SORT_IN_TEMPDB = ON, 
--      --    ONLINE = ON, 
--      --    MAXDOP = 10, 
--      + ') ' 
--endregion Опции
+ 'ON [PRIMARY]
END
GO';
PRINT @query;
-- Двигаем курсор.
FETCH indexesCursor INTO @IndexObjectID, @IndexID, @IndexName, @IndexType, @IndexUnique;
END
-- Завершаем работу с курсором.
CLOSE indexesCursor;
DEALLOCATE indexesCursor;
--ENDREGION INDEXES
