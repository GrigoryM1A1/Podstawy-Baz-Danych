-- Zwraca aktualne menu dla podanego dnia
create function udfGetMenuByDate(@date date)
returns table as
    return
    select d.DishID, Name, Price, StartDate, EndDate
    from MenuDate md
    inner join Menu m on md.MenuDateID = m.MenuDateID
    inner join Dishes d on m.DishID = d.DishID
    where (@date between StartDate and EndDate) and InStock = 1 and Approved = 1;

-- Zwraca klientów, którzy zapłacili co najmniej minVal i liczbę takich zamówień
-- (wydaje mi sie, że będzie pomocne do zniżek)
create function udfGetClientWithSingleOrderValAtLeastX(@minVal int, @id int)
returns table as
    return
    select ClientID, count(OrderID) OrdersNo
    from ClientOrderValues
    where ClientID = @id and OrderVal >= @minVal
    group by ClientID;

-- Wersja z tierami zniżki - zwraca klienta, którzy mają sumę zamówień o wartości
-- co najmniej minVal
create function udfGetClientWithAllTimeOrdersValAtLeastX(@minVal int, @id int)
returns table as
    return
    select ClientID, OrdersVal
    from AllTimeClientOrderStats
    where ClientID = @id and OrdersVal >= @minVal;


-- Zwraca najkorzystniejsza znizke jednorazową dla klienta (podajemy datę i id klienta)
create function udfGetOneTimeDiscounts(@id int, @date datetime)
returns table as
    return
    select DiscountID, Value
    from Discounts
    where ClientID = @id and Type = 'OneTime' and @date between  StartDate and EndDate;


-- Zwraca najkorzystniejsza znizke stałą dla klienta (podajemy datę i id klienta) [git]
create function udfGetBestPermanentDiscount(@id int, @date datetime)
returns real as
    begin
        declare @bestDiscount real;
        set @bestDiscount = (select max(Value)
                             from Discounts
                             where ClientID = @id and Type = 'Permanent' and @date > StartDate)
        if @bestDiscount is null
            begin
                return 0
            end
        return @bestDiscount
    end

-- Zwraca zniżkę dla danego zamówienia
create function udfGetOrderDiscount(@orderID int)
returns real as
    begin
        declare @orderDiscount real;
        set @orderDiscount = (select Value
                              from Orders o
                              inner join Discounts d on d.DiscountID = o.DiscountID
                              where OrderID = @orderID)
        if @orderDiscount is null
            begin
                return 0
            end
        return @orderDiscount
    end


-- Zwraca true/false w zależności czy menu moze zostac zaakceptowane
create function udfIsMenuAllowed(@menuID int)
returns bit as
    begin
        declare @sameDishesNo int;
        set @sameDishesNo = (select count(*)
                           from (
                               select DishID
                               from Menu
                               where MenuDateID = (@menuID - 1)
                               intersect
                               select DishID
                               from Menu
                               where MenuDateID = @menuID) outTabel
                           )

        declare @minToChange int;
        set @minToChange = (select count(*)
                            from Menu
                            where MenuDateID = (@menuID - 1)) / 2

        if @sameDishesNo <= @minToChange
            begin
                return 1
            end
        return 0
    end

create function udfIsOrderPaid(@orderID int)
returns bit as
    begin
        if exists(select OrderID from Orders where OrderID = @orderID) and
           not exists(select OrderID from Payments where OrderID = @orderID)
            return 0

        declare @valueToPay real
        declare @paymentVal real
        set @valueToPay = cast((select ValueToPay
                                from OrdersValues
                                where OrderID = @orderID) as real)

        set @paymentVal = cast((select sum(Value)
                                from Payments
                                where OrderID = @orderID) as real)

        if @valueToPay = @paymentVal
            return 1
        return 0
    end

create function udfCanBeReserved(@id int, @orderID int)
returns bit as
    begin
        declare @ordVal real;
        declare @ordNo int;

        set @ordVal = (select ValueToPay
                      from OrdersValues
                      where OrderID = @orderID)

        set @ordNo = (select OrdersNo
                     from AllTimeClientOrderStats
                     where ClientID = @id)

        if (@ordVal >= (select Value from Constants where Name like 'WZ')) and
           (@ordNo > (select Value from Constants where Name like 'WK'))
            begin
                return 1
            end
        return 0
    end

