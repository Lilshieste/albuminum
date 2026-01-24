#:package Aspire.Hosting.JavaScript@13.1.0
#:sdk Aspire.AppHost.Sdk@13.1.0

var builder = DistributedApplication.CreateBuilder(args);

var backend = builder.AddJavaScriptApp("node-api", "./server")
                     .WithHttpEndpoint(env: "PORT")
                     .WithArgs("--workspace", "server");

builder.AddJavaScriptApp("react-frontend", "./client")
       .WithReference(backend)
       .WithHttpEndpoint(env: "VITE_PORT")
       .WithArgs("--workspace", "client");

builder.Build().Run();