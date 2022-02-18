CREATE TABLE [dbo].[Book] (
    [bookId]      INT          IDENTITY (1, 1) NOT NULL,
    [bookName]    VARCHAR (50) NOT NULL,
    [catalogueId] INT          NOT NULL,
    [author]      VARCHAR (20) NOT NULL,
    [publisher]   VARCHAR (20) NULL,
    [pub_date]    DATE         NULL,
    [bookStatus]  BIT          NOT NULL,
    [bookPrice]   FLOAT (53)   NULL,
    PRIMARY KEY CLUSTERED ([bookId] ASC)
);

CREATE TABLE [dbo].[Admin] (
    [adminId]              NVARCHAR (128) NOT NULL,
    [Email]                NVARCHAR (256) NULL,
    [EmailConfirmed]       BIT            NOT NULL,
    [PasswordHash]         NVARCHAR (MAX) NULL,
    [SecurityStamp]        NVARCHAR (MAX) NULL,
    [PhoneNumber]          NVARCHAR (MAX) NULL,
    [PhoneNumberConfirmed] BIT            NOT NULL,
    [TwoFactorEnabled]     BIT            NOT NULL,
    [LockoutEndDateUtc]    DATETIME       NULL,
    [LockoutEnabled]       BIT            NOT NULL,
    [AccessFailedCount]    INT            NOT NULL,
    [UserName]             NVARCHAR (256) NOT NULL,
    CONSTRAINT [PK_Admin] PRIMARY KEY CLUSTERED ([adminId] ASC)
);

CREATE TABLE [dbo].[bookRentals] (
    [bookRentalId] INT            IDENTITY (1, 1) NOT NULL,
    [userId]       NVARCHAR (128) NOT NULL,
    [bookId]       INT            NOT NULL,
    [rentalDate]   DATE           DEFAULT (getdate()) NOT NULL,
    [returnDate]   DATE           NULL
);

CREATE TABLE [dbo].[bookCatalogue] (
    [catalogueId] INT          IDENTITY (1, 1) NOT NULL,
    [catalogue]   VARCHAR (20) NOT NULL,
    [bookId]      INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([catalogueId] ASC)
);

--------------------------------------------------
DROP PROCEDURE IF EXISTS getBooksToReturn
Go

CREATE PROCEDURE getBooksToReturn
	@userId	nvarchar(128)
AS
	SELECT DISTINCT br.bookRentalId, b.bookName, br.rentalDate, b.bookId
	FROM bookRentals br
		JOIN Book b ON b.bookId = br.bookId
	WHERE br.returnDate IS NULL AND userId = @userId
	ORDER BY b.bookName


	--------------------------------------------------
DROP PROCEDURE IF EXISTS spUpdateBookStatus
Go
CREATE PROCEDURE [spUpdateBookStatus]
	@bookId  INT
	
AS
IF EXISTS(SELECT NULL FROM Book WHERE bookId = @bookId) BEGIN
	UPDATE Book
	SET bookStatus = ~bookStatus
	WHERE bookId = @bookId
	SELECT iif(bookStatus=1, 'IN', 'OUT') AS bookStatus FROM Book where bookId = @bookId
END ELSE BEGIN
	SELECT 'error' AS bookStatus


	select bookStatus from Book 
END


	--------------------------------------------------
DROP PROCEDURE IF EXISTS spShowAvailableBooks
Go
CREATE PROCEDURE spShowAvailableBooks
	
AS
	SELECT  * from Book 
	where	bookStatus = 1;


		--------------------------------------------------
DROP PROCEDURE IF EXISTS spSearchBooks
Go
CREATE PROCEDURE spSearchBooks	
@input varchar(50)
AS
BEGIN 
	SELECT DISTINCT b.bookId, b.bookName, b.author, b.bookStatus, bc.catalogue, br.userId
	FROM Book   b
	JOIN	bookCatalogue  bc   ON  b.catalogueId = bc.catalogueId
	LEFT JOIN	bookRentals   br		ON	br.bookId = b.bookId AND br.returnDate IS NULL
	WHERE		bookName like '%'+@input+'%' 
				OR author like '%'+@input+'%' 
				OR catalogue like '%'+@input+'%'
