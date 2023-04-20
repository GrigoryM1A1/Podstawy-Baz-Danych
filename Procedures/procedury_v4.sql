CREATE PROCEDURE AddDishCategory @CategoryName varchar(255) AS
BEGIN
    BEGIN TRY

        IF EXISTS(SELECT CategoryID FROM Categories WHERE CategoryName = @CategoryName)
            THROW 52000, N'Podana nazwa kategorii już istnieje.', 1

        INSERT INTO Categories (CategoryName)
        VALUES (@CategoryName)
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania kategorii: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

-- CREATE PROCEDURE ModifyCategoryName

CREATE PROCEDURE AddDish @CategoryID int, @DishName varchar(255), @Description varchar(255) = NULL AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT CategoryID FROM Categories WHERE CategoryID = @CategoryID)
            THROW 52000, N'Podano nieprawidłową kategorię.', 1

        IF EXISTS(SELECT DishID FROM Dishes WHERE Name = @DishName)
            THROW 52000, N'Podane dane już jest w bazie.', 1

        INSERT INTO Dishes (CategoryID, Name, Description)
        VALUES (@CategoryID, @DishName, @Description);
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania dania: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE ModifyDishDescription @DishID int, @NewDescription varchar(255) AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT DishID FROM Dishes WHERE DishID = @DishID)
            THROW 52000, N'Podano nieprawidłowe danie.', 1

        UPDATE Dishes SET Description = @NewDescription WHERE DishID = @DishID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd modyfikacji opisu dania: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE AddMenuPeriod @EndDate Date AS
BEGIN
    BEGIN TRY

        IF EXISTS(SELECT MenuDateID FROM MenuDate WHERE (EndDate >= @EndDate))
            THROW 52000, N'Podano nieprawidłową datę.', 1

        DECLARE @StartDate date
        SELECT @StartDate = DATEADD(day, 1, MAX(EndDate))
        FROM MenuDate

        IF DATEDIFF(day, @EndDate, @StartDate) >= 14
            THROW 52000, N'Podano nieprawidłową datę. Okres czasu byłby dłuższy niż 2 tygodnie.', 1

        INSERT INTO MenuDate (StartDate, EndDate, Approved)
        VALUES (@StartDate, @EndDate, 0);
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania okresu: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE ApproveMenuPeriod @MenuDateID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT MenuDateID FROM MenuDate WHERE MenuDateID = @MenuDateID)
            THROW 52000, N'Podano nieprawidłowy okres czasu.', 1

        IF (SELECT dbo.udfIsMenuAllowed(@MenuDateID)) = 0
            THROW 52000, N'Menu nie spełnia warunków.', 1

        UPDATE MenuDate SET Approved = 1 WHERE MenuDateID = @MenuDateID
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd zatwierdzenia menu: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddDishToMenu @DishID int, @MenuDateID int, @Price money AS
BEGIN
    BEGIN TRY

        IF @Price <= 0
            THROW 52000, N'Podano niedodatnią cenę.', 1

        IF NOT EXISTS(SELECT DishID FROM Dishes WHERE DishID = @DishID)
            THROW 52000, N'Podano nieprawidłowe danie.', 1

        IF NOT EXISTS(SELECT MenuDateID FROM MenuDate WHERE MenuDateID = @MenuDateID)
            THROW 52000, N'Podano nieprawidłowy okres czasu.', 1

        IF (SELECT Approved FROM MenuDate WHERE MenuDateID = @MenuDateID) = 1
            THROW 52000, N'Menu na podany okres czasu zostało już zatwierdzone.', 1

        IF EXISTS(SELECT MenuID FROM Menu WHERE DishID = @DishID AND MenuDateID = @MenuDateID)
            THROW 52000, N'Podane dane już jest w menu na ten okres czasu.', 1

        IF dbo.udfCanSeafoodBeAddedToMenu(@MenuDateID) = 0 AND EXISTS(SELECT CategoryName
                                                                      FROM Dishes
                                                                               JOIN Categories C on C.CategoryID = Dishes.CategoryID
                                                                      WHERE CategoryName LIKE 'Owoce morza'
                                                                        AND DishID = @DishID)
            THROW 52000, N'Do menu na ten okres czasu nie można dodać dania z owocami morza.', 1
        INSERT INTO Menu (DishID, MenuDateID, Price, InStock)
        VALUES (@DishID, @MenuDateID, @Price, 1);
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania dania do menu na dany okres: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE DeleteDishFromMenu @MenuID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT MenuID FROM Menu WHERE MenuID = @MenuID)
            THROW 52000, N'Nie ma takiego dania w menu.', 1

        UPDATE Menu SET InStock = 0 WHERE MenuID = @MenuID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd usuwania dania z menu na dany okres: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE AddIndividualClient @Email varchar(255), @Street varchar(255), @City varchar(255),
                                     @PostalCode varchar(6), @Phone varchar(6), @FirstName varchar(255),
                                     @LastName varchar(255) AS
