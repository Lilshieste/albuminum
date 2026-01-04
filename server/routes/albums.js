const express = require('express');
const router = express.Router();
const { getAlbums } = require('../steel-thread');

router.get('/', (req, res) => {
  res.json(getAlbums());
});

router.get('/:id', (req, res) => {
  const albums = getAlbums();
  const album = albums.find(a => a.id === parseInt(req.params.id));
  if (!album) {
    return res.status(404).json({ error: 'Album not found' });
  }
  res.json(album);
});

module.exports = router;