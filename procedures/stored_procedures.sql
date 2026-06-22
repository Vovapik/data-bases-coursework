-- Communal Services DB — Stored Procedures & Functions

-- 1. GetClientDebt(client_id INT)
-- Returns the total debt of a client across all overdue invoices.
CREATE DEFINER = root@localhost FUNCTION GetClientDebt(client_id INT)
RETURNS DECIMAL(10, 2) DETERMINISTIC
BEGIN
    DECLARE total_debt DECIMAL(10, 2);

    SELECT SUM(i.TotalAmount)
    INTO total_debt
    FROM Invoice i
    JOIN Meter m ON i.MeterID = m.MeterID
    JOIN Apartment a ON m.ApartmentID = a.ApartmentID
    WHERE a.ClientID = client_id AND i.Status = 'Overdue';

    RETURN IFNULL(total_debt, 0.00);
END;


-- 2. ChangeComplaintStatus(complaint_id INT, new_status VARCHAR(50))
-- Updates the status of a client complaint and returns a confirmation message.
CREATE DEFINER = root@localhost FUNCTION ChangeComplaintStatus(complaint_id INT, new_status VARCHAR(50))
RETURNS VARCHAR(255) DETERMINISTIC
BEGIN
    DECLARE current_status VARCHAR(50);

    SELECT Status
    INTO current_status
    FROM Complaint
    WHERE ComplaintID = complaint_id;

    UPDATE Complaint
    SET Status = new_status
    WHERE ComplaintID = complaint_id;

    RETURN CONCAT('Complaint status updated to "', new_status, '".');
END;


-- 3. GetActiveDiscount(service_id INT)
-- Returns the active discount percentage for a given service, if any.
CREATE DEFINER = root@localhost FUNCTION GetActiveDiscount(service_id INT)
RETURNS DECIMAL(4, 2) DETERMINISTIC
BEGIN
    DECLARE discount_percentage DECIMAL(4, 2);

    SELECT Percentage
    INTO discount_percentage
    FROM Discount
    WHERE ServiceID = service_id
      AND CURRENT_DATE BETWEEN StartDate AND IFNULL(EndDate, CURRENT_DATE);

    RETURN IFNULL(discount_percentage, 0.00);
END;


-- 4. SendNotification(client_id INT, admin_id INT, message TEXT)
-- Inserts a new notification record for a given client from an admin.
CREATE DEFINER = root@localhost PROCEDURE SendNotification(
    IN client_id INT,
    IN admin_id  INT,
    IN message   TEXT
)
BEGIN
    INSERT INTO Notification (Message, NotificationDate, AdminID, ClientID)
    VALUES (message, CURRENT_DATE, admin_id, client_id);
END;


-- 5. ProcessPayment(invoice_id INT, payment_method VARCHAR(50))
-- Creates a payment record and marks the invoice as 'Paid'.
CREATE DEFINER = root@localhost PROCEDURE ProcessPayment(
    IN invoice_id     INT,
    IN payment_method VARCHAR(50)
)
BEGIN
    DECLARE total_amount DECIMAL(10, 2);

    SELECT TotalAmount INTO total_amount
    FROM Invoice
    WHERE InvoiceID = invoice_id;

    INSERT INTO Payment (PaymentDate, Amount, PaymentMethod, InvoiceID)
    VALUES (CURRENT_DATE, total_amount, payment_method, invoice_id);

    UPDATE Invoice
    SET Status = 'Paid'
    WHERE InvoiceID = invoice_id;
END;


-- 6. CalculateCashbackForClient(client_id INT, OUT cashback_amount DECIMAL(10,2))
-- Calculates cashback for a client based on their privilege and total payments made in the current year.
-- Implements business rule: privilege/discount application.
CREATE DEFINER = root@localhost PROCEDURE CalculateCashbackForClient(
    IN  client_id       INT,
    OUT cashback_amount DECIMAL(10, 2)
)
BEGIN
    DECLARE total_payments      DECIMAL(10, 2);
    DECLARE privilege_percentage DECIMAL(4, 2);
    DECLARE privilege_id        INT;

    SELECT PrivilegeID INTO privilege_id
    FROM Client
    WHERE ClientID = client_id
    LIMIT 1;

    IF privilege_id IS NOT NULL THEN
        SELECT Percentage INTO privilege_percentage
        FROM Privilege
        WHERE PrivilegeID = privilege_id
        LIMIT 1;

        SELECT SUM(Payment.Amount) INTO total_payments
        FROM Payment
        INNER JOIN Invoice   ON Payment.InvoiceID   = Invoice.InvoiceID
        INNER JOIN Meter     ON Invoice.MeterID      = Meter.MeterID
        INNER JOIN Apartment ON Meter.ApartmentID    = Apartment.ApartmentID
        WHERE Apartment.ClientID = client_id
          AND YEAR(Payment.PaymentDate) = YEAR(CURRENT_DATE);

        IF total_payments IS NOT NULL THEN
            SET cashback_amount = total_payments * (privilege_percentage / 100);
        ELSE
            SET cashback_amount = 0;
        END IF;
    ELSE
        SET cashback_amount = 0;
    END IF;
