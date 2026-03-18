using ArtGallery.Models;
using ArtGallery.Services;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Configuration;
using Moq;

namespace ArtGallery.Tests;

public class CosmosDbServiceTests
{
    private readonly Mock<Container> _mockContainer;
    private readonly CosmosDbService _service;

    public CosmosDbServiceTests()
    {
        _mockContainer = new Mock<Container>();

        var mockClient = new Mock<CosmosClient>();
        var mockDatabase = new Mock<Database>();

        mockClient.Setup(c => c.GetDatabase(It.IsAny<string>()))
            .Returns(mockDatabase.Object);
        mockDatabase.Setup(d => d.GetContainer(It.IsAny<string>()))
            .Returns(_mockContainer.Object);

        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                { "CosmosDb:AccountEndpoint", "https://localhost:8081/" },
                { "CosmosDb:AccountKey", "fakekey" },
                { "CosmosDb:DatabaseName", "ArtGallery" },
                { "CosmosDb:ContainerName", "Paintings" }
            })
            .Build();

        _service = new CosmosDbService(config, mockClient.Object);
    }

    [Fact]
    public async Task AddAsync_ShouldCallCreateItem()
    {
        var painting = new Painting { Title = "Testmålning", Medium = "Olja", Year = 2024 };

        var mockResponse = new Mock<ItemResponse<Painting>>();
        _mockContainer
            .Setup(c => c.CreateItemAsync(painting, It.IsAny<PartitionKey>(), null, default))
            .ReturnsAsync(mockResponse.Object);

        await _service.AddAsync(painting);

        _mockContainer.Verify(c =>
            c.CreateItemAsync(painting, It.IsAny<PartitionKey>(), null, default), Times.Once);
    }

    [Fact]
    public async Task GetByIdAsync_WhenNotFound_ShouldReturnNull()
    {
        _mockContainer
            .Setup(c => c.ReadItemAsync<Painting>(It.IsAny<string>(), It.IsAny<PartitionKey>(), null, default))
            .ThrowsAsync(new CosmosException("Not found", System.Net.HttpStatusCode.NotFound, 0, "", 0));

        var result = await _service.GetByIdAsync("nonexistent-id");

        Assert.Null(result);
    }

    [Fact]
    public async Task DeleteAsync_ShouldCallDeleteItem()
    {
        var id = Guid.NewGuid().ToString();
        var mockResponse = new Mock<ItemResponse<Painting>>();

        _mockContainer
            .Setup(c => c.DeleteItemAsync<Painting>(id, It.IsAny<PartitionKey>(), null, default))
            .ReturnsAsync(mockResponse.Object);

        await _service.DeleteAsync(id);

        _mockContainer.Verify(c =>
            c.DeleteItemAsync<Painting>(id, It.IsAny<PartitionKey>(), null, default), Times.Once);
    }
}