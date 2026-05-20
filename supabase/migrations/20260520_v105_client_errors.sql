-- v105: client_errors -- Tabelle fuer client-seitige Crash-Reports.
-- Wird vom Worker-Endpoint POST /api/error-report befuellt sobald die
-- App im Production-Build einen FlutterError oder Async-Error abfaengt.
-- RLS strikt -- nur service_role (Worker) darf schreiben/lesen.

CREATE TABLE IF NOT EXISTS public.client_errors (
  id BIGSERIAL PRIMARY KEY,
  error TEXT NOT NULL,
  library TEXT,
  stack TEXT,
  context TEXT,
  platform TEXT,
  client_timestamp TIMESTAMPTZ,
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_errors_received_at
  ON public.client_errors(received_at DESC);

ALTER TABLE public.client_errors ENABLE ROW LEVEL SECURITY;

-- Kein Policy fuer anon/authenticated -- nur service_role hat Zugriff
-- (umgeht RLS by default). Damit koennen Reports nur ueber den Worker
-- geschrieben werden.

GRANT SELECT, INSERT ON public.client_errors TO service_role;
