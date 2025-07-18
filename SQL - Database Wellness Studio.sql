CREATE DATABASE studio;
USE studio;

CREATE TABLE layanan (
    id_layanan INT PRIMARY KEY AUTO_INCREMENT,
    nama_layanan VARCHAR(50) NOT NULL
);

CREATE TABLE paket_member (
    id_paket INT PRIMARY KEY AUTO_INCREMENT,
    nama_paket VARCHAR(100) NOT NULL,
    id_layanan INT NOT NULL, 
    harga DECIMAL(12, 2) NOT NULL,
    durasi INT NOT NULL,
    satuan_durasi ENUM('hari', 'sesi') NOT NULL,
    FOREIGN KEY (id_layanan) REFERENCES layanan(id_layanan)
);

CREATE TABLE instruktur (
    id_instruktur INT PRIMARY KEY AUTO_INCREMENT,
	id_layanan INT NOT NULL,
    nama VARCHAR(100) NOT NULL, 
    no_hp VARCHAR(20),
    FOREIGN KEY (id_layanan) REFERENCES layanan(id_layanan)
);

CREATE TABLE member (
    id_member INT PRIMARY KEY AUTO_INCREMENT,
    nama VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    no_hp VARCHAR(20) UNIQUE,
    tanggal_daftar DATE NOT NULL
);

CREATE TABLE kelas (
    id_kelas INT PRIMARY KEY AUTO_INCREMENT,
    nama_kelas VARCHAR(100) NOT NULL,
    id_layanan INT NOT NULL,
    id_instruktur INT NOT NULL,
    tingkat ENUM('Beginner', 'Intermediate', 'Advanced') NOT NULL,
    tanggal_kelas DATE NOT NULL,
    jam_mulai TIME NOT NULL,
    jam_selesai TIME NOT NULL,
    durasi_kelas INT NOT NULL,
    kuota INT NOT NULL,
    FOREIGN KEY (id_layanan) REFERENCES layanan(id_layanan),
    FOREIGN KEY (id_instruktur) REFERENCES instruktur(id_instruktur)
);

CREATE TABLE transaksi (
    id_transaksi INT PRIMARY KEY AUTO_INCREMENT,
    id_member INT NOT NULL,
    id_paket INT NOT NULL,
    id_layanan INT NOT NULL,
    tanggal_transaksi DATE NOT NULL, 
    jumlah_pembayaran DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (id_member) REFERENCES member(id_member),
    FOREIGN KEY (id_paket) REFERENCES paket_member(id_paket),
    FOREIGN KEY (id_layanan) REFERENCES layanan(id_layanan)
);

CREATE TABLE booking (
    id_booking INT PRIMARY KEY AUTO_INCREMENT,
    id_member INT NOT NULL,
    id_kelas INT NOT NULL,
    id_layanan INT NOT NULL,
    tanggal_booking DATE NOT NULL, 
    FOREIGN KEY (id_member) REFERENCES member(id_member),
    FOREIGN KEY (id_kelas) REFERENCES kelas(id_kelas),
    FOREIGN KEY (id_layanan) REFERENCES layanan(id_layanan)
);

ALTER TABLE kelas
ADD sisa_kuota INT NOT NULL,
ADD status_kelas ENUM('TERSEDIA', 'KUOTA PENUH', 'SELESAI', 
'DIBATALKAN') DEFAULT 'TERSEDIA';

