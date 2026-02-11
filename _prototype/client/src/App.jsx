import { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [albums, setAlbums] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const getApiPrefix = () => {
    if (window.location.pathname.startsWith('/node')) return '/node';
    if (window.location.pathname.startsWith('/dotnet')) return '/dotnet';
    return '/dotnet';
  };

  const apiPrefix = getApiPrefix(); 

  useEffect(() => {
    fetch(`${apiPrefix}/api/albums`)
      .then(res => {
        if (!res.ok) throw new Error('Failed to fetch albums');
        return res.json();
      })
      .then(data => {
        setAlbums(data);
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  if (loading) return <div className="container">Loading albums...</div>;
  if (error) return <div className="container error">Error: {error}</div>;

  return (
    <div className="container">
      <h1>My Photo Albums</h1>
      <div className="albums-grid">
        {albums.map(album => (
          <div key={album.id} className="album-card">
            <img src={album.coverImage.path} alt={album.title} />
            <div className="album-info">
              <h2>{album.title}</h2>
              <p className="description">{album.description}</p>
              <p className="meta">{album.images.length} photos • {album.createdAt}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;