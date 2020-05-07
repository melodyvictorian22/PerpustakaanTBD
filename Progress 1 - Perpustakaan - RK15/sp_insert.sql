--Untuk memasukkan nama pengarang
create procedure insertPengarang @namaPengarang varchar(50) as
	begin
		if not exists (select * from Pengarang where namaPengarang = @namaPengarang)
		begin
			INSERT INTO pengarang select @namaPengarang
		end
		else
		begin
			select 'Pengarang sudah terdaftar' as 'Error Message'
		end
	end
	select * from pengarang

---------------------------------------------
--Untuk memasukkan tag
create procedure insertTag @tag varchar(50) as
	begin
		if not exists (select * from tag where namaTag = @tag)
		begin
			insert into tag select @tag
		end
		else
		begin
			select 'Tag sudah terdaftar' as 'Error Message'
		end
	end
	select * from tag

-----------------------------------------------
--Untuk memasukkan anggota dengan parameter nama anggota, email, dan password
create procedure insertMember @namaAnggota varchar(50), @email varchar(50), @pass varchar(50) as
	begin
		if not exists (select namaAnggota from anggota where namaAnggota = @namaAnggota)
		begin
			insert into anggota select @namaAnggota, @email, (HASHBYTES('SHA2_512', @pass+CAST(@namaAnggota AS NVARCHAR(36))))
		end
		else
		begin
			select 'Member sudah terdaftar' as 'Error Message'
		end
	end
	select * from Anggota

---------------------------------------------------
--Untuk memisahkan judul buku menjadi kata-kata
create function splitTitle
(
	@input varchar(50)
)
returns @res table(
	kata varchar(50)
)
begin
	declare @i int
	set @i = 1
	declare @index int
	declare @selisih int
	declare @prev int
	set @prev = 0
	if SUBSTRING(@input, LEN(@input), LEN(@input)) != ' ' 
	begin
		set @input += ' '
	end
	while(@i <= LEN(@input))
	begin
		set @index = CHARINDEX(' ',@input,@i)
		insert into @res select SUBSTRING(@input,@i,@index-@i)
		set @i = @index + 1
	end
	return
end

-----------------------------------------------------------
--Untuk memisahkan tag berdasarkan koma dari inputBuku
create function splitTag
(
	@input varchar(50)
)
returns @res table(
	kata varchar(50)
)
begin
	declare @i int
	set @i = 1
	declare @index int
	declare @selisih int
	declare @prev int
	set @prev = 0
	if SUBSTRING(@input, LEN(@input), LEN(@input)) != ',' 
	begin
		set @input += ','
	end
	while(@i <= LEN(@input))
	begin
		set @index = CHARINDEX(',',@input,@i)
		insert into @res select SUBSTRING(@input,@i,@index-@i)
		set @i = @index + 1
	end
	return
end

------------------------------------------------------------
--Untuk memasukkan buku baru dengan parameter judul buku, nama pengarang, tag, jumlah eksemplar
create procedure insertBuku 
    @judulBuku varchar(50), 
    @namaPengarang varchar(50),
    @tag NVARCHAR(max),
    @jmlEksemplar int
