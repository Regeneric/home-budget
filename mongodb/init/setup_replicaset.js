rs.initiate({
    _id: "mongoreplicaset1",
    version: 1,
    members: [{ _id: 0, host : "mongo-mongo1.hkk.internal:27017"}]
});