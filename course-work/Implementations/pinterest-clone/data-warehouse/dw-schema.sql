IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PinterestCloneDW')
BEGIN
    CREATE DATABASE PinterestCloneDW;
END
GO

USE PinterestCloneDW;
GO

IF OBJECT_ID('Fact_Pin_Activity', 'U') IS NOT NULL DROP TABLE Fact_Pin_Activity;
IF OBJECT_ID('Fact_User_Engagement', 'U') IS NOT NULL DROP TABLE Fact_User_Engagement;
IF OBJECT_ID('Fact_Board_Performance', 'U') IS NOT NULL DROP TABLE Fact_Board_Performance;
IF OBJECT_ID('Dim_User', 'U') IS NOT NULL DROP TABLE Dim_User;
IF OBJECT_ID('Dim_Pin', 'U') IS NOT NULL DROP TABLE Dim_Pin;
IF OBJECT_ID('Dim_Board', 'U') IS NOT NULL DROP TABLE Dim_Board;
IF OBJECT_ID('Dim_Category', 'U') IS NOT NULL DROP TABLE Dim_Category;
IF OBJECT_ID('Dim_Date', 'U') IS NOT NULL DROP TABLE Dim_Date;
IF OBJECT_ID('Dim_Location', 'U') IS NOT NULL DROP TABLE Dim_Location;
GO

CREATE TABLE Dim_User (
    user_key INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    registration_date DATE NOT NULL,
    is_active BIT DEFAULT 1,
    valid_from DATETIME DEFAULT GETDATE(),
    valid_to DATETIME NULL
);

CREATE TABLE Dim_Pin (
    pin_key INT IDENTITY(1,1) PRIMARY KEY,
    pin_id INT NOT NULL,
    title VARCHAR(255) NULL,
    category_name VARCHAR(100) NULL,
    creator_username VARCHAR(50) NOT NULL,
    created_date DATE NOT NULL,
    has_source_url BIT DEFAULT 0
);

CREATE TABLE Dim_Board (
    board_key INT IDENTITY(1,1) PRIMARY KEY,
    board_id INT NOT NULL,
    board_name VARCHAR(100) NOT NULL,
    owner_username VARCHAR(50) NOT NULL,
    is_private BIT DEFAULT 0,
    created_date DATE NOT NULL
);

CREATE TABLE Dim_Category (
    category_key INT IDENTITY(1,1) PRIMARY KEY,
    category_id INT NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    description VARCHAR(500) NULL,
    pin_count INT DEFAULT 0
);

CREATE TABLE Dim_Date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter INT NOT NULL,
    year INT NOT NULL,
    day_of_week VARCHAR(15) NOT NULL,
    is_weekend BIT DEFAULT 0
);

CREATE TABLE Dim_Location (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NULL,
    region VARCHAR(100) NULL,
    timezone VARCHAR(50) NULL,
    country_code VARCHAR(3) NULL
);

CREATE TABLE Fact_Pin_Activity (
    activity_key INT IDENTITY(1,1) PRIMARY KEY,
    pin_key INT NOT NULL,
    user_key INT NOT NULL,
    date_key INT NOT NULL,
    category_key INT NULL,
    view_count INT DEFAULT 0,
    save_count INT DEFAULT 0,
    click_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    CONSTRAINT FK_FPA_Pin FOREIGN KEY (pin_key) REFERENCES Dim_Pin(pin_key),
    CONSTRAINT FK_FPA_User FOREIGN KEY (user_key) REFERENCES Dim_User(user_key),
    CONSTRAINT FK_FPA_Date FOREIGN KEY (date_key) REFERENCES Dim_Date(date_key),
    CONSTRAINT FK_FPA_Category FOREIGN KEY (category_key) REFERENCES Dim_Category(category_key)
);

