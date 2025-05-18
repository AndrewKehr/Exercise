import { MongoClient } from 'mongodb';

const uri = process.env.MONGO_URI;
console.log("MONGO_URI value:", uri);

if (!uri) {
  console.error("MONGO_URI not set");
  process.exit(1);
}

const client = new MongoClient(uri);

async function connectToMongo() {
    try {
      await client.connect();
      console.log("Successfully connected to Mongo");
  
      const dbs = await client.db().admin().listDatabases();
      console.log("Databases:", dbs.databases.map(db => db.name));
    } catch (err) {
      console.error("Failed to connect to Mongo:", err.message || err);
      // Add a short delay before exiting to let logs flush
      await new Promise((res) => setTimeout(res, 500));
      process.exit(1);
    } finally {
      await client.close();
      console.log("Connection closed");
    }
  }
  

connectToMongo();

setInterval(() => {}, 1000 * 60 * 60);