const express = require('express');
const multer = require('multer');
const mysql = require('mysql2');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads')); // Serve images publicly

// Configure Multer for image uploads
const storage = multer.diskStorage({
  destination: 'uploads/', // Folder to store images
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname)); // Unique file name
  }
});
const upload = multer({ storage });

// MySQL Connection
const db = mysql.createConnection({
  host: process.env.DB_HOST, 
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});
db.connect(err => {
  if (err) console.log(err);
  else console.log('✅ MySQL Connected');
});

// API to upload an image
app.post('/upload', upload.single('image'), (req, res) => {
  if (!req.file) return res.status(400).send({ message: 'No file uploaded' });

  const imageUrl = `http://your-server-ip:5000/uploads/${req.file.filename}`;
  const sql = "INSERT INTO reports (image_url) VALUES (?)";
  
  db.query(sql, [imageUrl], (err, result) => {
    if (err) return res.status(500).send(err);
    res.send({ message: 'Image uploaded', url: imageUrl });
  });
});

// API to get all images
app.get('/images', (req, res) => {
  db.query("SELECT * FROM reports", (err, results) => {
    if (err) return res.status(500).send(err);
    res.send(results);
  });
});

const PORT = 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