create function udfCanSeafoodBeAddedToMenu(@menuDateID int)
returns bit as
    begin
        declare @startDate date;
        declare @endDate date;

        select @startDate = StartDate, @endDate = EndDate
        from MenuDate
        where MenuDateID = @menuDateID;

        if datepart(weekday, @startDate) >= 5 and datepart(weekday , @endDate) >= 5
               and datediff(day, @endDate, @startDate) <= 2
            begin
                return 1
            end
        return 0
    end


-- =====================RAPORTY=====================

-- Zwraca statystyki zamówień konkretnego klienta za konkretny miesiąc
-- (podajemy ClientID, rok, miesiąc)
create function udfGetMonthClientStats(@id int, @date date)
returns table as
    return
    select Year, Month, OrdersNo, OrdersVal
    from MonthlyClientOrderStats
    where ClientID = @id and Year = year(@date) and Month = month(@date);

-- Zwraca tygodniowe statystyki zamówień konkretnego klienta za konkretny tydzień
create function udfGetWeekClientStats(@id int, @year int, @month int, @week int)
returns table as
    return
    select Year, Month, Week, OrdersNo, OrdersVal
    from WeeklyClientOrderStats
    where ClientID = @id and Year = @year and Month = @month and Week = @week;

-- Zwraca tabelę z datą zamówienia, kwotą zamówienia oraz zniżką jaka została użyta dla klienta za dany miesiąc
create function udfClientMonthOrders(@id int, @date date)
returns table as
    return
    select OrderDate, OrderVal, dbo.udfGetOrderDiscount(OrderID) Discount
    from ClientOrderValues
    where ClientID = @id and year(OrderDate) = year(@date) and month(OrderDate) = month(@date);

-- Zwraca tabelę z datą zamówienia, kwotą zamówienia oraz zniżką jaka została użyta dla klienta za dany tydzień
create function udfClientWeekOrders(@id int, @year int, @month int, @week int)
returns table as
    return
    select OrderDate, OrderVal, dbo.udfGetOrderDiscount(OrderID) Discount
    from ClientOrderValues
    where ClientID = @id and year(OrderDate) = @year and month(OrderDate) = @month
      and datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7 * 7,
          dateadd(d, -1, OrderDate)) + 1 = @week;

-- Raporty dotyczące stolików i menu
create function udfMonthMenu(@year int, @month int)
returns table as 
    return
    select MenuID, StartDate, EndDate, Name
    from MenuDate
        inner join Menu M on MenuDate.MenuDateID = M.MenuDateID
        inner join Dishes D on D.DishID = M.DishID
    where (@year between year(StartDate) and year(EndDate)) and (@month between month(StartDate) and month(EndDate));

create function udfWeekMenu(@year int, @month int, @week int)
returns table as
    return
    select MenuID, StartDate, EndDate, Name
    from MenuDate
        inner join Menu M on MenuDate.MenuDateID = M.MenuDateID
        inner join Dishes D on D.DishID = M.DishID
    where (@year between year(StartDate) and year(EndDate))
      and (@month between month(StartDate) and month(EndDate))
      and (@week between
          (datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, StartDate), 0)) / 7 * 7,dateadd(d, -1, StartDate)) + 1)
          and
          (datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, EndDate), 0)) / 7 * 7, dateadd(d, -1, EndDate)) + 1));


-- Zwraca statystyki sprzedaży danego dania dla wprowadzonego miesiąca
create function udfGetDishStatsByMonth(@date date)
returns table as
    return
    select Name, SoldNo, Year, Month
    from MonthlySoldDishes
    where Month = month(@date) and Year = year(@date);

-- Zwraca informacje o zamówieniach konkretnego klienta (podajemy id kilenta) [git]
create function udfGetClientOrders(@id int)
returns table as
    return
    select OrderID, OrderVal, OrderDate, Takeaway, Status
    from ClientOrderValues
    where ClientID = @id;
