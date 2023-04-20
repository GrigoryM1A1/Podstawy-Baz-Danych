CREATE TABLE Categories
(
    CategoryID   int          NOT NULL PRIMARY KEY IDENTITY (1, 1),
    CategoryName varchar(255) NOT NULL,
    CONSTRAINT UniqueCategoryName UNIQUE (CategoryName)
);

CREATE TABLE Dishes
(
    DishID      int          NOT NULL PRIMARY KEY IDENTITY (1, 1),
    CategoryID  int          NOT NULL FOREIGN KEY REFERENCES Categories (CategoryID),
    Name        varchar(255) NOT NULL,
    Description varchar(255)
);

CREATE TABLE MenuDate
(
    MenuDateID int  NOT NULL PRIMARY KEY IDENTITY (1, 1),
    StartDate  date NOT NULL,
    EndDate    date NOT NULL,
    Approved   bit  NOT NULL,
    CONSTRAINT ValidDate CHECK ( EndDate > StartDate )
);

CREATE TABLE Menu
(
    MenuID     int   NOT NULL PRIMARY KEY IDENTITY (1, 1),
    DishID     int   NOT NULL FOREIGN KEY REFERENCES Dishes (DishID),
    MenuDateID int   NOT NULL FOREIGN KEY REFERENCES MenuDate (MenuDateID),
    Price      money NOT NULL,
    InStock    bit   NOT NULL,
    CONSTRAINT UniqueDishDate UNIQUE (DishID, MenuDateID),
    CONSTRAINT ValidPrice CHECK ( Price > 0 )
);

CREATE TABLE Clients
(
    ClientID   int          NOT NULL PRIMARY KEY IDENTITY (1, 1),
    Email      varchar(255) NOT NULL,
    Street     varchar(255) NOT NULL,
    City       varchar(255) NOT NULL,
    PostalCode varchar(6)   NOT NULL,
    Phone      varchar(9)   NOT NULL,
    CONSTRAINT ValidEmail CHECK ( Email LIKE '%_@__%.__%'),
    CONSTRAINT UniqueEmail UNIQUE (Email),
    CONSTRAINT ValidPostalCode CHECK ( PostalCode LIKE '[0-9][0-9]-[0-9][0-9][0-9]'),
    CONSTRAINT ValidPhone CHECK ( Phone NOT LIKE '%[^0-9]%'),
    CONSTRAINT UniquePhone UNIQUE (Phone)
);

CREATE TABLE IndividualClients
(
    ClientID  int          NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES Clients (ClientID),
    FirstName varchar(255) NOT NULL,
    LastName  varchar(255) NOT NULL
);

CREATE TABLE Discounts
(
    DiscountID int         NOT NULL PRIMARY KEY IDENTITY (1, 1),
    ClientID   int         NOT NULL FOREIGN KEY REFERENCES IndividualClients (ClientID),
    StartDate  datetime,
    EndDate    datetime,
    Value      real        NOT NULL,
    Type       varchar(10) NOT NULL,
    CONSTRAINT ValidDiscountDate CHECK ( EndDate > StartDate ),
    CONSTRAINT ValidValue CHECK ( Value > 0 AND Value < 1),
    CONSTRAINT ValidType CHECK ( Type IN ('Onetime', 'Permanent'))
);

CREATE TABLE Invoices
(
    InvoiceID  int          NOT NULL PRIMARY KEY IDENTITY (1, 1),
    Date       date         NOT NULL,
    Street     varchar(255) NOT NULL,
    City       varchar(255) NOT NULL,
    PostalCode varchar(6)   NOT NULL,
    Phone      varchar(9)   NOT NULL,
    CONSTRAINT ValidPostalCodeInvoices CHECK ( PostalCode LIKE '[0-9][0-9]-[0-9][0-9][0-9]'),
    CONSTRAINT ValidPhoneInvoices CHECK ( Phone NOT LIKE '%[^0-9]%')
);

CREATE TABLE Orders
(
    OrderID    int         NOT NULL PRIMARY KEY IDENTITY (1, 1),
    ClientID   int         NOT NULL FOREIGN KEY REFERENCES Clients (ClientID),
    DiscountID int FOREIGN KEY REFERENCES Discounts (DiscountID),
    InvoiceID  int FOREIGN KEY REFERENCES Invoices (InvoiceID),
    OrderDate  datetime    NOT NULL,
    Takeaway   bit         NOT NULL,
    Status     varchar(10) NOT NULL,
    CONSTRAINT ValidStatus CHECK (Status IN ('Pending', 'Approved', 'Rejected', 'Finished', 'Deleted'))
);

CREATE TABLE OrderDetails
(
    OrderID  int NOT NULL FOREIGN KEY REFERENCES Orders (OrderID),
    MenuID   int NOT NULL FOREIGN KEY REFERENCES Menu (MenuID),
    Quantity int NOT NULL,
    CONSTRAINT OrderDetails_PK PRIMARY KEY (OrderID, MenuID),
    CONSTRAINT ValidQuantity CHECK (Quantity > 0)
);

CREATE TABLE Payments
(
    PaymentID int      NOT NULL PRIMARY KEY IDENTITY (1, 1),
    OrderID   int      NOT NULL FOREIGN KEY REFERENCES Orders (OrderID),
    Value     money    NOT NULL,
    Date      datetime NOT NULL
);

CREATE TABLE Companies
(
    CompanyID   int          NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES Clients (ClientID),
    CompanyName varchar(255) NOT NULL,
    NIP         varchar(10),
    CONSTRAINT ValidNIP CHECK ( NIP NOT LIKE '%[^0-9]%')
);

CREATE TABLE Employees
(
    EmployeeID int          NOT NULL PRIMARY KEY IDENTITY (1, 1),
    CompanyID  int          NOT NULL FOREIGN KEY REFERENCES Companies (CompanyID),
    FirstName  varchar(255) NOT NULL,
    LastName   varchar(255) NOT NULL
);

CREATE TABLE Reservations
(
    ReservationID   int      NOT NULL PRIMARY KEY IDENTITY (1, 1),
    OrderID         int      NOT NULL FOREIGN KEY REFERENCES Orders (OrderID),
    NumberOfPeople int      NOT NULL,
    StartDate       datetime NOT NULL,
    EndDate         datetime NOT NULL,
    CONSTRAINT ValidReservationDate CHECK ( EndDate > StartDate ),
    CONSTRAINT ValidNumberOfPersons CHECK ( NumberOfPeople >= 2 )
);

CREATE TABLE Tables
(
    TableID int NOT NULL PRIMARY KEY IDENTITY (1, 1),
    Size    int NOT NULL
);

CREATE TABLE ReservationTables
(
    ReservationTablesID int NOT NULL PRIMARY KEY IDENTITY (1, 1),
    ReservationID       int NOT NULL FOREIGN KEY REFERENCES Reservations (ReservationID),
    TableID             int NOT NULL FOREIGN KEY REFERENCES Tables (TableID)
);

CREATE TABLE ReservationEmployees
(
    ReservationID      int NOT NULL FOREIGN KEY REFERENCES Reservations (ReservationID),
    EmployeeID         int NOT NULL FOREIGN KEY REFERENCES Employees (EmployeeID),
    ReservationTableID int FOREIGN KEY REFERENCES ReservationTables (ReservationTablesID),
    CONSTRAINT ReservationEmployees_PK PRIMARY KEY (ReservationID, EmployeeID)
);

CREATE TABLE Constants
(
    Name        varchar(8) NOT NULL PRIMARY KEY,
    Value       int        NOT NULL,
    Description varchar(255)
);
