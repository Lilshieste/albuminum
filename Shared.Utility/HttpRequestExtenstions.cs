using Microsoft.AspNetCore.Http;
namespace Microsoft.Extensions.Hosting;

public static class HttpRequestExtensions
{
    public static string GetBaseUrl(this HttpRequest request)
    {
        // PathBase is important if your app is hosted in a sub-directory (e.g., /api/v1/)
        return $"{request.Scheme}://{request.Host}{request.PathBase}";
    }

    public static string ToAbsoluteUrl(this HttpRequest request, string relativePath)
    {
        var baseUrl = request.GetBaseUrl().TrimEnd('/');
        var path = relativePath.TrimStart('/');
        
        return $"{baseUrl}/{path}";
    }
}