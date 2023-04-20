CREATE UNIQUE INDEX CategoriesIndex
    ON Categories (CategoryID)

CREATE UNIQUE INDEX DishesIndex
    ON Dishes (DishID)

CREATE UNIQUE INDEX MenuDateIndex
    ON MenuDate (MenuDateID)

CREATE UNIQUE INDEX MenuIndex
    ON Menu (MenuID)

CREATE UNIQUE INDEX ClientsIndex
    ON Clients (ClientID)

CREATE UNIQUE INDEX IndividualClientsIndex
    ON IndividualClients (ClientID)

CREATE UNIQUE INDEX DiscountsIndex
    ON Discounts (DiscountID)

CREATE UNIQUE INDEX InvoicesIndex
    ON Invoices (InvoiceID)

CREATE UNIQUE INDEX OrdersIndex
    ON Orders (OrderID)

CREATE UNIQUE INDEX OrderDetailsIndex
    ON OrderDetails (OrderID, MenuID)

CREATE UNIQUE INDEX PaymentsIndex
    ON Payments (PaymentID)

CREATE UNIQUE INDEX CompaniesIndex
    ON Companies (CompanyID)

CREATE UNIQUE INDEX EmployeesIndex
    ON Employees (EmployeeID)

CREATE UNIQUE INDEX ReservationsIndex
    ON Reservations (ReservationID)

CREATE UNIQUE INDEX TablesIndex
    ON Tables (TableID)

CREATE UNIQUE INDEX ReservationsTablesIndex
    ON ReservationTables (ReservationTablesID)

CREATE UNIQUE INDEX ReservationEmployeesIndex
    ON ReservationEmployees (ReservationID, EmployeeID)

CREATE UNIQUE INDEX ConstantsIndex
    ON Constants (Name)


CREATE NONCLUSTERED INDEX StatusIndex
    on Orders (Status)

CREATE NONCLUSTERED INDEX MenuStartDateIndex
    on MenuDate (StartDate)

CREATE NONCLUSTERED INDEX MenuEndDateIndex
    on MenuDate (EndDate)

CREATE NONCLUSTERED INDEX OrderDateIndex
    on Orders (OrderDate)