END

		--------------------------------------------------
DROP PROCEDURE IF EXISTS spReturnBook
Go

CREATE PROCEDURE spReturnBook
	@bid int
AS

	IF EXISTS(SELECT NULL FROM Book WHERE bookId = @bid) BEGIN
		UPDATE bookRentals
		SET returnDate = GETDATE()
		WHERE bookId = @bid AND returnDate IS NULL
		

		UPDATE Book
		SET bookStatus = ~bookStatus
		WHERE bookId = @bid
		SELECT iif(bookStatus=1, 'IN', 'OUT') AS bookStatus FROM Book where bookId = @bid
	END ELSE BEGIN
		SELECT 'error' AS bookStatus
	END

		--------------------------------------------------
DROP PROCEDURE IF EXISTS spGetBookList
Go
CREATE PROCEDURE spGetBookList
AS
	SET NOCOUNT ON

	SELECT	*
	FROM	Book


		--------------------------------------------------
DROP PROCEDURE IF EXISTS spBorrowBook
Go
CREATE PROCEDURE spBorrowBook
	@bid int,
	@uid nvarchar(128)
AS

	IF EXISTS(SELECT NULL FROM Book WHERE bookId = @bid) BEGIN
		IF NOT EXISTS (SELECT NULL FROM bookRentals WHERE  bookId = @bid AND returnDate IS NULL) BEGIN
			INSERT INTO bookRentals (userId, bookId)VALUES(@uid, @bid)
		
			UPDATE Book
			SET bookStatus = ~bookStatus
			WHERE bookId = @bid
			SELECT iif(bookStatus=1, 'IN', 'OUT') AS bookStatus FROM Book where bookId = @bid
		END
	END ELSE BEGIN
		SELECT 'error' AS bookStatus
	END

		--------------------------------------------------
DROP PROCEDURE IF EXISTS spAddRecord
Go
CREATE PROCEDURE spAddRecord
	@bookId   int,
	@userId	  int,
	@borrowDate  DATE,
	@returnDate DATE
AS
	INSERT INTO bookRentals(bookId, userId, rentalDate, returnDate) VALUES 
	 (@bookId, @userId, @borrowDate, @returnDate)



	 		--------------------------------------------------
DROP PROCEDURE IF EXISTS  spAddBorrowRecord
Go
CREATE PROCEDURE spAddBorrowRecord
	@userId int,
	@bookId int
	
AS

	INSERT INTO 
	bookRentals(bookId, userId) 
	VALUES (@bookId, @userId)


	SELECT  b.bookName, b.bookStatus, br.rentalDate, br.userId
	FROM	Book  b   
	JOIN	bookRentals   br  ON b.bookId = BR.bookId
	WHERE	b.bookId = @bookId
	AND		br.returnDate IS NULL


			--------------------------------------------------
DROP PROCEDURE IF EXISTS spAddBookCatalogue
Go
CREATE PROCEDURE spAddBookCatalogue 
	@catalogue   VARCHAR(50), 
	@bookId		INT
AS
SET IDENTITY_INSERT bookCatalogue ON
	INSERT INTO bookCatalogue (catalogue, bookId) VALUES 
	 (@catalogue, @bookId)
	
SET IDENTITY_INSERT bookCatalogue OFF


		--------------------------------------------------
DROP PROCEDURE IF EXISTS  spAddBook
Go
--INSERT INTO Book (bookId, bookName, catalogueId, author, publisher, pub_date, bookStatus, bookPrice) VALUES 
--	 (1, 'name 1', '1', 'tom', 'publisher', '4/7/2018', 1, 23.33)
CREATE PROCEDURE spAddBook
	@bookName		VARCHAR(50),
	@catelogueId	INT,
	@author			VARCHAR(50),
	@publisher		VARCHAR(50),
	@pub_date		DATE,
	@bookStatus		BIT,
	@bookPrice		FLOAT


AS


	INSERT INTO Book (bookName, catalogueId, author, publisher, pub_date, bookStatus, bookPrice) VALUES
	(@bookName, @catelogueId, @author, @publisher, @pub_date, @bookStatus, @bookPrice)

	SELECT *  FROM Book where bookId = @@IDENTITY


