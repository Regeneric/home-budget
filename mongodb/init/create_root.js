db.createUser({
    user: "root",
    pwd: "luckybell19",
    roles: [{role: "remote_role", db: "admin"}],
});