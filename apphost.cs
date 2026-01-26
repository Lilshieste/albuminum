#:package Aspire.Hosting.JavaScript@13.1.0
#:sdk Aspire.AppHost.Sdk@13.1.0
#:project ./server_dotnet/server_dotnet.csproj

var builder = DistributedApplication.CreateBuilder(args);

var dotnetBackend = builder.AddProject<Projects.server_dotnet>("dotnet-api")
       .WithExternalHttpEndpoints();

var nodeBackend = builder.AddJavaScriptApp("node-api", "./server")
       .WithHttpEndpoint(env: "PORT")
       .WithArgs("--workspace", "server");

var getDotNetBackendBaseUrl = () => dotnetBackend.GetEndpoint("http").Url;
var getNodeBackendBaseUrl = () => nodeBackend.GetEndpoint("http").Url;

dotnetBackend.WithEnvironment("API_BASE_URL", getDotNetBackendBaseUrl);
nodeBackend.WithEnvironment("API_BASE_URL", getNodeBackendBaseUrl);

builder.AddViteApp("react-frontend", "./client")
       // .WithReference(dotnetBackend)
       // .WithEnvironment("VITE_API_URL", getDotNetBackendBaseUrl)
       .WithReference(nodeBackend)
       .WithEnvironment("VITE_API_URL", getNodeBackendBaseUrl)
       .WithExternalHttpEndpoints();

builder.Build().Run();
