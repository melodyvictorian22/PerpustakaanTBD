--Untuk melakukan pengembalian buku dengan parameter nama anggota dan judul eksemplar(buku)
alter procedure UpdatePengembalianBuku @namaAnggota varchar(50), @judulEksemplar varchar(50) as
begin
	declare @idAnggota int, @idBuku int
	set @idAnggota = (select idAnggota from anggota where namaAnggota like '%'+@namaAnggota+'%')
	if(@idAnggota is not null)
	begin
		set @idBuku = (select id_buku from buku where judulBuku = @judulEksemplar)
		if(@idBuku is not null)
		begin	
			declare @idEksTemp int, @idPinjamTemp int, @idAnggotaTemp int, @idEksTerpinjam int
			declare @stat int
			declare cur cursor
			for select id_eksemplar, id_pinjaman from eksemplar where status_pinjaman = 1
			open cur
			fetch next from cur into @idEksTemp, @idPinjamTemp
			while(@@FETCH_STATUS=0)
			begin
				set @idAnggotaTemp = (select id_anggota from peminjaman where id_pinjaman = @idPinjamTemp)
				if (@idAnggota = @idAnggotaTemp)
				begin
					declare @tempId int
					declare curId cursor
					for select id_eksemplar from peminjaman where id_anggota = @idAnggota
					open curId
					fetch next from curId into @tempId
					while(@@FETCH_STATUS=0)
					begin
						set @idEksTerpinjam = @tempId
						declare @tempIdBuku int
						set @tempIdBuku = (select id_buku from eksemplar where id_eksemplar = @idEksTerpinjam)
						if(@tempIdBuku = @idBuku)
						begin
							set @stat = (select status_pinjaman from peminjaman where id_eksemplar = @idEksTerpinjam)
							if(@stat = 1)
							begin	
								update eksemplar
								set status_pinjaman = 0
								where id_eksemplar = @idEksTerpinjam
								update eksemplar
								set id_pinjaman = -1
								where id_eksemplar = @idEksTerpinjam
								update peminjaman
								set status_pinjaman = 0
								where id_anggota = @idAnggota and id_eksemplar = @idEksTerpinjam
							end						
						end
					fetch next from curId into @tempId
					end
					close curId
					deallocate curId
				end
				fetch next from cur into @idEksTemp, @idPinjamTemp
			end	
			close cur
			deallocate cur		
		end
		else
		begin
			select 'Tidak ada buku dengan judul tersebut' as 'Error Message'
		end
	end
	else
	begin
		select 'Tidak terdaftar sebagai anggota' as 'Error Message'
	end
end
---------------------------------------------------------------------
--Untuk mengupdate jumlah eksemplar dengan parameter nama buku dan jumlah eksemplar
create procedure updateJumlahEksemplar @namaBuku varchar(50), @jumlah int as
begin
	declare @jumlahEks int,@idBuku int
	set @idBuku = (select id_buku from buku where judulBuku = @namaBuku)
	set @jumlahEks = (select count(id_eksemplar) from eksemplar where id_buku = @idBuku)
	if(@jumlahEks = @jumlah)
	begin
		select 'Jumlah eksemplar sudah sama dengan param' as 'Error Message'
	end
	else if(@jumlahEks < @jumlah)
	begin
		declare @i int
		set @i = @jumlahEks
		while(@i<@jumlah)
		begin
			insert into eksemplar(status_pinjaman,id_pinjaman,id_buku) values (0,-1,@idBuku)
			set @i += 1
		end
	end
	else
	begin
		declare @idTemp int, @stat int, @selisih int, @j int
		set @selisih = @jumlahEks-@jumlah
		set @j=0
		declare cur cursor		
		for select id_eksemplar,status_pinjaman from eksemplar where id_buku = @idBuku
		open cur
		fetch next from cur into @idTemp, @stat
		while(@j<@selisih and @@FETCH_STATUS=0)
		begin
			if(@stat = 0)
			begin
				delete from peminjaman where id_eksemplar = @idTemp
				delete from eksemplar where id_eksemplar = @idTemp
			end
			set @j += 1
			fetch next from cur into @idTemp, @stat
		end
		close cur
		deallocate cur
	end
end
-------------------------------------------------------------------------------
--Untuk mengupdate nilai IDF pada stored procedure deleteBuku
create procedure updateIDF as
begin
	declare @temp varchar(50)
	declare cur cursor
	for select kata from kata
	open cur
	fetch next from cur into @temp
	while(@@FETCH_STATUS=0)
	begin
		exec insertKata @temp
		fetch next from cur into @temp
	end
	close cur
	deallocate cur
end
-----------------------------------------------------------------------
--Untuk menambah tag baru dengan parameter judul buku dan tag baru
create procedure tambahTag @judulBuku varchar(50), @tag nvarchar(max) as
begin
	declare @idBuku int
	set @idBuku = (select count(id_buku) from buku where judulBuku = @judulBuku)
	if(@idBuku = 0)
	begin
		select 'Tidak ada buku tersebut' as 'Error Message'
	end
	else
	begin
		set @idBuku = (select id_buku from buku where judulBuku = @judulBuku)
		declare @temp varchar(50), @idTag int
		declare cur cursor
		for select * from splitTag(@tag)
		open cur
		fetch next from cur into @temp
		while(@@FETCH_STATUS=0)
		begin
			exec insertTag @temp
			set @idTag = (select id_tag from tag where namaTag = @temp)
			if not exists (select id_tag from buku_memiliki_tag where id_buku = @idBuku and id_tag = @idTag)
			begin
				insert into buku_memiliki_tag select @idTag, @idBuku
			end
			fetch next from cur into @temp
		end
		close cur
		deallocate cur
	end
end
---------------------------------------------------------------------