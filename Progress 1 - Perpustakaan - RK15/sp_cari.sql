alter procedure cariBukuByTag @tags nvarchar(max) as
begin
	declare @result table(
		idBuku int,
		judulBuku varchar(50)
	)
	declare @TableIdTag table(
		idTag int
	)
	declare @tempTag varchar(50)
	declare curTag cursor --cursor untuk ubah setiap nama tag jadi id_tag dan masuk ke tabel temporary id_tag
	for select * from splitTag(@tags)
	open curTag
	fetch next from curTag into @tempTag
	while @@FETCH_STATUS=0
	begin
		if exists (select id_tag from tag where namaTag = @tempTag)
		begin
			insert into @TableIdTag select id_tag from tag where namaTag = @tempTag
		end
		else 
		begin
			select 'tag '+@tempTag+' tidak terdaftar maka tag tersebut tidak akan dijadikan tag yang akan dicari.' as 'warning'
		end
		fetch next from curTag into @tempTag
	end
	close curTag
	deallocate curTag
	declare @tempIdBuku int --cursor untuk check setiap buku
	declare curBuku cursor
	for select distinct id_buku from buku_memiliki_tag
	open curBuku 
	fetch next from curBuku into @tempIdBuku
	while  @@FETCH_STATUS=0 
	begin
		declare @tempIdTag2 int, @flag int
		set @flag = 0
		declare curCheckTag cursor --cursor untuk check setiap tag dengan setiap buku
		for select idTag from @TableIdTag
		open curCheckTag
		fetch next from curCheckTag into @tempIdTag2
		while @flag = 0 and @@FETCH_STATUS=0
		begin
			if not exists (select id_tag from buku_memiliki_tag where id_buku = @tempIdBuku and id_tag = @tempIdTag2)
			begin
				set @flag = 1
			end
			else
			begin
				fetch next from curCheckTag into @tempIdTag2
			end
		end
		if @flag = 0 --kalo semua tag yang dicari ada di buku, masukin buku ke result
		begin
			insert into @result select @tempIdBuku, (select judulBuku from buku where id_buku = @tempIdBuku)
		end		
		close curCheckTag
		deallocate curCheckTag
		fetch next from curBuku into @tempIdBuku
	end 
	close curBuku
	deallocate curBuku
	if (select count(idBuku) from @result) = 0
	begin
		select 'Tidak ada buku yang memenuhi semua kriteria tag' as 'Error Message'
	end
	else
	begin
		select judulBuku from @result
	end
end

--------------------------------------------------------------
alter procedure cariJumlahEksemplarAvailableByTag @tags nvarchar(max) as
begin
	declare @buku table(
		judulBuku varchar(50)
	)
	declare @result table(
		idEksemplar int,
		judulBuku varchar(50)
	)
	insert into @buku exec cariBukuByTag @tags
	declare @tempJudul varchar(50)
	declare curBuku cursor
	for select * from @buku 
	open curBuku
	fetch next from curBuku into @tempJudul
	while @@FETCH_STATUS=0
	begin
		declare @idBuku int, @countEksemplar int, @tempIdEksemplar int
		set @idBuku = (select id_buku from buku where judulBuku = @tempJudul)
		declare curEks cursor 
		for select id_buku, id_eksemplar from eksemplar  where status_pinjaman = 0 and id_buku = @idBuku
		open curEks
		fetch next from curEks into @idBuku, @tempIdEksemplar
		while @@FETCH_STATUS=0
		begin
			insert into @result select @tempIdEksemplar, @tempJudul
			fetch next from curEks into @idBuku, @tempIdEksemplar
		end
		close curEks
		deallocate curEks		
		fetch next from curBuku into @tempJudul
	end
	close curBuku
	deallocate curBuku
	select count(idEksemplar) as 'Jumlah Eksemplar Available', judulBuku from @result group by judulBuku
end
----------------------------------------------------------------
alter procedure cariEksemplarAvailableByTag @tags nvarchar(max) as
begin
	declare @buku table(
		judulBuku varchar(50)
	)
	declare @result table(
		idEksemplar int,
		judulBuku varchar(50)
	)
	insert into @buku exec cariBukuByTag @tags
	declare @tempJudul varchar(50)
	declare curBuku cursor
	for select * from @buku 
	open curBuku
	fetch next from curBuku into @tempJudul
	while @@FETCH_STATUS=0
	begin
		declare @idBuku int, @countEksemplar int, @tempIdEksemplar int
		set @idBuku = (select id_buku from buku where judulBuku = @tempJudul)
		declare curEks cursor 
		for select id_buku, id_eksemplar from eksemplar  where status_pinjaman = 0 and id_buku = @idBuku
		open curEks
		fetch next from curEks into @idBuku, @tempIdEksemplar
		while @@FETCH_STATUS=0
		begin
			insert into @result select @tempIdEksemplar, @tempJudul
			fetch next from curEks into @idBuku, @tempIdEksemplar
		end
		close curEks
		deallocate curEks		
		fetch next from curBuku into @tempJudul
	end
	close curBuku
	deallocate curBuku
	select * from @result
