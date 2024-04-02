-- usuniecie bazy
--DROP DATABASE "DBProject";

-- stworzenie bazy
--CREATE DATABASE "DBProject";
USE DBProject;

-- Usuniêcie tabel, jeœli istniej¹
DROP TABLE IF EXISTS Reports;
DROP TABLE IF EXISTS Feedback;
DROP TABLE IF EXISTS ShippingDetails;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Bids;
DROP TABLE IF EXISTS Wishlist;
DROP TABLE IF EXISTS Items;
DROP TABLE IF EXISTS Categories;
DROP TABLE IF EXISTS RegistrationInfo
DROP TABLE IF EXISTS Users;

-- utworzenie tabel
CREATE TABLE Users (
  userid INTEGER PRIMARY KEY IDENTITY(1,1),
  username VARCHAR(64) UNIQUE NOT NULL,
  CHECK (username LIKE '%[a-zA-Z0-9]%' AND username NOT LIKE '%[^a-zA-Z0-9]%'),
  [password] VARCHAR(64) NOT NULL,
  email VARCHAR(64) UNIQUE NOT NULL,
  CHECK (email LIKE '%@%' AND email NOT LIKE '%[^a-zA-Z0-9@._-]%'),
  address VARCHAR(255) NOT NULL,
  account_number INTEGER NOT NULL,
)

CREATE TABLE RegistrationInfo (
  userid INTEGER PRIMARY KEY,
  username VARCHAR(64) NOT NULL,
  created_at DATETIME DEFAULT GETDATE()
)

CREATE TABLE Categories (
  categoryid INTEGER PRIMARY KEY IDENTITY (1,1),
  categoryname VARCHAR(64) UNIQUE NOT NULL,
  [description] VARCHAR(256)
)

CREATE TABLE Items (
  itemid INTEGER PRIMARY KEY IDENTITY (1,1),
  sellerid INTEGER NOT NULL REFERENCES Users (userid) ON DELETE CASCADE,
  categoryid INTEGER REFERENCES Categories (categoryid),
  itemname VARCHAR(128) NOT NULL,
  [description] VARCHAR(256),
  start_price MONEY NOT NULL,
  win_bid INTEGER DEFAULT NULL, -- trzeba to jakos rozkminic bedzie
  buy_now MONEY NOT NULL,
  CHECK (buy_now > start_price),
  [availability] BIT NOT NULL DEFAULT 1,
  begins_at DATETIME,
  closed_at DATETIME
)

CREATE TABLE Wishlist (
  userid INTEGER NOT NULL REFERENCES Users (userid),
  itemid INTEGER NOT NULL REFERENCES Items (itemid) ON DELETE CASCADE,
  PRIMARY KEY (userid, itemid)
)

CREATE TABLE Bids (
  bidid INTEGER PRIMARY KEY IDENTITY (1,1),
  bidderid INTEGER NOT NULL REFERENCES Users (userid),
  itemid INTEGER NOT NULL REFERENCES Items (itemid) ON DELETE CASCADE,
  bidamount MONEY NOT NULL,
  created_at DATETIME
)

CREATE TABLE Orders (
  orderid INTEGER PRIMARY KEY IDENTITY (1,1),
  bidid INTEGER NOT NULL REFERENCES Bids (bidid) ON DELETE CASCADE,
  [status] VARCHAR(32) NOT NULL
)

CREATE TABLE ShippingDetails (
  orderid INTEGER REFERENCES Orders (orderid) ON DELETE CASCADE PRIMARY KEY,
  [status] VARCHAR(32) NOT NULL
)

CREATE TABLE Feedback (
  orderid INTEGER NOT NULL REFERENCES Orders (orderid) ON DELETE CASCADE,
  aboutwhom VARCHAR(10) NOT NULL,
  CHECK (aboutwhom = N'bidder' OR aboutwhom = N'seller'),
  rating INTEGER NOT NULL
  CHECK (rating BETWEEN 1 AND 10),
  comment VARCHAR(256),
  PRIMARY KEY(orderid, aboutwhom)
);

