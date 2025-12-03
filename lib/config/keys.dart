class SupabaseConfig {
  static const String supabaseUrl = 'https://pppybkjdcvxqhbfyqsuz.supabase.co';
  
  // La tua chiave Supabase (Anon Key)
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwcHlia2pkY3Z4cWhiZnlxc3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3ODU0NjYsImV4cCI6MjA3ODM2MTQ2Nn0.lZFlRJ804x5VL0TzS79DKiU3U6TOlZhJIOhnjHZjk4c';
}

class AzureConfig {
  // 1. CHIAVE AZURE
  // Incolla qui la chiave che inizia con "EuHU..." (o quella nuova se l'hai rigenerata)
  // Prendila da Azure AI Studio -> "Keys & Endpoint"
  static const String apiKey = 'EuHU0Q57ppItyHjGPJAKQTahO1Ze3bANdmW6ietwb0vwYztiGNoJJQQJ99BKACfhMk5XJ3w3AAAAACOGfZEA'; 
  
  // 2. ENDPOINT
  // Preso dal tuo codice precedente:
  static const String endpoint = 'https://limitless-openai-project.openai.azure.com'; 

  // 3. WHISPER DEPLOYMENT (Per l'audio)
  // Questo è il nome che abbiamo visto nel tuo screenshot:
  static const String whisperDeploymentName = 'my-whisper'; 
  
  // 4. CHAT DEPLOYMENT (Per il testo)
  // ATTENZIONE: Assicurati di avere un deployment chiamato "gpt-4o" su Azure!
  // Se il tuo deployment si chiama diversamente (es. "gpt-35-turbo"), cambia questa riga.
  static const String gptDeploymentName = 'gpt-4o';   
}

// Nota: Ho rimosso la classe 'ApiKeys' con la chiave 'sk-proj...' 
// perché ora stiamo usando Azure per tutto e non vogliamo mischiare i sistemi.