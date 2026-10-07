const mongoose = require('mongoose');
const CryptoJS = require('crypto-js');
const PersonInfo = require('./models/PersonInfo');
require('dotenv').config();

const SECRET_KEY = process.env.ENCRYPTION_KEY || 'msic_secret_encryption_key_32_ch';

// Data from PDF
const data = [
  {"name": "Mir Mohammad Helal Uddin (MP)", "contact": "01713213678", "ministry": "Ministry of Chittagong Hill Tracts Affairs"}, 
  {"name": "Habibur Rashid (MP)", "contact": "01677788880", "ministry": "Ministry of Road Transport, Bridges, Railways & Shipping"}, 
  {"name": "Md. Rajib Ahsan (MP)", "contact": "01711209155", "ministry": "Ministry of Road Transport, Bridges, Railways & Shipping"}, 
  {"name": "Md. Abdul Bari (MP)", "contact": "01789512368", "ministry": "Ministry of Public Administration"}, 
  {"name": "Mir Shahe Alam (MP)", "contact": "01711368609", "ministry": "Ministry of Local Govt, Rural Dev & Co-operatives"}, 
  {"name": "Md. Junaid Abdur Rahim Saki (MP)", "contact": "01715189545", "ministry": "Ministry of Finance, Planning & Home Affairs"}, 
  {"name": "Ishraque Hossain (MP)", "contact": "01761815229", "ministry": "Ministry of Liberation War Affairs"}, 
  {"name": "Farjana Sharmin (MP)", "contact": "01888717434", "ministry": "Ministry of Women, Children Affairs & Social Welfare"}, 
  {"name": "Sheikh Faridul Islam (MP)", "contact": "01711565151", "ministry": "Ministry of Environment, Religious & Law Affairs"}, 
  {"name": "A N M Ehsanul Hoque Milan (MP)", "contact": "01711551942", "ministry": "Ministry of Education, Primary & Mass Education"}, 
  {"name": "Sardar Md. Sakhawat Hossain (MP)", "contact": "01713250080", "ministry": "Ministry of Health and Family Welfare"}, 
  {"name": "Fakir Mahbub Anam (MP)", "contact": "01711556262", "ministry": "Ministry of Posts, Telecom & Science Technology"}, 
  {"name": "Sheikh Rabiul Alam (MP)", "contact": "01728555417", "ministry": "Ministry of Road Transport, Bridges, Railways & Shipping"}, 
  {"name": "Mirza Fakhrul Islam Alamgir (MP)", "contact": "01726676306", "ministry": "Ministry of Local Govt, Rural Dev & Co-operatives"}, 
  {"name": "Amir Khasru Mahmud Chowdhury (MP)", "contact": "01750020320", "ministry": "Ministry of Finance, Planning & Home Affairs"}, 
  {"name": "Salahuddin Ahmed (MP)", "contact": "01711402442", "ministry": "Ministry of Finance, Planning & Home Affairs"}, 
  {"name": "Iqbal Hasan Mahmud (MP)", "contact": "01676660666", "ministry": "Ministry of Power, Energy and Mineral Resources"}, 
  {"name": "Hafiz Uddin Ahmed Bir Bikrom (MP)", "contact": "01409302478", "ministry": "Ministry of Liberation War Affairs"}, 
  {"name": "Abu Zafar Md. Zahid Hossain (MP)", "contact": "01710193693", "ministry": "Ministry of Women, Children Affairs & Social Welfare"}, 
  {"name": "Dr. Khalilur Rahman (Technocrat)", "contact": "01739196580", "ministry": "Ministry of Foreign Affairs"}, 
  {"name": "Abdul Awal Mintoo (MP)", "contact": "01711531701", "ministry": "Ministry of Environment, Forest and Climate Change"}, 
  {"name": "Kazi Shah Mofazzal Hossain Kaikobad (MP)", "contact": "01711523361", "ministry": "Ministry of Religious Affairs"}, 
  {"name": "Mizanur Rahman Minu (MP)", "contact": "01720440157", "ministry": "Ministry of Land"}, 
  {"name": "Nitai Roy Chowdhury (MP)", "contact": "01711145414", "ministry": "Ministry of Cultural Affairs"}, 
  {"name": "Khandaker Abdul Muktadir (MP)", "contact": "01711804902", "ministry": "Ministry of Commerce, Industries, Textiles & Jute"}, 
  {"name": "Ariful Haque Chowdhury (MP)", "contact": "01733371800", "ministry": "Ministry of Labour, Expatriates' Welfare"}, 
  {"name": "Zahir Uddin Swapan (MP)", "contact": "01713009797", "ministry": "Ministry of Information and Broadcasting"}, 
  {"name": "Mohammad Amin Ur Rashid (Technocrat)", "contact": "01763426386", "ministry": "Ministry of Agriculture, Fisheries & Food"}, 
  {"name": "Afroza Khanam (MP)", "contact": "01711521001", "ministry": "Ministry of Civil Aviation and Tourism"}, 
  {"name": "Md. Shahid Uddin Chowdhury Annie (MP)", "contact": "01749899595", "ministry": "Ministry of Water Resources"}, 
  {"name": "Asadul Habib Dulu (MP)", "contact": "01915617968", "ministry": "Ministry of Disaster Management and Relief"}, 
  {"name": "Md. Asaduzzaman (MP)", "contact": "01911011887", "ministry": "Ministry of Law, Justice & Parliamentary Affairs"}, 
  {"name": "Zakaria Taher (MP)", "contact": "01333333000", "ministry": "Ministry of Housing and Public Works"}, 
  {"name": "Dipen Dewan (MP)", "contact": "01818969582", "ministry": "Ministry of Chittagong Hill Tracts Affairs"}
];

function encrypt(text) {
  // Using AES with a hardcoded IV for simplicity so Dart can decrypt easily
  // In a real prod environment, use a random IV per encryption and store it.
  const key = CryptoJS.enc.Utf8.parse(SECRET_KEY);
  const iv = CryptoJS.enc.Utf8.parse('1234567890123456'); // 16 char IV
  
  const encrypted = CryptoJS.AES.encrypt(text, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7
  });
  
  return encrypted.toString();
}

async function seed() {
  const dbUser = process.env.DB_USER;
  const dbPass = process.env.DB_PASS;

  let MONGODB_URI;
  if (dbUser && dbPass && dbPass !== '<db_password>') {
    MONGODB_URI = `mongodb+srv://${dbUser}:${dbPass}@cluster0.aaunuut.mongodb.net/mUsic?appName=Cluster0`;
  } else {
    MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/';
  }

  const clientOptions = { serverApi: { version: '1', strict: true, deprecationErrors: true } };

  console.log('Attempting to connect to:', MONGODB_URI.replace(/:([^:@]+)@/, ':***@'));
  
  await mongoose.connect(MONGODB_URI, clientOptions);
  console.log('Connected to DB');
  
  await mongoose.connection.db.admin().command({ ping: 1 });
  console.log("Pinged your deployment. You successfully connected to MongoDB!");

  await PersonInfo.deleteMany({});
  console.log('Cleared existing records');

  for (const item of data) {
    const encName = encrypt(item.name);
    const encContact = encrypt(item.contact);
    const encMinistry = encrypt(item.ministry);
    
    await PersonInfo.create({
      name: encName,
      contact: encContact,
      ministry: encMinistry
    });
  }

  console.log('Successfully seeded database with encrypted data');
  
  // Verify encryption by fetching one
  const first = await PersonInfo.findOne();
  console.log('Example encrypted record in DB:', first);
  
  mongoose.disconnect();
}

seed().catch(console.error);
