const express = require('express');
const router = express.Router();

// Mock data - we'll replace image URLs with your test images
const mockAlbums = [
  {
    id: 1,
    title: 'Summer Vacation 2024',
    description: 'Beach and mountain adventures',
    coverImage: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=400',
    photoCount: 24,
    createdAt: '2024-06-15'
  },
  {
    id: 2,
    title: 'Family Gathering',
    description: 'Holiday celebrations',
    coverImage: 'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400',
    photoCount: 18,
    createdAt: '2024-12-25'
  },
  {
    id: 3,
    title: 'City Explorations',
    description: 'Urban photography',
    coverImage: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=400',
    photoCount: 42,
    createdAt: '2024-09-10'
  }
];

router.get('/', (req, res) => {
  res.json(mockAlbums);
});

router.get('/:id', (req, res) => {
  const album = mockAlbums.find(a => a.id === parseInt(req.params.id));
  if (!album) {
    return res.status(404).json({ error: 'Album not found' });
  }
  res.json(album);
});

module.exports = router;