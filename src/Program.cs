using MudBlazor.Services;
using HelloAZD.Components;
using Azure.Identity;
using Microsoft.Extensions.Azure;
using HelloAZD;

var builder = WebApplication.CreateBuilder(args);

// Add MudBlazor services
builder.Services.AddMudServices();

var managedIdentityClientId = builder.Configuration["AZURE_MANAGED_IDENTITY_CLIENT_ID"];
var identity = new DefaultAzureCredential(new DefaultAzureCredentialOptions { ManagedIdentityClientId = managedIdentityClientId });

builder.Services.AddAzureClients(clientBuilder =>
{
    var storageUrl = builder.Configuration["STORAGE_URL"];
    var tablesUrl = builder.Configuration["TABLES_URL"];
    if (string.IsNullOrWhiteSpace(storageUrl))
    {
        throw new InvalidOperationException("STORAGE_URL is not configured.");
    }
    if (string.IsNullOrWhiteSpace(tablesUrl))
    {
        throw new InvalidOperationException("TABLES_URL is not configured.");
    }
    // Register clients for each service
    clientBuilder.AddBlobServiceClient(new Uri(storageUrl));
    clientBuilder.AddTableServiceClient(new Uri(tablesUrl));

    clientBuilder.UseCredential(identity);
});

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

// Register TableStorageService for DI
builder.Services.AddSingleton<TableStorageService>();

var app = builder.Build();


// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();

app.Run();
