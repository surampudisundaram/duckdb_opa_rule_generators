if('serviceWorker' in navigator) {window.addEventListener('load', () => {navigator.serviceWorker.register('/duckdb_opa_rule_generators/sw.js', { scope: '/duckdb_opa_rule_generators/' })})}
