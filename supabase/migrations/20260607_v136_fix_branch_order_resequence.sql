-- Fix: branch_order war teils der Branch-Index statt der Position im Branch
-- (V-31 landete auf Order 1 -> unter V-01). Neu durchnummerieren je Branch
-- nach numerischem Modul-Code.
WITH ranked AS (
  SELECT module_code,
         row_number() OVER (PARTITION BY branch ORDER BY NULLIF(regexp_replace(module_code,'\D','','g'),'')::int NULLS LAST) AS rn
  FROM vorhang_modules
)
UPDATE vorhang_modules m SET branch_order = r.rn FROM ranked r WHERE m.module_code = r.module_code;
WITH ranked AS (
  SELECT module_code,
         row_number() OVER (PARTITION BY branch ORDER BY NULLIF(regexp_replace(module_code,'\D','','g'),'')::int NULLS LAST) AS rn
  FROM ursprung_modules
)
UPDATE ursprung_modules m SET branch_order = r.rn FROM ranked r WHERE m.module_code = r.module_code;
WITH ranked AS (
  SELECT module_code,
         row_number() OVER (PARTITION BY branch ORDER BY NULLIF(regexp_replace(module_code,'\D','','g'),'')::int NULLS LAST) AS rn
  FROM materie_modules
)
UPDATE materie_modules m SET branch_order = r.rn FROM ranked r WHERE m.module_code = r.module_code;
WITH ranked AS (
  SELECT module_code,
         row_number() OVER (PARTITION BY branch ORDER BY NULLIF(regexp_replace(module_code,'\D','','g'),'')::int NULLS LAST) AS rn
  FROM energie_modules
)
UPDATE energie_modules m SET branch_order = r.rn FROM ranked r WHERE m.module_code = r.module_code;
