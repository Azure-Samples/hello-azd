using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Azure;
using Azure.Data.Tables;
using Azure.Identity;
using Microsoft.Extensions.Configuration;

namespace HelloAZD
{
    public class TableStorageService
    {
        private readonly TableClient _tableClient;

        public TableStorageService(IConfiguration configuration)
        {
            var tablesUrl = configuration["TABLES_URL"] ?? throw new ArgumentNullException("TABLES_URL");
            var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                ManagedIdentityClientId = configuration["AZURE_MANAGED_IDENTITY_CLIENT_ID"]
            });
            var serviceClient = new TableServiceClient(new Uri(tablesUrl), credential);
            _tableClient = serviceClient.GetTableClient("tickets");
            _tableClient.CreateIfNotExists();
        }

        public async Task<List<SupportTicket>> GetTicketsAsync(string partitionKey)
        {
            var list = new List<SupportTicket>();
            await foreach (var entity in _tableClient.QueryAsync<TableEntity>(e => e.PartitionKey == partitionKey))
            {
                list.Add(new SupportTicket
                {
                    id = entity.GetString("id") ?? string.Empty,
                    title = entity.GetString("title") ?? string.Empty,
                    description = entity.GetString("description") ?? string.Empty,
                    department = entity.PartitionKey,
                    notes = entity.GetString("notes") ?? string.Empty,
                    attachmentName = entity.GetString("attachmentName") ?? string.Empty
                });
            }
            return list;
        }

        public async Task UpsertTicketAsync(SupportTicket ticket)
        {
            var entity = new TableEntity(partitionKey: ticket.department, rowKey: ticket.id)
            {
                { "id", ticket.id },
                { "title", ticket.title },
                { "description", ticket.description },
                { "notes", ticket.notes },
                { "attachmentName", ticket.attachmentName }
            };
            await _tableClient.UpsertEntityAsync(entity);
        }
    }
}
