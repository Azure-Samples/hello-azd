using Azure.Data.Tables;

namespace HelloAZD;

public interface ITicketStorageService
{
    Task<List<SupportTicket>> GetTicketsAsync(
        string partitionKey,
        CancellationToken cancellationToken = default);

    Task UpsertTicketAsync(
        SupportTicket ticket,
        CancellationToken cancellationToken = default);
}

public sealed class TableStorageService : ITicketStorageService
{
    private const string TableName = "tickets";

    private readonly TableClient _tableClient;

    public TableStorageService(TableServiceClient serviceClient)
    {
        _tableClient = serviceClient.GetTableClient(TableName);
    }

    public async Task<List<SupportTicket>> GetTicketsAsync(
        string partitionKey,
        CancellationToken cancellationToken = default)
    {
        var tickets = new List<SupportTicket>();
        await foreach (var entity in _tableClient.QueryAsync<TableEntity>(
            entity => entity.PartitionKey == partitionKey,
            cancellationToken: cancellationToken))
        {
            tickets.Add(new SupportTicket
            {
                Id = entity.GetString("id") ?? string.Empty,
                Title = entity.GetString("title") ?? string.Empty,
                Description = entity.GetString("description") ?? string.Empty,
                Department = entity.PartitionKey,
                Notes = entity.GetString("notes") ?? string.Empty,
                AttachmentName = entity.GetString("attachmentName") ?? string.Empty
            });
        }

        return tickets;
    }

    public async Task UpsertTicketAsync(
        SupportTicket ticket,
        CancellationToken cancellationToken = default)
    {
        var entity = new TableEntity(partitionKey: ticket.Department, rowKey: ticket.Id)
        {
            { "id", ticket.Id },
            { "title", ticket.Title },
            { "description", ticket.Description },
            { "notes", ticket.Notes },
            { "attachmentName", ticket.AttachmentName }
        };
        await _tableClient.UpsertEntityAsync(entity, cancellationToken: cancellationToken);
    }
}