end
-----------------------------------------------------------------------
alter function countTF (@judul varchar(50), @kata varchar(50))
returns	int
begin
	declare @res int 
	declare @temp table(
		kata varchar(50)
	)
	insert into @temp select * from splitTitle(@judul)
	set @res = (select count(kata) from @temp where kata = @kata)
	return @res
end
---------------------------------------------------------------------
alter function countBobot(@judul varchar(50), @kata varchar(50))
returns float
begin	
	declare @res float, @tf int, @idf float
	set @tf = (select dbo.countTF(@judul,@kata))
	set @idf = (select idf from kata where kata = @kata)
	set @res = @tf * @idf 
	return @res
end
----------------------------------------------------------------------
alter procedure cariBukuByJudul @judul varchar(50) as
begin
	--table hasil
	declare @result table(
		idBuku int,
		judulBuku varchar(50),
		kemiripan float
	)
	--table sementara menyimpan bobot tiap kata dari judul yang dicari
	declare @title table(
		kata varchar(50),
		bobot float
	)
	--insert tiap kata dari judul dan bobotnya ke table
	declare @tempKata varchar(50)
	declare curJudul cursor
	for select kata from splitTitle(@judul)
	open curJudul
	fetch next from curJudul into @tempKata
	while @@FETCH_STATUS = 0
	begin
		if not exists (select kata from @title where kata = @tempKata)
		begin
			insert into @title select @tempKata, (select dbo.countBobot(@judul,@tempKata))
		end		
		fetch next from curJudul into @tempKata
	end
	close curJudul
	deallocate curJudul
	-------------------------------------------------
	--cursor semua buku di table buku, check kemiripan tiap judul buku dengan judul input
	declare @tempJudul varchar(50), @tempId int
	declare curBuku cursor
	for select id_buku, judulBuku from buku
	open curBuku
	fetch next from curBuku into @tempId, @tempJudul
	while @@FETCH_STATUS = 0
	begin
		declare @kemiripan float, @tempKataDicari varchar(50), @tempBobot float
		set @kemiripan = 0
		declare curCheck cursor --cursor untuk mengecek dan menambahkan bobot setiap kata di table title dengan dari cursor buku untuk dihitung kemiripannya
		for select * from @title 
		open curCheck
		fetch next from curCheck into @tempKataDicari, @tempBobot
		while @@FETCH_STATUS=0
		begin
			declare @bobotKataDariBuku float, @bobotKataDicari float, @total float
			set @bobotKataDicari = (select bobot from @title where kata = @tempKataDicari)
			set @bobotKataDariBuku = 0
			--kalo kata yang dicari ada di judul buku, itung bobotnya, kaliin bobot keduanya, tambahin ke kemiripan
			if exists (select judulBuku from buku where id_buku = @tempId and judulBuku like '%'+@tempKataDicari+'%')
			begin
				set @bobotKataDariBuku = (select dbo.countBobot(@tempJudul,@tempKataDicari))
				set @total = @bobotKataDariBuku * @bobotKataDicari
				set @kemiripan += @total
			end
			fetch next from curCheck into @tempKataDicari, @tempBobot
		end
		close curCheck
		deallocate curCheck
		insert into @result select @tempId, @tempJudul, @kemiripan
		fetch next from curBuku into @tempId, @tempJudul
	end
	close curBuku
	deallocate curBuku
	select judulBuku from @result where kemiripan > 0 order by kemiripan desc 
end
--------------------------------------------------------------------------------------------
create procedure cariEksemplarAvailableByJudul @judul varchar(50) as
begin
	declare @buku table(
		judulBuku varchar(50)
	)
	declare @result table(
		idEksemplar int,
		judulBuku varchar(50)
	)
	insert into @buku exec cariBukuByJudul @judul
	declare @tempJudul varchar(50)
	declare curBuku cursor
	for select * from @buku 
	open curBuku
	fetch next from curBuku into @tempJudul
	while @@FETCH_STATUS=0
	begin
		declare @idBuku int, @countEksemplar int, @tempIdEksemplar int
		set @idBuku = (select id_buku from buku where judulBuku = @tempJudul)
		declare curEks cursor 
		for select id_buku, id_eksemplar from eksemplar  where status_pinjaman = 0 and id_buku = @idBuku
		open curEks
		fetch next from curEks into @idBuku, @tempIdEksemplar
		while @@FETCH_STATUS=0
		begin
			insert into @result select @tempIdEksemplar, @tempJudul
			fetch next from curEks into @idBuku, @tempIdEksemplar
		end
		close curEks
		deallocate curEks		
		fetch next from curBuku into @tempJudul
	end
	close curBuku
	deallocate curBuku
	select * from @result
