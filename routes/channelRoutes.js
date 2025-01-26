const express=require("express");
const Channel=require("../models/channels");
const User=require("../models/user");
const router=express.Router();
const zod=require("zod");

const createChannelSchema=zod.object({
    name:zod.string().min(1,'Channel name is required'),
    userId:zod.string().min(1,"User ID is required"),
})

router.post('/create',async(req,res)=>{
    try{
        const {success}=createChannelSchema.safeParse(req.body);
        if(!success){
            return res.status(403).json({
                message:"Problem with parsing data",
            });
        }

        const name=req.body.name;
        const userId=req.body.userId;

        const channel = new Channel({
            name, 
            participants:[userId]
        });

        await channel.save();

        res.status(201).json({
            message:"Channel created successfully",
            channelId:channel._id,
        });
    }catch(err){
        res.status(403).json({})
    }
});

const joinChannelSchema=zod.object({
    channelId:zod.string().min(1, "Channel Id is required"),
    userId:zod.string().min(1, 'User ID is required'),
})

router.post('/join',async(req,res)=>{
    try{
        const validatedData=joinChannelSchema.parse(req.body);
        const channelId=req.body.channelId;
        const userId=req.body.userId;

        const channel=await Channel.findById(channelId);
        if(!channel){
            return res.status(403).json({
                message:"Channel not found",
            });
        }

        if(!channel.participants.includes(userId)){
            channel.participants.push(userId);
            await channel.save();
        }

        res.status(200).json({
            message:"Joined Channel Successfully",
            channel
        });
    }catch(err){
        if( err instanceof zod.ZodError){
            res.status(400).json({
                errors:err.errors
            });
        }else{
            res.status(500).json({
                error:err.message
            })
        }
    }
});

module.exports=router;