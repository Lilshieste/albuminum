#:package Aspire.Hosting.JavaScript@13.1.0
#:sdk Aspire.AppHost.Sdk@13.1.0
#:project ./server_dotnet/server_dotnet.csproj
#:project ./Gateway/Gateway.csproj

var builder = DistributedApplication.CreateBuilder(args);

var dotnetBackend = builder.AddProject<Projects.server_dotnet>("dotnet-api")
       .WithExternalHttpEndpoints();

var nodeBackend = builder.AddJavaScriptApp("node-api", "./server")
       .WithHttpEndpoint(env: "PORT")
       .WithArgs("--workspace", "server");

var frontend = builder.AddViteApp("react-frontend", "./client")
       .WithExternalHttpEndpoints();

var getDotNetBackendBaseUrl = () => dotnetBackend.GetEndpoint("http").Url;
var getNodeBackendBaseUrl = () => nodeBackend.GetEndpoint("http").Url;

dotnetBackend.WithEnvironment("API_BASE_URL", getDotNetBackendBaseUrl);
nodeBackend.WithEnvironment("API_BASE_URL", getNodeBackendBaseUrl);

var gateway = builder.AddProject<Projects.Gateway>("gateway")
                     .WithReference(dotnetBackend)
                     .WithReference(nodeBackend)
                     .WithReference(frontend)
                     .WithExternalHttpEndpoints();

builder.Build().Run();
