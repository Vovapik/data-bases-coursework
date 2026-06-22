CREATE ROLE database_admin;
GRANT ALL PRIVILEGES ON communalservices.* TO database_admin;


CREATE USER 'database_admin_user'@'localhost' IDENTIFIED BY 'password';
GRANT 'database_admin' TO 'database_admin_user'@'localhost';
ALTER USER 'database_admin_user'@'localhost' DEFAULT ROLE 'database_admin';
