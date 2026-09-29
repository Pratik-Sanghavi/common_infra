// Idempotent mock-data loader for the Novatek transfer-pricing demonstration.
CREATE CONSTRAINT legal_entity_id IF NOT EXISTS FOR (e:LegalEntity) REQUIRE e.entity_id IS UNIQUE;
CREATE CONSTRAINT rule_id IF NOT EXISTS FOR (r:TPRule) REQUIRE r.rule_id IS UNIQUE;
CREATE CONSTRAINT comparable_id IF NOT EXISTS FOR (c:Comparable) REQUIRE c.comp_id IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'file:///entities.csv' AS row
WITH row WHERE trim(coalesce(row.entity_id, '')) <> ''
MERGE (e:LegalEntity {entity_id: row.entity_id})
SET e.entity_name = row.entity_name, e.country = row.country, e.country_iso = row.country_iso,
    e.currency = row.currency, e.role = row.role, e.functional_profile = row.functional_profile,
    e.tested_party = row.tested_party = 'Y', e.suggested_method = row.suggested_method,
    e.suggested_pli = row.suggested_pli, e.ownership_pct = toFloat(row.ownership_pct),
    e.headcount = toInteger(row.headcount), e.fiscal_year_end = row.fiscal_year_end,
    e.key_functions = row.key_functions, e.key_assets = row.key_assets, e.key_risks = row.key_risks,
    e.source = 'mock CSV', e.illustrative = true;

LOAD CSV WITH HEADERS FROM 'file:///entities.csv' AS row
WITH row WHERE trim(coalesce(row.parent_entity_id, '')) <> ''
MATCH (parent:LegalEntity {entity_id: row.parent_entity_id}), (child:LegalEntity {entity_id: row.entity_id})
MERGE (parent)-[r:OWNS]->(child) SET r.ownership_pct = toFloat(row.ownership_pct);

LOAD CSV WITH HEADERS FROM 'file:///ic_transactions.csv' AS row
WITH row WHERE trim(coalesce(row.txn_id, '')) <> ''
MATCH (provider:LegalEntity {entity_id: row.provider_entity}), (recipient:LegalEntity {entity_id: row.recipient_entity})
MERGE (provider)-[t:INTERCOMPANY_TRANSACTION {txn_id: row.txn_id}]->(recipient)
SET t.fiscal_year = toInteger(row.fiscal_year), t.transaction_type = row.transaction_type,
    t.description = row.description, t.amount_local = toFloat(row.amount_local), t.currency = row.currency,
    t.amount_usd = toFloat(row.amount_usd), t.pricing_policy = row.pricing_policy,
    t.written_agreement = row.written_agreement = 'Y',
    t.agreement_date = CASE WHEN trim(coalesce(row.agreement_date, '')) = '' THEN null ELSE date(row.agreement_date) END,
    t.first_year = toInteger(row.first_year), t.notes = row.notes, t.source = 'mock CSV', t.illustrative = true;

LOAD CSV WITH HEADERS FROM 'file:///financials.csv' AS row
WITH row WHERE trim(coalesce(row.entity_id, '')) <> ''
MATCH (e:LegalEntity {entity_id: row.entity_id})
MERGE (f:FinancialResult {entity_id: row.entity_id, fiscal_year: toInteger(row.fiscal_year)})
SET f.currency = row.currency, f.fx_per_usd = toFloat(row.fx_per_usd), f.revenue = toFloat(row.revenue), f.related_party_revenue = toFloat(row.related_party_revenue),
    f.cogs = toFloat(row.cogs), f.opex = toFloat(row.opex), f.royalty_expense = toFloat(row.royalty_expense),
    f.operating_profit = toFloat(row.operating_profit), f.total_costs = toFloat(row.total_costs),
    f.total_operating_assets = toFloat(row.total_operating_assets), f.source = 'mock CSV', f.illustrative = true
MERGE (e)-[:REPORTED_RESULT]->(f);

LOAD CSV WITH HEADERS FROM 'file:///tp_rules.csv' AS row
WITH row WHERE trim(coalesce(row.rule_id, '')) <> ''
MERGE (r:TPRule {rule_id: row.rule_id})
SET r.jurisdiction = row.jurisdiction, r.trigger_name = row.trigger_name, r.applies_to = row.applies_to,
    r.condition = row.condition, r.threshold = row.threshold, r.severity = row.severity,
    r.action = row.action, r.reference = row.reference,
    r.source = 'hand-authored illustrative rules table', r.illustrative = true;

MATCH (e:LegalEntity), (r:TPRule)
WHERE r.jurisdiction CONTAINS 'OECD' OR (e.country_iso = 'US' AND r.jurisdiction = 'US')
   OR (e.country_iso = 'IN' AND r.jurisdiction = 'India') OR (e.country_iso = 'MX' AND r.jurisdiction = 'Mexico')
   OR (e.country_iso = 'DE' AND r.jurisdiction = 'Germany') OR (e.country_iso = 'CH' AND r.jurisdiction = 'Switzerland')
MERGE (e)-[:SUBJECT_TO]->(r);

LOAD CSV WITH HEADERS FROM 'file:///comparables_distributors.csv' AS row
WITH row WHERE trim(coalesce(row.comp_id, '')) <> ''
MERGE (c:Comparable {comp_id: row.comp_id})
SET c.company_name = row.company_name, c.country = row.country, c.business_description = row.business_description,
    c.largest_shareholder_pct = toFloat(row.largest_shareholder_pct), c.segment = 'distributor',
    c.source = 'pre-curated illustrative comparable set', c.illustrative = true
MERGE (cf:ComparableFinancial {comp_id: row.comp_id, fiscal_year: toInteger(row.fiscal_year)})
SET cf.revenue_musd = toFloat(row.revenue_musd), cf.operating_profit_musd = toFloat(row.operating_profit_musd),
    cf.total_costs_musd = toFloat(row.total_costs_musd)
MERGE (c)-[:HAS_FINANCIAL]->(cf);

LOAD CSV WITH HEADERS FROM 'file:///comparables_services.csv' AS row
WITH row WHERE trim(coalesce(row.comp_id, '')) <> ''
MERGE (c:Comparable {comp_id: row.comp_id})
SET c.company_name = row.company_name, c.country = row.country, c.business_description = row.business_description,
    c.largest_shareholder_pct = toFloat(row.largest_shareholder_pct), c.segment = 'services',
    c.source = 'pre-curated illustrative comparable set', c.illustrative = true
MERGE (cf:ComparableFinancial {comp_id: row.comp_id, fiscal_year: toInteger(row.fiscal_year)})
SET cf.revenue_musd = toFloat(row.revenue_musd), cf.operating_profit_musd = toFloat(row.operating_profit_musd),
    cf.total_costs_musd = toFloat(row.total_costs_musd)
MERGE (c)-[:HAS_FINANCIAL]->(cf);

MATCH (e:LegalEntity {entity_id: 'E05'}), (c:Comparable {segment: 'distributor'})
MERGE (e)-[:BENCHMARKED_AGAINST {pli: 'Operating Margin', method: 'TNMM'}]->(c);
MATCH (e:LegalEntity {entity_id: 'E02'}), (c:Comparable {segment: 'services'})
MERGE (e)-[:BENCHMARKED_AGAINST {pli: 'Net Cost Plus', method: 'TNMM / CPM'}]->(c);