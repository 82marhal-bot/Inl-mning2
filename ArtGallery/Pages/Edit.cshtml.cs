using ArtGallery.Models;
using ArtGallery.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace ArtGallery.Pages;

public class EditModel : PageModel
{
    private readonly ICosmosDbService _cosmos;

    [BindProperty]
    public Painting? Painting { get; set; }

    public EditModel(ICosmosDbService cosmos)
    {
        _cosmos = cosmos;
    }

    public async Task<IActionResult> OnGetAsync(string id)
    {
        Painting = await _cosmos.GetByIdAsync(id);
        if (Painting == null)
            return NotFound();

        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid || Painting == null)
            return Page();

        await _cosmos.UpdateAsync(Painting);
        return RedirectToPage("/Details", new { id = Painting.Id });
    }
}