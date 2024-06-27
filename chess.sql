DROP SCHEMA IF EXISTS chess CASCADE;
CREATE SCHEMA chess;
SET SEARCH_PATH TO chess;


DROP TABLE IF EXISTS Openings CASCADE;
DROP TABLE IF EXISTS TempGames CASCADE;
DROP TABLE IF EXISTS Players CASCADE;
DROP TABLE IF EXISTS Games CASCADE;
DROP TABLE IF EXISTS PlayerHistory CASCADE;
DROP TABLE IF EXISTS TempOpenings CASCADE;


-- create openings table

CREATE TABLE Openings (
	oID SERIAL,
	eco TEXT,
	opening_name TEXT,
	ply INT,
	PRIMARY KEY (oID)
);

-- create tempopenings table in order to keep track of which game has what opening

CREATE TABLE TempOpenings (
	ID int,
        oID INT,
	eco TEXT,
	opening_name TEXT,
	ply INT
);

-- tempgames is for reading the file and it will be used to create the other tables

CREATE TABLE TempGames (
	gID INT,
	rated TEXT,
	created_at TIMESTAMP,
	last_move_at TIMESTAMP,
	turns INT,
	victory_status TEXT,
	winner TEXT,
	increment_code TEXT,
	white TEXT,
	white_rating INT,
	black TEXT,
	black_rating INT,
	moves TEXT,
	opening_eco TEXT,
	opening_name TEXT,
	opening_ply INT,
	PRIMARY KEY (gID)
);

-- read the temp_games file and populate temp_games

\COPY TempGames from temp_games.csv with csv


-- A table which contains all players usernames
CREATE TABLE Players (
	username TEXT,
	PRIMARY KEY (username)
);
-- Read the usernames file and populate players
\COPY Players from usernames.csv with csv

-- populate openings using tempgames
INSERT INTO Openings (eco, opening_name, ply)
select distinct opening_eco, opening_name, opening_ply FROM TempGames;

-- populate TempOpenings using tempgames and openings
INSERT INTO TempOpenings (ID, oID, eco, opening_name, ply)
select TempGames.gID, Openings.oID, TempGames.opening_eco, TempGames.opening_name, TempGames.opening_ply FROM TempGames, Openings WHERE Openings.eco = TempGames.opening_eco and
TempGames.opening_name = Openings.opening_name and TempGames.opening_ply = Openings.ply;

CREATE TABLE Games (
	gID INT,
	rated TEXT,
	created_at TIMESTAMP,
	last_move_at TIMESTAMP,
	turns INT,
	victory_status TEXT,
	winner TEXT,
	increment_code TEXT,
	white TEXT,
	black TEXT,
	moves TEXT,
	oID INT,
	PRIMARY KEY (gID),
	FOREIGN KEY (white) REFERENCES Players(username),
	FOREIGN KEY (black) REFERENCES Players(username),
	FOREIGN KEY (oID) REFERENCES Openings(oID)
);

-- populate games using tempgames and tempopenings
INSERT INTO Games (gID, rated, created_at, last_move_at, turns, victory_status, winner, increment_code, white, black, moves, oID)
select gID, rated, created_at, last_move_at, turns, victory_status, winner, increment_code, white, black, moves, oID FROM TempGames, TempOpenings WHERE TempOpenings.ID = TempGames.gID;

-- create player history which tracks all the games a player has played and their rating at that time.
CREATE TABLE PlayerHistory (
	username TEXT,
	time TIMESTAMP,
	rating INT,
	gID INT,
	FOREIGN KEY (username) REFERENCES Players(username),
	FOREIGN KEY (gID) REFERENCES Games(gID)
);

-- populate player history by finding each players history

INSERT INTO PlayerHistory (username, time, rating, gID)
select username, created_at, white_rating, gID FROM TempGames, Players WHERE Players.username = white;

INSERT INTO PlayerHistory (username, time, rating, gID)
select username, created_at, black_rating, gID FROM TempGames, Players WHERE Players.username = black;

--drop temporary tables
DROP TABLE IF EXISTS TempOpenings CASCADE;
DROP TABLE IF EXISTS TempGames CASCADE;