CREATE TABLE Fact_User_Engagement (
    engagement_key INT IDENTITY(1,1) PRIMARY KEY,
    user_key INT NOT NULL,
    date_key INT NOT NULL,
    location_key INT NULL,
    pins_created INT DEFAULT 0,
    boards_created INT DEFAULT 0,
    pins_saved INT DEFAULT 0,
    comments_made INT DEFAULT 0,
    new_followers INT DEFAULT 0,
    engagement_score DECIMAL(10,2) DEFAULT 0,
    CONSTRAINT FK_FUE_User FOREIGN KEY (user_key) REFERENCES Dim_User(user_key),
    CONSTRAINT FK_FUE_Date FOREIGN KEY (date_key) REFERENCES Dim_Date(date_key),
    CONSTRAINT FK_FUE_Location FOREIGN KEY (location_key) REFERENCES Dim_Location(location_key)
);

CREATE TABLE Fact_Board_Performance (
    performance_key INT IDENTITY(1,1) PRIMARY KEY,
    board_key INT NOT NULL,
    user_key INT NOT NULL,
    date_key INT NOT NULL,
    total_pins INT DEFAULT 0,
    pins_added INT DEFAULT 0,
    collaborators_count INT DEFAULT 0,
    total_saves INT DEFAULT 0,
    avg_pin_saves DECIMAL(10,2) DEFAULT 0,
    CONSTRAINT FK_FBP_Board FOREIGN KEY (board_key) REFERENCES Dim_Board(board_key),
    CONSTRAINT FK_FBP_User FOREIGN KEY (user_key) REFERENCES Dim_User(user_key),
    CONSTRAINT FK_FBP_Date FOREIGN KEY (date_key) REFERENCES Dim_Date(date_key)
);

CREATE INDEX IX_FPA_Pin ON Fact_Pin_Activity(pin_key);
CREATE INDEX IX_FPA_User ON Fact_Pin_Activity(user_key);
CREATE INDEX IX_FPA_Date ON Fact_Pin_Activity(date_key);
CREATE INDEX IX_FPA_Category ON Fact_Pin_Activity(category_key);
CREATE INDEX IX_FUE_User ON Fact_User_Engagement(user_key);
CREATE INDEX IX_FUE_Date ON Fact_User_Engagement(date_key);
CREATE INDEX IX_FBP_Board ON Fact_Board_Performance(board_key);
CREATE INDEX IX_FBP_User ON Fact_Board_Performance(user_key);
CREATE INDEX IX_FBP_Date ON Fact_Board_Performance(date_key);
GO

DECLARE @StartDate DATE = '2024-01-01';
DECLARE @EndDate DATE = '2024-12-31';
DECLARE @CurrentDate DATE = @StartDate;

WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO Dim_Date (date_key, full_date, day, month, month_name, quarter, year, day_of_week, is_weekend)
    VALUES (
        CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT),
        @CurrentDate,
        DAY(@CurrentDate),
        MONTH(@CurrentDate),
        DATENAME(MONTH, @CurrentDate),
        DATEPART(QUARTER, @CurrentDate),
        YEAR(@CurrentDate),
        DATENAME(WEEKDAY, @CurrentDate),
        CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END
    );
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END
GO

INSERT INTO Dim_Location (country, city, region, timezone, country_code) VALUES
('Bulgaria', 'Sofia', 'Sofia-City', 'Europe/Sofia', 'BG'),
('Bulgaria', 'Plovdiv', 'Plovdiv', 'Europe/Sofia', 'BG'),
('Bulgaria', 'Varna', 'Varna', 'Europe/Sofia', 'BG'),
('Bulgaria', 'Burgas', 'Burgas', 'Europe/Sofia', 'BG'),
('Germany', 'Berlin', 'Berlin', 'Europe/Berlin', 'DE'),
('Germany', 'Munich', 'Bavaria', 'Europe/Berlin', 'DE'),
('United Kingdom', 'London', 'England', 'Europe/London', 'GB'),
('United States', 'New York', 'New York', 'America/New_York', 'US'),
('United States', 'Los Angeles', 'California', 'America/Los_Angeles', 'US'),
('Unknown', 'Unknown', 'Unknown', 'UTC', 'XX');
GO

INSERT INTO Dim_Category (category_id, category_name, description, pin_count)
SELECT category_id, category_name, CAST(description AS VARCHAR(500)), 0
FROM PinterestClone.dbo.Categories;
GO

INSERT INTO Dim_User (user_id, username, email, registration_date, is_active)
SELECT user_id, username, email, CAST(created_at AS DATE), 1
FROM PinterestClone.dbo.Users;
GO

