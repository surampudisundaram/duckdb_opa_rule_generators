<#
.SYNOPSIS
  Builds databases/insurance_data_opa_rego.duckdb - a metadata-only DuckDB file
  whose 21 views read the parquet files in ./insurance_data_opa_rego.parquet/
  over HTTP.

.DESCRIPTION
  Why this is a script and not a committed binary:

  DuckDB binds a view's body at CREATE time. Creating a view over
  read_parquet('https://...') therefore requires the URL to already resolve, so
  this file cannot be generated until the site is live on GitHub Pages. The
  views point at the deployed origin rather than a local path because DuckDB
  WASM has no filesystem - a relative path cannot work in the browser.

  Run this ONCE after the first successful Pages deploy, then commit the
  resulting .duckdb. Subsequent deploys do not need it unless the origin
  changes.

.PARAMETER BaseUrl
  Origin the parquet files are served from, with trailing slash.
  Defaults to the project's own Pages URL.

.EXAMPLE
  pwsh -File databases/build-parquet-views.ps1
  pwsh -File databases/build-parquet-views.ps1 -BaseUrl 'https://example.com/duckdb_opa_rule_generators/databases/'
#>
[CmdletBinding()]
param(
  [string]$BaseUrl = 'https://surampudisundaram.github.io/duckdb_opa_rule_generators/databases/'
)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not $BaseUrl.EndsWith('/')) { $BaseUrl += '/' }
$parquetDir = Join-Path (Get-Location) 'insurance_data_opa_rego.parquet'
if (-not (Test-Path -LiteralPath $parquetDir -PathType Container)) {
  throw "Parquet directory not found: $parquetDir"
}

# --- locate the duckdb CLI -------------------------------------------------
$duckdb = (Get-Command duckdb -ErrorAction SilentlyContinue).Source
if (-not $duckdb) {
  foreach ($cand in @("$env:ProgramFiles\duckdb\duckdb.exe", 'D:\duckdb\duckdb.exe',
                      "$env:LOCALAPPDATA\duckdb\duckdb.exe")) {
    if (Test-Path -LiteralPath $cand) { $duckdb = $cand; break }
  }
}
if (-not $duckdb) { throw 'duckdb CLI not found. Install it or add it to PATH.' }
Write-Host "duckdb: $duckdb"

# --- generate the view DDL ------------------------------------------------
# Only the schema-qualified parquet files are exposed. The unqualified
# taccount.parquet etc. alongside them are byte-identical duplicates
# (verified by SHA-256) and would otherwise double every table name.
$tables = @('taccount','tactivity','taddress','tclaim','tclaimcontact','tcontact',
            'tcoverage','texposure','tincident','tjob','tpolicy','tpolicycontactrole',
            'tpolicyline','tpolicyperiod','tproducer','treserveline','ttransaction',
            'ttransactionlineitem','tuser')

# Single template for every view so the quoting cannot drift between statements.
$viewDdl = "CREATE VIEW {0}.{1} AS SELECT * FROM read_parquet('{2}');"

$ddl = New-Object System.Collections.Generic.List[string]
$ddl.Add('CREATE SCHEMA IF NOT EXISTS insurance_tables;')
$ddl.Add('CREATE SCHEMA IF NOT EXISTS llm_wiki_tables;')
$ddl.Add('CREATE SCHEMA IF NOT EXISTS opa_from_wiki;')
foreach ($t in $tables) {
  $ddl.Add(($viewDdl -f 'insurance_tables', $t,
            "${BaseUrl}insurance_data_opa_rego.parquet/insurance_tables_$t.parquet"))
}
$ddl.Add(($viewDdl -f 'llm_wiki_tables', 'llm_wiki_pages',
          "${BaseUrl}insurance_data_opa_rego.parquet/llm_wiki_tables_llm_wiki_pages.parquet"))
$ddl.Add(($viewDdl -f 'opa_from_wiki', 'rego_policies_from_wiki_with_provenance_tags',
          "${BaseUrl}insurance_data_opa_rego.parquet/opa_from_wiki_rego_policies_from_wiki_with_provenance_tags.parquet"))

$sqlFile = Join-Path $env:TEMP 'build_insurance_views.sql'
[System.IO.File]::WriteAllText($sqlFile, ($ddl -join "`n"))

# --- build ----------------------------------------------------------------
$outDb = Join-Path (Get-Location) 'insurance_data_opa_rego.duckdb'
if (Test-Path -LiteralPath $outDb) { Remove-Item -LiteralPath $outDb -Force }

# NOTE: the DuckDB CLI's .read treats backslashes as escapes - use forward slashes.
& $duckdb $outDb -c ".read $($sqlFile.Replace('\','/'))"
if ($LASTEXITCODE -ne 0) { throw "duckdb failed. Is '$BaseUrl' reachable? The site must be deployed first." }

$count = & $duckdb $outDb -readonly -noheader -list -c "SELECT count(*) FROM information_schema.tables WHERE table_type='VIEW';"
if ([int]$count -ne 21) { throw "Expected 21 views, got $count" }
Write-Host "built $outDb with $count views"

# --- register in the manifest --------------------------------------------
$manifestPath = Join-Path (Get-Location) 'manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if (-not $manifest.databases) { $manifest | Add-Member -NotePropertyName databases -NotePropertyValue @() }

$existing = @($manifest.databases | Where-Object { $_.file -eq 'insurance_data_opa_rego.duckdb' })
if ($existing.Count -eq 0) {
  $manifest.databases += [pscustomobject]@{
    name        = 'Insurance data (parquet views)'
    file        = 'insurance_data_opa_rego.duckdb'
    alias       = 'opa_parquet'
    description = 'Views over the raw parquet export, read over HTTP from the site origin.'
    autoLoad    = $true
    readOnly    = $true
  }
  [System.IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10))
  Write-Host 'registered insurance_data_opa_rego.duckdb in manifest.json'
} else {
  Write-Host 'already present in manifest.json - left as is'
}

Write-Host ''
Write-Host 'Next: git add databases/ && git commit -m "Add parquet view database"'
