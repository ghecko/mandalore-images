# TODO

## Tools to re-evaluate

### TheManticoreProject (https://github.com/TheManticoreProject)

Reviewed 2026-11-19. Already integrated: `smbclient-ng`, `delegations`, `LDAPWordlistHarvester`.
Not added yet because too young (0-1 stars, created in the last few months) or overlapping existing tools.
Re-check maturity around 2027-Q2. Most publish `<name>-linux-<amd64|arm64>` release binaries,
installable with `gh_release_binary` (see `sources/install/common.sh`).

| Tool | Why it could be interesting | Overlaps with (already in image) |
|---|---|---|
| findgpppasswords | Cross-platform GPP password finder (177★) | impacket `Get-GPPPassword.py` (kept on purpose) |
| keycredentials | Full shadow-credentials management over LDAP | pywhisker |
| keycredentialhound | BloodHound OpenGraph collector for KeyCredentials | - (complements BloodHound-CE) |
| findreusedkeycredentials | Find key credentials reused across objects | - |
| findoldsidtraces | Find leftovers of old SIDs in LDAP objects | - |
| ldapmonitor | Live diff of AD object changes over LDAP | - |
| aclmonitor | Live diff of AD security descriptors | - |
| ldapconsole | Interactive LDAP queries, XLSX export | godap, ldeep, ldapsearch |
| adidns | Query/add/modify AD-integrated DNS records | krbrelayx `dnstool.py` |
| registry | Remote registry (MS-RRP) read/write/backup/monitor | impacket `reg.py` |
| msrpc | Enumerate/monitor/fuzz MS-RPC interfaces | impacket `rpcdump.py` |
| coercer (Go) | Go rewrite of Coercer — no release/description yet | p0dalirius Coercer (python) |
| goLAPS | LAPS getter/setter | pyLAPS |
| keytab | Work with Kerberos keytab files | - |
| sidtool / ComputeSIDFromServiceName | SID utilities | - |

## BloodHound CE: PostgreSQL graph driver

BloodHound CE can store the graph in PostgreSQL (`bhe_graph_driver=pg`) instead of neo4j.
Test it to drop neo4j 4.4 and the Temurin Java 11 it needs (UseBiasedLocking breaks on Java >= 18).
Upstream still pins `neo4j:4.4.42` in its docker-compose (checked 2026-11-19), so we stay on 4.4 until then.
