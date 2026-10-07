const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const User = require('./models/User');
const PersonInfo = require('./models/PersonInfo');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
const dbUser = process.env.DB_USER;
const dbPass = process.env.DB_PASS;

let MONGODB_URI;
if (dbUser && dbPass && dbPass !== '<db_password>') {
  MONGODB_URI = `mongodb+srv://${dbUser}:${dbPass}@cluster0.aaunuut.mongodb.net/mUsic?appName=Cluster0`;
} else {
  MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/';
}

const clientOptions = { serverApi: { version: '1', strict: true, deprecationErrors: true } };

mongoose.connect(MONGODB_URI, clientOptions)
  .then(() => {
    console.log('Successfully connected to MongoDB.');
    // Optional ping
    mongoose.connection.db.admin().command({ ping: 1 }).then(() => {
      console.log("Pinged your deployment. You successfully connected to MongoDB!");
    });
  })
  .catch((error) => console.error('MongoDB connection error:', error));

// Routes
app.post('/api/login', async (req, res) => {
  const { msic } = req.body;
  
  if (!msic) {
    return res.status(400).json({ error: 'MSIC is required' });
  }

  try {
    // Find the user
    let user = await User.findOne({ msic });
    
    if (!user) {
      // If user doesn't exist, create them automatically (since there's no signup screen)
      user = new User({ msic });
      await user.save();
      return res.status(201).json({ message: 'New user created successfully', user });
    }

    return res.status(200).json({ message: 'Login successful', user });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/info', async (req, res) => {
  try {
    const info = await PersonInfo.find().select('name contact ministry -_id');
    res.status(200).json(info);
  } catch (error) {
    console.error('Info fetch error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
