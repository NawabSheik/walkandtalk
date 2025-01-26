const express=require("express");
const mongoose=require("mongoose");
const cors=require("cors");
const dotenv=require("dotenv");
const http=require("http");
const {Server}=require("socket.io");
const authRoutes=require("./routes/userRoutes");
const channelRoutes=require("./routes/channelRoutes");

dotenv.config();
const app=express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.DB_URL).then(()=>console.log("MongoDB connected")).catch(err=>console.error(err));

app.use('/auth',authRoutes);
app.use('/channel',channelRoutes);

const server=http.createServer(app);
const io=new Server(server, {
    cors:{
        origin:"*",
        methods:["GET","POST"],
    },
});

io.on('connection',(socket)=>{
    console.log("User connected: ",socket.id);

    socket.on("join-channel",(channelId)=>{
        socket.join(channelId);
        console.log(`User joined channel ${channelId}`);
        io.to(channelId).emit('user-joined',{userId:socket.id,channelId});
    });

    socket.on('disconnect',()=>{
        console.log("User Disconnected",socket.io);
    });
});

const PORT=process.env.PORT||5000;
server.listen(PORT,()=>console.log(`Server running on PORT ${PORT}`));
