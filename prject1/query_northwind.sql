WITH full_ord as (
		SELECT 
			*
		FROM Orders          as ord
		JOIN OrderDetails    as orddt
		on   ord.OrderID     =  orddt.OrderID
		JOIN Products        as pro
		on   orddt.ProductID =  pro.ProductID
		JOIN Categories      as cat
		on   cat.CategoryID  =  pro.CategoryID
		JOIN Employees	     as emp
		on   emp.EmployeeID  =  ord.EmployeeID
		JOIN Customers       as cus
		on   cus.CustomerID  =  ord.CustomerID
)

SELECT
	OrderDate,
	CustomerName,
	ContactName,
	City,
	Country,
	PostalCode,
	ProductName,
	CategoryName,
	Price,
	Quantity,
	Price*Quantity                 as total_spent,
	FirstName ||' '||LastName      as employee
FROM full_ord
WHERE OrderDate > '1996-09-30' 
and   OrderDate <= '1996-12-31'
ORDER by OrderDate
;
