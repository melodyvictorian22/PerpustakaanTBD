--data dummy
--pada file query awal.sql
--1. jalankan semua create table dulu 
--2. jalankan semua add primary key
--3. jalankan semua add foreign key
--4. lalu jalankan semua stored procedure dan function pada file :
--   sp_insert.sql, sp_update.sql, sp_delete.sql, sp_cari.sql
--5. jalankan sp insert berikut ini (sp_insert.sql): 
--insert anggota
exec insertMember 'David Christopher','gmail@david.com','123456'
exec insertMember 'Melody','gmail@melody.com','123456'
exec insertMember 'Leonard Wang','gmail@wang.com','123456'
exec insertMember 'Juan Capitan','gmail@juan.com','123456'
exec insertMember 'Rio Roi','gmail@yazoo.com','123456'

--insert buku
exec insertBuku 'Sunshine Becomes You','Illana Tan','romance,comedy',5
exec insertBuku 'Winter in Tokyo','Illana Tan','romance,comedy',5
exec insertBuku 'Summer in Paris','Illana Tan','romance,comedy',5
exec insertBuku 'Harry Potter 1 gatau apa ga ngikutin','JK they see me rolling','fantasy,magic',5
exec insertBuku 'Harry Potter 2 gatau apa ga ngikutin','JK they see me rolling','fantasy,magic',5
exec insertBuku 'Harry Potter 3 gatau apa ga ngikutin','JK they see me rolling','fantasy,magic',5
exec insertBuku 'Star Wars A New Hope','George Lucas','space,war,laser',5
exec insertBuku 'Star Wars The Empire Strikes Back','George Lucas','space,war,laser',5
exec insertBuku 'Star Wars Revenge of The Sith','George Lucas','space,war,laser',5
exec insertBuku 'Milea','Pidi Baiq','comedy,drama,romance',5
exec insertBuku 'Dilong','Pidi Baiq','comedy,drama,romance',5
exec insertBuku 'Database','Dosenqu','komputer,database',1
exec insertBuku 'Algoritma dan Struktur Data','David','komputer,algoritma,struktur,data',2
exec insertBuku 'Jaringan Komputer dan Jaringan Hewan','Rararararaw','komputer,jaringan,hewan',2
exec insertBuku 'Petualangan Alice','David','petualangan,fantasy',2
exec insertBuku 'Petualangan Bobi','David','petualangan,fantasy',2
exec insertBuku 'Petualangan melo','David','petualangan,fantasy',2
exec insertBuku 'juna 2','juan','manggang,masak',2

--mencoba kasus pinjam buku
exec insertPinjamanBaru 'David','Star Wars A New Hope'
exec insertPinjamanBaru 'Melody','Milea'
exec insertPinjamanBaru 'Juan Capitan','Database'
--test case eksemplar dipinjam semua
exec insertPinjamanBaru 'Rio','Database'
--test case anggota tidak terdaftar
exec insertPinjamanBaru 'Dio','Dilong'
--test case buku tidak terdaftar
exec insertPinjamanBaru 'David','Algoritma'
--test case anggota dan buku tidak terdaftar
exec insertPinjamanBaru 'Dio','upin-ipin'

--pada file sp_update.sql

--coba kasus pengembalian buku : pengembalian tidak menghapus data dari tabel peminjaman, hanya merubah status di eksemplar dan peminjaman menjadi 0
-- status dipinjam = 1 dan status pengembalian = 0
exec updatePengembalianBuku 'David','Star Wars A New Hope'
exec updatePengembalianBuku 'Melody','Milea'
exec updatePengembalianBuku 'Juan Capitan','Database'
--test case buku tidak ada
exec updatePengembalianBuku 'Juan Capitan','upin-ipin'
--test case bukan anggota 
exec updatePengembalianBuku 'Dio','database'
--test case bukan anggota dan buku tidak ada
exec updatePengembalianBuku 'Dio','upin-ipin'

--mencoba kasus tambah eksemplar
--test case jumlah baru = jumlah lama
exec updateJumlahEksemplar 'Winter in Tokyo', 5
--test case jumlah baru > jumlah lama
exec updateJumlahEksemplar 'Winter in Tokyo', 8
--test case jumlah baru < jumlah lama
exec updateJumlahEksemplar 'Winter in Tokyo', 3

--mencoba kasus insert tag baru
exec tambahTag 'Winter in Tokyo','laser,perang'
--mencoba case buku tidak ada
exec tambahTag 'buku ini tidak ada','laser'

--pada file sp_delete.sql

--mencoba kasus delete buku
exec deleteBuku 'Jaringan Komputer dan Jaringan Hewan'
--test case buku tidak ada
exec deleteBuku 'buku ini tidak ada'

--mencoba kasus delete anggota
--test case anggota ada
exec deleteMemberByNama 'Melody'
--test case anggota tidak ada
exec deleteMemberByNama 'Orang ini tidak ada'

--pada file sp_cari.sql

--mencoba kasus mencari buku berdasarkan tag
exec cariBukuByTag 'petualangan,fantasy'
--test case semua tag tidak ada di buku
exec cariBukuByTag 'horror,education'
--test case salah satu tag tidak terdaftar
exec cariBukuByTag 'romance, horror'

--mencoba kasus jumlah eksemplar yang tersedia berdasarkan tag
exec cariJumlahEksemplarAvailableByTag 'comedy,romance'

--mencoba kasus eksemplar yang tersedia berdasarkan tag
exec cariEksemplarAvailableByTag 'petualangan,fantasy'

--mencoba kasus mencari judul buku
exec cariBukuByJudul 'petualangan'

--mencoba kasus eksemplar yang tersedia berdasarkan judul buku
exec cariEksemplarAvailableByJudul 'milea'

--mencoba kasus mencari buku yang tag nya mirip
exec cariBukuYangSifatnyaMirip 'milea'
--test case judul buku tidak terdaftar
exec cariBukuYangSifatnyaMirip 'jurus masak'

--mencari tag buku favorit
exec cariJenisBukuFavorit
--mencari judul buku favorit
exec cariBukuPalingSeringTerpinjam

--untuk melihat tabel2
select * from peminjaman
select * from anggota
select * from buku
select * from pengarang
select * from kata
select * from tag
select * from buku_memiliki_kata
select * from buku_memiliki_tag
select * from eksemplar






