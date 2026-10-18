---
id: 20260107000004
title: Linux notes for tools
date: 2026-01-07 00:03
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [postgresql, docker, database, archlinux, setup, development]
links: []
---
# Log
- 2026-01-07 00:03 - Created note.

# Notes
# Linux Database & Tool Services
- [ ] PostgreSQL Setup on Arch Linux
- [ ] MariaDB Setup on Arch Linux
- [ ] Media Transfer Protocol (MTP & Android File Transfer)

## 1: PostgreSQL Setup on Arch Linux -------------------------------

Minimal, repeatable steps. Focus on: install → init → service → role/db → authentication → maintenance.

### 1.1 Install
```bash
sudo pacman -Syu postgresql          # install latest packaged version
pacman -Qi postgresql || echo "Not installed?"  # verify
```

## 2. Initialize the data directory (cluster)
Arch package ships an empty dir at `/var/lib/postgres`. Run initdb as the postgres system user (NOT root).
```bash
sudo -iu postgres initdb -D /var/lib/postgres/data --locale=en_US.UTF-8 --encoding=UTF8
# After success it prints how to start with pg_ctl (we'll use systemd instead).
```

If you rerun and need a clean slate:
```bash
sudo systemctl stop postgresql 2>/dev/null || true
sudo rm -rf /var/lib/postgres/data
sudo -iu postgres initdb -D /var/lib/postgres/data
```

## 3. Enable + start service
```bash
sudo systemctl enable --now postgresql   # enables at boot and starts now
systemctl is-active postgresql && echo OK
sudo systemctl status postgresql --no-pager | sed -n '1,6p'
```

If not active, inspect logs:
```bash
journalctl -u postgresql -b -n 80 --no-pager   # current boot recent lines
```

## 4. Basic psql access
```bash
sudo -iu postgres psql   # superuser prompt postgres=#
\q                      # quit
```

## 5. Create a normal superuser role matching my Linux user
This allows passwordless peer auth locally (safer than trust).
```bash
sudo -iu postgres createuser --superuser plutonium   # or --interactive
sudo -iu postgres createdb plutonium                 # DB with same name
psql   # now connects automatically to db 'plutonium' as role 'plutonium'
```

## 6. Secure authentication (replace initdb's default "trust")
Edit `pg_hba.conf`:
```bash
sudo vim /var/lib/postgres/data/pg_hba.conf
```
Recommended minimal local-only setup:
```
# TYPE  DATABASE        USER            ADDRESS             METHOD
local   all             postgres                            peer          # admin via system user
local   all             all                                 peer          # match unix user → db role
host    all             all             127.0.0.1/32        scram-sha-256 # TCP local needs password
host    all             all             ::1/128             scram-sha-256
```
Then set passwords for roles that will use TCP:
```bash
psql -c "\password postgres"     # set inside interactive prompt if needed
```
Reload / restart:
```bash
sudo systemctl reload postgresql  # picks up pg_hba.conf changes
# If reload fails (syntax error), use restart after fixing.
```

## 7. Useful psql meta commands
```
\l          # list databases
\du         # list roles
\dn         # list schemas
\dt         # tables in current schema
\conninfo   # connection info
```

## 8. Common errors & fixes
| Symptom | Cause | Fix |
|---------|-------|-----|
| `socket ... No such file or directory` | Server not started | `sudo systemctl start postgresql` |
| `FATAL: role "plutonium" does not exist` | Role missing | `sudo -iu postgres createuser plutonium` |
| Cannot sudo inside `postgres` shell | postgres user not in sudoers (normal) | Run sudo from your own user, not from `sudo -iu postgres` session |
| Trust auth warning after initdb | Default insecure for multi-user | Edit `pg_hba.conf` → peer/scram |
| Want a clean reset | Corrupt / experimental state | Stop service, remove data dir, re-run initdb |

## 9. Change listen addresses (optional)
For remote connections:
```bash
sudo vim /var/lib/postgres/data/postgresql.conf
# set: listen_addresses = 'localhost,192.168.1.50'   (remove leading #)
sudo systemctl restart postgresql
```
Open firewall (if using e.g. ufw):
```bash
sudo ufw allow 5432/tcp
```
Ensure matching `pg_hba.conf` host lines with `scram-sha-256`.

## 10. Simple backup & restore (logical)
```bash
pg_dump -Fc plutonium > plutonium.dump   # custom format
pg_restore -d plutonium plutonium.dump   # restore into existing DB
```

## 11. Service management quick refs
```bash
sudo systemctl (start|stop|restart|reload) postgresql
sudo systemctl disable postgresql        # remove from boot
```

## 12. Version & binaries
```bash
postgres -V
which psql
```

## 13. One-liner verification script
```bash
sudo -iu postgres bash -c 'psql -Atqc "select version();" && echo OK'
```

## 14. Re-initialization checklist (destructive)
```bash
sudo systemctl stop postgresql
sudo mv /var/lib/postgres/data /var/lib/postgres/data.bak.$(date +%s)
sudo -iu postgres initdb -D /var/lib/postgres/data
sudo systemctl start postgresql
```