ALTER TABLE member
ADD status_member ENUM('AKTIF', 'NONAKTIF') DEFAULT 'NONAKTIF',
ADD tgl_update_gym DATE,
ADD status_gym ENUM('AKTIF', 'NONAKTIF') DEFAULT 'NONAKTIF',
ADD id_paket_gym INT,
ADD kuota_gym INT,
ADD tgl_update_pilates DATE,
ADD status_pilates ENUM('AKTIF', 'NONAKTIF') DEFAULT 'NONAKTIF',
ADD id_paket_pilates INT,
ADD kuota_pilates INT,
ADD tgl_update_yoga DATE,
ADD status_yoga ENUM('AKTIF', 'NONAKTIF') DEFAULT 'NONAKTIF',
ADD id_paket_yoga INT,
ADD kuota_yoga INT,
ADD CONSTRAINT fk_paket_gym FOREIGN KEY (id_paket_gym) 
REFERENCES paket_member(id_paket),
ADD CONSTRAINT fk_paket_pilates FOREIGN KEY (id_paket_pilates) 
REFERENCES paket_member(id_paket),
ADD CONSTRAINT fk_paket_yoga FOREIGN KEY (id_paket_yoga) 
REFERENCES paket_member(id_paket);

DELIMITER //
CREATE TRIGGER durasi_kelas
BEFORE INSERT ON kelas
FOR EACH ROW
BEGIN
    SET NEW.durasi_kelas = TIMESTAMPDIFF(MINUTE, NEW.jam_mulai, 
    NEW.jam_selesai);
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER set_sisa_kuota
BEFORE INSERT ON kelas
FOR EACH ROW
BEGIN
    SET NEW.sisa_kuota = NEW.kuota;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER set_id_layanan
BEFORE INSERT ON transaksi
FOR EACH ROW
BEGIN
    DECLARE layanan INT;

    SELECT id_layanan INTO layanan
    FROM paket_member
    WHERE id_paket = NEW.id_paket
    LIMIT 1;

    SET NEW.id_layanan = layanan;
END;
//
DELIMITER ;

DELIMITER //
CREATE TRIGGER set_id_layanan2
BEFORE INSERT ON booking
FOR EACH ROW
BEGIN
    DECLARE layanan INT;
    
    SELECT id_layanan INTO layanan
    FROM kelas
    WHERE id_kelas = NEW.id_kelas
    LIMIT 1;
    
    SET NEW.id_layanan = layanan;
