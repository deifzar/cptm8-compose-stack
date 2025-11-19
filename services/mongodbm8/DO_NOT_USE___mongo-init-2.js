// Read passwords from Docker secrets files
const rootPassword = cat('/run/secrets/mongodb_root_password');
const userPassword = cat('/run/secrets/mongodb_user_password');

db0 = db.getSiblingDB("admin");
db0.auth({user: process.env.MONGO_INITDB_ROOT_USERNAME, pwd: rootPassword});

db1 = db.getSiblingDB(process.env.MONGO_INITDB_DATABASE);
db1.createCollection(process.env.MONGO_INITDB_COLLECTION);
// CPT create user
db1.createUser({user: process.env.MONGO_NON_ROOT_USERNAME, pwd: userPassword, mechanisms: ["SCRAM-SHA-256"], roles: [{role: "dbOwner", db: process.env.MONGO_INITDB_DATABASE}]});
// CPT Auth
db1.auth({user: process.env.MONGO_NON_ROOT_USERNAME, pwd: userPassword});
// CPT update user
// db.updateUser(process.env.MONGO_NON_ROOT_USERNAME, { pwd: process.env.MONGO_NON_ROOT_PASSWORD, mechanisms: ["SCRAM-SHA-256"], roles: [{role: "dbOwner", db: "cptm8chat"}]});