## 15. Minimal workflow summary
1. Install package
2. `initdb` as postgres user
3. Enable + start systemd service
4. Create matching role + database
5. Harden `pg_hba.conf` (peer + scram)
6. Set passwords where needed
7. Use psql + meta commands

---

## 2: MariaDB Setup on Arch Linux -------------------------------

Minimal, repeatable steps. Focus on: install → init → service → user/db → authentication → maintenance.

### 2.1 Install
```bash
sudo pacman -Syu mariadb          # install latest packaged version
pacman -Qi mariadb || echo "Not installed?"  # verify
```

## 2. Initialize the data directory
Arch package ships without initialized data. Run mysql_install_db as the mysql system user (NOT root).
```bash
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
# After success, MariaDB data directory is ready.
```

If you rerun and need a clean slate:
```bash
sudo systemctl stop mariadb 2>/dev/null || true
sudo rm -rf /var/lib/mysql
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
```

## 3. Enable + start service
```bash
sudo systemctl enable --now mariadb   # enables at boot and starts now
systemctl is-active mariadb && echo OK
sudo systemctl status mariadb --no-pager | sed -n '1,6p'
```

If not active, inspect logs:
```bash
journalctl -u mariadb -b -n 80 --no-pager   # current boot recent lines
```

## 4. Basic mariadb access
```bash
sudo mariadb   # root prompt (no password by default)
\q             # quit
```

## 5. Create a normal user and database
This allows password-protected access (safer than default root).
```bash
sudo mariadb
CREATE USER 'uraniumdb'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'uraniumdb'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
exit

# Connect as user
mariadb -u uraniumdb -p
CREATE DATABASE testdb;
SHOW DATABASES;
```

## 6. Secure authentication (replace default blank root password)
Set passwords for root and other users:
```bash
sudo mariadb
ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_secure_password';
FLUSH PRIVILEGES;
exit
```

## 7. Useful mariadb commands
```
SHOW DATABASES;    # list databases
SHOW TABLES;       # list tables in current db
SELECT USER();     # show current user
STATUS;           # connection and server info
```

## 8. Common errors & fixes
| Symptom | Cause | Fix |
|---------|-------|-----|
| `socket ... No such file or directory` | Server not started | `sudo systemctl start mariadb` |
| `Access denied for user` | Wrong credentials | Check username/password, use `mariadb -u user -p` |
| Cannot connect as root | Root password not set properly | Use `sudo mariadb` to bypass auth |
| MySQL Connector/C++ unavailable | Package not in repos | Use MariaDB (compatible) instead |
| Old C++ headers | Deprecated includes | Use `<iostream>` not `<iostream.h>`, `<sstream>` not `<sstream.h>` |

## 9. Change listen addresses (optional)
For remote connections:
```bash
sudo vim /etc/my.cnf.d/server.cnf
# Add under [mysqld]:
# bind-address = 127.0.0.1
# bind-address = 192.168.1.50
sudo systemctl restart mariadb
```

Open firewall (if using e.g. ufw):
```bash
sudo ufw allow 3306/tcp
```

## 10. Simple backup & restore (logical)
```bash
mysqldump -u uraniumdb -p testdb > testdb.sql   # dump to SQL
mariadb -u uraniumdb -p testdb < testdb.sql     # restore from SQL
```

## 11. Service management quick refs
```bash
sudo systemctl (start|stop|restart|reload) mariadb
sudo systemctl disable mariadb        # remove from boot
```

## 12. Version & binaries
```bash
mariadb -V
which mariadb
```

## 13. One-liner verification script
```bash
mariadb -u uraniumdb -p -e "SELECT VERSION();" 2>/dev/null && echo OK
```

## 14. Re-initialization checklist (destructive)
```bash
sudo systemctl stop mariadb
sudo mv /var/lib/mysql /var/lib/mysql.bak.$(date +%s)
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl start mariadb
```

## 15. Minimal workflow summary
1. Install package
2. `mariadb-install-db` to initialize
3. Enable + start systemd service
4. Create user + database with privileges
5. Set secure passwords
6. Use mariadb client + SQL commands

---
Fine for local development. For production: tune `innodb_buffer_pool_size`, add regular backups, enable binary logging, and monitor with appropriate tools.

---

Fine for local development. For production: tune `shared_buffers`, add regular backups, enable WAL archiving, and monitor with `prometheus-postgres-exporter`.

---

## 3: Media Transfer Protocol (MTP & Android File Transfer) -------------------------------

[Arch Linux wiki: Media Transfer Protocol](https://wiki.archlinux.org/title/Media_Transfer_Protocol)

### Android File Transfer

MTP client with CLI, Qt UI, and FUSE wrapper (custom MTP implementation).

- Project: https://whoozle.github.io/android-file-transfer-linux/
- Package: `android-file-transfer`

```bash
pacman -S android-file-transfer
```

Mount the device on `~/mnt`:

```bash
aft-mtp-mount ~/mnt
```

Album art: name the file `albumart.xxx` and place it first in the destination folder, then copy other files.

FUSE mounts can be roughly 7–8× slower than UI/CLI file transfer.
