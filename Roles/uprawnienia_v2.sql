CREATE ROLE worker
GRANT SELECT ON Categories to worker
GRANT SELECT ON Dishes to worker
GRANT SELECT ON Menu to worker
GRANT SELECT ON MenuDate to worker
GRANT SELECT ON OrderDetails to worker
GRANT SELECT ON Orders to worker
GRANT SELECT ON Payments to worker
GRANT SELECT ON Invoices to worker
GRANT SELECT ON Discounts to worker
GRANT SELECT ON Clients to worker
GRANT SELECT ON IndividualClients to worker
GRANT SELECT ON Companies to worker
GRANT SELECT ON Employees to worker
GRANT SELECT ON Reservations to worker
GRANT SELECT ON ReservationTables to worker
GRANT SELECT ON ReservationEmployees to worker
GRANT SELECT ON Tables to worker
GRANT SELECT ON Constants to worker

GRANT EXECUTE ON udfCanBeReserved to worker
GRANT SELECT ON udfGetMenuByDate to worker
GRANT SELECT ON udfGetDishStatsByMonth to worker
GRANT SELECT ON udfGetClientOrders to worker
GRANT SELECT ON udfGetClientWithSingleOrderValAtLeastX to worker
GRANT SELECT ON udfGetClientWithAllTimeOrdersValAtLeastX to worker
GRANT SELECT ON udfGetOneTimeDiscounts to worker
GRANT EXECUTE ON udfGetBestPermanentDiscount to worker
GRANT EXECUTE ON udfGetOrderDiscount to worker
GRANT EXECUTE ON udfIsOrderPaid to worker
GRANT SELECT ON udfGetMonthClientStats to worker
GRANT SELECT ON udfGetWeekClientStats to worker
GRANT SELECT ON udfClientMonthOrders to worker
GRANT SELECT ON udfClientWeekOrders to worker
GRANT SELECT ON udfMonthMenu to worker
GRANT SELECT ON udfWeekMenu to worker

GRANT EXECUTE ON AddIndividualClient to worker
GRANT EXECUTE ON AddCompanyClient to worker
GRANT EXECUTE ON AddEmployee to worker
GRANT EXECUTE ON AddInvoice to worker
GRANT EXECUTE ON AddOrderToInvoice to worker
GRANT EXECUTE ON CreateInvoiceFromDateToDate to worker
GRANT EXECUTE ON AddOrder to worker
GRANT EXECUTE ON DeleteOrder to worker
GRANT EXECUTE ON RejectReservationAndDeleteOrder to worker
GRANT EXECUTE ON AddDishToOrder to worker
GRANT EXECUTE ON DeleteDishFromOrder to worker
GRANT EXECUTE ON AddReservation to worker
GRANT EXECUTE ON AddEmployeeToReservation to worker
GRANT EXECUTE ON AddReservationOfTable to worker
GRANT EXECUTE ON AssignEmployeeToTable to worker
GRANT EXECUTE ON ApproveReservation to worker
GRANT EXECUTE ON AddTable to worker
GRANT EXECUTE ON ChangeOrderStatusToFinished to worker


CREATE ROLE moderator
ALTER ROLE worker ADD MEMBER moderator

GRANT UPDATE ON Companies to moderator
GRANT UPDATE ON Clients to moderator
GRANT UPDATE ON IndividualClients to moderator
GRANT UPDATE ON Employees to moderator

GRANT EXECUTE ON udfCanSeafoodBeAddedToMenu to moderator
GRANT EXECUTE ON udfIsMenuAllowed to moderator

GRANT EXECUTE ON AddDish to moderator
GRANT EXECUTE ON AddDishCategory to moderator
GRANT EXECUTE ON AddDishToMenu to moderator
GRANT EXECUTE ON AddMenuPeriod to moderator
GRANT EXECUTE ON ApproveMenuPeriod to moderator
GRANT EXECUTE ON DeleteDishFromMenu to moderator
GRANT EXECUTE ON ModifyConstants to moderator
GRANT EXECUTE ON ModifyDishDescription to moderator

CREATE ROLE admin
GRANT ALL PRIVILEGES ON u_bwalczak.dbo To admin
