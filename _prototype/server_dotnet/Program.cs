var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddOpenApi();
builder.Services.AddSingleton<SteelThreadData>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendPolicy", policy =>
    {
        policy.AllowAnyOrigin() 
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

if(app.Configuration["API_BASE_URL"] == null)
{
    throw new InvalidOperationException("CRITICAL ERROR: 'API_BASE_URL' is missing from configuration. Configuration must provide this.");
}

app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseCors("FrontendPolicy");

app.MapStaticAssets().ShortCircuit(); 

var albumsApi = app
    .MapGroup("/api/albums")
    .WithTags("Inventory");

albumsApi.MapGet("/", (SteelThreadData data) => data.GetAlbums())
    .WithName("GetAlbums");

albumsApi.MapGet("/{id:int}", (int id, SteelThreadData data) =>
{
    var album = data.GetAlbums().FirstOrDefault(a => a.Id == id);
    return album is not null ? Results.Ok(album) : Results.NotFound();
})
    .WithName("GetAlbum");

app.Run();