INSERT INTO Dim_Pin (pin_id, title, category_name, creator_username, created_date, has_source_url)
SELECT
    p.pin_id,
    p.title,
    c.category_name,
    u.username,
    CAST(p.created_at AS DATE),
    CASE WHEN p.source_url IS NOT NULL THEN 1 ELSE 0 END
FROM PinterestClone.dbo.Pins p
INNER JOIN PinterestClone.dbo.Users u ON p.user_id = u.user_id
LEFT JOIN PinterestClone.dbo.Categories c ON p.category_id = c.category_id;
GO

INSERT INTO Dim_Board (board_id, board_name, owner_username, is_private, created_date)
SELECT
    b.board_id,
    b.board_name,
    u.username,
    b.is_private,
    CAST(b.created_at AS DATE)
FROM PinterestClone.dbo.Boards b
INNER JOIN PinterestClone.dbo.Users u ON b.user_id = u.user_id;
GO

UPDATE Dim_Category
SET pin_count = (
    SELECT COUNT(*)
    FROM PinterestClone.dbo.Pins p
    WHERE p.category_id = Dim_Category.category_id
);
GO

INSERT INTO Fact_Pin_Activity (pin_key, user_key, date_key, category_key, view_count, save_count, click_count, comment_count)
SELECT
    dp.pin_key,
    du.user_key,
    CAST(FORMAT(p.created_at, 'yyyyMMdd') AS INT),
    dc.category_key,
    p.view_count,
    p.save_count,
    p.click_count,
    (SELECT COUNT(*) FROM PinterestClone.dbo.Comments c WHERE c.pin_id = p.pin_id)
FROM PinterestClone.dbo.Pins p
INNER JOIN Dim_Pin dp ON p.pin_id = dp.pin_id
INNER JOIN Dim_User du ON p.user_id = du.user_id
LEFT JOIN Dim_Category dc ON p.category_id = dc.category_id;
GO

INSERT INTO Fact_User_Engagement (user_key, date_key, location_key, pins_created, boards_created, pins_saved, comments_made, new_followers, engagement_score)
SELECT
    du.user_key,
    CAST(FORMAT(u.created_at, 'yyyyMMdd') AS INT),
    1,
    (SELECT COUNT(*) FROM PinterestClone.dbo.Pins p WHERE p.user_id = u.user_id),
    (SELECT COUNT(*) FROM PinterestClone.dbo.Boards b WHERE b.user_id = u.user_id),
    (SELECT COUNT(*) FROM PinterestClone.dbo.Pin_Saves ps WHERE ps.user_id = u.user_id),
    (SELECT COUNT(*) FROM PinterestClone.dbo.Comments c WHERE c.user_id = u.user_id),
    u.follower_count,
    PinterestClone.dbo.fn_GetUserEngagementScore(u.user_id)
FROM PinterestClone.dbo.Users u
INNER JOIN Dim_User du ON u.user_id = du.user_id;
GO

INSERT INTO Fact_Board_Performance (board_key, user_key, date_key, total_pins, pins_added, collaborators_count, total_saves, avg_pin_saves)
SELECT
    db.board_key,
    du.user_key,
    CAST(FORMAT(b.created_at, 'yyyyMMdd') AS INT),
    b.pin_count,
    b.pin_count,
    (SELECT COUNT(*) FROM PinterestClone.dbo.Board_Collaborators bc WHERE bc.board_id = b.board_id),
    (SELECT ISNULL(SUM(p.save_count), 0) FROM PinterestClone.dbo.Board_Pins bp
     INNER JOIN PinterestClone.dbo.Pins p ON bp.pin_id = p.pin_id WHERE bp.board_id = b.board_id),
    CASE WHEN b.pin_count > 0
         THEN (SELECT ISNULL(SUM(p.save_count), 0) FROM PinterestClone.dbo.Board_Pins bp
               INNER JOIN PinterestClone.dbo.Pins p ON bp.pin_id = p.pin_id WHERE bp.board_id = b.board_id) * 1.0 / b.pin_count
         ELSE 0 END
FROM PinterestClone.dbo.Boards b
INNER JOIN Dim_Board db ON b.board_id = db.board_id
INNER JOIN Dim_User du ON b.user_id = du.user_id;
GO