end
-----------------------------------------------------------------------------------------
alter procedure cariBukuYangSifatnyaMirip @judul varchar(50) as
begin
	if exists (select judulBuku from buku where judulBuku = @judul)
	begin
		declare @id int
		set @id = (select id_buku from buku where judulBuku = @judul)
		declare @tableTag table(
			idTag int
		)
		declare @result table(
			idBuku int,
			judul varchar(50),
			kemiripan int
		)
		insert into @tableTag 
		select tag.id_tag from tag join buku_memiliki_tag on buku_memiliki_tag.id_tag = tag.id_tag where id_buku = @id
		declare @tempIdBuku int
		declare curBuku cursor
		for select id_buku from buku where id_buku != @id
		open curBuku
		fetch next from curBuku into @tempIdBuku
		while @@FETCH_STATUS=0
		begin
			declare @kemiripan int, @tempIdTag int
			set @kemiripan = 0
			declare curTag cursor
			for select * from @tableTag
			open curTag
			fetch next from curTag into @tempIdTag
			while @@FETCH_STATUS=0
			begin
				if exists(select id_tag from buku_memiliki_tag where id_buku = @tempIdBuku and id_tag = @tempIdTag)
				begin
					set @kemiripan += 1
				end
				fetch next from curTag into @tempIdTag
			end
			close curTag
			deallocate curTag
			insert into @result 
			select @tempIdBuku,(select judulBuku from buku where id_buku = @tempIdBuku), @kemiripan
			fetch next from curBuku into @tempIdBuku
		end
		close curBuku
		deallocate curBuku
		select * from @result where kemiripan>0 order by kemiripan desc
	end
	else
	begin
		select 'Judul buku yang anda masukkan tidak terdaftar' as 'Error Message'
	end
end
--------------------------------------------------------------------------------------------------------------------
alter procedure cariJenisBukuFavorit as
begin
	declare @result table(
		tag varchar(50),
		skor int
	)
	declare @tempTag table(
		tag varchar(50)
	)
	declare @tempIdEks int
	declare curPeminjaman cursor
	for select id_eksemplar from peminjaman
	open curPeminjaman
	fetch next from curPeminjaman into @tempIdEks
	while @@FETCH_STATUS=0
	begin
		declare @idBuku int, @tempNamaTag varchar(50)
		set @idBuku = (select id_buku from eksemplar where id_eksemplar = @tempIdEks)
		insert into @tempTag 
		select tag.namaTag from buku_memiliki_tag join tag on buku_memiliki_tag.id_tag = tag.id_tag where id_buku = @idBuku 
		declare curTag cursor
		for select tag from @tempTag
		open curTag
		fetch next from curTag into @tempNamaTag
		while @@FETCH_STATUS=0
		begin
			if not exists (select tag from @result where tag = @tempNamaTag)
			begin
				insert into @result select @tempNamaTag,0
			end
			else
			begin
				update @result
				set skor = skor + 1
				where tag = @tempNamaTag
			end
			fetch next from curTag into @tempNamaTag
		end
		close curTag
		deallocate curTag
		fetch next from curPeminjaman into @tempIdEks
	end
	close curPeminjaman
	deallocate curPeminjaman
	select top 1 * from @result
end
--------------------------------------------------------------------------------
alter procedure cariBukuPalingSeringTerpinjam as
begin
	declare @result table(
		idBuku int,
		judul varchar(50),
		skor int
	)	
	declare @tempIdEks int
	declare curPeminjaman cursor
	for select id_eksemplar from peminjaman
	open curPeminjaman
	fetch next from curPeminjaman into @tempIdEks
	while @@FETCH_STATUS=0
	begin
		declare @idBuku int
		set @idBuku = (select id_buku from eksemplar where id_eksemplar = @tempIdEks)
		if not exists(select idBuku from @result where idBuku = @idBuku)
		begin
			insert into @result select @idBuku,(select judulBuku from buku where id_buku = @idBuku),1
		end
		else
		begin
			update @result
			set skor = skor + 1
			where idBuku = @idBuku
		end
		fetch next from curPeminjaman into @tempIdEks
	end
	close curPeminjaman
	deallocate curPeminjaman
	select top 5 * from @result
end



