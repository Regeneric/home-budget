db.createUser({ 
    user: 'admin',
    pwd: 'luckybell19',
    roles: [{role: 'root', db: 'admin'}]
});