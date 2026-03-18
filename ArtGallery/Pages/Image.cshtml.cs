using ArtGallery.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ArtGallery.Pages;

public class ImageModel : PageModel
{
    private readonly IBlobStorageService _blob;

    public ImageModel(IBlobStorageService blob)
    {
        _blob = blob;
    }

    public async Task<IActionResult> OnGetAsync(string fileName)
    {
        if (string.IsNullOrEmpty(fileName))
            return NotFound();

        var (content, contentType) = await _blob.GetImageAsync(fileName);
        return File(content, contentType);
    }
}