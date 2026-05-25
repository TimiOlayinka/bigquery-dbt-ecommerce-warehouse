// ---------------------------------------------------------------------------
// Shared helpers for Dataform SQLX models
// ---------------------------------------------------------------------------

/**
 * Generates versioning columns: row_version, version_count
 * @param {string} partitionKey - The business key column to partition by
 * @returns {string} SQL fragment for the versioned CTE
 */
function versioningColumns(partitionKey) {
  return `
        ROW_NUMBER() OVER (
            PARTITION BY ${partitionKey}
            ORDER BY ingest_date DESC, ingest_ts DESC
        ) AS row_version,
        COUNT(*) OVER (
            PARTITION BY ${partitionKey}
        ) AS version_count`;
}

/**
 * Generates an MD5 record hash from an array of field names
 * @param {string[]} fields - Array of column names to include in the hash
 * @returns {string} SQL TO_HEX(MD5(...)) expression
 */
function recordHash(fields) {
  const parts = fields.map(f => `COALESCE(CAST(${f} AS STRING), '')`);
  return `TO_HEX(MD5(${parts.join(" || '|' || \n            ")})) AS record_hash`;
}

module.exports = { versioningColumns, recordHash };
