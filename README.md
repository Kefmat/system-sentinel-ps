# System Sentinel Framework (PowerShell)

## Oversikt
System Sentinel Framework er et modulært PowerShell-rammeverk utviklet for automatisert overvåking og integritetskontroll av bedriftskritiske systemer. Verktøyet gir systemadministratorer full oversikt over filendringer og rettighetsavvik gjennom et visuelt dashboard og proaktiv logging.

## Nøkkelfunksjoner
* **Filintegritetskontroll:** Overvåking av filendringer ved bruk av SHA256-hashing.
* **NTFS Rettighetskontroll:** Deteksjon av uautoriserte endringer i tilgangslister (ACL).
* **Visuelt Dashboard:** Genererer interaktive HTML-rapporter med Chart.js-visualisering.
* **Enterprise Logging:** Omfattende loggføring til fil med fargekodet terminal-output.
* **Sentralisert Konfigurasjon:** Enkel styring av miljøer via `Settings.json`.

## Prosjektstruktur
* `/Core`: Kjernelogikk for fil- og rettighetsskanning.
* `/Modules`: Rapportgeneratorer og hjelpefunksjoner.
* `/Config`: JSON-konfigurasjon og CSS-maler for rapporter.
* `/Reports`: Ferdige revisjonsrapporter (HTML).
* `/Logs`: Operasjonell loggføring av kjøringer.

## Installasjon & Bruk
1.  Klon repoet til din maskin.
2.  Oppdater `Config/Settings.json` med stiene du ønsker å overvåke.
3.  Kjør Master-skriptet som Administrator:
    ```powershell
    ./Start-SentinelScan.ps1
    ```

## Tekniske Krav
* **OS:** Windows 10/11 eller Windows Server.
* **PowerShell:** Versjon 5.1 eller nyere.
* **Rettigheter:** Krever Administrator-privilegier for ACL-skanning.

---
*Utviklet som et verktøy for sikkerhetsrevisjon og automatisert systemovervåking.*