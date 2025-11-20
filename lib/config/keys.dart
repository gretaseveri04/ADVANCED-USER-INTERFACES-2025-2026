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

