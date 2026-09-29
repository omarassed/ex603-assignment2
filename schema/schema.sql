-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Music Streaming & Publishing Platform
-- Author: Omar A.
-- Target: PostgreSQL 14+
-- =================================================================



-- Reset block: Reverse creation order to handle dependencies cleanly
DROP TABLE IF EXISTS event CASCADE;
DROP TABLE IF EXISTS song_artists CASCADE;
DROP TABLE IF EXISTS songs CASCADE;
DROP TABLE IF EXISTS albums CASCADE;
DROP TABLE IF EXISTS artists CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

-- 1. accounts: First because it has no outgoing foreign keys.
CREATE TABLE accounts (
    account_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(255) NOT NULL CONSTRAINT uq_accounts_email UNIQUE,
    created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. artists: References accounts via table-per-type inheritance.
CREATE TABLE artists (
    account_id   INTEGER PRIMARY KEY,
    stage_name   VARCHAR(100) NOT NULL,
    bio          TEXT,
    formed_year  INTEGER CONSTRAINT chk_artists_formed_year CHECK (formed_year BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)),
    CONSTRAINT fk_artists_accounts 
        FOREIGN KEY (account_id) REFERENCES accounts (account_id) 
        ON DELETE CASCADE
);

-- 3. albums: References artists as the primary creator/owner.
CREATE TABLE albums (
    album_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    artist_id    INTEGER NOT NULL,
    title        VARCHAR(150) NOT NULL,
    release_date DATE NOT NULL,
    CONSTRAINT fk_albums_artists 
        FOREIGN KEY (artist_id) REFERENCES artists (account_id) 
        ON DELETE RESTRICT
);

-- 4. songs: References albums to organize catalog tracklists.
CREATE TABLE songs (
    song_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    album_id     INTEGER NOT NULL,
    title        VARCHAR(150) NOT NULL,
    duration_sec INTEGER NOT NULL CONSTRAINT chk_songs_duration CHECK (duration_sec > 0),
    track_num    INTEGER NOT NULL CONSTRAINT chk_songs_track CHECK (track_num > 0),
    CONSTRAINT fk_songs_albums 
        FOREIGN KEY (album_id) REFERENCES albums (album_id) 
        ON DELETE CASCADE,
    CONSTRAINT uq_songs_album_track UNIQUE (album_id, track_num)
);

-- 5. song_artists: Junction table linking songs and artists (M:N relationship).
CREATE TABLE song_artists (
    song_id      INTEGER NOT NULL,
    artist_id    INTEGER NOT NULL,
    role         VARCHAR(50) NOT NULL DEFAULT 'Contributor',
    CONSTRAINT pk_song_artists PRIMARY KEY (song_id, artist_id),
    CONSTRAINT fk_song_artists_songs 
        FOREIGN KEY (song_id) REFERENCES songs (song_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_song_artists_artists 
        FOREIGN KEY (artist_id) REFERENCES artists (account_id) 
        ON DELETE RESTRICT
);

-- 6. event: Last because it references both accounts and songs.
CREATE TABLE event (
    event_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_id   INTEGER NOT NULL,
    song_id      INTEGER,
    logged_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    parent_event INTEGER,
    CONSTRAINT fk_event_accounts 
        FOREIGN KEY (account_id) REFERENCES accounts (account_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_event_songs 
        FOREIGN KEY (song_id) REFERENCES songs (song_id) 
        ON DELETE SET NULL,
    CONSTRAINT fk_event_parent 
        FOREIGN KEY (parent_event) REFERENCES event (event_id) 
        ON DELETE SET NULL,
    CONSTRAINT chk_event_no_self_referral CHECK (parent_event IS DISTINCT FROM event_id)
);
