# limitless_app

Assistant-oriented Flutter app for managing recordings, transcripts and AI chat
insights.

## Features

- **Conversational assistant** backed by Azure OpenAI (chat completion API).
- **Offline fallback** that synthesizes answers from `mock_data/mock_responses.json`
  whenever cloud credentials are missing/unavailable.
- **Lifelog browser** (transcriptions, categories, quick navigation).

## Prerequisites

- Flutter `3.35.x` (`flutter doctor`)
- Chrome (or another Flutter-supported target)
- Access to an Azure OpenAI resource with at least one chat deployment

## Azure configuration

All values are read by `lib/core/services/ai_service.dart` from
`lib/config/keys.dart` (fallback constants) or from `--dart-define`
variables. You need four values:

| Variable | Dove trovarla |
| --- | --- |
| `AZURE_OPENAI_ENDPOINT` | Portale Azure → tua risorsa **Azure OpenAI** → **Overview** → *Endpoint servizi IA* (es. `https://my-resource.openai.azure.com/`). |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | Risorsa → **Deployments** → colonna **Name** (es. `gpt-4o`). Il nome deve combaciare esattamente. |
| `AZURE_OPENAI_API_VERSION` | Nel portale, apri il deployment e clicca **View API call** oppure **Open in Playground**: nell’URL copiato c’è `api-version=...` (es. `2024-08-01-preview`). |
| `AZURE_OPENAI_KEY` | Risorsa → **Keys and Endpoint** → “Key 1/Key 2”. Copia una chiave o rigenerala se necessario. |


Durante l’avvio vengono stampati i valori letti (se `kDebugMode`), utile per
verificare che endpoint/deployment/version/key siano corretti.

## Comportamento dell’assistente

1. `AIService.sendMessage` prova sempre la chiamata Azure.  
   - Se la risposta restituisce `200`, il messaggio arriva dal modello cloud.
   - In caso di errori (401, 404, mismatch API version, rete) l’eccezione viene
     loggata e scatta il fallback.
2. **Fallback offline**  
   - i lifelog vengono caricati da `mock_data/mock_responses.json`;
   - viene fatta una ricerca a keyword per trovare gli entry più rilevanti;
   - l’assistente costruisce una risposta con sintesi, azioni e decisioni per
     restare utile anche senza connessione.

Quando rimetti le credenziali corrette (oppure l’endpoint torna
raggiungibile) non serve alcuna modifica al codice: il servizio ricomincia a
rispondere da Azure automaticamente.
