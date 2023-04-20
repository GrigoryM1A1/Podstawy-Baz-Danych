use u_bwalczak
DROP TRIGGER TR_grant_discount

CREATE TRIGGER TR_grant_discount
    ON Orders
    FOR UPDATE AS
BEGIN
    DECLARE @OldStatus varchar(10)
    DECLARE @NewStatus varchar(10)
    SELECT TOP 1 @OldStatus = Status FROM deleted
    SELECT TOP 1 @NewStatus = Status FROM inserted
    IF @OldStatus <> 'Finished' AND @NewStatus = 'Finished'
        AND EXISTS(SELECT I.ClientID
                   FROM IndividualClients I
                        JOIN inserted ON I.ClientID = inserted.ClientID)
        BEGIN
            DECLARE @ClientID int
            SELECT @ClientID = ClientID FROM inserted

            DECLARE @Z1 int
            DECLARE @K1 int
            DECLARE @R1 int
            DECLARE @K2 int
            DECLARE @R2 int
            DECLARE @D1 int

            SELECT @Z1 = Value FROM Constants WHERE Name = 'Z1'
            SELECT @K1 = Value FROM Constants WHERE Name = 'K1'
            SELECT @R1 = Value FROM Constants WHERE Name = 'R1'
            SELECT @K2 = Value FROM Constants WHERE Name = 'K2'
            SELECT @R2 = Value FROM Constants WHERE Name = 'R2'
            SELECT @D1 = Value FROM Constants WHERE Name = 'D1'

            --zniżka stała
            IF NOT EXISTS(SELECT DiscountID FROM Discounts WHERE Discounts.ClientID = @ClientID AND Type = 'Permanent')
                BEGIN
                    IF (SELECT OrdersNo FROM dbo.udfGetClientWithSingleOrderValAtLeastX(@K1, @ClientID)) >= @Z1
                        INSERT INTO Discounts (ClientID, StartDate, EndDate, Value, Type)
                        VALUES (@ClientID, GETDATE(), NULL, CAST(@R1 AS real) / 100, 'Permanent')
                END

            --zniżka jednorazowa
            IF NOT EXISTS(SELECT DiscountID FROM Discounts WHERE Discounts.ClientID = @ClientID AND Type = 'Onetime')
                BEGIN
                    IF EXISTS(SELECT OrdersVal FROM dbo.udfGetClientWithAllTimeOrdersValAtLeastX(@K2, @ClientID))
                        INSERT INTO Discounts (ClientID, StartDate, EndDate, Value, Type)
                        VALUES (@ClientID, GETDATE(), DATEADD(day, @D1, GETDATE()), CAST(@R2 AS real) / 100, 'Onetime')
                END
        END
END
GO;
