CREATE ROLE 'client_role';

GRANT SELECT ON communalservices.Client TO 'client_role';
GRANT SELECT ON communalservices.Apartment TO 'client_role';
GRANT SELECT ON communalservices.Invoice TO 'client_role';
GRANT SELECT ON communalservices.Payment TO 'client_role';

GRANT SELECT, INSERT ON communalservices.Complaint TO 'client_role';

GRANT SELECT ON communalservices.Notification TO 'client_role';

FLUSH PRIVILEGES;

CREATE USER 'client_user'@'localhost' IDENTIFIED BY 'password';
GRANT 'client_role' TO 'client_user'@'localhost';
ALTER USER 'client_user'@'localhost' DEFAULT ROLE 'client_role';
