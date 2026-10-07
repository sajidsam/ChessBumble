const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  msic: {
    type: String,
    required: true,
    unique: true,
    trim: true
  }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
