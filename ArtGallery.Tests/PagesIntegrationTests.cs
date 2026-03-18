using ArtGallery.Models;
using ArtGallery.Services;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using Moq;

namespace ArtGallery.Tests;

public class PagesIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly Mock<ICosmosDbService> _mockCosmos;
    private readonly Mock<IBlobStorageService> _mockBlob;

    public PagesIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _mockCosmos = new Mock<ICosmosDbService>();
        _mockBlob = new Mock<IBlobStorageService>();

        _mockCosmos.Setup(c => c.GetAllAsync()).ReturnsAsync(new List<Painting>
{
   new() { Id = "1", Title = "Testmalning", Medium = "Gouache", Year = 2024, ImageUrl = "test.jpg" }
});

        _mockCosmos.Setup(c => c.GetByIdAsync(It.IsAny<string>())).ReturnsAsync((Painting?)null);

        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureServices(services =>
            {
                services.AddSingleton<ICosmosDbService>(_mockCosmos.Object);
                services.AddSingleton<IBlobStorageService>(_mockBlob.Object);
            });
        }).CreateClient();
    }

    [Fact]
    public async Task Index_ShouldReturn200()
    {
        var response = await _client.GetAsync("/");
        Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Index_ShouldContainPaintingTitle()
    {
        var response = await _client.GetAsync("/");
        var content = await response.Content.ReadAsStringAsync();
        Assert.Contains("Testmalning", content);
    }

    [Fact]
    public async Task Upload_ShouldReturn200()
    {
        var response = await _client.GetAsync("/Upload");
        Assert.Equal(System.Net.HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Details_WithInvalidId_ShouldShowNotFoundMessage()
    {
        _mockCosmos.Setup(c => c.GetByIdAsync("nonexistent")).ReturnsAsync((Painting?)null);

        var response = await _client.GetAsync("/Details?id=nonexistent");
        var content = await response.Content.ReadAsStringAsync();

        Assert.Contains("hittades inte", content);
    }
}