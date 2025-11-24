IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'PinterestClone')
BEGIN
    CREATE DATABASE PinterestClone;
END
GO

USE PinterestClone;
GO

IF OBJECT_ID('Board_Collaborators', 'U') IS NOT NULL DROP TABLE Board_Collaborators;
IF OBJECT_ID('Pin_Tags', 'U') IS NOT NULL DROP TABLE Pin_Tags;
IF OBJECT_ID('Pin_Saves', 'U') IS NOT NULL DROP TABLE Pin_Saves;
IF OBJECT_ID('Board_Pins', 'U') IS NOT NULL DROP TABLE Board_Pins;
IF OBJECT_ID('Comments', 'U') IS NOT NULL DROP TABLE Comments;
IF OBJECT_ID('User_Follows', 'U') IS NOT NULL DROP TABLE User_Follows;
IF OBJECT_ID('Pins', 'U') IS NOT NULL DROP TABLE Pins;
IF OBJECT_ID('Boards', 'U') IS NOT NULL DROP TABLE Boards;
IF OBJECT_ID('Tags', 'U') IS NOT NULL DROP TABLE Tags;
IF OBJECT_ID('Categories', 'U') IS NOT NULL DROP TABLE Categories;
IF OBJECT_ID('Users', 'U') IS NOT NULL DROP TABLE Users;
GO

CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    profile_picture VARCHAR(500) NULL,
    bio TEXT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    follower_count INT DEFAULT 0,
    following_count INT DEFAULT 0
);

CREATE TABLE Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT NULL
);

CREATE TABLE Tags (
    tag_id INT IDENTITY(1,1) PRIMARY KEY,
    tag_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Boards (
    board_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    board_name VARCHAR(100) NOT NULL,
    description TEXT NULL,
    is_private BIT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),
    pin_count INT DEFAULT 0,
    CONSTRAINT FK_Boards_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE
);

CREATE TABLE Pins (
    pin_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    category_id INT NULL,
    image_url VARCHAR(500) NOT NULL,
    title VARCHAR(255) NULL,
    description TEXT NULL,
    source_url VARCHAR(500) NULL,
    created_at DATETIME DEFAULT GETDATE(),
    save_count INT DEFAULT 0,
    view_count INT DEFAULT 0,
    click_count INT DEFAULT 0,
    CONSTRAINT FK_Pins_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    CONSTRAINT FK_Pins_Categories FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE SET NULL
);

CREATE TABLE Comments (
    comment_id INT IDENTITY(1,1) PRIMARY KEY,
    pin_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Comments_Pins FOREIGN KEY (pin_id) REFERENCES Pins(pin_id) ON DELETE CASCADE,
    CONSTRAINT FK_Comments_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE NO ACTION
);

CREATE TABLE User_Follows (
    follow_id INT IDENTITY(1,1) PRIMARY KEY,
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_UserFollows_Follower FOREIGN KEY (follower_id) REFERENCES Users(user_id) ON DELETE NO ACTION,
    CONSTRAINT FK_UserFollows_Following FOREIGN KEY (following_id) REFERENCES Users(user_id) ON DELETE NO ACTION,
    CONSTRAINT UQ_UserFollows UNIQUE (follower_id, following_id),
    CONSTRAINT CHK_NoSelfFollow CHECK (follower_id <> following_id)
);

CREATE TABLE Board_Pins (
    board_pin_id INT IDENTITY(1,1) PRIMARY KEY,
    board_id INT NOT NULL,
    pin_id INT NOT NULL,
    added_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_BoardPins_Boards FOREIGN KEY (board_id) REFERENCES Boards(board_id) ON DELETE CASCADE,
    CONSTRAINT FK_BoardPins_Pins FOREIGN KEY (pin_id) REFERENCES Pins(pin_id) ON DELETE NO ACTION,
    CONSTRAINT UQ_BoardPins UNIQUE (board_id, pin_id)
);

CREATE TABLE Pin_Tags (
    pin_tag_id INT IDENTITY(1,1) PRIMARY KEY,
    pin_id INT NOT NULL,
    tag_id INT NOT NULL,
    CONSTRAINT FK_PinTags_Pins FOREIGN KEY (pin_id) REFERENCES Pins(pin_id) ON DELETE CASCADE,
    CONSTRAINT FK_PinTags_Tags FOREIGN KEY (tag_id) REFERENCES Tags(tag_id) ON DELETE CASCADE,
    CONSTRAINT UQ_PinTags UNIQUE (pin_id, tag_id)
);

CREATE TABLE Pin_Saves (
    save_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    pin_id INT NOT NULL,
    board_id INT NOT NULL,
    saved_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_PinSaves_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE NO ACTION,
    CONSTRAINT FK_PinSaves_Pins FOREIGN KEY (pin_id) REFERENCES Pins(pin_id) ON DELETE NO ACTION,
    CONSTRAINT FK_PinSaves_Boards FOREIGN KEY (board_id) REFERENCES Boards(board_id) ON DELETE NO ACTION,
    CONSTRAINT UQ_PinSaves UNIQUE (user_id, pin_id, board_id)
);

CREATE TABLE Board_Collaborators (
    collaborator_id INT IDENTITY(1,1) PRIMARY KEY,
    board_id INT NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(50) DEFAULT 'contributor',
    added_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_BoardCollabs_Boards FOREIGN KEY (board_id) REFERENCES Boards(board_id) ON DELETE CASCADE,
    CONSTRAINT FK_BoardCollabs_Users FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE NO ACTION,
    CONSTRAINT UQ_BoardCollabs UNIQUE (board_id, user_id)
);

CREATE INDEX IX_Pins_UserId ON Pins(user_id);
CREATE INDEX IX_Pins_CategoryId ON Pins(category_id);
CREATE INDEX IX_Pins_CreatedAt ON Pins(created_at DESC);
CREATE INDEX IX_Boards_UserId ON Boards(user_id);
CREATE INDEX IX_Comments_PinId ON Comments(pin_id);
CREATE INDEX IX_Comments_UserId ON Comments(user_id);
CREATE INDEX IX_UserFollows_FollowerId ON User_Follows(follower_id);
CREATE INDEX IX_UserFollows_FollowingId ON User_Follows(following_id);
CREATE INDEX IX_BoardPins_BoardId ON Board_Pins(board_id);
CREATE INDEX IX_BoardPins_PinId ON Board_Pins(pin_id);
CREATE INDEX IX_PinSaves_UserId ON Pin_Saves(user_id);
CREATE INDEX IX_PinSaves_PinId ON Pin_Saves(pin_id);
GO
