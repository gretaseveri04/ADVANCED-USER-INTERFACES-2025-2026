const String _fallbackEndpoint = 'https://limitless-openai-project.openai.azure.com/';
const String _fallbackDeploymentName = 'gpt-4o';
const String _fallbackApiVersion = '2024-08-01-preview';
const String _fallbackAzureKey = 'EuHU0Q57ppItyHjGPJAKQTahO1Ze3bANdmW6ietwb0vwYztiGNoJJQQJ99BKACfhMk5XJ3w3AAAAACOGfZEA';

/// Azure OpenAI resource endpoint. 
const String endpoint = String.fromEnvironment(
  'AZURE_OPENAI_ENDPOINT',
  defaultValue: _fallbackEndpoint,
);

/// The model deployment name configured in the Azure OpenAI resource.
const String deploymentName = String.fromEnvironment(
  'AZURE_OPENAI_DEPLOYMENT_NAME',
  defaultValue: _fallbackDeploymentName,
);

/// Azure OpenAI API version to use.
const String apiVersion = String.fromEnvironment(
  'AZURE_OPENAI_API_VERSION',
  defaultValue: _fallbackApiVersion,
);

/// API key used to authenticate against Azure OpenAI.
const String AzureKey = String.fromEnvironment(
  'AZURE_OPENAI_KEY',
  defaultValue: _fallbackAzureKey,
);

class SupabaseConfig {
  static const supabaseUrl = 'https://pppybkjdcvxqhbfyqsuz.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwcHlia2pkY3Z4cWhiZnlxc3V6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI3ODU0NjYsImV4cCI6MjA3ODM2MTQ2Nn0.lZFlRJ804x5VL0TzS79DKiU3U6TOlZhJIOhnjHZjk4c';
}