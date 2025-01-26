const express=require("express");
const Channel=require("../models/channels");
const User=require("../models/user");
const router=express.Router();
const {RtcTokenBuilder, RtcRole}=require("agora-access-token");
const zod=require("zod");
const dotenv=require("dotenv");

dotenv.config();

const createChannelSchema=zod.object({
    name:zod.string().min(1,'Channel name is required'),
    userId:zod.string().min(1,"User ID is required"),
});

const APP_ID=process.env.APP_ID;
const APP_CERTIFICATE=process.env.APP_CERTIFICATE;


router.post('/create',async(req,res)=>{
    try{
        const {success,data}=createChannelSchema.safeParse(req.body);
        if(!success){
            return res.status(403).json({
                message:"Problem with parsing data",
            });
        }

        const {name,userId}=data;

        const existingChannel=await Channel.findOne({name});
        if(existingChannel){
            return res.status(200).json({
                message:"Channel already exists",
                channelId:existingChannel._id,
            });
        }

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
        const {channelId,userId}=validatedData;

        const channel=await Channel.findById(channelId);
        if(!channel){
            return res.status(403).json({
                message:"Channel not found",
            });
        }

        if(!channel.participants.includes(userId)){
            channel.participants.push(userId);
            await channel.save();
        };

        const channelName=channel.name;
        const uid=userId;

        const token=generateAgoraToken(channelName,uid);

        res.status(200).json({
            message:"Joined Channel Successfully",
            channel,
            token,
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

function generateAgoraToken(channelName,uid){
    const currentTime=Math.floor(Date.now()/1000);
    const previligeExpiredTs=currentTime+3600;
    
    const token=RtcTokenBuilder.buildTokenWithUid(
        APP_ID,
        APP_CERTIFICATE,
        channelName,
        uid,
        RtcRole.PUBLISHER,
        previligeExpiredTs
    );
    return token;
}

module.exports=router;