using Azure.Core;
using Azure.Identity;
using HelloAZD;
using HelloAZD.Components;
using Microsoft.Extensions.Azure;
using MudBlazor.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddMudServices();

var managedIdentityClientId = builder.Configuration["AZURE_MANAGED_IDENTITY_CLIENT_ID"];
var credentialOptions = new DefaultAzureCredentialOptions();
if (!string.IsNullOrWhiteSpace(managedIdentityClientId))
{
    credentialOptions.ManagedIdentityClientId = managedIdentityClientId;
}

TokenCredential credential = new DefaultAzureCredential(credentialOptions);
builder.Services.AddSingleton(credential);

var storageUri = GetRequiredUri(builder.Configuration, "STORAGE_URL");
var tablesUri = GetRequiredUri(builder.Configuration, "TABLES_URL");

builder.Services.AddAzureClients(clientBuilder =>
{
    clientBuilder.AddBlobServiceClient(storageUri);
    clientBuilder.AddTableServiceClient(tablesUri);
    clientBuilder.UseCredential(credential);
});

builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddSingleton<ITicketStorageService, TableStorageService>();
builder.Services.AddSingleton<IAttachmentStorageService, AttachmentStorageService>();
builder.Services.AddSingleton<TicketSubmissionService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapGet("/healthz", () => Results.Ok());

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode(options =>
    {
        options.ContentSecurityFrameAncestorsPolicy = "'none'";
        options.DisableWebSocketCompression = true;
    });

app.Run();

static Uri GetRequiredUri(IConfiguration configuration, string key)
{
    var value = configuration[key];
    if (!Uri.TryCreate(value, UriKind.Absolute, out var uri))
    {
        throw new InvalidOperationException($"{key} must be configured with an absolute URI.");
    }

    return uri;
}

public partial class Program;
