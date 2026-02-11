public class SteelThreadData
{
    private readonly List<ImageModel> _images;
    
    public SteelThreadData(IConfiguration configuration)
    {
        var _baseUrl = configuration["API_BASE_URL"];
        
        _images = new List<ImageModel>
        {
            new(1, $"{_baseUrl}/images/img1.png", "2024-06-15"),
            new(2, $"{_baseUrl}/images/img2.png", "2024-06-16"),
            new(3, $"{_baseUrl}/images/image3.png", "2024-06-17"),
            new(4, $"{_baseUrl}/images/img4.png", "2024-06-18"),
            new(5, $"{_baseUrl}/images/image_5.png", "2024-12-25"),
            new(6, $"{_baseUrl}/images/image6.png", "2024-12-25"),
            new(7, $"{_baseUrl}/images/img7.png", "2024-12-25"),
            new(8, $"{_baseUrl}/images/image8.png", "2024-09-10")
        };
    }

    public List<AlbumModel> GetAlbums()
    {
        return new List<AlbumModel>
        {
            new(
                Id: 1,
                Title: "Summer Vacation 2024",
                Description: "Beach and mountain adventures",
                CoverImage: _images[0],
                Images: new List<ImageModel> { _images[0], _images[2], _images[4] },
                CreatedAt: "2024-06-15"
            ),
            new(
                Id: 2,
                Title: "Family Gathering",
                Description: "Holiday celebrations",
                CoverImage: _images[6],
                Images: new List<ImageModel> { _images[1], _images[3], _images[6], _images[7] },
                CreatedAt: "2024-12-25"
            ),
            new(
                Id: 3,
                Title: "City Explorations",
                Description: "Urban photography",
                CoverImage: _images[5],
                Images: new List<ImageModel> { _images[5] },
                CreatedAt: "2024-09-10"
            )
        };
    }

    public List<ImageModel> GetImages() => _images;
}