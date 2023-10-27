$codeProfileClasses = @"
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SmallsOnline.VSCode.Profiles.Models
{
    public class CodeProfileItem
    {
        [JsonPropertyName("displayName")]
        public string DisplayName { get; set; } = null!;

        [JsonPropertyName("description")]
        #nullable enable
        public string? Description { get; set; }
        #nullable restore

        [JsonPropertyName("filePath")]
        public string FilePath { get; set; } = null!;
    }

    public class CodeProfileExtension
    {
        public CodeProfileExtension(string displayName, string extensionId)
        {
            DisplayName = displayName;
            ExtensionId = extensionId;
        }

        [JsonPropertyName("displayName")]
        public string DisplayName { get; set; } = null!;

        [JsonPropertyName("extensionId")]
        public string ExtensionId { get; set; } = null!;
    }

    public static class CodeProfileJsonSerializer
    {
        public static CodeProfileItem[] DeserializeProfileItemList(string json) => JsonSerializer.Deserialize<CodeProfileItem[]>(json);
    }
}
"@

Add-Type -TypeDefinition $codeProfileClasses -Language "CSharp"