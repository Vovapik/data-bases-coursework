-- Communal Services DB — Triggers

-- 1. MarkComplaintInProcess
-- Changes a complaint's status from 'Unread' to 'In process' when an administrator sends a notification to the corresponding client.
CREATE DEFINER = root@localhost TRIGGER MarkComplaintInProcess
AFTER INSERT ON Notification
FOR EACH ROW
BEGIN
    UPDATE Complaint
    SET Status = 'In process'
    WHERE ClientID = NEW.ClientID
      AND Status = 'Unread';
END;


-- 2. BeforeMeterInsert
-- Before inserting a new meter record, checks that the current reading is not less than the previous reading.
-- Implements business rule: "Current reading must be greater than the previous reading."
CREATE DEFINER = root@localhost TRIGGER BeforeMeterInsert
BEFORE INSERT ON Meter
FOR EACH ROW
BEGIN
    IF NEW.CurrentReading < NEW.PreviousReading THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CurrentReading cannot be less than PreviousReading.';
    END IF;
END;


-- 3. BeforeMeterUpdate
-- Before updating a meter record, checks that the current reading is not less than the previous reading.
-- Implements business rule: "Current reading must be greater than the previous reading."
CREATE DEFINER = root@localhost TRIGGER BeforeMeterUpdate
BEFORE UPDATE ON Meter
FOR EACH ROW
BEGIN
    IF NEW.CurrentReading < NEW.PreviousReading THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'CurrentReading cannot be less than PreviousReading.';
    END IF;
END;


-- 4. UpdatePreviousMeterReading
-- Writes the current reading into the previous reading field whenever a new reading value is entered for a meter.
CREATE DEFINER = root@localhost TRIGGER UpdatePreviousMeterReading
BEFORE UPDATE ON Meter
FOR EACH ROW
BEGIN
    SET NEW.PreviousReading = OLD.CurrentReading;
END;


-- 5. ValidateDiscountDates
-- Checks that a discount's end date is later than its start date.
-- Implements the corresponding business rule.
CREATE DEFINER = root@localhost TRIGGER ValidateDiscountDates
BEFORE INSERT ON Discount
FOR EACH ROW
BEGIN
    IF NEW.EndDate <= NEW.StartDate THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'EndDate must be later than StartDate';
    END IF;
END;


-- 6. NotifyOverdueInvoice
-- Creates a notification about the need for payment when an invoice's status changes to 'Overdue'.
CREATE DEFINER = root@localhost TRIGGER NotifyOverdueInvoice
AFTER UPDATE ON Invoice
FOR EACH ROW
BEGIN
    IF NEW.Status = 'Overdue' AND OLD.Status != 'Overdue' THEN
        INSERT INTO Notification (Message, NotificationDate, AdminID, ClientID)
        VALUES (
            CONCAT('Your invoice #', NEW.InvoiceID, ' is overdue. Please pay as soon as possible.'),
            CURDATE(),
            (SELECT AdminID FROM Administrator LIMIT 1),
            (SELECT ClientID
             FROM Apartment a
             JOIN Meter m ON a.ApartmentID = m.ApartmentID
             WHERE m.MeterID = NEW.MeterID)
        );
    END IF;
END;


-- 7. ApplyDiscountToInvoice
-- Applies the currently active discount to an invoice when it is created.
CREATE DEFINER = root@localhost TRIGGER ApplyDiscountToInvoice
BEFORE INSERT ON Invoice
FOR EACH ROW
BEGIN
    DECLARE discount_percentage DECIMAL(4, 2);

    SELECT Percentage
    INTO discount_percentage
    FROM Discount
    WHERE ServiceID = NEW.ServiceID
      AND CURDATE() BETWEEN StartDate AND EndDate
    LIMIT 1;

    IF discount_percentage IS NOT NULL THEN
        SET NEW.TotalAmount = NEW.TotalAmount * (1 - discount_percentage / 100);
    END IF;
END;


-- 8. ValidateApartmentArea
-- Checks that the apartment area is greater than 0.
-- Implements the corresponding business rule.
CREATE DEFINER = root@localhost TRIGGER ValidateApartmentArea
BEFORE INSERT ON Apartment
FOR EACH ROW
BEGIN
    IF NEW.Area <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Apartment area must be greater than 0.';
    END IF;
END;


-- 9. ValidateRegistrationDate
-- Checks that a client's registration date is not set in the future.
CREATE DEFINER = root@localhost TRIGGER ValidateRegistrationDate
BEFORE INSERT ON Client
FOR EACH ROW
BEGIN
    IF NEW.RegistrationDate > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Registration date cannot be in the future.';
    END IF;
END;
