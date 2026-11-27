# 🧠 FPGA avancé 2A — Processeur Nios V, niveau à bulle & écran magique

Dépôt du module **FPGA avancé** (2ᵉ année, 2026-2027). Il regroupe :

- la construction d'un **système à processeur softcore Nios V** (RISC-V) sous **Platform Designer**, programmé en **C** ;
- le **niveau à bulle** : l'accéléromètre **ADXL345** est lu en **I2C** par le Nios V et l'inclinaison de la carte est affichée sur les **10 LEDs** ;
- l'intégration de l'**écran magique** HDMI du module précédent, dont l'effacement est désormais **commandé par le processeur** : il suffit de **retourner la carte**.

---

## 📑 Sommaire

- [Matériel et prérequis](#-matériel-et-prérequis)
- [Structure du dépôt](#-structure-du-dépôt)
- [Démarrage rapide](#-démarrage-rapide)
- [Étape 1 : système Nios V](#-étape-1--système-nios-v)
- [Étape 2 : Hello world et chenillard](#-étape-2--hello-world-et-chenillard)
- [Étape 3 : niveau à bulle](#-étape-3--niveau-à-bulle)
- [Étape 4 : écran magique](#-étape-4--écran-magique)
- [Broches](#-broches)
- [Démonstration](#-démonstration)
- [Conclusion](#-conclusion)
- [Auteurs](#-auteurs)

---

## 🔌 Matériel et prérequis

### Logiciels

| Outil | Version | Usage |
|-------|---------|-------|
| Intel Quartus Prime Lite | 24.1std | Synthèse, placement-routage, programmation |
| Platform Designer | 24.1 | Construction du système processeur (`nios.qsys`) |
| niosv-shell (`niosv-bsp`, `niosv-app`) | 24.1 | Génération du BSP et de l'application C |
| RiscFree IDE (Ashling) | — | Compilation, chargement et débogage du programme |
| `juart-terminal` | — | Lecture des `printf` via le JTAG UART |

### Carte et périphériques

- **Carte :** **DE10-Nano** — FPGA cible Cyclone V `5CSEBA6U23I7`
  > ⚠️ Bien sélectionner cette référence et non les variantes **L** ou **S**.
- **Programmation et débogage :** port **USB Blaster II** (côté alimentation et HDMI), utilisé à la fois pour le `.sof` et pour le debugger du Nios V.
- **Carte mezzanine TELECRAN :** 10 LEDs, 2 encodeurs rotatifs et accéléromètre **ADXL345**.
- **Écran magique :** sortie **HDMI** de la DE10-Nano (en salle de TP : adaptateur HDMI → USB et **VLC**, *Média → Ouvrir un périphérique de capture*).

---

## 📂 Structure du dépôt

```
.
├── tp_nios_v/
│   ├── rtl/                   # Sources matérielles
│   │   ├── tp_nios_v.vhd      #   ✅ Top-level : Nios V + écran magique
│   │   └── telecran/          #   Écran magique (projet de mineure, adapté)
│   ├── sim/                   # Simulation
│   ├── sopc/                  # Système Platform Designer
│   │   ├── nios.qsys          #   Description du système
│   │   └── nios/              #   Fichiers VHDL générés
│   ├── synt/                  # Projet Quartus (.qpf, .qsf, .sdc)
│   └── soft/
│       ├── app/main.c         #   ✅ Programme C (niveau à bulle + effacement)
│       └── bsp/               #   BSP généré (system.h, linker…)
├── WhatsApp Video …44.49.mp4  # Démonstrations sur carte
├── WhatsApp Video …44.59.mp4
└── README.md
```

### Fichiers principaux

| Fichier | Rôle |
|---------|------|
| [`rtl/tp_nios_v.vhd`](tp_nios_v/rtl/tp_nios_v.vhd) | Entité principale : instancie le Nios et l'écran magique, câble l'I2C en drain ouvert |
| [`rtl/telecran/telecran.vhd`](tp_nios_v/rtl/telecran/telecran.vhd) | Écran magique : encodeurs → mémoire d'image → HDMI, effacement par `i_clear_n` |
| [`rtl/telecran/encoder.vhd`](tp_nios_v/rtl/telecran/encoder.vhd) | Décodage des deux encodeurs en quadrature → coordonnées X et Y |
| [`rtl/telecran/dpram.vhd`](tp_nios_v/rtl/telecran/dpram.vhd) | Mémoire double port 720 × 480 × 8 bits |
| [`rtl/telecran/hdmi_controler.vhd`](tp_nios_v/rtl/telecran/hdmi_controler.vhd) | Synchronisation HDMI 720 × 480 |
| [`rtl/telecran/i2c/`](tp_nios_v/rtl/telecran/i2c) | Configuration I2C du transmetteur HDMI |
| [`rtl/telecran/pll/`](tp_nios_v/rtl/telecran/pll) | PLL 50 MHz → 27 MHz (horloge pixel) |
| [`sopc/nios.qsys`](tp_nios_v/sopc/nios.qsys) | Système Nios V (processeur, mémoire, UART, PIO, I2C) |
| [`soft/app/main.c`](tp_nios_v/soft/app/main.c) | Lecture de l'ADXL345, affichage sur les LEDs, détection du retournement |
| [`synt/tp_nios_v.qsf`](tp_nios_v/synt/tp_nios_v.qsf) / [`.sdc`](tp_nios_v/synt/tp_nios_v.sdc) | Affectation des broches et contraintes de timing |

---

## 🚀 Démarrage rapide

### Partie matérielle

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/neku89123/2627_2A_FPGA_AVANCE_MALEPART_M-TIR.git
   ```
2. Ouvrir `tp_nios_v/synt/tp_nios_v.qpf` dans **Quartus Prime Lite 24.1**.
3. Si `nios.qsys` a été modifié : l'ouvrir dans **Platform Designer** et cliquer sur **Generate HDL** (langage **VHDL**).
4. Compiler (**Processing → Start Compilation**).
5. Programmer la carte via **Tools → Programmer** avec le `.sof` généré.

### Partie logicielle

Dans **niosv-shell**, depuis `tp_nios_v/soft/` :

```bash
niosv-bsp -c -t=hal --sopcinfo=../sopc/nios.sopcinfo bsp/settings.bsp
niosv-app --bsp-dir=bsp --app-dir=app --srcs=app/main.c
```

Puis :

1. Importer les projets `bsp` et `app` dans **RiscFree** (*File → Import → CMake project*).
2. Compiler `app`, puis lancer `app.elf` avec le debugger **Ashling RISC-V**.
3. Lire la console dans un terminal :
   ```bash
   juart-terminal
   ```

> ⚠️ À chaque modification du système Platform Designer, il faut **supprimer et régénérer** le BSP et l'application (en conservant `main.c`) : les adresses et les noms des périphériques dans `system.h` changent.

---

Le projet se répartit entre deux mondes :

- **Logiciel (Nios V, C)** : la partie « intelligente » et lente — dialogue I2C avec le capteur, calcul de l'inclinaison, décision d'effacer.
- **Matériel (VHDL)** : la partie temps réel — affichage HDMI pixel par pixel, lecture des encodeurs, balayage de la mémoire.

Les deux communiquent par des **PIO** : `pio_0` vers les LEDs et `pio_1` vers l'entrée d'effacement de l'écran magique.

---

## 🧩 Étape 1 : système Nios V

### Composition du système ([`nios.qsys`](tp_nios_v/sopc/nios.qsys))

| Composant | Adresse de base | Taille | Rôle |
|-----------|-----------------|--------|------|
| `onchip_memory2_0` | `0x0000_0000` | 128 Ko | Mémoire programme et données (vecteur de reset) |
| `intel_niosv_m_0` (debug) | `0x0002_0000` | 64 Ko | Module de debug — *Enable Reset from Debug Module* activé |
| `i2c_0` | `0x0003_0000` | 64 o | Maître I2C Avalon pour l'ADXL345 |
| Timer du Nios V | `0x0003_0040` | 64 o | Timer système (utilisé par `usleep`) |
| `pio_1` | `0x0003_0080` | 8 bits | Bit 0 : effacement de l'écran magique (actif à `0`) |
| `pio_0` | `0x0003_0090` | 10 bits | LEDs de la carte TELECRAN |
| `jtag_uart_0` | `0x0003_00A0` | 8 o | Console (`stdin`, `stdout`, `stderr`) |

Le **gestionnaire d'instructions** du processeur est relié à la mémoire, le **gestionnaire de données** à la mémoire et à tous les périphériques. Les adresses sont attribuées automatiquement (*System → Assign Base Addresses*) et le système est généré en **VHDL**.

### Intégration dans Quartus ([`tp_nios_v.vhd`](tp_nios_v/rtl/tp_nios_v.vhd))

Le fichier `nios.qip` est ajouté au projet, puis le composant `nios` est instancié dans le top-level :

```vhdl
nios0 : entity nios.nios
    port map (
        clk_clk                          => i_clk,
        reset_reset_n                    => i_rst_n,
        pio_0_external_connection_export => o_led,
        pio_1_external_connection_export => s_pio_1,
        i2c_0_i2c_serial_sda_in          => s_i2c_sda_in,
        i2c_0_i2c_serial_scl_in          => s_i2c_scl_in,
        i2c_0_i2c_serial_sda_oe          => s_i2c_sda_oe,
        i2c_0_i2c_serial_scl_oe          => s_i2c_scl_oe
    );
```

---

## 💡 Étape 2 : Hello world et chenillard

Premier programme : un `printf("Hello, world!\n")` lu dans `juart-terminal`, pour valider toute la chaîne (bitstream, BSP, debugger, JTAG UART).

Le chenillard reprend ensuite celui du TP de mineure, mais **en logiciel** : au lieu d'un registre à décalage en VHDL, c'est le processeur qui écrit dans le registre de données du PIO.

```c
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include <unistd.h>

int main(void){
    int i = 0;
    while(1){
        IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, 1 << i);
        i = (i + 1) % 10;
        usleep(50000);
    }
}
```

- `PIO_0_BASE` vient de `system.h`, généré avec le BSP à partir du système Platform Designer.
- `IOWR_ALTERA_AVALON_PIO_DATA` écrit directement dans le registre de données du PIO : chaque bit pilote une LED.
- `usleep` s'appuie sur le timer du Nios V.

> ℹ️ Comparé au TP de mineure, aucune ligne de VHDL n'a changé entre le chenillard et le niveau à bulle : seul le programme C est modifié. C'est tout l'intérêt d'un processeur softcore.

---

## 🫧 Étape 3 : niveau à bulle

### Principe

```
 ┌─────────┐   I2C    ┌──────────┐  Avalon  ┌──────────┐  pio_0   ┌───────────┐
 │ ADXL345 │◄────────►│  i2c_0   │◄────────►│  Nios V  ├─────────►│ 10 LEDs   │
 │ (x,y,z) │ SCL/SDA  │ (maître) │          │  main.c  │  1 << n  │ ○○○○●○○○○○│
 └─────────┘          └──────────┘          └──────────┘          └───────────┘
```

L'accéléromètre mesure la projection de la gravité sur ses trois axes. Carte à plat, X ≈ 0 ; carte inclinée, X tend vers ±1 g. Le Nios V convertit X en un numéro de LED : la LED allumée se déplace comme la **bulle** d'un niveau.

### Câblage I2C en drain ouvert

Le contrôleur I2C Avalon ne pilote pas directement les broches : il fournit une entrée (`*_in`) et une commande de sortie (`*_oe`) pour chaque ligne. Une ligne I2C n'est jamais forcée à `1` : on la **tire à `0`** ou on la **laisse flotter** (`'Z'`), la résistance de pull-up la ramenant à `1`.

```
                         ┌────────────────────┐
     s_i2c_sda_oe ──────►│ si oe = '1' : '0'  │
                         │ sinon       : 'Z'  ├────────┬───────► io_i2c_sda ◄──► ADXL345
                         └────────────────────┘        │              ▲
     s_i2c_sda_in ◄────────────────────────────────────┘              │
                                                                  pull-up 3,3 V
```

```vhdl
s_i2c_scl_in <= io_i2c_scl;
io_i2c_scl   <= '0' when s_i2c_scl_oe = '1' else 'Z';

s_i2c_sda_in <= io_i2c_sda;
io_i2c_sda   <= '0' when s_i2c_sda_oe = '1' else 'Z';

-- ADXL345 : nCS = '1' -> mode I2C ; SDO = '0' -> adresse 0x53
o_i2c_ncs <= '1';
o_i2c_sdo <= '0';
```

### Registres de l'ADXL345 utilisés

| Registre | Adresse | Usage |
|----------|---------|-------|
| `DEVID` | `0x00` | Identifiant du composant, doit valoir **`0xE5`** |
| `POWER_CTL` | `0x2D` | Écriture de `0x08` : bit *Measure* à 1, démarrage des mesures |
| `DATAX0` … `DATAZ1` | `0x32` … `0x37` | 6 octets : X, Y, Z en 16 bits signés, poids faible en premier |

En pleine échelle par défaut (±2 g), **1 g ≈ 256**.

### Programme ([`main.c`](tp_nios_v/soft/app/main.c))

```
          ┌──────────────────────────────┐
          │ alt_avalon_i2c_open("i2c_0") │
          │ adresse esclave = 0x53       │
          └──────────────┬───────────────┘
                         ▼
          ┌──────────────────────────────┐
          │ lire DEVID → 0xE5 ?          │
          │ POWER_CTL ← 0x08             │
          └──────────────┬───────────────┘
                         ▼
   ┌────────►┌──────────────────────────────┐
   │         │ lire 6 octets depuis DATAX0  │
   │         │ x, y, z sur 16 bits signés   │
   │         └──────────────┬───────────────┘
   │                        ▼
   │         ┌──────────────────────────────┐    oui   ┌──────────────────────────┐
   │         │ z < -200 ? (carte retournée) ├─────────►│ pio_1 ← 0, 10 ms, ← 1    │
   │         └──────────────┬───────────────┘          │ → effacement de l'écran  │
   │                        │ non                      └────────────┬─────────────┘
   │                        ▼◄──────────────────────────────────────┘
   │         ┌──────────────────────────────┐
   │         │ led = (x + 256) × 10 / 512   │
   │         │ borné entre 0 et 9           │
   │         │ pio_0 ← 1 << led             │
   │         └──────────────┬───────────────┘
   │                        ▼
   └──────────────── usleep(50 ms)
```

Lecture des données et reconstruction des valeurs signées :

```c
txbuffer[0] = REG_DATAX0;
alt_avalon_i2c_master_tx_rx(i2c_dev, txbuffer, 1, rxbuffer, 6, ALT_AVALON_I2C_NO_INTERRUPTS);

x = (rxbuffer[1] << 8) + rxbuffer[0];
y = (rxbuffer[3] << 8) + rxbuffer[2];
z = (rxbuffer[5] << 8) + rxbuffer[4];
```

Conversion de l'inclinaison en numéro de LED :

```c
led = (x + ONE_G) * LED_COUNT / (2 * ONE_G);   // -1 g → LED 0, +1 g → LED 9
if(led < 0)             led = 0;
if(led > LED_COUNT - 1) led = LED_COUNT - 1;

IOWR_ALTERA_AVALON_PIO_DATA(PIO_0_BASE, 1 << led);
```

| X mesuré | Inclinaison | LED allumée |
|----------|-------------|-------------|
| ≈ −256 | penchée d'un côté (−1 g) | LED0 |
| ≈ 0 | à plat | LED4 / LED5 |
| ≈ +256 | penchée de l'autre côté (+1 g) | LED9 |

Les valeurs `x`, `y`, `z` et le numéro de LED sont affichés en continu dans `juart-terminal`, ce qui a servi au réglage des seuils.

---

## 🎨 Étape 4 : écran magique

### Reprise du projet de mineure

Le projet [Télécran](https://github.com/neku89123/2627_2A_FPGA_MALEPART_M-TIR) est intégré tel quel dans `rtl/telecran/` (encodeurs, mémoire double port, contrôleur HDMI, PLL). Deux modifications ont été apportées à [`telecran.vhd`](tp_nios_v/rtl/telecran/telecran.vhd) :

| Avant (mineure) | Après (FPGA avancé) |
|-----------------|---------------------|
| Les 10 LEDs affichent les compteurs des encodeurs | Les LEDs sont libérées : elles sont pilotées par le Nios V (`pio_0`) |
| L'effacement est lancé par le bouton `RIGHT_PB` | L'effacement est lancé par l'entrée **`i_clear_n`**, reliée au bit 0 de `pio_1` |

### Effacement commandé par le processeur

```
   Nios V                        top-level                          telecran
 ┌──────────┐  pio_1(0)   ┌──────────────────┐   i_clear_n   ┌─────────────────────────┐
 │ z < -200 ├────────────►│ s_pio_1(0)       ├──────────────►│ balayage d'effacement   │
 │ → 0 10ms │             └──────────────────┘               │ 0x00 écrit sur 345 600  │
 └──────────┘                                                │ adresses de la dpram    │
                                                             └─────────────────────────┘
```

Dans `telecran.vhd`, tant que `i_clear_n = '0'`, le compteur d'effacement est maintenu à 0. Dès que le signal repasse à `1`, il parcourt toute la mémoire en écrivant `0x00`, avec priorité sur le dessin :

```vhdl
process(i_clk_50)
begin
    if rising_edge(i_clk_50) then
        if i_clear_n = '0' then
            s_clear      <= '1';
            s_clear_addr <= 0;
        elsif s_clear = '1' then
            if s_clear_addr = h_res * v_res - 1 then
                s_clear <= '0';
            else
                s_clear_addr <= s_clear_addr + 1;
            end if;
        end if;
    end if;
end process;
```

Côté logiciel, une **impulsion de 10 ms** à `0` suffit à déclencher le balayage :

```c
if(z < -200){                                     // carte retournée
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, 0x00);   // efface
    usleep(10000);                                   // 10 ms
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_1_BASE, 0x01);   // relâche
}
```

> ℹ️ Le balayage dure 345 600 cycles à 50 MHz, soit environ **7 ms**. L'impulsion de 10 ms couvre donc largement un effacement complet.

Le seuil `z < -200` (≈ −0,8 g) correspond à une carte **face vers le bas** : carte à plat, `z` vaut environ +256.

---

## 📌 Broches

Toutes les entrées-sorties utilisent le standard **3.3-V LVTTL**.

### Horloge, reset et ADXL345

| Signal VHDL | Rôle | Broche FPGA |
|-------------|------|-------------|
| `i_clk` | Horloge 50 MHz | PIN_V11 |
| `i_rst_n` | Reset (actif à l'état bas) | PIN_AH17 |
| `io_i2c_scl` | SCL de l'ADXL345 | PIN_Y11 |
| `io_i2c_sda` | SDA de l'ADXL345 | PIN_AB26 |
| `o_i2c_ncs` | nCS (forcé à `1` : mode I2C) | PIN_W14 |
| `o_i2c_sdo` | SDO (forcé à `0` : adresse `0x53`) | PIN_AB25 |

### LEDs (`pio_0`)

| Nom | GPIO | FPGA |
|-----|------|------|
| LED0 | J1:5 | AG28 |
| LED1 | J1:7 | AE25 |
| LED2 | J1:9 | AG26 |
| LED3 | J1:13 | AG25 |
| LED4 | J1:17 | AG23 |
| LED5 | J1:21 | AH21 |
| LED6 | J1:25 | AF22 |
| LED7 | J1:27 | AG20 |
| LED8 | J1:33 | AG18 |
| LED9 | J1:37 | AG15 |

Les broches des encodeurs et de la sortie HDMI sont identiques à celles du projet Télécran de mineure (voir [`tp_nios_v.qsf`](tp_nios_v/synt/tp_nios_v.qsf)).

---

## 🎬 Démonstration

<!-- Glisser les vidéos dans l'éditeur GitHub pour obtenir un lien https://github.com/user-attachments/assets/… et le coller ici -->

- [Vidéo 1](<WhatsApp Video 2026-11-26 at 11.44.49.mp4>) : Effacement en retournant la carte
- [Vidéo 2](<WhatsApp Video 2026-11-26 at 11.44.59.mp4>) : Niveau à bulle

---

## 📚 Ressources

- Énoncé du TP (ENSEA) : [fpga_adv_tp.md](https://github.com/lfiack/ENSEA_2A_FPGA_Public/blob/main/majeure/3-tp/fpga_adv_tp.md)
- Datasheet de l'accéléromètre : [ADXL345 (Analog Devices)](https://www.analog.com/media/en/technical-documentation/data-sheets/ADXL345.pdf)
- Principe du télécran : [Écran magique (Wikipédia)](https://fr.wikipedia.org/wiki/%C3%89cran_magique)

---


## 👥 Auteurs

**MALEPART** et **M-TIR** — projet réalisé dans le cadre du module FPGA avancé, 2ᵉ année (2026-2027).