as
begin
    --insert pengarang
    exec insertPengarang @namaPengarang
    --insert buku
    if not exists (select * from Buku where judulBuku = @judulBuku)
        begin
            INSERT INTO buku select @judulBuku, (select id_pengarang from pengarang where namaPengarang = @namaPengarang)
        end
    else
        begin
            select 'Buku sudah terdaftar' as 'Error Message'
        end
    --insert tag
    declare @idBuku int
    set @idBuku = (select id_buku from buku where judulBuku = @judulBuku)
    declare @tempTag varchar(50)
    declare curTag cursor
    for select * from splitTag(@tag)
    open curTag
    fetch next from curTag into @tempTag
    declare @idTag int
    while(@@FETCH_STATUS = 0)
    begin
        exec insertTag @tempTag
        set @idTag = (select id_tag from tag where namaTag = @tempTag)
        if not exists (select * from buku_memiliki_tag where id_buku = @idBuku and id_tag = @idTag)
        begin
            insert into buku_memiliki_tag select @idTag, @idBuku
        end
        fetch next from curTag into @tempTag
    end
    close curTag
    deallocate curTag
    --insert kata
    declare @tempKata varchar(50) 
    declare curKata cursor
    for select * from splitTitle(@judulBuku)
    open curKata
    fetch next from curKata into @tempKata
    while(@@FETCH_STATUS = 0)
    begin
        exec insertKata @tempKata
        if not exists (select * from buku_memiliki_kata where id_buku = @idBuku and kata = @tempKata)
        begin
            insert into buku_memiliki_kata select @tempKata, @idBuku
        end
        fetch next from curKata into @tempKata
    end
    close curKata
    deallocate curKata
--insert eksemplar
    declare @iterator int
    set @iterator = 0
    while(@iterator<@jmlEksemplar)
    begin
        insert into eksemplar (status_pinjaman,id_pinjaman,id_buku) values( 0,-1, (select id_buku from buku where judulBuku = @judulBuku))
        set @iterator += 1
    end
end

------------------------------------------------------------------
--Untuk memasukkan kata dari insertBuku
create procedure insertKata @kata varchar(50) as
	begin
		declare @counterBuku int, @counterBukuContainKata int
		if not exists (select * from kata where kata = @kata)
		begin			
			set @counterBuku = (select count(id_buku) from buku) 
			set @counterBukuContainKata = (select count(id_buku) from buku where judulBuku like '%'+@kata+'%')
			insert into kata select LOG10(@counterBuku/@counterBukuContainKata), @kata
		end
		else
		begin
			set @counterBuku = (select count(id_buku) from buku) 
			set @counterBukuContainKata = (select count(id_buku) from buku where judulBuku like '%'+@kata+'%')
			if @counterBukuContainKata = 0
			begin
				delete from kata where kata = @kata
			end
			else
			begin
				update kata
				set idf = LOG10(@counterBuku/@counterBukuContainKata)
				where kata = @kata
			end
		end
	end
	
-----------------------------------------------------------------
--Untuk melakukan peminjaman buku dengan nama parameter nama peminjam dan nama eksemplar(buku)
alter procedure insertPinjamanBaru @namaPeminjam varchar(50), @namaEks varchar(50) as
begin
	declare @idAnggota int, @idBuku int
	set @idAnggota = (select idAnggota from anggota where namaAnggota like '%'+@namaPeminjam+'%')
	if(@idAnggota is not null)
	begin
		set @idBuku = (select id_buku from buku where judulBuku = @namaEks)
		if(@idBuku is not null)
		begin
			declare @stat int
			declare @idAvail int, @idTemp int
			set @idAvail = -1
			declare cur cursor
			for select id_eksemplar, status_pinjaman from eksemplar where id_buku = @idBuku
			open cur
			fetch next from cur into @idTemp, @stat
			while(@@FETCH_STATUS=0)
			begin
				if @stat = 0
				begin
					set @idAvail = @idTemp
				end
				fetch next from cur into @idTemp, @stat
			end
			close cur
			deallocate cur
			if(@idAvail != -1)
			begin 
				declare @tglPinjam date, @tglKembali date
				set @tglPinjam = GETDATE()
				set @tglKembali = DATEADD(day,7,@tglPinjam)
				insert into peminjaman select @tglPinjam, @tglKembali, @idAnggota, @idAvail,1
				update eksemplar
				set status_pinjaman = 1
				where id_eksemplar = @idAvail
				update eksemplar
				set id_pinjaman = (select id_pinjaman from peminjaman where id_anggota=@idAnggota and id_eksemplar=@idAvail)
				where id_eksemplar = @idAvail
			end
			else
			begin
				select 'Tidak ada buku yg bisa dipinjam' as 'Error Message'
			end
			
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

----------------------------------------------------------------------------------------