BEGIN
    BEGIN TRY

        INSERT INTO Clients (Email, Street, City, PostalCode, Phone)
        VALUES (@Email, @Street, @City, @PostalCode, @Phone);

        INSERT INTO IndividualClients (ClientID, FirstName, LastName)
        VALUES (@@IDENTITY, @FirstName, @LastName)
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania nowego klienta indywidualnego: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddCompanyClient @Email varchar(255), @Street varchar(255), @City varchar(255),
                                  @PostalCode varchar(6), @Phone varchar(6), @CompanyName varchar(255),
                                  @NIP varchar(10) AS
BEGIN
    BEGIN TRY

        INSERT INTO Clients (Email, Street, City, PostalCode, Phone)
        VALUES (@Email, @Street, @City, @PostalCode, @Phone);

        INSERT INTO Companies (CompanyID, CompanyName, NIP) VALUES (@@IDENTITY, @CompanyName, @NIP)
    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania nowego klienta firmowego: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddEmployee @CompanyID varchar(255), @FirstName varchar(255), @LastName varchar(255) AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT CompanyID FROM Companies WHERE CompanyID = @CompanyID)
            THROW 52000, N'Podano nieprawidłowy numer firmy.', 1

        INSERT INTO Employees (CompanyID, FirstName, LastName)
        VALUES (@CompanyID, @FirstName, @LastName)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania pracownika: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

-- CREATE PROCEDURE ModifyClientDetails
CREATE PROCEDURE AddInvoice @OrderID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID AND Status IN ('Finished'))
            THROW 52000, N'Podano nieprawidłowe zamówienie.', 1

        IF (SELECT InvoiceID FROM Orders WHERE OrderID = @OrderID) IS NOT NULL
            THROW 52000, N'Podane zamówienie jest już przypisane do faktury.', 1

        DECLARE @ClientID int
        SELECT @ClientID = ClientID
        FROM Orders
        WHERE OrderID = @OrderID

        DECLARE @Street varchar(255)
        DECLARE @City varchar(255)
        DECLARE @PostalCode varchar(6)
        DECLARE @Phone varchar(9)

        SELECT @Street = Street, @City = City, @PostalCode = PostalCode, @Phone = Phone
        FROM Clients
        WHERE ClientID = @ClientID


        INSERT INTO Invoices (Date, Street, City, PostalCode, Phone)
        VALUES (getdate(), @Street, @City, @PostalCode, @Phone)

        UPDATE Orders SET InvoiceID = @@IDENTITY WHERE OrderID = @OrderID

        RETURN @@IDENTITY

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd utworzenia faktury: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddOrderToInvoice @OrderID int, @InvoiceID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID AND Status IN ('Finished'))
            THROW 52000, N'Podano nieprawidłowe zamówienie.', 1

        IF (SELECT InvoiceID FROM Orders WHERE OrderID = @OrderID) IS NOT NULL
            THROW 52000, N'Podane zamówienie jest już przypisane do faktury.', 1

        IF NOT EXISTS(SELECT InvoiceID FROM Invoices WHERE InvoiceID = @InvoiceID)
            THROW 52000, N'Podano nieprawidłową fakturę.', 1

        IF NOT EXISTS(SELECT (SELECT max(ClientID) FROM Orders WHERE InvoiceID = @InvoiceID)
                      INTERSECT
                      (SELECT ClientID FROM Orders WHERE OrderID = @OrderID))
            THROW 52000, N'Podana faktura dotyczy innego klienta niż podane zamówienie', 1

        UPDATE Orders SET InvoiceID = @InvoiceID WHERE OrderID = @OrderID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania zamówienia do faktury: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE CreateInvoiceFromDateToDate @ClientID int, @StartDate datetime, @EndDate datetime AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT ClientID FROM Clients WHERE ClientID = @ClientID)
            THROW 52000, N'Podano nieprawidłowy numer klienta.', 1

        IF NOT EXISTS(SELECT OrderID
                      FROM Orders
                      WHERE ClientID = @ClientID
                        AND OrderDate BETWEEN @StartDate AND @EndDate
                        AND Status LIKE 'Finished'
                        AND InvoiceID IS NULL)
            THROW 52000, N'Podany klient nie ma w podanym okresie żadnego ukończonego zamówienia, które nie jest jeszcze na fakturze', 1

        DECLARE @OrderID int
        DECLARE myCursor CURSOR FORWARD_ONLY FOR SELECT OrderID
                                                 FROM Orders
                                                 WHERE ClientID = @ClientID
                                                   AND OrderDate BETWEEN @StartDate AND @EndDate
                                                   AND Status LIKE 'Finished'
                                                   AND InvoiceID IS NULL
        OPEN myCursor
        FETCH NEXT FROM myCursor INTO @OrderID

        DECLARE @InvoiceID int
        EXEC @InvoiceID = dbo.AddInvoice @OrderID

        FETCH NEXT FROM myCursor INTO @OrderID

        WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC dbo.AddOrderToInvoice @OrderID, @InvoiceID
                FETCH NEXT FROM myCursor INTO @OrderID
            END
        CLOSE myCursor
        DEALLOCATE myCursor

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd tworzenia faktury od daty do daty: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE AddOrder @ClientID int, @OrderDate datetime, @DiscountID int = NULL, @Takeaway bit,
                          @Status varchar(10) AS
