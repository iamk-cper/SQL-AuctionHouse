USE DBProject;
-- Uzupe³nienie tabeli Categories
INSERT INTO Categories (categoryname, [description])
VALUES 
    ('Electronics', 'Includes gadgets, appliances, and electronic devices'),
    ('Books', 'Various genres of books'),
    ('Clothing', 'Apparel and accessories'),
    ('Home & Garden', 'Items related to home decor and gardening'),
    ('Sports & Outdoors', 'Sporting goods and outdoor equipment');

-- Utworzenie kont przez u¿ytkowników
EXEC CreateUser 'johndoe', 'password123', 'john@example.com', '123 Main St, Anytown, USA', 12345678;
EXEC CreateUser 'janesmith', 'abc123', 'jane@example.com', '456 Oak St, Othertown, USA', 09876543;
EXEC CreateUser 'user3', 'pass456', 'user3@example.com', '789 Elm St, Anothertown, USA', 13579240;
EXEC CreateUser 'user4', 'pass789', 'user4@example.com', '101 Pine St, Somewhere, USA', 24681350;
EXEC CreateUser 'user5', 'passabc', 'user5@example.com', '202 Maple St, Nowhere, USA', 98765430;

-- Sprawdzenie danych logowania
EXEC CheckLoginProcedure 'user3', 'pass456'

-- Zg³oszenie raportu przez u¿ytkownika
EXEC CreateReport 1, [Hello, site doesn't work at all]
SELECT * FROM Reports

-- Uzupe³nienie tabeli Items przyk³adowymi ofertami
EXEC AddNewItem 1, 1, 'Smartphone', 'Brand new smartphone with latest features', 500.00, 600.00, '2024-02-15', '2024-03-15';
EXEC AddNewItem 1, 2, 'Python Programming Book', 'Comprehensive guide to Python programming language', 30.00, 40.00, '2024-02-15', '2024-03-01';
EXEC AddNewItem 3, 3, 'Men''s Jacket', 'Warm and stylish jacket for men', 80.00, 100.00, '2024-02-15', '2024-02-28';

-- Uzupe³nienie tabeli Bids, Bid nr2 powoduje zakup produktu (cena buy_now)
INSERT INTO Bids (bidderid, itemid, bidamount, created_at)
VALUES 
    (2, 1, 550.00, '2024-02-20'),
    (3, 2, 40.00, '2024-02-18'),
    (1, 3, 90.00, '2024-02-17');

-- Podbicie ceny
INSERT INTO Bids (bidderid, itemid, bidamount, created_at)
VALUES
	(3, 1, 560.00, '2024-02-21')

-- Uzupe³nienie tabeli Wishlist
INSERT INTO Wishlist (userid, itemid)
VALUES 
    (1, 2),
    (2, 3),
    (3, 1);

-- trigger nie aktualizuje, cena poni¿ej aktualnie najwy¿szej dla Itema
-- natomiast Bid znajduje siê w historii bidów (tabeli Bids)
INSERT INTO Bids (bidderid, itemid, bidamount, created_at)
VALUES
	(3, 1, 68.00, '2024-02-22')

-- przekroczenie ceny buy_now, cena zostanie zrównana do buy_now, a aukcja zakoñczona
INSERT INTO Bids (bidderid, itemid, bidamount, created_at)
VALUES
	(3, 1, 668.00, '2024-02-22')

-- przejœcie w stan CONFIRMED, uznaniowo zaakceptowanie p³atnoœci
UPDATE Orders
SET [status] = N'CONFIRMED'
WHERE orderid = 1

UPDATE Orders
SET [status] = N'CONFIRMED'
WHERE orderid = 2

-- potwierdzenie dostawy, trigger zmieni te¿ status zamówienia
UPDATE ShippingDetails
SET [status] = N'FINISHED'
WHERE orderid = 1 OR orderid = 2

-- przeslanie feedbackow o zamowieniach
EXEC SubmitFeedback @orderid = 1, @aboutwhom = 'seller', @rating = 3;
EXEC SubmitFeedback @orderid = 1, @aboutwhom = 'bidder', @rating = 10;
EXEC SubmitFeedback @orderid = 2, @aboutwhom = 'seller', @rating = 6;

SELECT * FROM Feedback
SELECT * FROM RegistrationInfo
SELECT * FROM SellerRatings ORDER BY Rating DESC;
SELECT * FROM GetUserWishlist(1)
SELECT * FROM AvailableItems
SELECT * FROM ItemsCountByCategory
SELECT * FROM Orders
SELECT * FROM ShippingDetails
SELECT * FROM GetUserOrders(1)