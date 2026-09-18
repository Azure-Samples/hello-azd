using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Components.Forms;

namespace HelloAZD;

public sealed class SupportTicket
{
    public string Id { get; set; } = string.Empty;
    public string Department { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string Title { get; set; } = string.Empty;

    [Required, StringLength(1_000)]
    public string Description { get; set; } = string.Empty;

    [Required, StringLength(1_000)]
    public string Notes { get; set; } = string.Empty;

    public string AttachmentName { get; set; } = string.Empty;
    public IBrowserFile? Attachment { get; set; }
}
