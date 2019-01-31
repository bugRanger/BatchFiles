--EXEC CAT 'tDefaultValue'
DECLARE @query NVARCHAR(MAX);
SET @query = '';

-- Запрос 1го уровня на кол-во индексов, параметры.
-- Запрос 2го уровня на кол-во полей.
SET @query = @query + REPLACE((SELECT -- 1ый уровнь.
    'CREATE ' +
    -- Уникальность.
    CASE i.is_unique
      WHEN 1 THEN 'UNIQUE '
      ELSE ''
    END +
    -- Кластерный/Некластерный.
    ISNULL(i.type_desc, '') + ' '
    -- Наименование.
    + 'INDEX ' + ISNULL(i.name, '') + ' ON ' + ISNULL(o.name, '') + ' (' + 
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
          WHERE ic.OBJECT_ID = i.OBJECT_ID
          AND ic.index_id = i.index_id
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
          WHERE ic.OBJECT_ID = i.OBJECT_ID
          AND ic.index_id = i.index_id
          AND ic.is_included_column = 1
          ORDER BY ic.is_included_column, ic.key_ordinal
          FOR XML PATH (''))
        , 1, 1, '') + ') ')
    --endregion Включеные столбцы.
    , '')
    +
    -- Фильтрация.
    CASE i.has_filter
      WHEN 1 THEN 'WHERE ' + i.filter_definition + ' '
      ELSE ''
    END
    + 'WITH(' +
    --region Опции: ...
    -- Разредить индекс.
    'PAD_INDEX = ' +
    CASE i.is_padded
      WHEN 1 THEN 'ON'
      ELSE 'OFF'
    END +
    -- Пропускать повторяющиеся значения.
    ', IGNORE_DUP_KEY = ' +
    CASE i.ignore_dup_key
      WHEN 1 THEN 'ON'
      ELSE 'OFF'
    END +
    -- Разрешить блокировку строк.
    ', ALLOW_ROW_LOCKS = ' +
    CASE i.allow_row_locks
      WHEN 1 THEN 'ON'
      ELSE 'OFF'
    END +
    -- Разрешить блокировку страниц.
    ', ALLOW_PAGE_LOCKS = ' +
    CASE i.allow_page_locks
      WHEN 1 THEN 'ON'
      ELSE 'OFF'
    END +
    -- Коэффицент заполнения.
    CASE  
      WHEN i.fill_factor > 0 THEN ', FILLFACTOR = ' + CAST(i.fill_factor AS NVARCHAR(MAX))
      ELSE ''
    END 
    -- ???: Неопределенно.      
    --	STATISTICS_NORECOMPUTE = ON, 
    --	SORT_IN_TEMPDB = ON, 
    --	ONLINE = ON, 
    --	MAXDOP = 10,  
    --endregion Опции
    + ') ON [PRIMARY];
'
  FROM sys.indexes i
  JOIN sys.objects o
    ON i.object_id = o.object_id
  WHERE i.type = 2
  AND i.is_primary_key = 0
  AND o.type = 'U'
  ORDER BY o.[name], i.[name]
  FOR XML PATH (''))
, '&#x0D;', '');

SELECT
  @query;