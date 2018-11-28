use northwind;

/*
 2
 */
DELIMITER //
DROP PROCEDURE if exists sp_LowStock//
CREATE PROCEDURE sp_LowStock ()
BEGIN
	SELECT CompanyName, ProductName, UnitsInStock-ReorderLevel 
    as n, ReorderLevel  
	FROM products p, suppliers s
    where (UnitsInStock-ReorderLevel) >= 0;
END //
DELIMITER ;

CAll sp_LowStock ();
	
	
/*
3
*/
DELIMITER //
DROP PROCEDURE if exists sp_EmployeeTerritories//
CREATE PROCEDURE sp_EmployeeTerritories(in employee_id int, out r1 text, out r2 text)
BEGIN
		SET r1 = (SELECT concat(Title, ' ', FirstName, ' ', LastName) FROM  employees where EmployeeID =  employee_id);
		SET r2 = (    SELECT GROUP_CONCAT(DISTINCT t.TerritoryDescription SEPARATOR ', ') 
    FROM territories t
	INNER JOIN employeeterritories et
	ON t.TerritoryID = et.TerritoryID
	WHERE et.EmployeeID = 1);
END //
DELIMITER ;

CALL sp_EmployeeTerritories(1, @result1, @result2);
SELECT @result1, @result2;




--     -----------------------
DELIMITER //
CREATE DEFINER= root @ localhost PROCEDURE sp_AddOrderItem(IN orderid INT(11),IN productid INT(11), IN quantity SMALLINT(6),IN discountamount FLOAT, OUT quantityadded SMALLINT(6))

BEGIN
 DECLARE stock SMALLINT(6);
DECLARE EXIT HANDLER FOR SQLEXCEPTION
 SELECT 'sql exception invoked';
 
 
DECLARE EXIT HANDLER FOR 1062 
 
        SELECT 'MySQL error code 1062 invoked';
DECLARE EXIT HANDLER FOR 1264

	SELECT 'Out of range exception';


SET SQL_SAFE_UPDATES = 0;

SELECT 
    UnitsInStock
INTO stock FROM
    Products
WHERE
    ProductID = productid
LIMIT 1;
IF(stock>quantity) THEN


INSERT INTO order_details(OrderID,ProductID,UnitPrice,Quantity,Discount) VALUES (orderid,productid,(SELECT UnitPrice FROM products WHERE ProductID=productid LIMIT 1),quantity,discountamount);
SET quantityadded=quantity;
UPDATE Products 
SET 
    UnitsInStock = (UnitsInStock - quantity)
WHERE
    ProductID = productid;
ELSEIF (stock<quantity) THEN
INSERT INTO order_details(OrderID,ProductID,UnitPrice,Quantity,Discount) VALUES (orderid,productid,(SELECT UnitPrice FROM products WHERE ProductID=productid LIMIT 1),stock,discountamount);
SET quantityadded=stock;
UPDATE Products 
SET 
    UnitsInStock = 0
WHERE
    ProductID = productid;
END IF;



END//
DELIMITER ;

/*
4
*/
DELIMITER //
DROP FUNCTION IF EXISTS OrderFulfilmentCycleTime//
CREATE FUNCTION OrderFulfilmentCycleTime () RETURNS INT(6)
BEGIN

	DECLARE averagevalue INT;

	SET averagevalue = (SELECT AVG(DATEDIFF(DATE(ShippedDate), DATE(OrderDate))) FROM Orders); 

	RETURN averagevalue;

END //
DELIMITER ;

SELECT ORDERFULFILMENTCYCLETIME();

/*
 5
*/
DELIMITER //
CREATE DEFINER= root @ localhost TRIGGER northwind.orders_AFTER_DELETE AFTER DELETE ON orders FOR EACH ROW
BEGIN

IF (ROW_COUNT()>1) THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'error you shouldnt do that';
END IF;

END //
DELIMITER ;


/*
6
*/
DELIMITER //
CREATE DEFINER=root @ localhost TRIGGER northwind.products_AFTER_UPDATE AFTER UPDATE ON products FOR EACH ROW
BEGIN
	IF(new.UnitsInStock<new.ReorderLevel) THEN
	INSERT INTO supplierorders(SupplierID,ProductID,Date,Quantity) VALUES (new.SupplierID,new.ProductID,NOW(),new.UnitsInStock);
	END IF;
END //
DELIMITER ;

/*
7
*/
DELIMITER //
create EVENT LegacyProducts
    ON SCHEDULE
   EVERY 1 WEEK
  STARTS CURRENT_DATE + INTERVAL 6 - WEEKDAY(CURRENT_DATE) DAY + INTERVAL 23 HOUR  
    DO
      UPDATE northwind.products set LegacyProduct=true where northwind.products.ProductID in (SELECT * from( select

        northwind.order_details.ProductID AS productid
  
    FROM
        ((northwind.orders
        JOIN northwind.order_details ON ((northwind.order_details.OrderID = northwind.orders.OrderID)))
        JOIN northwind.products ON ((northwind.products.ProductID = northwind.order_details.ProductID)))
    WHERE
        (northwind.orders.OrderDate not BETWEEN CURDATE() AND (CURDATE()- INTERVAL 1 YEAR))
        group by northwind.order_details.ProductID)tbl);

DELIMITER ;