BEGIN
    BEGIN TRY

        IF @OrderDate < getdate()
            THROW 52000, N'Podano nieprawidłową datę.', 1

        IF NOT EXISTS(SELECT ClientID FROM Clients WHERE ClientID = @ClientID)
            THROW 52000, N'Podano nieprawidłowy numer klienta.', 1

        IF NOT EXISTS(SELECT DiscountID FROM Discounts WHERE DiscountID = @DiscountID)
            THROW 52000, N'Podano nieprawidłowy numer zniżki.', 1

        IF (SELECT ClientID FROM Discounts WHERE DiscountID = @DiscountID) <> @ClientID
            THROW 52000, N'Podana zniżka przysługuje innemu klientowi.', 1

        IF @OrderDate NOT BETWEEN
                (SELECT StartDate FROM Discounts WHERE DiscountID = @DiscountID) AND
                (SELECT EndDate FROM Discounts WHERE DiscountID = @DiscountID)
            THROW 52000, N'Zniżka nie obowiązuje w podanym  czasie.', 1

        IF @Status NOT IN ('Pending', 'Approved')
            THROW 52000, N'Podano nieprawidłowy status zamówienia', 1

        INSERT INTO Orders (ClientID, DiscountID, InvoiceID, OrderDate, Takeaway, Status)
        VALUES (@ClientID, @DiscountID, NULL, @OrderDate, @Takeaway, @Status)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodawania nowego zamówienia: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE DeleteOrder @OrderID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID)
            THROW 52000, N'Brak podanego zamówienia.', 1

        IF (SELECT Status FROM Orders WHERE OrderID = @OrderID) NOT IN ('Pending', 'Approved')
            THROW 52000, N'Nie można usunąć tego zamówienia', 1

        DELETE FROM OrderDetails WHERE OrderID = @OrderID
        UPDATE Orders SET Status = 'Deleted' WHERE OrderID = @OrderID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd usuwania zamówienia: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE ChangeOrderStatusToFinished @OrderID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID)
            THROW 52000, N'Brak podanego zamówienia.', 1

        IF dbo.udfIsOrderPaid(@OrderID) = 0
            THROW 52000, N'Płatność za zamówienie nie jest uregulowana.', 1

        UPDATE Orders SET Status = 'Finished' WHERE OrderID = @OrderID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd ukończenia zamówienia: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE RejectReservationAndDeleteOrder @OrderID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID)
            THROW 52000, N'Brak podanego zamówienia.', 1

        IF NOT EXISTS(SELECT OrderID FROM Reservations WHERE OrderID = @OrderID)
            THROW 52000, N'Do podanego zamówienia nie jest przypisana rezerwacja.', 1

        IF (SELECT Status FROM Orders WHERE OrderID = @OrderID) NOT IN ('Pending')
            THROW 52000, N'Nie można odrzucić tej rezerwacji', 1

        DELETE FROM OrderDetails WHERE OrderID = @OrderID
        UPDATE Orders SET Status = 'Rejected' WHERE OrderID = @OrderID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd odrzucania rezerwacji: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddDishToOrder @OrderID int, @MenuID int, @Quantity int = 1 AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID)
            THROW 52000, N'Podano nieprawidłowy numer zamówienia.', 1

        IF (SELECT Status FROM Orders WHERE OrderID = @OrderID) IN ('Rejected', 'Finished', 'Deleted')
            THROW 52000, N'Do podanego zamówienia nie można dodać dania.', 1

        IF NOT EXISTS(SELECT MenuID FROM Menu WHERE MenuID = @MenuID)
            THROW 52000, N'Podano nieprawidłowy numer dania.', 1

        IF (SELECT OrderDate FROM Orders WHERE OrderID = @OrderID) NOT BETWEEN
            (SELECT StartDate
             FROM MenuDate
                      JOIN Menu M on MenuDate.MenuDateID = M.MenuDateID
             WHERE MenuID = @MenuID) AND
            (SELECT EndDate
             FROM MenuDate
                      JOIN Menu M on MenuDate.MenuDateID = M.MenuDateID
             WHERE MenuID = @MenuID)
            THROW 52000, N'Podany numer dania w menu dotyczy innego okresu niż zamówienie.', 1

        DECLARE @OrderDate datetime
        SELECT @OrderDate = OrderDate FROM Orders WHERE OrderID = @OrderID

        IF getdate() > DATEADD(DAY, (DATEDIFF(DAY, 1, @OrderDate) / 7) * 7, 1)
            THROW 52000, N'Owoce morza muszą być zamówione najpóźniej w poniedziałek poprzedzający datę zamówienia.', 1


        IF EXISTS(SELECT MenuID FROM OrderDetails WHERE MenuID = @MenuID AND OrderID = @OrderID)
            BEGIN
                IF (SELECT Quantity FROM OrderDetails WHERE MenuID = @MenuID AND OrderID = @OrderID) + @Quantity < 0
                    THROW 52000, N'Podano nieprawidłową ilość.', 1

                ELSE
                    IF (SELECT Quantity FROM OrderDetails WHERE MenuID = @MenuID AND OrderID = @OrderID) + @Quantity = 0
                        DELETE FROM OrderDetails WHERE MenuID = @MenuID AND OrderID = @OrderID
                    ELSE
                        UPDATE OrderDetails
                        SET Quantity = Quantity + @Quantity
                        WHERE MenuID = @MenuID
                          AND OrderID = @OrderID
            END

        ELSE
            INSERT INTO OrderDetails (OrderID, MenuID, Quantity) VALUES (@OrderID, @MenuID, @Quantity)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodawania dania do zamówienia: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE DeleteDishFromOrder @OrderID int, @MenuID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT MenuID FROM OrderDetails WHERE MenuID = @MenuID AND OrderID = @OrderID)
            THROW 52000, N'Brak takiego dania w podanym zamówieniu.', 1

        DELETE FROM OrderDetails WHERE MenuID = @MenuID AND OrderID = @OrderID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd usuwania dania z zamówienia: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddPayment @OrderID int, @Value money AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID)
            THROW 52000, N'Podano nieprawidłowy numer zamówienia.', 1

        INSERT INTO Payments (OrderID, Value, Date)
        VALUES (@OrderID, @Value, getdate())

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodawania płatności: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

