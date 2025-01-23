const express=require("express");
const User=require("../models/user");
const RefreshToken=require("../models/refreshToken");
const bcrypt=require("bcryptjs");
const router=express.Router();
const zod=require("zod");
const jwt=require("jsonwebtoken");

const signupBody=zod.object({
    username:zod.string().email(),
    password:zod.string()
});

router.post("/signup",async(req,res)=>{
    const {success,error}=signupBody.safeParse(req.body);
    if(!success){
        res.status(403).json({
            error:error,
        })
    }
    
    const existingUser=await User.findOne({
        username:req.body.username
    })
    
    if(existingUser){
         res.status(403).json({
            message:"User exists",
        });
    }
   
    const hashedPassword=await bcrypt.hash(req.body.password,10);
    const user = await User.create({
        username:req.body.username,
        password:hashedPassword,
    });

    await user.save();

    res.status(200).json({
        message:"User created successfully",
    });
});

const signinBody=zod.object({
    username:zod.string().email(),
    password:zod.string(),
})

function generateAccessToken(user) {
    return jwt.sign({user}, process.env.ACCESS_TOKEN_SECRET, { expiresIn: "1m" }) 
}

function generateRefreshToken(user) {
    return jwt.sign({user}, process.env.REFRESH_TOKEN_SECRET);
}

router.post("/signin",async(req,res)=>{
    const {success,error}=signinBody.safeParse(req.body);
    if(!success){
        res.status(403).json({
            error:error,
        });
    }
    
    const username=req.body.username
    const user=await User.findOne({username});
    if(!user){
        return res.status(404).json({
            message:"User not found",
        });
    }
    const isMatch=await bcrypt.compare(req.body.password,user.password);
    if(!isMatch){
        return res.status(400).json({
            message:"Invalid Credentials",
        });
    }

    const accessToken = generateAccessToken(user);
    const refreshToken = generateRefreshToken(user);

    const newRefreshToken = new RefreshToken({ token: refreshToken });
    await newRefreshToken.save();

    res.status(200).json({
        message:"Login successfully",
        userId:user._id,
        accessToken,
        refreshToken
    })

});

router.post("/token", async(req, res) => {
    const { refreshToken } = req.body;

    if(!refreshToken) {
        return res.status(400).json({
            msg: "Refresh token is required"
        })
    };

    const storedToken = await RefreshToken.findOne({ token: refreshToken });

    if(!storedToken) {
        return res.status(400).json({
            msg: "Invalid Refresh Token"
        })
    }

    jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, (err, u) => {
        if(err) {
            return res.status(403).json({
                msg: "Invalid Refresh Token"
            })
        }

        const accessToken = generateAccessToken({ username: u.username });
        res.json({ accessToken });
    })
})

module.exports=router;