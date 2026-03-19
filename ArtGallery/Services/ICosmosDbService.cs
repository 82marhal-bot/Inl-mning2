using ArtGallery.Models;

namespace ArtGallery.Services;

public interface ICosmosDbService
{
    Task<List<Painting>> GetAllAsync();
    Task<Painting?> GetByIdAsync(string id);
    Task AddAsync(Painting painting);
    Task DeleteAsync(string id);
    Task UpdateAsync(Painting painting);
}