CREATE TABLE Reports (
  reportid INTEGER PRIMARY KEY IDENTITY (1,1),
  userid INTEGER REFERENCES Users (userid),
  [description] VARCHAR(512) NOT NULL,
  created_at DATETIME
)


GO
-- funkcja dla podanego u¿ytkownika zwraca tabelê przedmiotów na jego liœcie ¿yczeñ
CREATE OR ALTER FUNCTION GetUserWishlist
(
@userId INT
)
RETURNS TABLE
AS
RETURN (
    SELECT i.itemid, i.itemname, i.description, i.start_price, i.buy_now
    FROM Wishlist w
    INNER JOIN Items i ON w.itemid = i.itemid
    WHERE w.userid = @userId
);

GO
-- funkcja dla podanych danych logowania zwraca 1 dla poprawnych lub 0 dla b³êdnych danych
CREATE OR ALTER FUNCTION CheckLoginCredentials
(
    @username VARCHAR(64),
    @password VARCHAR(64)
)
RETURNS BIT
AS
BEGIN
    DECLARE @isValid BIT;

    IF EXISTS (
        SELECT 1 
        FROM Users 
        WHERE username = @username AND [password] = @password
    )
    BEGIN
        SET @isValid = 1; -- poprawne dane logowania
    END
    ELSE
    BEGIN
        SET @isValid = 0; -- niepoprawne dane logowania
    END

    RETURN @isValid;
END;
GO
-- procedura korzystaj¹ca z funkcji CheckLoginCredentials, wypisuje odpowiedni komunikat w zale¿noœci od poprawnoœci danych
CREATE OR ALTER PROCEDURE CheckLoginProcedure
    @username VARCHAR(64),
    @password VARCHAR(64)
AS
BEGIN
    DECLARE @isValid BIT;
    SET @isValid = dbo.CheckLoginCredentials(@username, @password);

    IF @isValid = 1
    BEGIN
        PRINT 'Poprawne dane logowania.';
    END
    ELSE
    BEGIN
        PRINT 'Niepoprawne dane logowania.';
    END
END;

GO
-- funkcja wypisuje dostêpne przedmioty z podanej kategorii (wg nazwy)
CREATE OR ALTER FUNCTION GetItemsByCategory
(
    @categoryName VARCHAR(64)
)
RETURNS TABLE
AS
RETURN (
    SELECT i.itemid, i.itemname, i.description, i.start_price, i.buy_now
    FROM Items i
    INNER JOIN Categories c ON i.categoryid = c.categoryid
    WHERE c.categoryname = @categoryName
);

GO
-- widok pokazuje dane tylko dostêpnych itemów (availability = 1)
CREATE OR ALTER VIEW AvailableItems AS
SELECT 
    itemid,
	categoryid,
    itemname, 
    description, 
    start_price, 
	CASE
        WHEN win_bid IS NULL THEN NULL
        ELSE (SELECT MAX(bidamount) FROM Bids WHERE Bids.bidid = Items.win_bid)
    END AS curr_price,
    buy_now
FROM Items
WHERE availability = 1;


