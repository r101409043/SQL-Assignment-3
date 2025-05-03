-- List all cities that have both Employees and Customers.
SELECT DISTINCT e.City
FROM Employees e
-- INNER JOIN get City for both Employees and Customers are located
INNER JOIN Customers c ON c.City = e.City

-- List all cities that have Customers but no Employee.
-- a. Use sub-query
SELECT DISTINCT c.City
FROM Customers c
-- Check city only in Customers not in Employees
WHERE c.City NOT IN
      (
	      SELECT DISTINCT e.City
	      FROM Employees e
      );
-- b. Do not use sub-query
SELECT DISTINCT c.City
FROM Customers c
EXCEPT
SELECT DISTINCT e.City
FROM Employees e;

-- List all products and their total order quantities throughout all orders.
SELECT p.ProductName AS products, SUM(od.Quantity) AS TotalQuantities
FROM Products p
-- get Quantity by using ProductID
JOIN [Order Details] od ON p.ProductID = od.ProductID
GROUP BY p.ProductName;

-- List all Customer Cities and total products ordered by that city.
SELECT c.City AS CustomerCities, SUM(od.Quantity) AS TotalProductsOrdered
FROM Customers c
-- get OrderID by using CustomerID
JOIN Orders o ON c.CustomerID = o.CustomerID
-- get Quantity by using OrderID 
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City

-- List all Customer Cities that have at least two customers.
SELECT c.City AS CustomerCities
FROM Customers c
GROUP BY City
HAVING COUNT(*) >= 2;

-- List all Customer Cities that have ordered at least two different kinds of products.
SELECT DISTINCT c.City AS CustomerCities
FROM Customers c
-- get OrderID by using CustomerID
JOIN Orders o ON c.CustomerID = o.CustomerID
-- get CityName by using OrderID
JOIN [Order Details] od ON o.OrderID = od.OrderID
GROUP BY c.City
HAVING COUNT(DISTINCT od.ProductID) >= 2;

-- List all Customers who have ordered products, 
-- but have the ¡¥ship city¡¦ on the order different from their own customer cities.
SELECT DISTINCT c.CompanyName AS Customers
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
WHERE c.City != o.ShipCity;

-- List 5 most popular products, their average price, 
-- and the customer city that ordered most quantity of it.
-- get (ProductID, ProductName, City, AvgPrice, MostQuantity) From All products
WITH ProductQty AS
	     (
		     SELECT p.ProductID, p.ProductName, c.City, AVG(p.UnitPrice) AS AvgPrice, SUM(od.Quantity) AS MostQty
		     FROM [Order Details] od
			     -- get OrderID by using ProductID
		     JOIN Products p ON od.ProductID = p.ProductID
			          -- get CustomerID by using OrderID
		     JOIN Orders o ON od.OrderID = o.OrderID
			          -- get City by using OrderID
		     JOIN Customers c ON o.CustomerID = c.CustomerID
		     GROUP BY p.ProductID, p.ProductName, c.City
	     ),
     -- for each product, rank City by using ROW_NUMBER(MostQuantity)
     Ranked AS
	     (
		     SELECT ProductID, ProductName, City, AvgPrice, MostQty,
		            ROW_NUMBER() OVER ( PARTITION BY ProductID ORDER BY MostQty DESC ) AS ROW_NUM
		     FROM ProductQty
	     ),
     -- get Top 5 ProductID by SUM(Quantity) = MostQuantity
     Top5 AS (
		     SELECT TOP 5 ProductID
		     FROM [Order Details]
		     GROUP BY ProductID
		     ORDER BY SUM(Quantity) DESC
	     )
SELECT rnk.ProductName, rnk.AvgPrice, rnk.City, rnk.MostQty AS MostQuantity
FROM Ranked rnk
-- get Ranked's products in the Top5's MostQuantity products by using ProductID
JOIN Top5 tp5 ON rnk.ProductID = tp5.ProductID
-- get City with the most orders for each Top5's product
WHERE rnk.ROW_NUM = 1
-- order by product's SUM(Quantity)
ORDER BY (
	         SELECT SUM(Quantity)
	         FROM [Order Details] od
	         WHERE od.ProductID = rnk.ProductID
         ) DESC;

-- List all cities that have never ordered something, but we have employees there.
-- a. Use sub-query
SELECT DISTINCT e.City
FROM Employees e
WHERE e.City NOT IN
      (
	      SELECT DISTINCT o.ShipCity
	      FROM Orders o
      );
-- b. Do not use sub-query
SELECT DISTINCT e.City
FROM Employees e
/* LEFT JOIN get Employee's city which in Order's shipping city, 
if any not in will = Null in Order's shipping city */
LEFT JOIN Orders o ON e.City = o.ShipCity
-- get all Order's shipping city is Null = have employees, but have never ordered something
WHERE o.ShipCity IS NULL;

-- List one city, if exists, that is the city from where the employee sold most orders (not the product quantity) is, 
-- and also the city of most total quantity of products ordered from. (tip: join  sub-query)
SELECT TOP 1 CountedOrder.City AS City
-- get all City CountedOrder
FROM (
	     SELECT ShipCity AS City, COUNT(ShipCity) AS Counted
	     FROM Orders
	     GROUP BY ShipCity
     ) AS CountedOrder
-- get TotalQuantity by using City
JOIN (
	     SELECT o.ShipCity AS City, SUM(od.Quantity) AS TotalQty
	     FROM Orders o
		     -- get TotalQuantity by using OrderID
	     JOIN [Order Details] od ON o.OrderID = od.OrderID
	     GROUP BY o.ShipCity
     ) AS TotalQuantity ON CountedOrder.City = TotalQuantity.City
-- MostTotalQuantity & MostCountedOrder City
ORDER BY CountedOrder.Counted DESC, TotalQuantity.TotalQty DESC;

-- How do you remove the duplicates record of a table?
/* WITH CTE AS (
	            SELECT *, ROW_NUMBER() OVER (PARTITION BY... ORDER BY ID) AS ROW_NUM
	            FROM...
            )
DELETE FROM CTE
WHERE rn > 1; */
