-- Optional stored procedure (Task 3): materialize monthly report into a table for dashboards / repeat reads.
-- Run after sql/30_reports.sql

CREATE TABLE IF NOT EXISTS public.report_cache_monthly (
    month           DATE PRIMARY KEY,
    total_orders    BIGINT,
    total_quantity  NUMERIC,
    total_revenue   NUMERIC,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE public.refresh_report_cache_monthly(
    p_start_date DATE,
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM public.report_cache_monthly
    WHERE month >= date_trunc('month', p_start_date)::DATE
      AND month <= date_trunc('month', p_end_date)::DATE;

    INSERT INTO public.report_cache_monthly (month, total_orders, total_quantity, total_revenue)
    SELECT month, total_orders, total_quantity, total_revenue
    FROM public.report_monthly_revenue(p_start_date, p_end_date);
END;
$$;
