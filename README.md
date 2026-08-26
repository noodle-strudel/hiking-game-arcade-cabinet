# Kick Rocks!
## The World's First Official Rock Erosion by Means of Podiatric Impact Simulator 
Kick Rocks! is an arcade game whose physical location will be in the Downtown Portland Shirtzenpantz store by the end of 2026. The goal of the game is to kick a rock until it becomes a sphere, but you must sign a contact before you play that agrees you can only kick it once a day.
## MariaDB Integration

### Installation
- MariaDB Version 10.11 or higher.
- Port set to 3306 (believed to happen during setup).

### Root Setup
After initially setting up root with a password, it must be removed. For some reason when setting up the database access in Godot, there must be a password, and the user in MariaDB must have no password. If the user has a password, it will not connect the game to the server, even if the passwords match. **The only combination we have found to work is a password on Godot and no password in the server.**

After initial setup, remove the password from root. Log into MariaDB using root and the password you gave it:
```
mariadb -u root -p
```
Then, enter the following command to remove the password:
```mysql
ALTER USER root@localhost IDENTIFIED BY '';
```

### Setup Database
To recreate the database, open the MariaDB terminal with this command if not already open:
```
mariadb -u root -p
```
Log into root and use these commands to make the database and table:
```mysql
CREATE DATABASE kicks_db;
```
```
USE kicks_db;
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
