var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddReverseProxy()
  .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
  .AddServiceDiscoveryDestinationResolver();

var app = builder.Build();

// Default to the .Net backend
app.MapGet("/", () => Results.Redirect("/dotnet/"));

app.MapReverseProxy();
app.Run();