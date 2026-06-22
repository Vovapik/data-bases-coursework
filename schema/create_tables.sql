CREATE DATABASE CommunalServices;
USE comnunalservices;
CREATE TABLE Privilege (
    PrivilegeID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    PrivilegeType VARCHAR(50) NOT NULL,
    Percentage DECIMAL(4,2) NOT NULL,
    Description TEXT
);

CREATE TABLE Service (
    ServiceID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    ServiceName VARCHAR(100) NOT NULL,
    Description TEXT,
    Tariff DECIMAL(10,2) NOT NULL,
    Unit VARCHAR(50) NOT NULL
);

CREATE TABLE Administrator (
    AdminID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(15),
    Password VARCHAR(255) NOT NULL
);

CREATE TABLE Client (
    ClientID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Address VARCHAR(200) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    PhoneNumber VARCHAR(15),
    Password VARCHAR(255) NOT NULL,
    RegistrationDate DATE NOT NULL,
    PrivilegeID INT,
    FOREIGN KEY (PrivilegeID) REFERENCES Privilege(PrivilegeID)
);

CREATE TABLE Discount (
    DiscountID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    DiscountName VARCHAR(100) NOT NULL,
    Percentage DECIMAL(4,2) NOT NULL,
    StartDate DATE,
    EndDate DATE,
    ServiceID INT,
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
);

CREATE TABLE Apartment (
    ApartmentID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    Address VARCHAR(200) NOT NULL,
    Area DECIMAL(10,2) NOT NULL,
    ApartmentType VARCHAR(50) NOT NULL,
    ClientID INT NOT NULL,
    FOREIGN KEY (ClientID) REFERENCES Client(ClientID)
);

CREATE TABLE Meter (
    MeterID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    MeterType VARCHAR(50) NOT NULL,
    CurrentReading DECIMAL(10,2) NOT NULL,
    PreviousReading DECIMAL(10,2),
    ReadingDate DATE NOT NULL,
    ApartmentID INT NOT NULL,
    FOREIGN KEY (ApartmentID) REFERENCES Apartment(ApartmentID)
);

CREATE TABLE Invoice (
    InvoiceID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    InvoiceDate DATE NOT NULL,
    DueDate DATE NOT NULL,
    TotalAmount DECIMAL(10,2) NOT NULL,
    Status VARCHAR(50) NOT NULL,
    MeterID INT NOT NULL,
    ServiceID INT NOT NULL,
    FOREIGN KEY (MeterID) REFERENCES Meter(MeterID),
    FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)
);

CREATE TABLE Payment (
    PaymentID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    PaymentDate DATE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod VARCHAR(50) NOT NULL,
    InvoiceID INT NOT NULL,
    FOREIGN KEY (InvoiceID) REFERENCES Invoice(InvoiceID)
);

CREATE TABLE Complaint (
    ComplaintID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    ComplaintDate DATE NOT NULL,
    Description TEXT NOT NULL,
    Status VARCHAR(50) NOT NULL,
    ClientID INT NOT NULL,
    FOREIGN KEY (ClientID) REFERENCES Client(ClientID)
);

CREATE TABLE Notification (
    NotificationID INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    Message TEXT,
    NotificationDate DATE NOT NULL,
    AdminID INT,
    ClientID INT NOT NULL,
    FOREIGN KEY (AdminID) REFERENCES Administrator(AdminID),
    FOREIGN KEY (ClientID) REFERENCES Client(ClientID)
);
