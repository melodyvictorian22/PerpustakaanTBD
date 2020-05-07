-- Table structure for table anggota
CREATE TABLE anggota (
  idAnggota int IDENTITY(1,1) NOT NULL,
  namaAnggota varchar(50),
  email varchar(50),
  pass binary(64)
) 

-- Table structure for table buku
CREATE TABLE buku (
  id_buku int IDENTITY(1,1) NOT NULL,
  judulBuku varchar(50),
  id_pengarang int NOT NULL
) 

-- Table structure for table buku_memiliki_kata
CREATE TABLE buku_memiliki_kata (
  kata varchar(50) NOT NULL,
  id_buku int NOT NULL
) 


-- Table structure for table buku_memiliki_tag
CREATE TABLE buku_memiliki_tag (
  id_tag int NOT NULL,
  id_buku int NOT NULL
) 

-- Table structure for table eksemplar
CREATE TABLE eksemplar (
  id_eksemplar int IDENTITY(1,1) NOT NULL,
  status_pinjaman int, --0 = tidak sedang dipinjam
  id_pinjaman int NOT NULL,
  id_buku int NOT NULL,
) 

-- Table structure for table kata
CREATE TABLE kata (
  IDF float,
  kata varchar(50) NOT NULL
) 

-- Table structure for table peminjaman
CREATE TABLE peminjaman (
  id_pinjaman int IDENTITY(1,1)  NOT NULL,
  tgl_pinjam date,
  tgl_kembali date,
  id_anggota int NOT NULL,
  id_eksemplar int NOT NULL,
  status_pinjaman int NOT NULL
) 

-- Table structure for table pengarang
CREATE TABLE pengarang (
  id_pengarang int IDENTITY(1,1) NOT NULL,
  namaPengarang varchar(50)
) 

-- Table structure for table tag
CREATE TABLE tag (
  id_tag int IDENTITY(1,1) NOT NULL,
  namaTag varchar(50)
) 

-- Primary Key for table anggota
ALTER TABLE anggota
ADD PRIMARY KEY (idAnggota)


-- Primary Key for table buku
ALTER TABLE buku
ADD PRIMARY KEY (id_buku)


-- Primary Key for table eksemplar
ALTER TABLE eksemplar
ADD PRIMARY KEY (id_eksemplar)


-- Primary Key for table kata
ALTER TABLE kata
ADD PRIMARY KEY (kata);


-- Primary Key for table peminjaman
ALTER TABLE peminjaman
ADD PRIMARY KEY (id_pinjaman)


-- Primary Key for table pengarang
ALTER TABLE pengarang
ADD PRIMARY KEY (id_pengarang)


-- Primary Key for table tag
ALTER TABLE tag
ADD PRIMARY KEY (id_tag)


-- Constraints for buku
ALTER TABLE buku
ADD CONSTRAINT [FK_Buku_Pengarang] FOREIGN KEY (id_pengarang) REFERENCES pengarang (id_pengarang) 

-- Constraints for table buku_memiliki_kata
ALTER TABLE buku_memiliki_kata
ADD CONSTRAINT [FK_Buku_Memiliki] FOREIGN KEY (id_buku) REFERENCES buku (id_buku)
ALTER TABLE buku_memiliki_kata
ADD CONSTRAINT [FK_Kata_Memiliki] FOREIGN KEY (kata) REFERENCES kata (kata) 

-- Constraints for table buku_memiliki_tag
ALTER TABLE buku_memiliki_tag
ADD CONSTRAINT [FK_Memiliki_Buku] FOREIGN KEY (id_buku) REFERENCES buku (id_buku)
ALTER TABLE buku_memiliki_tag
ADD CONSTRAINT [FK_Memiliki_Tag] FOREIGN KEY (id_tag) REFERENCES tag (id_tag) ON DELETE NO ACTION ON UPDATE NO ACTION

-- Constraints for table eksemplar
ALTER TABLE eksemplar
ADD CONSTRAINT [FK_Eksemplar_Buku] FOREIGN KEY (id_buku) REFERENCES buku (id_buku) ON DELETE NO ACTION ON UPDATE NO ACTION

-- Constraints for table peminjaman
ALTER TABLE peminjaman
ADD CONSTRAINT [FK_Anggota_Pinjam] FOREIGN KEY (id_anggota) REFERENCES anggota (idAnggota)

