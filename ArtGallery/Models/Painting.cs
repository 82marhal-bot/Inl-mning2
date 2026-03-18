using Newtonsoft.Json;

namespace ArtGallery.Models;

public class Painting
{
    [JsonProperty("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonProperty("title")]
    public string Title { get; set; } = string.Empty;

    [JsonProperty("description")]
    public string Description { get; set; } = string.Empty;

    [JsonProperty("medium")]
    public string Medium { get; set; } = string.Empty;

    [JsonProperty("year")]
    public int Year { get; set; } = DateTime.Now.Year;

    [JsonProperty("imageUrl")]
    public string ImageUrl { get; set; } = string.Empty;
}