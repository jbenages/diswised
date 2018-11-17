CREATE TABLE rawclientsignal(
	station_mac TEXT,
	first_time_seen DATETIME,
	last_time_seen DATETIME,
	power INTEGER,
	packets INTEGER,
	bssid TEXT,
	probed_essids TEXT
);
CREATE TABLE rawroutersignal(
	bssid TEXT,
	first_time_seen DATETIME,
	last_time_seen DATETIME,
	channel INTEGER,
	speed INTEGER,
	privacy TEXT,
	cipher TEXT,
	authentication TEXT,
	power INTEGER,
	beacons INTEGER,
	iv INTEGER,
	lan_ip INTEGER,
	id_length INTEGER,
	essid TEXT,
	key TEXT
);

CREATE TABLE client(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	station_mac TEXT,
	date_in DATETIME,
	date_scan DATETIME,
	manufacturer TEXT,
	hostname TEXT,
	scan_os TEXT,
	scan_hostname TEXT,
	scan_port TEXT
);
CREATE TABLE attack(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	description TEXT
);
CREATE TABLE client_attack(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	success BOOLEAN,
	date_in DATETIME,
	client_id INTEGER,
	attack_id INTEGER
);
CREATE TABLE router(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	essid TEXT,
	bssid TEXT,
	date_in DATETIME,
	manufacturer TEXT,
	channel INTEGER
);
CREATE TABLE client_router(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	associate BOOLEAN,
	rap_assoc BOOLEAN,
	client_id INTEGER,
	router_id INTEGER
);
INSERT INTO attack (description) VALUES ("rogueapassoc"),("rogueap"),("openwifi");
