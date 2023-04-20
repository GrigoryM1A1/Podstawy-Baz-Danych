-- Menu, które aktualnie obowiązuje [GIT]
create view CurrentMenu as
select d.Name, m.Price, StartDate, EndDate
from MenuDate md
    inner join Menu m on md.MenuDateID = m.MenuDateID
    inner join Dishes d on m.DishID = d.DishID
where (CAST(getdate() AS date) between md.StartDate and md.EndDate) and InStock = 1 and Approved = 1;

-- Dania niedostępne w danym czasie [GIT]
create view UnavailableCurrentDishes as
select d.Name, m.Price
from MenuDate md
    inner join Menu m on md.MenuDateID = m.MenuDateID
    inner join Dishes d on m.DishID = d.DishID
where (CAST(getdate() AS date) between md.StartDate and md.EndDate) and InStock = 0;

-- Informacje o danym posiłku [GIT]
create view DishDetails as
select d.Name, d.Description, c.CategoryName
from Dishes d
    inner join Categories c on c.CategoryID = d.CategoryID;

-- Zamówienia bez przeprowadzonej jakiejkolwiek transakcji (też takie, z ktorych klient nie zrezygnował) [GIT]
create view OrdersToBePaid as
select o.OrderID, ClientID, DiscountID, Takeaway, Status, OrderDate
from Orders o
    left join Payments p on o.OrderID = p.OrderID
where p.OrderID is null and Status not in ('Deleted', 'Rejected');

-- Wartość poszczególnego zamówienia (nie uwzgledniamy zamowien anulowanych i odrzuconych) [GIT]
-- jeśli zamówienie usunięto albo odrzucono to valuetopay jest równe 0
create view OrdersValues as
select o.OrderID, isnull(round(sum(OrderValue), 2), 0) ValueToPay
from (select OrderID, Quantity * Price * (1 - dbo.udfGetOrderDiscount(OrderID)) OrderValue
      from OrderDetails od
      inner join Menu m on od.MenuID = m.MenuID) ov
right join Orders o on ov.OrderID = o.OrderID
group by o.OrderID;

-- Wartość zamówień konkretnego klienta [GIT]
create view ClientOrderValues as
select ClientID, o.OrderID, round(ov.ValueToPay, 2) OrderVal, OrderDate, Takeaway, Status
from Orders o
    inner join OrdersValues ov on o.OrderID = ov.OrderID
where Status like 'Finished';

-- Rezerwacje oczekujące na potwierdzenie [GIT]
create view PendingReservations as
select ClientID, o.OrderID, StartDate, EndDate
from Orders o
inner join Reservations r1 on o.OrderID = r1.OrderID
where Status = 'Pending';

-- Informacje o rezerwacjach (bez odrzuconych i anulowanych) [GIT]
create view ReservationInfo as
select ClientID, o.OrderID, o.Status, StartDate, EndDate
from Orders o
inner join Reservations r1 on o.OrderID = r1.OrderID and Status not in ('Rejected', 'Deleted');

-- Zamównienia na wynos będące w realizacji (o ile dobrze rozumiem to tak) [GIT]
create view TakeawayInRealization as
select ClientID, OrderID, Takeaway, Status
from Orders
where Takeaway = 1 and Status = 'Approved';


-- ====================RAPORTY===================
create view TablesMonthlyStats as
select T.TableID, max(Size) TableSize, count(R2.ReservationID) ReservationsNo,
       year(OrderDate) Year, month(OrderDate) Month
from Tables T
    inner join ReservationTables RT on T.TableID = RT.TableID
    inner join Reservations R2 on R2.ReservationID = RT.ReservationID
    inner join Orders O on O.OrderID = R2.OrderID
where Status = 'Finished'
group by T.TableID, year(OrderDate), month(OrderDate);

create view TablesWeeklyStats as
select T.TableID, max(Size) TableSize, count(R2.ReservationID) ReservationsNo,
       year(OrderDate) Year, month(OrderDate) Month,
       (datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7 * 7,
           dateadd(d, -1, OrderDate)) + 1) Week
from Tables T
    inner join ReservationTables RT on T.TableID = RT.TableID
    inner join Reservations R2 on R2.ReservationID = RT.ReservationID
    inner join Orders O on O.OrderID = R2.OrderID
where Status = 'Finished'
group by T.TableID, year(OrderDate), month(OrderDate),
         (datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7 * 7,dateadd(d, -1, OrderDate)) + 1);

