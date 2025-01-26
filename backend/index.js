const express=require("express");
const mongoose=require("mongoose");
const cors=require("cors");
const dotenv=require("dotenv");


const authRoutes=require("./routes/userRoutes");
const channelRoutes=require("./routes/channelRoutes");


dotenv.config();
const app=express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.DB_URL).then(()=>console.log("MongoDB connected")).catch(err=>console.error(err));

app.use('/auth',authRoutes);
app.use('/channel',channelRoutes);

const PORT=3000
app.listen(PORT,()=>console.log(`Server running on PORT ${PORT}`));