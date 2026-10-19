# Atlas

Workspace leggero per note e oggetti collegati.

## Avvio

Non richiede Node, npm o dipendenze:

```bash
cd /home/dariocastellano/capacities-inspired
python3 -m http.server 8766
```

Aprire `http://127.0.0.1:8766/`.

## Funzioni implementate

- Today, Inbox, Library e Connections;
- creazione e modifica di note, progetti, fonti, persone e task;
- ricerca su titoli, contenuti e tag;
- filtro per tipo;
- persistenza locale con `localStorage`;
- export/import JSON;
- command palette con `Ctrl/Cmd+K`;
- layout responsive.

## Verifica

```bash
pytest -q test_app.py
node --check app.js
```

Il prototipo precedente è conservato in `atlas-prototype.html`.
