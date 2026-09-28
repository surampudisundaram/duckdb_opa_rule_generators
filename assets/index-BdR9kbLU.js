import{l as R,m as f,n as L,o as O}from"./index-C5KVUYCF.js";import{A as x,D as N,p as y}from"./index-C5KVUYCF.js";const l=["SELECT","INSERT","UPDATE","DELETE","CREATE","DROP","ALTER","WITH","SHOW","DESCRIBE","EXPLAIN","PRAGMA","COPY","EXPORT","IMPORT"];function d(a){const i=[];let e=a.trim();const h=/```(?:sql|SQL)?\s*([\s\S]*?)```/g,r=[];let p;for(;(p=h.exec(e))!==null;){const t=p[1].trim();t&&r.push(t)}if(r.length>0){const t=r.find(s=>l.some(n=>s.toUpperCase().startsWith(n)));t?(e=t,i.push("Extracted from code block")):(e=r.reduce((s,n)=>s.length>n.length?s:n),i.push("Used longest code block"))}if(r.length===0){const t=[/^(?:Here(?:'s| is)(?: the)? (?:SQL|query)[:\s]*)/i,/^(?:The (?:SQL|query) (?:is|would be)[:\s]*)/i,/^(?:SQL[:\s]+)/i,/^(?:Query[:\s]+)/i,/^(?:Try this[:\s]*)/i,/^(?:You can use[:\s]*)/i,/^(?:Sure[,!]?\s*(?:here(?:'s| is)[:\s]*)?)/i,/^(?:Certainly[,!]?\s*(?:here(?:'s| is)[:\s]*)?)/i];for(const s of t)if(s.test(e)){e=e.replace(s,"").trim(),i.push("Removed explanatory prefix");break}}if(r.length===0){const t=e.match(new RegExp(`(${l.join("|")})\\b`,"i"));if(t&&t.index!==void 0){let s=e.slice(t.index);const n=s.indexOf(";");if(n!==-1){const c=s.slice(n+1).trim();(/^(This|Note|The above|It |I |You |Where |Which |Here |--|\n\n)/i.test(c)||!c)&&(s=s.slice(0,n+1),c&&i.push("Trimmed trailing explanation after semicolon"))}e=s.trim()}}if(e=e.replace(/^`+|`+$/g,"").trim(),!l.some(t=>e.toUpperCase().startsWith(t)))return i.push("Does not start with expected SQL keyword"),{sql:null,confidence:0,issues:i};e.toUpperCase().startsWith("SELECT")&&(/\bFROM\b/i.test(e)||/SELECT\s+[\d+\-*/() ]+;?\s*$/i.test(e)||i.push("SELECT query might be missing FROM clause"));const E=(e.match(/\(/g)||[]).length,b=(e.match(/\)/g)||[]).length;E!==b&&i.push("Mismatched parentheses - query may be incomplete");let o=1;return o-=i.length*.1,o=Math.max(.1,o),{sql:e,confidence:o,issues:i}}function S(a){return a.replace(/\bSELECT\b/gi,"SELECT").replace(/\bFROM\b/gi,`
FROM`).replace(/\bWHERE\b/gi,`
WHERE`).replace(/\bAND\b/gi,`
  AND`).replace(/\bOR\b/gi,`
  OR`).replace(/\bGROUP BY\b/gi,`
GROUP BY`).replace(/\bORDER BY\b/gi,`
ORDER BY`).replace(/\bHAVING\b/gi,`
HAVING`).replace(/\bLIMIT\b/gi,`
LIMIT`).replace(/\bJOIN\b/gi,`
JOIN`).replace(/\bLEFT JOIN\b/gi,`
LEFT JOIN`).replace(/\bRIGHT JOIN\b/gi,`
RIGHT JOIN`).replace(/\bINNER JOIN\b/gi,`
INNER JOIN`).replace(/\bON\b/gi,`
  ON`)}export{x as AVAILABLE_MODELS,N as DEFAULT_MODEL,R as buildFixQueryRequest,L as buildTextToSQLMessages,f as duckBrainService,d as extractSQLFromResponse,S as formatSQLForDisplay,O as formatSchemaForContext,y as getSchemaSummary};
