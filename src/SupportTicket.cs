using Microsoft.AspNetCore.Components.Forms;
using System.ComponentModel.DataAnnotations;

namespace HelloAZD
{
    public class SupportTicket
    {
        public string id { get; set; }
        public string department { get; set; }
        [Required]
        public string title { get; set; }
        [Required]
        public string description { get; set; }
        [Required]
        public string notes { get; set; }
        public string attachmentName { get; set; }
        public IBrowserFile Attachment { get; set; }
    }
}