CREATE PROCEDURE AddReservation @OrderID int, @NumberOfPeople int, @StartDate datetime, @EndDate datetime AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT OrderID FROM Orders WHERE OrderID = @OrderID)
            THROW 52000, N'Podano nieprawidłowy numer zamówienia.', 1

        IF @NumberOfPeople < 2
            THROW 52000, N'Można złożyć rezerwację tylko dla co najmniej 2 osób.', 1

        IF (SELECT Status FROM Orders WHERE OrderID = @OrderID) <> 'Pending'
            THROW 52000, N'Do podanego zamówienia nie można dodać rezerwacji.', 1

        IF @StartDate > @EndDate OR CAST(@StartDate AS DATE) <> CAST(@EndDate AS DATE)
            THROW 52000, N'Podano nieprawidłowy zakres dat.', 1

        IF (SELECT OrderDate FROM Orders WHERE OrderID = @OrderID) NOT BETWEEN @StartDate AND @EndDate
            THROW 52000, N'Data realizacji zamówienia nie zawiera się w podanym zakresie dat.', 1

        DECLARE @ClientID int
        SELECT @ClientID = ClientID FROM Orders WHERE OrderID = @OrderID

        IF dbo.udfCanBeReserved(@ClientID, @OrderID) = 0
            THROW 52000, N'Klient lub nie spełnia wymagań rezerwacji.', 1

        INSERT INTO Reservations (OrderID, NumberOfPeople, StartDate, EndDate)
        VALUES (@OrderID, @NumberOfPeople, @StartDate, @EndDate)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodawania rezerwacji: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AddEmployeeToReservation @ReservationID int, @EmployeeID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT ReservationID FROM Reservations WHERE ReservationID = @ReservationID)
            THROW 52000, N'Podano nieprawidłowy numer rezerwacji.', 1


        IF (SELECT Status
            FROM Orders
                     JOIN Reservations R2 on Orders.OrderID = R2.OrderID
            WHERE ReservationID = @ReservationID) <> 'Pending'
            THROW 52000, N'Do podanej rezerwacji nie można dodać pracownika.', 1

        IF NOT EXISTS(SELECT CompanyID
                      FROM Reservations
                               JOIN Orders O on O.OrderID = Reservations.OrderID
                               JOIN Clients C on C.ClientID = O.ClientID
                               JOIN Companies C2 on C.ClientID = C2.CompanyID
                      WHERE ReservationID = @ReservationID)
            THROW 52000, N'Podana rezerwacja nie dotyczy klienta firmowego.', 1

        IF NOT EXISTS(SELECT EmployeeID
                      FROM Reservations
                               JOIN Orders O on O.OrderID = Reservations.OrderID
                               JOIN Clients C on C.ClientID = O.ClientID
                               JOIN Companies C2 on C.ClientID = C2.CompanyID
                               JOIN Employees E on C2.CompanyID = E.CompanyID
                      WHERE ReservationID = @ReservationID
                        AND EmployeeID = @EmployeeID)
            THROW 52000, N'Podany pracownik nie pracuje w firmie, której dotyczy rezerwacja', 1

        IF EXISTS(SELECT ReservationID
                  FROM ReservationEmployees
                  WHERE ReservationID = @ReservationID
                    AND EmployeeID = @EmployeeID)
            THROW 52000, N'Podany pracownik już jest przypisany do tej rezerwacji', 1


        INSERT INTO ReservationEmployees (ReservationID, EmployeeID, ReservationTableID)
        VALUES (@ReservationID, @EmployeeID, NULL)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodawania pracownika do rezerwacji: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;