END;


-- 7. ApplyDiscountToInvoice(invoice_id INT)
-- Applies a specific discount (DiscountID = 4) to an invoice if the invoice's service matches the discount's target service.
CREATE DEFINER = root@localhost PROCEDURE ApplyDiscountToInvoice(IN invoice_id INT)
BEGIN
    DECLARE discount_percentage  DECIMAL(4, 2);
    DECLARE total_amount         DECIMAL(10, 2);
    DECLARE new_total_amount     DECIMAL(10, 2);
    DECLARE service_id           INT;
    DECLARE discount_service_id  INT;

    SELECT ServiceID INTO service_id
    FROM Invoice
    WHERE InvoiceID = invoice_id;

    SELECT Percentage, ServiceID INTO discount_percentage, discount_service_id
    FROM Discount
    WHERE DiscountID = 4;

    IF service_id = discount_service_id THEN
        SELECT TotalAmount INTO total_amount
        FROM Invoice
        WHERE InvoiceID = invoice_id;

        SET new_total_amount = total_amount - (total_amount * discount_percentage / 100);

        UPDATE Invoice
        SET TotalAmount = new_total_amount
        WHERE InvoiceID = invoice_id;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Discount is not applicable for this service.';
    END IF;
END;


-- 8. UpdateInvoiceStatusForOverdue()
-- Sets status to 'Overdue' for all unpaid invoices past their due date.
CREATE DEFINER = root@localhost PROCEDURE UpdateInvoiceStatusForOverdue()
BEGIN
    UPDATE Invoice
    SET Status = 'Overdue'
    WHERE Status = 'Not paid' AND DueDate < CURRENT_DATE;
END;


-- 9. GetMonthlyPaymentReport(report_month INT)
-- Generates a temporary table with per-client payment totals and counts for a given month, then returns the result.
-- Implements business rule: consumer data reporting.
CREATE DEFINER = root@localhost PROCEDURE GetMonthlyPaymentReport(IN report_month INT)
BEGIN
    CREATE TEMPORARY TABLE TempPaymentReport AS
    SELECT c.ClientID,
           c.FullName,
           SUM(p.Amount)    AS TotalPaid,
           COUNT(p.PaymentID) AS PaymentCount
    FROM Payment p
    INNER JOIN Invoice   i ON p.InvoiceID   = i.InvoiceID
    INNER JOIN Meter     m ON i.MeterID      = m.MeterID
    INNER JOIN Apartment a ON m.ApartmentID  = a.ApartmentID
    INNER JOIN Client    c ON a.ClientID     = c.ClientID
    WHERE MONTH(p.PaymentDate) = report_month
    GROUP BY c.ClientID, c.FullName;

    SELECT * FROM TempPaymentReport;

    DROP TEMPORARY TABLE TempPaymentReport;
END;


-- 10. GetTotalPaymentsForClient(client_id INT)
-- Returns the all-time total amount paid by a client.
-- Implements business rule: automation & consumer data.
CREATE DEFINER = root@localhost FUNCTION GetTotalPaymentsForClient(client_id INT)
RETURNS DECIMAL(10, 2) DETERMINISTIC
BEGIN
    DECLARE total_payments DECIMAL(10, 2);

    SELECT SUM(p.Amount)
    INTO total_payments
    FROM Payment p
    INNER JOIN Invoice   i ON p.InvoiceID  = i.InvoiceID
    INNER JOIN Meter     m ON i.MeterID     = m.MeterID
    INNER JOIN Apartment a ON m.ApartmentID = a.ApartmentID
    WHERE a.ClientID = client_id;

    RETURN IFNULL(total_payments, 0.00);
END;


-- 11. GetAveragePaymentForClientsInCurrentYear()
-- Returns the average payment amount across all clients for the current calendar year.
-- Implements business rule: automation & consumer data.
CREATE DEFINER = root@localhost FUNCTION GetAveragePaymentForClientsInCurrentYear()
RETURNS DECIMAL(10, 2) DETERMINISTIC
BEGIN
    DECLARE average_payment DECIMAL(10, 2);

    SELECT AVG(p.Amount)
    INTO average_payment
    FROM Payment p
    INNER JOIN Invoice   i ON p.InvoiceID  = i.InvoiceID
    INNER JOIN Meter     m ON i.MeterID     = m.MeterID
    INNER JOIN Apartment a ON m.ApartmentID = a.ApartmentID
    WHERE YEAR(p.PaymentDate) = YEAR(CURRENT_DATE);

    RETURN IFNULL(average_payment, 0.00);
END;
