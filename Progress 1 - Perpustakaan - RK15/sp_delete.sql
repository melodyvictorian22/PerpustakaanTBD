--Untuk melakukan delete anggota dengan parameter nama anggota
create procedure deleteMemberByNama @namaAnggota varchar(50) as
begin
	if exists (select namaAnggota from anggota where namaAnggota = @namaAnggota)
	begin
		declare @stat int,@id int, @counter int
		set @id = (select idAnggota from anggota where namaAnggota = @namaAnggota)
		set @counter = (select count(status_pinjaman) from peminjaman where id_anggota = @id and status_pinjaman = 1)
		if(@counter>0)
		begin
			select 'Masih ada buku yang belum dikembalikan. Tidak bisa menghapus member!' as 'Error Message'
		end
		else
		begin
			delete from peminjaman where id_anggota = @id
			delete from anggota where @namaAnggota = namaAnggota
		end
	end
	else
	begin
		select 'Member tidak ada' as 'Error Message'
	end
end
	
-----------------------------------------------------------
--Untuk melakukan delete buku dengan parameter judul buku
create procedure deleteBuku @judul varchar(50) as
begin
    if exists (select judulBuku from buku where judulBuku = @judul)
    begin
        declare @stat int,@id int, @counter int
        set @id = (select id_buku from buku where judulBuku = @judul)
        delete from buku_memiliki_tag where id_buku = @id
        delete from buku_memiliki_kata where id_buku = @id
        delete from eksemplar where id_buku = @id
        exec updateIDF
        delete from buku where id_buku = @id
    end
    else
    begin
        select 'Buku tidak ada' as 'Error Message'
    end
end