END;
//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE refresh_member_data()
BEGIN
    UPDATE member m
    JOIN (
        SELECT id_member, id_paket, MAX(tanggal_transaksi) AS tanggal_terbaru
        FROM transaksi
        WHERE id_layanan = 1
        GROUP BY id_member, id_paket
    ) b ON m.id_member = b.id_member
    JOIN paket_member pm ON b.id_paket = pm.id_paket
    SET 
        m.id_paket_gym = b.id_paket,
        m.tgl_update_gym = b.tanggal_terbaru,
        m.kuota_gym = pm.durasi,
        m.status_gym = CASE 
            WHEN pm.durasi > 0 THEN 'AKTIF'
            ELSE 'NONAKTIF'
        END;

    UPDATE member m
    JOIN (
        SELECT id_member, id_paket, MAX(tanggal_transaksi) AS tanggal_terbaru
        FROM transaksi
        WHERE id_layanan = 2
        GROUP BY id_member, id_paket
    ) b ON m.id_member = b.id_member
    JOIN paket_member pm ON b.id_paket = pm.id_paket
    SET 
        m.id_paket_pilates = b.id_paket,
        m.tgl_update_pilates = b.tanggal_terbaru,
        m.kuota_pilates = pm.durasi,
        m.status_pilates = CASE 
            WHEN pm.durasi > 0 THEN 'AKTIF'
            ELSE 'NONAKTIF'
        END;

    UPDATE member m
    JOIN (
        SELECT id_member, id_paket, MAX(tanggal_transaksi) AS tanggal_terbaru
        FROM transaksi
        WHERE id_layanan = 3
        GROUP BY id_member, id_paket
    ) b ON m.id_member = b.id_member
    JOIN paket_member pm ON b.id_paket = pm.id_paket
    SET 
        m.id_paket_yoga = b.id_paket,
        m.tgl_update_yoga  = b.tanggal_terbaru,
        m.kuota_yoga  = pm.durasi,
        m.status_yoga  = CASE 
            WHEN pm.durasi > 0 THEN 'AKTIF'
            ELSE 'NONAKTIF'
        END;
     
	UPDATE member m
	JOIN (
		SELECT m.id_member, p.durasi, m.tgl_update_gym
		FROM member m
		JOIN paket_member p ON m.id_paket_gym = p.id_paket
		WHERE p.id_layanan = 1
	) AS sub ON m.id_member = sub.id_member
	SET 
		m.kuota_gym = GREATEST(0, sub.durasi - DATEDIFF(CURRENT_DATE(), 
        sub.tgl_update_gym)),
		m.status_gym = CASE 
			WHEN (sub.durasi - DATEDIFF(CURRENT_DATE(), sub.tgl_update_gym)) 
            <= 0 THEN 'NONAKTIF'
			ELSE m.status_gym
		END;
        
	UPDATE member m
	JOIN (
		SELECT bk.id_member, COUNT(*) AS total_pilates
		FROM booking bk
		JOIN kelas k ON bk.id_kelas = k.id_kelas
		WHERE k.id_layanan = 2
		GROUP BY bk.id_member
	) AS sub ON m.id_member = sub.id_member
	SET 
		m.kuota_pilates = GREATEST(0, m.kuota_pilates - sub.total_pilates),
		m.status_pilates = CASE 
			WHEN (m.kuota_pilates - sub.total_pilates) <= 0 THEN 'NONAKTIF'
			ELSE m.status_pilates
		END;
    
	UPDATE member m
	JOIN (
		SELECT bk.id_member, COUNT(*) AS total_yoga
		FROM booking bk
		JOIN kelas k ON bk.id_kelas = k.id_kelas
		WHERE k.id_layanan = 3
		GROUP BY bk.id_member
	) AS sub ON m.id_member = sub.id_member
	SET 
		m.kuota_yoga = GREATEST(0, m.kuota_yoga- sub.total_yoga),
		m.status_yoga = CASE 
			WHEN (m.kuota_yoga - sub.total_yoga) <= 0 THEN 'NONAKTIF'
			ELSE m.status_yoga
		END;
        
	CREATE TEMPORARY TABLE IF NOT EXISTS temp_member_aktif AS
	SELECT id_member
	FROM member
	WHERE status_gym = 'AKTIF' 
		OR status_pilates = 'AKTIF' 
		OR status_yoga = 'AKTIF';

	UPDATE member
	JOIN temp_member_aktif t ON member.id_member = t.id_member
	SET member.status_member = 'AKTIF';

	SELECT * FROM member;
END;
//
DELIMITER ;

CALL refresh_member_data();

DELIMITER //
CREATE PROCEDURE refresh_kelas()
BEGIN
    DROP TEMPORARY TABLE IF EXISTS temp_kuota;
    CREATE TEMPORARY TABLE temp_kuota AS
    SELECT 
        k.id_kelas,
        GREATEST(k.sisa_kuota - IFNULL(b.jumlah_booking, 0), 0) AS kuota_baru
    FROM kelas k
    LEFT JOIN (
        SELECT id_kelas, COUNT(*) AS jumlah_booking
        FROM booking
        GROUP BY id_kelas
    ) b ON k.id_kelas = b.id_kelas;

    UPDATE kelas k
    JOIN temp_kuota t ON k.id_kelas = t.id_kelas
    SET k.sisa_kuota = t.kuota_baru;

    DROP TEMPORARY TABLE IF EXISTS temp_status;
    CREATE TEMPORARY TABLE temp_status AS
    SELECT 
        k.id_kelas,
        CASE
            WHEN k.tanggal_kelas < CURRENT_DATE() THEN 'SELESAI'
            WHEN k.sisa_kuota = 0 THEN 'KUOTA PENUH'
            ELSE 'TERSEDIA'
        END AS status_baru
    FROM kelas k
    WHERE k.status_kelas != 'DIBATALKAN';

    UPDATE kelas k
    JOIN temp_status s ON k.id_kelas = s.id_kelas
    SET k.status_kelas = s.status_baru;

    SELECT * FROM kelas;
END;
//
DELIMITER ; 

CALL refresh_kelas();