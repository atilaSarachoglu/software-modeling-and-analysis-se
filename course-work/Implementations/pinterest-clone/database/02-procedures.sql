USE PinterestClone;
GO

IF OBJECT_ID('sp_SavePinToBoard', 'P') IS NOT NULL
    DROP PROCEDURE sp_SavePinToBoard;
GO

CREATE PROCEDURE sp_SavePinToBoard
    @user_id INT,
    @pin_id INT,
    @board_id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1 FROM Boards WHERE board_id = @board_id AND user_id = @user_id
            UNION
            SELECT 1 FROM Board_Collaborators WHERE board_id = @board_id AND user_id = @user_id
        )
        BEGIN
            RAISERROR('User does not have access to this board.', 16, 1);
            RETURN;
        END

        IF NOT EXISTS (SELECT 1 FROM Pins WHERE pin_id = @pin_id)
        BEGIN
            RAISERROR('Pin does not exist.', 16, 1);
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Pin_Saves WHERE user_id = @user_id AND pin_id = @pin_id AND board_id = @board_id)
        BEGIN
            RAISERROR('Pin already saved to this board.', 16, 1);
            RETURN;
        END

        INSERT INTO Pin_Saves (user_id, pin_id, board_id, saved_at)
        VALUES (@user_id, @pin_id, @board_id, GETDATE());

        IF NOT EXISTS (SELECT 1 FROM Board_Pins WHERE board_id = @board_id AND pin_id = @pin_id)
        BEGIN
            INSERT INTO Board_Pins (board_id, pin_id, added_at)
            VALUES (@board_id, @pin_id, GETDATE());

            UPDATE Boards SET pin_count = pin_count + 1 WHERE board_id = @board_id;
        END

        UPDATE Pins SET save_count = save_count + 1 WHERE pin_id = @pin_id;

        COMMIT TRANSACTION;

        SELECT 'Pin saved successfully!' AS Message;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END
GO

IF OBJECT_ID('fn_GetUserEngagementScore', 'FN') IS NOT NULL
    DROP FUNCTION fn_GetUserEngagementScore;
GO

CREATE FUNCTION fn_GetUserEngagementScore(@user_id INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @score DECIMAL(10, 2) = 0;
    DECLARE @pins_created INT;
    DECLARE @boards_created INT;
    DECLARE @comments_made INT;
    DECLARE @pins_saved INT;
    DECLARE @followers INT;
    DECLARE @total_pin_saves INT;

    SELECT @pins_created = COUNT(*) FROM Pins WHERE user_id = @user_id;
    SELECT @boards_created = COUNT(*) FROM Boards WHERE user_id = @user_id;
    SELECT @comments_made = COUNT(*) FROM Comments WHERE user_id = @user_id;
    SELECT @pins_saved = COUNT(*) FROM Pin_Saves WHERE user_id = @user_id;
    SELECT @followers = ISNULL(follower_count, 0) FROM Users WHERE user_id = @user_id;
    SELECT @total_pin_saves = ISNULL(SUM(save_count), 0) FROM Pins WHERE user_id = @user_id;

    SET @score = (@pins_created * 10.0) +
                 (@boards_created * 5.0) +
                 (@comments_made * 2.0) +
                 (@pins_saved * 1.0) +
                 (@followers * 3.0) +
                 (@total_pin_saves * 0.5);

    RETURN @score;
END
GO

IF OBJECT_ID('trg_UpdateFollowerCounts', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateFollowerCounts;
GO

CREATE TRIGGER trg_UpdateFollowerCounts
ON User_Follows
AFTER INSERT, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE Users
        SET follower_count = follower_count + 1
        WHERE user_id IN (SELECT following_id FROM inserted);

        UPDATE Users
        SET following_count = following_count + 1
        WHERE user_id IN (SELECT follower_id FROM inserted);
    END

    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        UPDATE Users
        SET follower_count = CASE WHEN follower_count > 0 THEN follower_count - 1 ELSE 0 END
        WHERE user_id IN (SELECT following_id FROM deleted);

        UPDATE Users
        SET following_count = CASE WHEN following_count > 0 THEN following_count - 1 ELSE 0 END
        WHERE user_id IN (SELECT follower_id FROM deleted);
    END
END
GO

IF OBJECT_ID('sp_GetPopularPinsByCategory', 'P') IS NOT NULL
    DROP PROCEDURE sp_GetPopularPinsByCategory;
GO

CREATE PROCEDURE sp_GetPopularPinsByCategory
    @category_id INT,
    @top_count INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@top_count)
        p.pin_id,
        p.title,
        p.image_url,
        p.description,
        p.save_count,
        p.view_count,
        p.click_count,
        u.username AS creator_username,
        c.category_name,
        p.created_at
    FROM Pins p
    INNER JOIN Users u ON p.user_id = u.user_id
    LEFT JOIN Categories c ON p.category_id = c.category_id
    WHERE p.category_id = @category_id OR @category_id IS NULL
    ORDER BY p.save_count DESC, p.view_count DESC, p.created_at DESC;
END
GO

IF OBJECT_ID('fn_GetBoardPinCount', 'FN') IS NOT NULL
    DROP FUNCTION fn_GetBoardPinCount;
GO

CREATE FUNCTION fn_GetBoardPinCount(@board_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;

    SELECT @count = COUNT(*)
    FROM Board_Pins
    WHERE board_id = @board_id;

    RETURN ISNULL(@count, 0);
END
GO
