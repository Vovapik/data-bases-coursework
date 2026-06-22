CREATE ROLE 'meter_reader_role';

GRANT SELECT, INSERT, UPDATE ON communalservices.Meter TO 'meter_reader_role';

GRANT SELECT ON communalservices.Apartment TO 'meter_reader_role';
GRANT SELECT ON communalservices.Client TO 'meter_reader_role';

FLUSH PRIVILEGES;

CREATE USER 'meter_reader_user'@'localhost' IDENTIFIED BY 'password';
GRANT 'meter_reader_role' TO 'meter_reader_user'@'localhost';
ALTER USER 'meter_reader_user'@'localhost' DEFAULT ROLE 'meter_reader_role';
