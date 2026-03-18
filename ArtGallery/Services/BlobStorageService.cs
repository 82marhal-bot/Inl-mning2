using Azure.Storage.Blobs;

namespace ArtGallery.Services;

public class BlobStorageService : IBlobStorageService
{
    private readonly BlobContainerClient _containerClient;

    public BlobStorageService(IConfiguration config, BlobContainerClient? containerClient = null)
    {
        if (containerClient != null)
        {
            _containerClient = containerClient;
        }
        else
        {
            var connectionString = config["BlobStorage:ConnectionString"];
            var containerName = config["BlobStorage:ContainerName"];
            _containerClient = new BlobContainerClient(connectionString, containerName);
            _containerClient.CreateIfNotExists();
        }
    }

    public virtual async Task<string> UploadAsync(IFormFile file)
    {
        var fileName = $"{Guid.NewGuid()}{Path.GetExtension(file.FileName)}";
        var blobClient = _containerClient.GetBlobClient(fileName);

        using var stream = file.OpenReadStream();
        await blobClient.UploadAsync(stream, overwrite: true);

        return fileName; // Returnera bara filnamnet, inte hela URL:en
    }

    public virtual async Task DeleteAsync(string fileName)
{
    var blobClient = _containerClient.GetBlobClient(fileName);
    await blobClient.DeleteIfExistsAsync();
}


public virtual async Task<(Stream Content, string ContentType)> GetImageAsync(string fileName)
{
    var blobClient = _containerClient.GetBlobClient(fileName);
    var response = await blobClient.DownloadContentAsync();
    return (response.Value.Content.ToStream(), response.Value.Details.ContentType);
}
}