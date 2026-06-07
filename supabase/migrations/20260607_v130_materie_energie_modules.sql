-- v130: materie_modules + energie_modules tables + expand admin_module_access constraint

CREATE TABLE IF NOT EXISTS materie_modules (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  module_code      text        NOT NULL UNIQUE,
  branch           text        NOT NULL,
  branch_order     integer     NOT NULL,
  title            text        NOT NULL,
  subtitle         text,
  theory_content   text        NOT NULL DEFAULT '',
  case_study       text        NOT NULL DEFAULT '',
  exercise_description text    NOT NULL DEFAULT '',
  test_questions   jsonb       NOT NULL DEFAULT '[]',
  xp_reward        integer     NOT NULL DEFAULT 50,
  is_boss_module   boolean     NOT NULL DEFAULT false,
  prerequisites    text[]               DEFAULT '{}',
  youtube_search_query text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE materie_modules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read materie_modules" ON materie_modules FOR SELECT USING (true);
CREATE POLICY "Service write materie_modules" ON materie_modules FOR ALL USING (auth.role() = 'service_role');

CREATE TABLE IF NOT EXISTS energie_modules (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  module_code      text        NOT NULL UNIQUE,
  branch           text        NOT NULL,
  branch_order     integer     NOT NULL,
  title            text        NOT NULL,
  subtitle         text,
  theory_content   text        NOT NULL DEFAULT '',
  case_study       text        NOT NULL DEFAULT '',
  exercise_description text    NOT NULL DEFAULT '',
  test_questions   jsonb       NOT NULL DEFAULT '[]',
  xp_reward        integer     NOT NULL DEFAULT 50,
  is_boss_module   boolean     NOT NULL DEFAULT false,
  prerequisites    text[]               DEFAULT '{}',
  youtube_search_query text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE energie_modules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read energie_modules" ON energie_modules FOR SELECT USING (true);
CREATE POLICY "Service write energie_modules" ON energie_modules FOR ALL USING (auth.role() = 'service_role');

CREATE TABLE IF NOT EXISTS user_materie_progress (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       text        NOT NULL,
  module_code   text        NOT NULL REFERENCES materie_modules(module_code) ON DELETE CASCADE,
  completed_at  timestamptz,
  exercise_completed boolean NOT NULL DEFAULT false,
  test_passed   boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, module_code)
);
ALTER TABLE user_materie_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service rw user_materie_progress" ON user_materie_progress FOR ALL USING (auth.role() = 'service_role');

CREATE TABLE IF NOT EXISTS user_energie_progress (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       text        NOT NULL,
  module_code   text        NOT NULL REFERENCES energie_modules(module_code) ON DELETE CASCADE,
  completed_at  timestamptz,
  exercise_completed boolean NOT NULL DEFAULT false,
  test_passed   boolean     NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, module_code)
);
ALTER TABLE user_energie_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Service rw user_energie_progress" ON user_energie_progress FOR ALL USING (auth.role() = 'service_role');

ALTER TABLE admin_module_access DROP CONSTRAINT IF EXISTS admin_module_access_module_type_check;
ALTER TABLE admin_module_access ADD CONSTRAINT admin_module_access_module_type_check
  CHECK (module_type = ANY (ARRAY['vorhang','ursprung','materie','energie']));
