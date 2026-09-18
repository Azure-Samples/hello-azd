using Azure.Storage.Blobs;
using Microsoft.AspNetCore.Components.Forms;

namespace HelloAZD;

public interface IAttachmentStorageService
{
    Task<string> UploadAsync(IBrowserFile file, CancellationToken cancellationToken = default);
    Task DeleteAsync(string blobName, CancellationToken cancellationToken = default);
}

public sealed class AttachmentStorageService(BlobServiceClient blobServiceClient)
    : IAttachmentStorageService
{
    private const long MaxAttachmentSize = 512_000;
    private readonly BlobContainerClient _containerClient =
        blobServiceClient.GetBlobContainerClient("attachments");

    public async Task<string> UploadAsync(
        IBrowserFile file,
        CancellationToken cancellationToken = default)
    {
        var blobName = Guid.NewGuid().ToString("N");
        await using var stream = file.OpenReadStream(MaxAttachmentSize, cancellationToken);
        await _containerClient.UploadBlobAsync(blobName, stream, cancellationToken);
        return blobName;
    }

    public async Task DeleteAsync(
        string blobName,
        CancellationToken cancellationToken = default) =>
        await _containerClient.DeleteBlobIfExistsAsync(blobName, cancellationToken: cancellationToken);
}

public sealed class TicketSubmissionService(
    ITicketStorageService ticketStorage,
    IAttachmentStorageService attachmentStorage,
    ILogger<TicketSubmissionService> logger)
{
    private const string PartitionKey = "helpdesk";

    public async Task<SupportTicket> SubmitAsync(
        SupportTicket ticket,
        CancellationToken cancellationToken = default)
    {
        var attachmentName = string.Empty;
        try
        {
            if (ticket.Attachment is not null)
            {
                attachmentName = await attachmentStorage.UploadAsync(
                    ticket.Attachment,
                    cancellationToken);
            }

            var item = new SupportTicket
            {
                Id = Guid.NewGuid().ToString("N"),
                Title = ticket.Title.Trim(),
                Description = ticket.Description.Trim(),
                Department = PartitionKey,
                Notes = ticket.Notes.Trim(),
                AttachmentName = attachmentName
            };

            await ticketStorage.UpsertTicketAsync(item, cancellationToken);
            return item;
        }
        catch
        {
            if (!string.IsNullOrEmpty(attachmentName))
            {
                try
                {
                    await attachmentStorage.DeleteAsync(attachmentName, cancellationToken);
                }
                catch (Exception cleanupException)
                {
                    logger.LogWarning(
                        cleanupException,
                        "Failed to delete orphaned attachment {BlobName}",
                        attachmentName);
                }
            }

            throw;
        }
    }
}