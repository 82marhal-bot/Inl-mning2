# 🎨 Mitt Bildgalleri

Ett enkelt och personligt bildgalleri byggt med .NET Razor Pages och Azure-tjänster. Ladda upp målningar, visa dem i ett galleri och hantera dem enkelt via webbgränssnittet.

![Galleriet](screenshots/gallery.png)

---

## Teknisk stack

| Teknologi | Användning |
|---|---|
| .NET 10 Razor Pages | Webbapplikation |
| Azure Cosmos DB (NoSQL) | Lagring av metadata (titel, medium, år) |
| Azure Blob Storage | Lagring av bildfiler |
| Azure Virtual Network | Säker nätverksarkitektur |
| Azure Bastion | Säker administrativ åtkomst |
| GitHub Actions | CI/CD-pipeline |
| xUnit + Moq | Enhetstester och integrationstester |

---

## Arkitektur

Applikationen körs i ett säkert Azure Virtual Network (VNet) uppdelat i fyra subnät:

![Arkitektur](screenshots/infrastructure.png)

Varje subnät skyddas av NSG-regler (Network Security Groups) som begränsar trafiken till enbart det som är nödvändigt.

---

## Kom igång lokalt

### Förutsättningar

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [Node.js](https://nodejs.org) (för Azurite)
- [Azure Cosmos DB Emulator](https://aka.ms/cosmosdb-emulator)

### Installation

**1. Klona repot**

```bash
git clone https://github.com/82marhal-bot/Inl-mning2.git
cd artgallery
```

**2. Installera Azurite (lokal Blob Storage-emulator)**

```bash
npm install -g azurite
```

**3. Starta emulatorerna**

Starta Azure Cosmos DB Emulator via startmenyn och vänta tills ikonen i systemfältet blir grön.

Starta sedan Azurite i terminalen:

```bash
azurite --silent --skipApiVersionCheck &
```

**4. Skapa databas i Cosmos DB Emulator**

Öppna `https://localhost:8081/_explorer/index.html` i webbläsaren och skapa:
- Database ID: `ArtGallery`
- Container ID: `Paintings`
- Partition key: `/id`

**5. Starta applikationen**

```bash
cd ArtGallery
dotnet run
```

Öppna `https://localhost:5001` i webbläsaren.

---

## Skärmdumpar

**Galleriet**

![Galleriet](screenshots/gallery.png)

**Uppladdning**

![Uppladdning](screenshots/upload.png)

**Detaljvy**

![Detaljvy](screenshots/details.png)

---

## Tester

Projektet har 10 tester uppdelade i tre kategorier:

| Kategori | Antal | Beskrivning |
|---|---|---|
| Enhetstester — CosmosDbService | 3 | Testar att data sparas, hämtas och raderas korrekt |
| Enhetstester — BlobStorageService | 2 | Testar uppladdning och borttagning av bildfiler |
| Integrationstester — Sidor | 4 | Testar att sidorna svarar korrekt via HTTP |

### Kör testerna

```bash
cd ArtGallery.Tests
dotnet test
```

Förväntat resultat:

```
Test summary: total: 10; failed: 0; succeeded: 10; skipped: 0
```

---

## CI/CD-pipeline

Projektet använder GitHub Actions för automatiserad bygge, testning och driftsättning.

```
Git Push
    │
    ▼
┌─────────────────────┐
│   CI — Build & Test │
│  dotnet build       │
│  dotnet test        │
└──────────┬──────────┘
           │ Godkänd
           ▼
┌─────────────────────┐
│   CD — Deploy       │
│  dotnet publish     │
│  SSH via Bastion    │
│  systemctl restart  │
└─────────────────────┘
```

CD-steget körs enbart vid push till `main` och kräver att följande GitHub Secrets är konfigurerade:

| Secret | Beskrivning |
|---|---|
| `SSH_PRIVATE_KEY` | Privat SSH-nyckel för åtkomst via Bastion |
| `BASTION_HOST` | Bastionens publika IP-adress |
| `APP_SERVER_IP` | App Serverns interna IP-adress |

---

## Projektstruktur

```
ArtGallery/
├── Models/
│   └── Painting.cs              # Datamodell
├── Services/
│   ├── ICosmosDbService.cs      # Interface för Cosmos DB
│   ├── CosmosDbService.cs       # Implementering
│   ├── IBlobStorageService.cs   # Interface för Blob Storage
│   └── BlobStorageService.cs    # Implementering
├── Pages/
│   ├── Index.cshtml             # Galleriet
│   ├── Upload.cshtml            # Uppladdning
│   ├── Details.cshtml           # Detaljvy
│   └── Image.cshtml             # Bildservare
└── wwwroot/
    └── css/site.css             # Styling

ArtGallery.Tests/
├── CosmosDbServiceTests.cs      # Enhetstester för Cosmos DB
├── BlobStorageServiceTests.cs   # Enhetstester för Blob Storage
└── PagesIntegrationTests.cs     # Integrationstester
```
