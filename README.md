Placeholder text! Kick rocks!!!!!!!

## MariaDB

### Installation
Mariadb ver 10.11? unless changed when installing on new system
Port set to 3306 (I believe this happens during setup)

### Root Setup
When setting up the root@localhost user for the database the password must be left blank, do so like this:
```mysql
alter user root@localhost identified by '';
```
For some reason when setting up the database access in Godot there must be a password, and the user in MariaDB must have no password. If the user has a password it will not connect the game to the server even if the passwords match. The only combination we have found to work is a password on Godot and no password in the server.
### Setup Database
To recreate the database, open the MariaDB terminal with this command if not already open:
```
mariadb -u root -p
```
and use these commands to make the database and table:
```mysql
CREATE DATABASE kicks_db;
```
```
USE kicks_db
```
```mysql
CREATE TABLE kicks (
  kick_number int(11) AUTO_INCREMENT PRIMARY KEY NOT NULL,
  score int(11) NOT NULL,
  time timestamp DEFAULT CURRENT_TIMESTAMP(),
  initials varchar(3)
);
```
### Issues Encountered with MariaDB
The main issue encountered was the aforementioned password weirdness with the game not being able to access the server unless the server password was blank.
#### NOTE TO DELETE: I'm sorry I couldn't think of any issues we ran into, the only stuff was like the addon not playing nice with windows and the double addition which was a completely separate bug in the game and neither of those are related to MariaDB and would fit better in other things besides the readme
