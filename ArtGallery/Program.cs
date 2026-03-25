using ArtGallery.Services;
using Microsoft.AspNetCore.HttpOverrides; // Lägg till denna!

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();
builder.Services.AddSingleton<ICosmosDbService, CosmosDbService>();
builder.Services.AddSingleton<IBlobStorageService, BlobStorageService>();

// --- VIKTIGT: Lägg till stöd för Proxy-headers ---
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownIPNetworks.Clear();
    options.KnownProxies.Clear();
});

var app = builder.Build();

// --- VIKTIGT: Aktivera Middleware ---
app.UseForwardedHeaders(); 

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // HSTS kan ibland bråka bakom proxy om man inte har certifikat, 
    // så den kan vara bra att avvakta med.
}

// app.UseHttpsRedirection(); // <--- TA BORT eller kommentera ut denna! 
// Varför? Nginx sköter trafiken. Om appen försöker tvinga HTTPS internt på port 5000 blir det ofta "Infinite Loop" eller 500-fel.

app.UseStaticFiles();
app.UseRouting();
app.MapRazorPages();

app.Run();

public partial class Program { }