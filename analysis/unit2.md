# Unit 2 Analysis: Schema Constraints & Integrity Rules

## The Constraints Table

| Foreign Key Constraint | ON DELETE Choice | Business Rationale (1 Sentence) |
| :--- | :--- | :--- |
| `fk_artists_accounts` | `CASCADE` | Removing a user account automatically deletes their artist profile to keep user accounts and subclass entities synchronized. |
| `fk_albums_artists` | `RESTRICT` | Prevents removing an artist profile if they have active albums in the catalog, protecting platform content availability. |
| `fk_songs_albums` | `CASCADE` | Deleting an album automatically purges its associated tracks. |
| `fk_song_artists_songs` | `CASCADE` | Removing a track from the catalog cleans up its artist contribution records. |
| `fk_song_artists_artists` | `RESTRICT` | Prevents deleting an artist profile if historical song credit records depend on their mapping. |
| `fk_event_accounts` | `CASCADE` | Deleting a user account cleans up their activity log entries. |
| `fk_event_songs` | `SET NULL` | Removing a track sets the `song_id` to NULL in historical log entries, preserving analytics metrics while removing the missing song reference. |
| `fk_event_parent` | `SET NULL` | Deleting a parent event sets child event pointers to NULL so audit logs remain readable without broken links. |

---

## ON DELETE Narrative

### 1. `fk_artists_accounts` (`CASCADE`)
* **Real-world Event:** A platform user closes their account.
* **Who/What is affected:** The base `accounts` row is removed, which automatically purges the child `artists` record.
* **Alternative Risk:** Under `RESTRICT`, attempting to delete an account would fail until the artist entry was deleted separately.

### 2. `fk_albums_artists` (`RESTRICT`)
* **Real-world Event:** An admin attempts to delete an artist profile that still has published albums.
* **Who/What is affected:** The database blocks the deletion until the albums are transferred or removed.
* **Alternative Risk:** Under `CASCADE`, deleting an artist would accidentally wipe their entire album and song catalog from the database.

### 3. `fk_songs_albums` (`CASCADE`)
* **Real-world Event:** A label removes an album from the platform.
* **Who/What is affected:** Deleting the album row automatically deletes all tracks belonging to that album.
* **Alternative Risk:** Under `SET NULL`, individual tracks would remain in the database without an album, creating orphaned song rows.

### 4. `fk_event_songs` (`SET NULL`)
* **Real-world Event:** A track is removed from the service due to licensing changes.
* **Who/What is affected:** Log entries keep their timestamp and account ID, but the `song_id` becomes `NULL`.
* **Alternative Risk:** Under `CASCADE`, removing a single track would destroy historic play-count data and auditing history.

---

## CHECK Constraints Narrative

### 1. `chk_artists_formed_year`
* **Invalid State Prevented:** Prevents entering formation years in the future or prior to 1900.
* **How it could otherwise arise:** Unvalidated registration form inputs or dirty data imports.

### 2. `chk_songs_duration` & `chk_songs_track`
* **Invalid State Prevented:** Prevents tracks with zero/negative duration or invalid track numbers (`< 1`).
* **How it could otherwise arise:** File upload parsing errors or missing audio metadata.

### 3. `chk_event_no_self_referral`
* **Invalid State Prevented:** Prevents an event log entry from pointing to itself as its own parent event.
* **How it could otherwise arise:** Bugs in recursive auditing scripts during log generation.

---

## Derived Attributes Strategy
* **Derived Attribute:** `active_years`
* **Implementation Decision:** Omitted as a physical database column. Values are calculated dynamically in queries using `EXTRACT(YEAR FROM CURRENT_DATE) - formed_year`.
* **Rationale:** Storing derived attributes physically requires background updates to stay current and risks showing stale data.
