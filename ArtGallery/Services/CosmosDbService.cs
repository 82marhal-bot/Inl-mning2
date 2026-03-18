using Microsoft.Azure.Cosmos;
using ArtGallery.Models;

namespace ArtGallery.Services;

public class CosmosDbService : ICosmosDbService
{
    private readonly Container _container;

    public CosmosDbService(IConfiguration config, CosmosClient? client = null)
    {
        client ??= new CosmosClient(
            config["CosmosDb:AccountEndpoint"],
            config["CosmosDb:AccountKey"]
        );

        var database = client.GetDatabase(config["CosmosDb:DatabaseName"]);
        _container = database.GetContainer(config["CosmosDb:ContainerName"]);
    }

    public virtual async Task<List<Painting>> GetAllAsync()
    {
        var query = _container.GetItemQueryIterator<Painting>("SELECT * FROM c");
        var results = new List<Painting>();
        while (query.HasMoreResults)
        {
            var response = await query.ReadNextAsync();
            results.AddRange(response);
        }
        return results;
    }

    public virtual async Task<Painting?> GetByIdAsync(string id)
    {
        try
        {
            var response = await _container.ReadItemAsync<Painting>(id, new PartitionKey(id));
            return response.Resource;
        }
        catch (CosmosException) { return null; }
    }

    public virtual async Task AddAsync(Painting painting) =>
        await _container.CreateItemAsync(painting, new PartitionKey(painting.Id));

    public virtual async Task DeleteAsync(string id) =>
        await _container.DeleteItemAsync<Painting>(id, new PartitionKey(id));
}