-- Informacje o dostępności zniżek dla klienta (jak będzie funkcja do liczenia wartości to dodane będzie [Raczej GIT]
create view ClientDiscountInfo as
select d.ClientID, FirstName, LastName , d.Type, d.Value
from Discounts d
inner join IndividualClients ic on d.ClientID = ic.ClientID
where getdate() > StartDate
union
select d.ClientID, FirstName, LastName , d.Type, d.Value
from Discounts d
inner join IndividualClients ic on d.ClientID = ic.ClientID
where getdate() between StartDate and EndDate;


-- Informacje o rezerwacjach na całą firmę [GIT]
create view CompanyResInfo as
select CompanyID, CompanyName, o.Status, r.ReservationID, rt.TableID, r.StartDate, r.EndDate
from Companies c
inner join Clients cl on c.CompanyID = cl.ClientID
inner join Orders o on cl.ClientID = o.ClientID
inner join Reservations r on o.OrderID = r.OrderID
inner join ReservationTables rt on r.ReservationID = rt.ReservationID;

-- Informacje o rezerwacjach dla pracownika firmy [GIT]
create view EmployeeResInfo as
select e.EmployeeID, FirstName, LastName, CompanyID, o.Status, r.StartDate, r.EndDate
from Employees e
inner join ReservationEmployees re on e.EmployeeID = re.EmployeeID
inner join Reservations r on re.ReservationID = r.ReservationID
inner join Orders o on r.OrderID = o.OrderID;

-- Informacje o rezerwacjach klientów indywidualnych
create view IndividualClientResInfo as
select ic.ClientID, FirstName, LastName, o.Status, rt.TableID, r.StartDate, r.EndDate
from IndividualClients ic
inner join Clients c on ic.ClientID = c.ClientID
inner join Orders o on c.ClientID = o.ClientID
inner join Reservations r on o.OrderID = r.OrderID
inner join ReservationTables rt on r.ReservationID = rt.ReservationID;

-- Ogólne statystyki zamównień konkretnego klienta (ile razy zamawiał,
-- łączna wartość wszystkich zamówień) [GIT]
create view AllTimeClientOrderStats as
select c.ClientID, Email, Street, City, PostalCode, Phone,
       count(cov.OrderID) OrdersNo,
       round(sum(cov.OrderVal), 2) OrdersVal
from Clients c
inner join ClientOrderValues cov on c.ClientID = cov.ClientID
group by c.ClientID, Email, Street, City, PostalCode, Phone;

-- Tygodniowe statystyki zamówień klienta (ile razy zamawiał,
-- łączna wartość wszystkich zamówień) [GIT]
create view WeeklyClientOrderStats as
select c.ClientID, year(OrderDate) Year, month(OrderDate) Month,
       max(datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7 * 7,
           dateadd(d, -1, OrderDate)) + 1) Week,
       count(cov.OrderID) OrdersNo,
       round(sum(cov.OrderVal),2) OrdersVal
from Clients c
inner join ClientOrderValues cov on cov.ClientID = c.ClientID
group by c.ClientID, year(OrderDate), month(OrderDate),
         (datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7 * 7,dateadd(d, -1, OrderDate)) + 1);

-- Miesięczne statystyki zamówień klienta (ile razy zamawiał,
-- łączna wartość wszystkich zamówień) [GIT]
create view MonthlyClientOrderStats as
select c.ClientID, year(OrderDate) Year, month(OrderDate) Month,
       count(cov.OrderID) OrdersNo,
       round(sum(cov.OrderVal), 2) OrdersVal
from Clients c
inner join ClientOrderValues cov on cov.ClientID = c.ClientID
group by c.ClientID, year(OrderDate), month(OrderDate);

-- Statystyki sprzedanych posiłków [GIT]
create view AllTimeSoldDishes as
select d.DishID, d.Name, sum(Quantity) SoldNo
from Dishes d
    inner join Menu m on d.DishID = m.DishID
    inner join OrderDetails od on m.MenuID = od.MenuID
    inner join Orders O on O.OrderID = od.OrderID
where Status like 'Finished'
group by d.DishID, d.Name;

-- Miesięczna statystyki sprzedanych posiłków [GIT]
create view MonthlySoldDishes as
select d.Name, sum(od.Quantity) SoldNo, year(OrderDate) Year, month(OrderDate) Month
from Dishes d
    inner join Menu m on d.DishID = m.DishID
    inner join OrderDetails od on m.MenuID = od.MenuID
    inner join Orders o on od.OrderID = o.OrderID
where Status like 'Finished'
group by d.Name, d.DishID, year(OrderDate), month(OrderDate);

-- Tygodniowa statystyki sprzedanych posiłków, pierwszy dzień tygodnia to Poniedziałek [GIT]
create view WeeklySoldDishes as
select d.Name, sum(od.Quantity) SoldNo, year(OrderDate) Year, month(OrderDate) Month,
       max(datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7* 7,
           dateadd(d, -1, OrderDate)) + 1) Week
from Dishes d
    inner join Menu m on d.DishID = m.DishID
    inner join OrderDetails od on m.MenuID = od.MenuID
    inner join Orders o on od.OrderID = o.OrderID
where Status like 'Finished'
group by d.DishID, d.Name, year(OrderDate), month(OrderDate),
         (datediff(ww, datediff(d, 0, dateadd(m, datediff(m, 7, OrderDate), 0)) / 7 * 7,dateadd(d, -1, OrderDate)) + 1);
