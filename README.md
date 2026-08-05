Placeholder text! Kick rocks!!!!!!!

## MariaDB

To recreate the database, use this:
```mysql
CREATE TABLE kicks (
  kick_number int(11) AUTO_INCREMENT PRIMARY KEY NOT NULL,
  score int(11) NOT NULL,
  time timestamp DEFAULT CURRENT_TIMESTAMP(),
  initials varchar(3)
);
```
