using ArtGallery.Models;
using ArtGallery.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ArtGallery.Pages;

public class UploadModel : PageModel
{
    private readonly ICosmosDbService _cosmos;
    private readonly IBlobStorageService _blob;

    [BindProperty] public string Title { get; set; } = string.Empty;
    [BindProperty] public string Description { get; set; } = string.Empty;
    [BindProperty] public string Medium { get; set; } = string.Empty;
    [BindProperty] public int Year { get; set; } = DateTime.Now.Year;

    public UploadModel(ICosmosDbService cosmos, IBlobStorageService blob)
    {
        _cosmos = cosmos;
        _blob = blob;
    }

    public async Task<IActionResult> OnPostAsync(IFormFile imageFile)
    {
        if (!ModelState.IsValid || imageFile == null)
            return Page();

        var imageUrl = await _blob.UploadAsync(imageFile);

        var painting = new Painting
        {
            Title = Title,
            Description = Description,
            Medium = Medium,
            Year = Year,
            ImageUrl = imageUrl
        };

        await _cosmos.AddAsync(painting);
        return RedirectToPage("/Index");
    }
}