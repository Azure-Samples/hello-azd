using Microsoft.AspNetCore.Components.Forms;
using System.ComponentModel.DataAnnotations;

namespace HelloAZD
{
    public class SupportTicket
    {
        public string id { get; set; } = string.Empty;
        public string department { get; set; } = string.Empty;
        [Required]
        public string title { get; set; } = string.Empty;
        [Required]
        public string description { get; set; } = string.Empty;
        [Required]
        public string notes { get; set; } = string.Empty;
        public string attachmentName { get; set; } = string.Empty;
        public IBrowserFile? Attachment { get; set; }
    }
}
