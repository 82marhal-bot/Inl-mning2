namespace ArtGallery.Services;

public interface IBlobStorageService
{
    Task<string> UploadAsync(IFormFile file);
    Task DeleteAsync(string fileName);
    Task<(Stream Content, string ContentType)> GetImageAsync(string fileName);
}