const mongoose=require("mongoose");

const userSchema=new mongoose.Schema({
    username:{
        type:String,
        trim:true,
        required:true,
        unique:true,
        lowercase:true,
        minLength:3,
        maxLength:30,
    },
    password:{
        type:String,
        required:true,
        minLength:6
    },
    channels:{
        type:mongoose.Schema.Types.ObjectId,
        ref:"Channel",
    },
},
{timestamps:true})

module.exports=mongoose.model('User',userSchema);;