GO
--widok wypisuj¹cy ka¿d¹ kategoriê oraz iloœæ dostêpnych itemów które do niej nale¿¹
CREATE OR ALTER VIEW ItemsCountByCategory AS
SELECT c.categoryname, COUNT(i.itemid) AS items_count
FROM Categories c
LEFT JOIN AvailableItems i ON c.categoryid = i.categoryid
GROUP BY c.categoryname;
GO
-- widok obliczaj¹cy rating wybranego sprzedawcy
CREATE OR ALTER FUNCTION CalculateSellerRating(@sellerId INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @AverageRating FLOAT;

    SELECT @AverageRating = AVG(CAST(rating AS FLOAT))
    FROM Feedback
    WHERE orderid IN (
        SELECT orderid
        FROM Orders
        WHERE bidid IN (
            SELECT bidid
            FROM Bids
            WHERE itemid IN (
                SELECT itemid
                FROM Items
                WHERE sellerid = @sellerId
            )
        )
    ) AND aboutwhom = 'seller';

    RETURN ISNULL(@AverageRating, 0);
END;

GO
-- widok obliczaj¹cy rating wybranego kupuj¹cego
CREATE OR ALTER FUNCTION CalculateBidderRating(@bidderId INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @AverageRating FLOAT;

    SELECT @AverageRating = AVG(CAST(rating AS FLOAT))
    FROM Feedback
    WHERE orderid IN (
        SELECT orderid
        FROM Orders
        WHERE bidid IN (
            SELECT bidid
            FROM Bids
            WHERE bidderid = @bidderId
        )
    ) AND aboutwhom = 'bidder';

    RETURN ISNULL(@AverageRating, 0);
END;

GO
-- widok, który wypisuje wszystkich sprzedawców, który otrzymali opiniê wraz z ich œrednim ratingiem
CREATE OR ALTER VIEW SellerRatings AS
SELECT 
    u.userid AS SellerId,
    u.username AS SellerName,
    dbo.CalculateSellerRating(u.userid) AS Rating
FROM 
    Users u
WHERE 
    EXISTS (
        SELECT 1
        FROM Orders o
        JOIN Bids b ON o.bidid = b.bidid
        JOIN Items i ON b.itemid = i.itemid
        WHERE i.sellerid = u.userid
    );


GO
-- widok, który wypisuje wszystkich kupuj¹cych, który otrzymali opiniê wraz z ich œrednim ratingiem
CREATE OR ALTER VIEW BidderRatings AS
SELECT 
    u.userid AS BidderId,
    u.username AS BidderName,
    dbo.CalculateBidderRating(u.userid) AS Rating
FROM 
    Users u
WHERE 
    EXISTS (
        SELECT 1
        FROM Orders o
        JOIN Bids b ON o.bidid = b.bidid
        WHERE b.bidderid = u.userid
    );


GO
-- widok modyfikuj¹cy najwy¿sz¹ ofertê dla itemu, je¿eli pojawi siê wy¿sza ni¿ aktualnie najwy¿sza
CREATE TRIGGER UpdateMaxBid
ON Bids
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted INNER JOIN Items ON Items.itemid = inserted.itemid WHERE Items.availability = 1)
    BEGIN
        UPDATE Items
        SET win_bid = inserted.bidid
        FROM Items
        INNER JOIN inserted ON Items.itemid = inserted.itemid
        WHERE Items.availability = 1
        AND (Items.win_bid IS NULL OR (SELECT bidamount FROM Bids WHERE bidid = Items.win_bid) < (SELECT bidamount FROM inserted WHERE bidid = inserted.bidid));
    END;
END;

GO
-- widok sprawdzaj¹cy czy nowo wp³ywaj¹ca oferta przekroczy³a cenê zakupu teraz i przekazuj¹ca item do realizacji, je¿eli tak
CREATE TRIGGER Trigger_CheckBuyNow
ON Bids
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Sprawdzenie, czy wystêpuj¹ nowe wiersze w tabeli Bids
    IF EXISTS(SELECT 1 FROM inserted)
    BEGIN
        -- Aktualizacja ceny oferty na cenê "kup teraz" dla bida, który osi¹gn¹³ lub przekroczy³ cenê "kup teraz"
        UPDATE Bids
        SET Bidamount = Items.buy_now
        FROM Bids
        INNER JOIN inserted i ON Bids.bidid = i.bidid
        INNER JOIN Items ON Bids.itemid = Items.itemid
        WHERE Items.buy_now <= i.bidamount AND Items.availability = 1;

		-- Aktualizacja dostêpnoœci i ceny wygrywaj¹cej dla ka¿dego nowego bida
        UPDATE Items
        SET availability = 0,
            win_bid = i.bidid
        FROM Items
        INNER JOIN inserted i ON Items.itemid = i.itemid
        WHERE Items.buy_now <= i.bidamount AND Items.availability = 1;
    END;
END;

GO
-- je¿eli item jest przekazany do realizacji to trigger utworzy zamówienie w orders
CREATE TRIGGER Trigger_CreatePaymentOnAvailabilityChange
ON Items
AFTER UPDATE
AS
BEGIN
    IF UPDATE(availability) -- SprawdŸ, czy wartoœæ availability zosta³a zmieniona
    BEGIN
        DECLARE @itemid INT;
        DECLARE @win_bid INT;

        SELECT @itemid = itemid, @win_bid = win_bid FROM inserted;

        -- Jeœli availability zmieni³o siê na 0, utwórz rekord w tabeli Orders
        IF (SELECT availability FROM inserted) = 0 AND @win_bid IS NOT NULL
        BEGIN
            INSERT INTO Orders (bidid, [status])
            VALUES (@win_bid, 'WAITING FOR PAYMENT');
        END;
    END;
END;

GO
-- je¿eli zamówienie jest potwierdzone to utworzy shipping
CREATE TRIGGER Trigger_OrderConfirmed
ON Orders
AFTER UPDATE
AS
BEGIN
    IF UPDATE([status])
    BEGIN
        DECLARE @orderId INT;
        DECLARE @status VARCHAR(32);

        SELECT @orderId = inserted.orderid, @status = inserted.status
        FROM inserted;

        IF @status = 'CONFIRMED'
        BEGIN
            INSERT INTO ShippingDetails (orderid, [status])
            VALUES (@orderId, 'IN PROGRESS');
        END;
    END;
END;

GO
-- je¿eli shipping bêdzie potwierdzony to zamówienie zostanie zakoñczone
CREATE TRIGGER Trigger_UpdateOrdersStatus
ON ShippingDetails
AFTER UPDATE
AS
BEGIN
    IF UPDATE(status)
    BEGIN
        UPDATE Orders
        SET [status] = 'FINISHED'
        FROM Orders o
        INNER JOIN inserted i ON o.orderid = i.orderid
        WHERE i.[status] = 'FINISHED';
    END
END;

GO
-- dla nowo stworzonego konta zapisze informacjê o rejestracji w bazie 
CREATE TRIGGER Trigger_CreateUserRegistrationInfoTrigger
ON Users
AFTER INSERT
AS
BEGIN
    -- Wstawianie danych do tabeli RegistrationInfo po wstawieniu danych do tabeli Users
    INSERT INTO RegistrationInfo (userid, username)
    SELECT userid, username FROM inserted;
END;
GO
-- procedura tworz¹ca nowego u¿ytkownika na podstawie podanych danych i wyœwietlaj¹ca odpowiednie komunikaty/b³êdy
CREATE OR ALTER PROCEDURE CreateUser
    @username VARCHAR(64),
    @password VARCHAR(64),
    @email VARCHAR(64),
    @address VARCHAR(255),
    @account_number INT
AS
BEGIN
    SET NOCOUNT ON;

    -- SprawdŸ, czy podane dane s¹ poprawne
    IF @username IS NULL OR @password IS NULL OR @email IS NULL OR @address IS NULL OR @account_number IS NULL
    BEGIN
        RAISERROR('Wszystkie pola s¹ wymagane.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Users WHERE username = @username)
    BEGIN
        -- Wstaw nowego u¿ytkownika do tabeli Users
        INSERT INTO Users (username, [password], email, address, account_number)
        VALUES (@username, @password, @email, @address, @account_number);

        PRINT 'Konto zosta³o pomyœlnie utworzone.';
    END
    ELSE
    BEGIN
        RAISERROR('Nazwa u¿ytkownika jest ju¿ zajêta.', 16, 1);
        RETURN;
    END
END
GO
-- procedura umo¿liwiaj¹ca u¿ytkownikowi z³o¿enie zg³oszenia
CREATE OR ALTER PROCEDURE CreateReport
    @userid INT,
    @description VARCHAR(512)
AS
BEGIN
    SET NOCOUNT ON;

    -- SprawdŸ, czy u¿ytkownik istnieje
    IF NOT EXISTS (SELECT 1 FROM Users WHERE userid = @userid)
    BEGIN
        RAISERROR('U¿ytkownik o podanym ID nie istnieje.', 16, 1);
        RETURN;
    END

    -- Wstaw nowy raport do tabeli Reports
    INSERT INTO Reports (userid, [description], created_at)
    VALUES (@userid, @description, GETDATE());

    PRINT 'Raport zosta³ pomyœlnie zg³oszony.';
END
GO
-- procedura umo¿liwiaj¹ca u¿ytkownikowi z³o¿enie opinie o sprzedawcy/kupuj¹cym na podstawie zakoñczonego zamówienia
CREATE OR ALTER PROCEDURE SubmitFeedback
    @orderid INTEGER,
    @aboutwhom VARCHAR(10),
    @rating INTEGER,
    @comment VARCHAR(256) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- SprawdŸ, czy zamówienie istnieje i ma status 'FINISHED'
    IF EXISTS (SELECT 1 FROM Orders WHERE orderid = @orderid AND status = 'FINISHED')
    BEGIN
        -- SprawdŸ, czy ocena mieœci siê w zakresie 1-10
        IF @rating BETWEEN 1 AND 10
        BEGIN
            -- SprawdŸ, czy 'aboutwhom' jest poprawn¹ wartoœci¹ ('bidder' lub 'seller')
            IF @aboutwhom IN ('bidder', 'seller')
            BEGIN
                -- Wstaw nowy feedback do tabeli Feedback
                INSERT INTO Feedback (orderid, aboutwhom, rating, comment)
                VALUES (@orderid, @aboutwhom, @rating, @comment);

                PRINT 'Opinia zosta³a pomyœlnie dodana.';
            END
            ELSE
            BEGIN
                RAISERROR('Nieprawid³owa wartoœæ parametru @aboutwhom. Dozwolone wartoœci to ''bidder'' lub ''seller''.', 16, 1);
                RETURN;
            END
        END
        ELSE
        BEGIN
            RAISERROR('Ocena musi byæ liczb¹ ca³kowit¹ z zakresu od 1 do 10.', 16, 1);
            RETURN;
        END
    END
    ELSE
    BEGIN
        RAISERROR('Zamówienie o podanym ID nie istnieje lub ma status inny ni¿ ''FINISHED''.', 16, 1);
        RETURN;
    END
END
GO
-- funkcja wypisuj¹ca zamówienia wybranego u¿ytkownika
CREATE OR ALTER FUNCTION GetUserOrders
(
    @userId INT
)
RETURNS TABLE
AS
RETURN (
    SELECT o.orderid, o.status
    FROM Orders o
    INNER JOIN Bids b ON o.bidid = b.bidid
    INNER JOIN Items i ON b.itemid = i.itemid
    WHERE i.sellerid = @userId
);
GO
-- procedura dodaj¹ca nowy item do listy itemów
CREATE OR ALTER PROCEDURE AddNewItem
(
    @sellerId INT,
    @categoryId INT,
    @itemName VARCHAR(128),
    @description VARCHAR(256),
    @startPrice MONEY,
    @buyNowPrice MONEY,
    @beginsAt DATETIME,
    @closedAt DATETIME
)
AS
BEGIN
    INSERT INTO Items (sellerid, categoryid, itemname, [description], start_price, buy_now, begins_at, closed_at)
    VALUES (@sellerId, @categoryId, @itemName, @description, @startPrice, @buyNowPrice, @beginsAt, @closedAt);
    PRINT 'Nowy przedmiot zosta³ dodany do aukcji.';
END;