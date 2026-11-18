-- Phase 1: create the five schemas used by the warehouse.
-- stg   = raw landing copies of source extracts
-- core  = cleaned star schema (dimensions + facts)
-- mart  = reporting views for Power BI
-- audit = exceptions, rule parameters, pipeline and data-quality logs
-- label = hidden ground truth for planted anomalies (never read by the rules)
USE SentinelBank;
GO

IF SCHEMA_ID('stg')   IS NULL EXEC('CREATE SCHEMA stg');
IF SCHEMA_ID('core')  IS NULL EXEC('CREATE SCHEMA core');
IF SCHEMA_ID('mart')  IS NULL EXEC('CREATE SCHEMA mart');
IF SCHEMA_ID('audit') IS NULL EXEC('CREATE SCHEMA audit');
IF SCHEMA_ID('label') IS NULL EXEC('CREATE SCHEMA label');
GO
