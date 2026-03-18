using ArtGallery.Services;
using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Moq;

namespace ArtGallery.Tests;

public class BlobStorageServiceTests
{
    private readonly Mock<BlobContainerClient> _mockContainer;
    private readonly BlobStorageService _service;

    public BlobStorageServiceTests()
    {
        _mockContainer = new Mock<BlobContainerClient>();

        _mockContainer
            .Setup(c => c.CreateIfNotExists(It.IsAny<PublicAccessType>(), null, null, default))
            .Returns(Mock.Of<Response<BlobContainerInfo>>());

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                { "BlobStorage:ConnectionString", "UseDevelopmentStorage=true" },
                { "BlobStorage:ContainerName", "paintings" }
            })
            .Build();

        _service = new BlobStorageService(config, _mockContainer.Object);
    }

    [Fact]
    public async Task UploadAsync_ShouldReturnFileName()
    {
        var mockFile = new Mock<IFormFile>();
        mockFile.Setup(f => f.FileName).Returns("tavla.jpg");
        mockFile.Setup(f => f.OpenReadStream()).Returns(new MemoryStream(new byte[] { 1, 2, 3 }));

        var mockBlobClient = new Mock<BlobClient>();
        mockBlobClient
            .Setup(b => b.UploadAsync(It.IsAny<Stream>(), true, default))
            .ReturnsAsync(Mock.Of<Response<BlobContentInfo>>());
        mockBlobClient.Setup(b => b.Uri).Returns(new Uri("https://fake.blob.core.windows.net/paintings/test.jpg"));

        _mockContainer
            .Setup(c => c.GetBlobClient(It.IsAny<string>()))
            .Returns(mockBlobClient.Object);

        var result = await _service.UploadAsync(mockFile.Object);

        Assert.EndsWith(".jpg", result);
        Assert.NotEmpty(result);
    }

    [Fact]
    public async Task DeleteAsync_ShouldCallDeleteIfExists()
    {
        var fileName = "test-uuid.jpg";
        var mockBlobClient = new Mock<BlobClient>();

        mockBlobClient
            .Setup(b => b.DeleteIfExistsAsync(It.IsAny<DeleteSnapshotsOption>(), null, default))
            .ReturnsAsync(Mock.Of<Response<bool>>());

        _mockContainer
            .Setup(c => c.GetBlobClient(fileName))
            .Returns(mockBlobClient.Object);

        await _service.DeleteAsync(fileName);

        mockBlobClient.Verify(b =>
            b.DeleteIfExistsAsync(It.IsAny<DeleteSnapshotsOption>(), null, default), Times.Once);
    }
}