# Linux Disk Optimization 2.0

Automatiserat, säkert och flexibelt skript för att optimera disk-, minnes- och nätverksparametrar på Linux-servrar. Innehåller backup/restaurering, loggning, prestandatest och olika optimeringsnivåer.

---

## ⚠️ Viktig Varning

> **Det här skriptet ändrar kritiska systemfiler och systeminställningar!**
>
> - Kör **aldrig** på produktion utan backup!
> - Skriptet skriver över `/etc/sysctl.conf` (backup skapas automatiskt).
> - Körs som root och påverkar diskparametrar, kernel och nätverksinställningar.
> - Ej avsett för vanliga desktop-datorer eller icke-experter.

---

## Innehåll

- [Syfte](#syfte)
- [Vad skriptet gör](#vad-skriptet-gör)
- [Funktioner](#funktioner)
- [Krav & systemsupport](#krav--systemsuppport)
- [Installation & användning](#installation--användning)
- [Flaggor och nivåer](#flaggor-och-nivåer)
- [Exempel](#exempel)
- [Restore och backup](#restore-och-backup)
- [Output och loggning](#output-och-loggning)
- [Edge cases & tips](#edge-cases--tips)
- [Resultat & Prestanda](#resultat--prestanda)
- [Licens](#licens)

---

## Syfte

Detta skript syftar till att maximera I/O-prestanda och optimera kärn-, disk- och nätverksparametrar för Linux-servrar med mycket RAM och snabba diskar (t.ex. för databasanvändning eller storage-intensiva miljöer).

---

## Vad skriptet gör

- **Backup av systemfiler** innan ändring
- **Dynamisk optimering** av kernelparametrar utifrån RAM
- **Disk scheduler- och read-ahead-tuning** på alla `/dev/sd*`-diskar (utom på VM)
- **Nätverks- och file-systemtuning** för höga samtidiga anslutningar
- **Stöd för flera optimeringsnivåer** (safe, aggressive, custom)
- **Restore**: enkel återställning till senaste backup
- **Loggning** till `/var/log/linux-disk-optimization.log`
- **Prestandatest** före/efter med iozone om installerat
- **Dry-run**: visa vad som hade gjorts utan att ändra något

---

## Funktioner

- **Automatisk backup & restore** av `/etc/sysctl.conf`
- **Optimeringsnivåer:** safe, aggressive, custom
- **Loggning av alla förändringar**
- **Prestandatest** (med `iozone` om tillgängligt)
- **Detekterar virtuella maskiner** och hoppar över riskabla optimeringar
- **Dry-run**-läge för säker testning
- **Säkerhetscheckar** (körs som root, beroenden, etc)

---

## Krav & systemsuppport

### **Stöds**
- **Debian/Ubuntu** (testat på kernel 4.x/5.x)
- Fysiska Linux-servrar eller kraftfulla VM:ar där disk-parametrar kan ändras
- Körs som root

### **Stöds ej / Ej testat**
- RedHat/CentOS/Fedora (viss manuell anpassning kan behövas)
- macOS, BSD, WSL
- Virtuella servrar där blockdev/IO-parametrar är låsta (t.ex. vissa molnleverantörer)
- Desktop-system (kan påverka användbarhet och stabilitet!)

---

## Installation & användning

1. **Kloning av repo:**
   ```sh
   git clone https://github.com/Caripson/Linux-disk-optimization.git
   cd Linux-disk-optimization
   ```

2. **Gör scriptet körbart:**
   ```sh
   chmod +x runme.sh
   ```

3. **Kör scriptet (som root):**
   ```sh
   sudo ./runme.sh --level=aggressive
   ```

   Eller kör en torrkörning:
   ```sh
   sudo ./runme.sh --dry-run
   ```

---

## Flaggor och nivåer

| Flagga         | Funktion                                                            |
|----------------|---------------------------------------------------------------------|
| `--level=safe`       | Konservativ, säker optimering (default)                        |
| `--level=aggressive` | Maximal prestanda (använd på eget ansvar)                      |
| `--level=custom`     | Manuell justering (kräver att du själv redigerar i scriptet)   |
| `--dry-run`          | Endast visa vad som skulle ske, ändrar inget                   |
| `--restore`          | Återställer senaste backup av `/etc/sysctl.conf`               |
| `--help`             | Visar hjälp och exempel                                        |

---

## Exempel

**Säker optimering:**
```sh
sudo ./runme.sh --level=safe
```

**Aggressiv optimering (max prestanda):**
```sh
sudo ./runme.sh --level=aggressive
```

**Visa alla ändringar utan att skriva något:**
```sh
sudo ./runme.sh --dry-run
```

**Återställ till senaste backup:**
```sh
sudo ./runme.sh --restore
```

---

## Restore och backup

- Backup av `/etc/sysctl.conf` sparas med timestamp i samma katalog.
- Vid återställning (`--restore`) ersätts aktuell sysctl.conf med senaste backupen.
- **Manuell återställning:**  
  ```sh
  sudo cp /etc/sysctl.conf.bak.YYYY-MM-DD-HHMMSS /etc/sysctl.conf
  sudo sysctl -p
  ```

---

## Output och loggning

- Alla händelser loggas till `/var/log/linux-disk-optimization.log`.
- Loggfilen innehåller även fel och warnings.
- Prestandatest (`iozone`) sparas till `/tmp/iozone_test_*.log`.

---

## Edge cases & tips

- **Virtuell maskin:** Scriptet känner av VM-miljö och hoppar över disk-parametrar (kan tvingas på manuellt om du vet vad du gör).
- **Molnplattformar:** Kontrollera att du har rättigheter för att ändra blockdev/sysctl.
- **IOzone** måste installeras manuellt för prestandatest (`sudo apt-get install iozone3`).
- **Anpassa sysctl:** Vid "custom"-läge kan du själv redigera parametervärden i scriptet innan körning.
- **Flera körningar:** Rekommenderas att alltid ta backup innan om du gör flera justeringar.

---

## Resultat & Prestanda

- Prestandatester (`iozone`) körs före och efter optimering och sparas i `/tmp`.
- **Exempel på förväntad förbättring:**
  - Högre I/O throughput vid stora filöverföringar
  - Fler samtidiga anslutningar, snabbare socket-prestanda

---

## Licens

MIT License. Se [LICENSE](LICENSE) för mer info.

---

## Kontakt / Issues

[Öppna en issue på GitHub](https://github.com/Caripson/Linux-disk-optimization/issues) vid problem, buggar eller förslag!

---


