const mongoose = require("mongoose");

const refreshTokenSchema = new mongoose.Schema({
    token: String
})

module.exports = mongoose.model('RefreshToken', refreshTokenSchema);