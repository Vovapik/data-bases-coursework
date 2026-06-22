CREATE ROLE 'technical_support_role';

GRANT SELECT ON communalservices.Complaint TO 'technical_support_role';

GRANT SELECT, INSERT ON communalservices.Notification TO 'technical_support_role';

GRANT SELECT ON communalservices.Client TO 'technical_support_role';
GRANT SELECT ON communalservices.Apartment TO 'technical_support_role';

FLUSH PRIVILEGES;

CREATE USER 'technical_support_user'@'localhost' IDENTIFIED BY 'password';
GRANT 'technical_support_role' TO 'technical_support_user'@'localhost';
ALTER USER 'technical_support_user'@'localhost' DEFAULT ROLE 'technical_support_role';