--dodawać sprawdzanie czy stolik jest dostępny w tym czasie?
CREATE PROCEDURE AddReservationOfTable @ReservationID int, @TableID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT ReservationID FROM Reservations WHERE ReservationID = @ReservationID)
            THROW 52000, N'Podano nieprawidłowy numer rezerwacji.', 1

        IF NOT EXISTS(SELECT TableID FROM Tables WHERE TableID = @TableID)
            THROW 52000, N'Podano nieprawidłowy numer stolika.', 1

        INSERT INTO ReservationTables (ReservationID, TableID)
        VALUES (@ReservationID, @TableID)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodawania rezerwacji stolika: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE AssignEmployeeToTable @ReservationID int, @EmployeeID int, @ReservationTableID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT ReservationID
                      FROM ReservationEmployees
                      WHERE ReservationID = @ReservationID
                        AND EmployeeID = @EmployeeID)
            THROW 52000, N'Podano pracownika nie przypisanego do podanej rezerwacji', 1

        IF NOT EXISTS(SELECT ReservationTablesID FROM ReservationTables WHERE ReservationTablesID = @ReservationTableID)
            THROW 52000, N'Podano nieprawidłowy numer rezerwacji stolika.', 1

        UPDATE ReservationEmployees
        SET ReservationTableID = @ReservationTableID
        WHERE ReservationID = @ReservationID
          AND EmployeeID = @EmployeeID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd przypisania pracownika do rezerwacji stolika: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE ApproveReservation @ReservationID int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT ReservationID FROM Reservations WHERE ReservationID = @ReservationID)
            THROW 52000, N'Podano nieprawidłową rezerwację.', 1

        DECLARE @OrderID int
        SELECT @OrderID = OrderID FROM Reservations WHERE ReservationID = @ReservationID


        IF (SELECT Status FROM Orders WHERE OrderID = @OrderID) NOT IN ('Pending')
            THROW 52000, N'Nie można zaakceptować tej rezerwacji.', 1

        UPDATE Orders SET Status = 'Approved' WHERE OrderID = @OrderID

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd akceptacji rezerwacji: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;



CREATE PROCEDURE AddTable @Size int AS
BEGIN
    BEGIN TRY

        INSERT INTO Tables (Size) VALUES (@Size)

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd dodania stolika: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;


CREATE PROCEDURE ModifyConstants @Name varchar(8), @Value int AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS(SELECT Name FROM Constants WHERE Name = @Name)
            THROW 52000, N'Brak podanej stałej.', 1

        UPDATE Constants SET Value = @Value WHERE Name = @Name

    END TRY
    BEGIN CATCH
        DECLARE @msg nvarchar(2048)
            =N'Błąd modyfikacji stałej: ' + ERROR_MESSAGE();
        THROW 52000, @msg, 1
    END CATCH
END
GO;