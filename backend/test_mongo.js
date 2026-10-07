const { MongoClient, ServerApiVersion } = require('mongodb');
require('dotenv').config();

const uri = `mongodb+srv://${process.env.DB_USER}:${process.env.DB_PASS}@cluster0.aaunuut.mongodb.net/?appName=Cluster0`;

const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

async function run() {
  try {
    await client.connect();
    await client.db("admin").command({ ping: 1 });
    console.log("Pinged your deployment. You successfully connected to MongoDB!");
    
    // List databases
    const adminDb = client.db('admin');
    const dbList = await adminDb.admin().listDatabases();
    console.log("Databases in your cluster:");
    dbList.databases.forEach(db => console.log(` - ${db.name}`));

    // List collections in 'test' and 'msic_db'
    const testDb = client.db('test');
    const testCols = await testDb.listCollections().toArray();
    console.log("Collections in 'test':", testCols.map(c => c.name));

    const msicDb = client.db('msic_db');
    const msicCols = await msicDb.listCollections().toArray();
    console.log("Collections in 'msic_db':", msicCols.map(c => c.name));

  } catch(e) {
    console.error("Connection failed:", e);
  } finally {
    await client.close();
  }
}
run().catch(console.dir);
