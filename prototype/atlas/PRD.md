# Atlas — PRD e piano di prodotto

> Prodotto originale ispirato ai principi osservati pubblicamente in Capacities; non replica codice, asset, copy o identità visiva proprietaria.

## 1. Obiettivo

Creare uno spazio personale per catturare pensieri e trasformarli in oggetti collegati: note, persone, progetti, fonti e decisioni. L'utente deve poter iniziare a scrivere senza progettare prima una gerarchia di cartelle e ritrovare il contesto attraverso relazioni e ricerca.

## 2. Evidenze pubbliche osservate

Analisi passiva della homepage pubblica di `https://capacities.io/` (HTTP 200, titolo “A studio for your mind”, contenuti accessibili senza login). I messaggi e le feature pubblicamente enfatizzati includono:

- pensare in “oggetti” invece che in file;
- collegamenti tra idee;
- scrittura immediata;
- calendario e vista del giorno;
- note, immagini, file, audio e fonti;
- AI come funzione del prodotto;
- esportazione dei dati e attenzione a privacy/GDPR.

Queste sono osservazioni di prodotto, non una ricostruzione del codice interno. Il prototipo usa un nome, copy, palette e componenti originali.

## 3. Utente e problema

**Utente principale:** persona che studia, scrive, fa ricerca o gestisce progetti individuali.

**Problema:** le informazioni vengono catturate in luoghi diversi e perdono contesto; la manutenzione dell'organizzazione diventa più onerosa del pensiero.

**Outcome:** in meno di 30 secondi l'utente può catturare una nota, classificarla come oggetto e collegarla a un progetto o a una fonte.

## 4. MVP — incluso

1. Workspace personale con sidebar e ricerca.
2. Inbox / Today con elenco cronologico.
3. Editor a blocchi semplificato: testo, checklist, citazione.
4. Tipi di oggetto: nota, persona, progetto, fonte.
5. Collegamenti bidirezionali visibili nella pagina dell'oggetto.
6. Pannello “related” con oggetti collegati e tag.
7. Command palette (`⌘/Ctrl+K`) per creare, cercare e cambiare vista.
8. Persistenza locale del prototipo tramite `localStorage`.
9. Stati base: vuoto, ricerca, selezionato, nuova nota.

## 5. Non incluso nella prima iterazione

Account, sync multi-device, collaborazione, allegati reali, import/export completo, OCR, AI generativa, notifiche, pagamenti e app mobile nativa.

## 6. Principi UX

- Capture first: un'azione primaria evidente per iniziare.
- Objects over folders: le relazioni sono più importanti della profondità gerarchica.
- Context on demand: mostrare i collegamenti senza sovraccaricare l'editor.
- Keyboard friendly: ricerca e creazione rapide.
- Data ownership: progettare fin dall'inizio export JSON/Markdown e cancellazione locale.

## 7. Metriche di accettazione MVP

- Nuova nota creata in massimo 2 interazioni dalla dashboard.
- Ricerca filtra titolo e contenuto senza ricaricare la pagina.
- Selezionando un oggetto si vedono almeno due relazioni o uno stato vuoto esplicito.
- Refresh della pagina mantiene gli oggetti creati nel browser.
- Layout usabile a 390 px e 1280 px.

## 8. Architettura proposta per l'implementazione

- **Frontend MVP:** HTML semantico, CSS e JavaScript vanilla, senza build step.
- **Stato MVP:** modulo JavaScript piccolo e funzioni pure dove possibile.
- **Persistenza MVP:** `localStorage`; IndexedDB solo quando gli allegati o il volume dati lo renderanno necessario.
- **Editor:** tiptap/ProseMirror in fase implementativa, non nel mockup.
- **Backend successivo:** API TypeScript + PostgreSQL, con tabelle `objects`, `blocks`, `links`, `tags`, `users`.
- **Ricerca successiva:** PostgreSQL full-text, poi indice dedicato solo se necessario.
- **Privacy:** cifratura at-rest, export, audit dei dati, minimizzazione degli eventi.

## 9. Roadmap

### Fase A — Prototipo

Dashboard cliccabile, creazione nota, ricerca, relazioni simulate, responsive QA.

### Fase B — MVP locale

React/TypeScript, modello dati reale, editor a blocchi, IndexedDB, import/export.

### Fase C — Sync privato

Autenticazione, API, sincronizzazione offline-first e conflitti.

### Fase D — Funzioni avanzate

Allegati, AI opt-in, graph view, app mobile e collaborazione selettiva.

## 10. Rischi

- Un editor ricco può diventare il progetto invece di un mezzo: partire da pochi blocchi.
- Le relazioni automatiche possono generare rumore: suggerimenti opt-in, mai collegamenti invisibili.
- Sync e cifratura cambiano fortemente il modello dati: evitare di bloccare l'MVP locale su un backend prematuro.
