-- Communal Services DB — Views

-- 1. ActiveClients
-- Displays information about clients and their privileges.
CREATE DEFINER = root@localhost VIEW ActiveClients AS
SELECT
    c.ClientID,
    c.FullName,
    c.Email,
    p.PrivilegeType,
    p.Percentage AS PrivilegePercentage
FROM
    Client c
LEFT JOIN
    Privilege p ON c.PrivilegeID = p.PrivilegeID;


-- 2. UnpaidInvoices
-- Shows invoices that are unpaid but not yet overdue.
CREATE DEFINER = root@localhost VIEW UnpaidInvoices AS
SELECT
    i.InvoiceID,
    i.InvoiceDate,
    i.DueDate,
    i.TotalAmount,
    c.FullName AS ClientName,
    a.Address AS ApartmentAddress
FROM
    Invoice i
JOIN
    Meter m ON i.MeterID = m.MeterID
JOIN
    Apartment a ON m.ApartmentID = a.ApartmentID
JOIN
    Client c ON a.ClientID = c.ClientID
WHERE
    i.Status = 'Not paid';


-- 3. ClientInvoices
-- Displays information about all client invoices, including the client's name and apartment address.
CREATE DEFINER = root@localhost VIEW ClientInvoices AS
SELECT
    i.InvoiceID,
    i.InvoiceDate,
    i.DueDate,
    i.TotalAmount,
    c.FullName AS ClientName,
    a.Address AS ApartmentAddress
FROM
    communalservices.Invoice i
JOIN
    communalservices.Meter m ON i.MeterID = m.MeterID
JOIN
    communalservices.Apartment a ON m.ApartmentID = a.ApartmentID
JOIN
    communalservices.Client c ON a.ClientID = c.ClientID;


-- 4. DetailedClientOverview
-- Contains detailed information about clients, their apartments, meters, invoices, privileges, and discounts applicable to invoices.
CREATE DEFINER = root@localhost VIEW DetailedClientOverview AS
SELECT
    c.ClientID,
    c.FullName            AS ClientName,
    c.Email                AS ClientEmail,
    c.Address               AS RegistrationAddress,
    a.ApartmentID,
    a.Address               AS ApartmentAddress,
    a.Area                  AS ApartmentArea,
    a.ApartmentType,
    m.MeterID,
    m.MeterType,
    m.CurrentReading        AS LatestReading,
    m.ReadingDate           AS LatestReadingDate,
    i.InvoiceID,
    i.InvoiceDate,
    i.DueDate,
    i.TotalAmount,
    i.Status                AS InvoiceStatus,
    p.PrivilegeType,
    p.Percentage            AS PrivilegePercentage,
    d.DiscountName,
    d.Percentage            AS DiscountPercentage
FROM
    Client c
LEFT JOIN
    Apartment a ON c.ClientID = a.ClientID
LEFT JOIN
    Meter m ON a.ApartmentID = m.ApartmentID
LEFT JOIN
    Invoice i ON m.MeterID = i.MeterID
LEFT JOIN
    Privilege p ON c.PrivilegeID = p.PrivilegeID
LEFT JOIN
    Discount d ON i.ServiceID = d.ServiceID
    AND (i.InvoiceDate BETWEEN d.StartDate AND d.EndDate);
