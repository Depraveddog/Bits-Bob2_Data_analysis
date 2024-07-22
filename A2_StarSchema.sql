-- Create the Dim_Time dimension table
CREATE TABLE Dim_Time (
    Sales_Date DATE PRIMARY KEY,
    Day INT,
    Month INT,
    Year INT
);

-- Insert distinct date values into the Dim_Time table
INSERT INTO Dim_Time (Sales_Date)
SELECT DISTINCT Sales_Date
FROM Clean_Data;


-- Populate the Day, Month, and Year columns
UPDATE Dim_Time
SET Day = DAY(Sales_Date),
    Month = MONTH(Sales_Date),
    Year = YEAR(Sales_Date);



-- Create the Dim_Customer dimension table
CREATE TABLE Dim_Customer (
    customerId varchar(50)PRIMARY KEY,
    name VARCHAR(255),
    surname VARCHAR(255)
);

-- Insert distinct customer IDs into the Dim_Customer table
INSERT INTO Dim_Customer (customerId)
SELECT DISTINCT [Customer_ID]
FROM [Clean_Data];

-- Update the Dim_Customer table with customer details
UPDATE Dim_Customer
SET
name = [Customer_First_Name],
surname = [Customer_Surname]
FROM Dim_Customer
JOIN [Clean_Data] ON Dim_Customer.customerId = [Clean_Data].[Customer_ID];



-- Create the Dim_Office dimension table
CREATE TABLE Dim_Office (
    officeId INT PRIMARY KEY,
    location VARCHAR(255)
);


-- Insert distinct office data into the Dim_Office table
INSERT INTO Dim_Office (officeId, location)
SELECT DISTINCT [Staff_office], [Office_Location]
FROM [Clean_Data];


-- Create the Dim_Staff dimension table
CREATE TABLE Dim_Staff (
    staffId VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255),
    surname VARCHAR(255)
);

INSERT INTO Dim_Staff(staffId, name, surname)
SELECT DISTINCT [Staff_ID], [Staff_First_Name],[Staff_Surname]
FROM [Clean_Data];


-- Create the Dim_Item dimension table
CREATE TABLE Dim_Item (
    itemId INT PRIMARY KEY,
    description VARCHAR(255)
);

INSERT INTO Dim_Item(itemId, description)
SELECT DISTINCT [Item_ID], [Item_Description]
FROM [Clean_Data];


-- Create the Fact_Sales table
CREATE TABLE Fact_Sales (
    factSalesId INT PRIMARY KEY IDENTITY(1,1),
    customerId VARCHAR(50) FOREIGN KEY REFERENCES Dim_Customer(customerId),
    sales_date date FOREIGN KEY REFERENCES Dim_Time(Sales_Date),
    officeId INT FOREIGN KEY REFERENCES Dim_Office(officeId),
    staffId varchar(50) FOREIGN KEY REFERENCES Dim_Staff(staffId),
    itemId INT FOREIGN KEY REFERENCES Dim_Item(itemId),
    receiptId VARCHAR(50),
    transaction_Row INT,
    item_Price DECIMAL(18, 2),
    quantity INT,
    discounted_Row_Total DECIMAL(18, 3),
    row_total DECIMAL(18, 2)
);


-- Insert sales data into the Fact_Sales table
INSERT INTO Fact_Sales (customerId, sales_date, officeId, staffId, itemId, receiptId, transaction_Row, item_Price, quantity, row_total)
SELECT
    Dim_Customer.customerId,
    Dim_Time.Sales_Date,
    Dim_Office.officeId,
    Dim_Staff.staffId,
    Dim_Item.itemId,
	[Reciept_Id],
    [Reciept_Transaction_Row_ID],
    [Item_Price],
    [Item_Quantity],
    [Row_Total]
FROM [Clean_Data]
JOIN Dim_Customer ON Dim_Customer.customerId = [Clean_Data].[Customer_ID]
JOIN Dim_Time ON Dim_Time.Sales_Date = [Clean_Data].[Sales_Date] -- Replace with the appropriate date key
JOIN Dim_Office ON Dim_Office.officeId = [Clean_Data].[Staff_office]
JOIN Dim_Staff ON Dim_Staff.staffId = [Clean_Data].[Staff_ID]
JOIN Dim_Item ON Dim_Item.itemId = [Clean_Data].[Item_ID];

UPDATE [A2_Dirty].[dbo].[Fact_Sales] 
SET discounted_Row_Total = 
    CASE
        WHEN [receiptId] IN (
            SELECT [receiptId]
            FROM [A2_Dirty].[dbo].[Fact_Sales]
            GROUP BY [receiptId]
            HAVING COUNT(DISTINCT [itemId]) > 4
        )
        THEN fs.Item_Price * fs.Quantity * (1 - 0.05) -- 5% discount for customers with more than 4 distinct items
        ELSE fs.Item_Price * fs.Quantity -- No discount for others
    END
FROM [A2_Dirty].[dbo].[Fact_Sales] AS fs;
