const express=require("express");
const User=require("../models/user");
const bcrypt=require("bcryptjs");
const router=express.Router();
const zod=require("zod");

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

router.post("/signin",async(req,res)=>{
    const {success,error}=signinBody.safeParse(req.body);
    if(!success){
        res.status(403).json({
            error:error,
        });
    }

    try{
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
        res.status(200).json({
            message:"Login successfully",
            userId:user._id
        })
    }catch(err){
        res.status(500).json({
            error:err.message,
        })
    }
});

module.exports=router;
