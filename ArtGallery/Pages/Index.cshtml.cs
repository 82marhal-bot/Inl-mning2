using ArtGallery.Models;
using ArtGallery.Services;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ArtGallery.Pages;

public class IndexModel : PageModel
{
    private readonly ICosmosDbService _cosmos;
    public List<Painting> Paintings { get; set; } = new();

    public IndexModel(ICosmosDbService cosmos)
    {
        _cosmos = cosmos;
    }

    public async Task OnGetAsync()
    {
        Paintings = await _cosmos.GetAllAsync();
    }
}
