using ArtGallery.Models;
using ArtGallery.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ArtGallery.Pages;

public class DetailsModel : PageModel
{
    private readonly ICosmosDbService _cosmos;
    private readonly IBlobStorageService _blob;
    public Painting? Painting { get; set; }

    public DetailsModel(ICosmosDbService cosmos, IBlobStorageService blob)
    {
        _cosmos = cosmos;
        _blob = blob;
    }

    public async Task OnGetAsync(string id)
    {
        Painting = await _cosmos.GetByIdAsync(id);
    }

    public async Task<IActionResult> OnPostAsync(string id)
    {
        var painting = await _cosmos.GetByIdAsync(id);
        if (painting != null)
        {
            await _blob.DeleteAsync(painting.ImageUrl);
            await _cosmos.DeleteAsync(id);
        }
        return RedirectToPage("/Index");
    }
}