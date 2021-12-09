--Tạo DATABASE QuanLyNhaHang
CREATE DATABASE QuanLyNhaHang
GO

USE QuanLyNhaHang
GO

--1. Tạo và nhập dữ liệu cho các quan hệ trên.
--2.Khai báo các khóa chính và khóa ngoại của quan hệ

--Tạo quan hệ NHAHANG
CREATE TABLE NHAHANG (
	MANH char(4),
	TENNH varchar(40),
	AMTHUC varchar(20),
	MAVT char(4),
	MADG char(4),
	CONSTRAINT PK_NHAHANG PRIMARY KEY (MANH)
);

--Tạo quan hệ VITRI
CREATE TABLE VITRI (
	MAVT char(4),
	QUAN varchar(40),
	THANHPHO varchar(40),
	CONSTRAINT PK_VITRI PRIMARY KEY (MAVT)
);

--Tạo quan hệ DANHGIA
CREATE TABLE DANHGIA (
	MADG char(4),
	DANHGIA float,
	GIATB money,
	SLDG int,
	CONSTRAINT PK_DANHGIA PRIMARY KEY (MADG)
);

--Khai báo khóa ngoại của quan hệ NHAHANG
ALTER TABLE NHAHANG ADD CONSTRAINT FK_NHAHANG_01 FOREIGN KEY (MAVT) REFERENCES VITRI (MAVT);
ALTER TABLE NHAHANG ADD CONSTRAINT FK_NHAHANG_02 FOREIGN KEY (MADG) REFERENCES DANHGIA (MADG);

--Nhập dữ liệu cho quan hệ NHAHANG
INSERT INTO NHAHANG VALUES ('NH01', 'Sushi Ngon', 'Nhat Ban', 'VT01', 'DG01');
INSERT INTO NHAHANG VALUES ('NH02', 'Tiem banh New York', 'My', 'VT03', 'DG02');
INSERT INTO NHAHANG VALUES ('NH03', 'Tiem tra Hoang Gia', 'My', 'VT01', 'DG03');
INSERT INTO NHAHANG VALUES ('NH04', 'Bun bo Hue', 'Viet Nam', 'VT01', 'DG04');

--Nhập dữ liệu cho quan hệ VITRI
INSERT INTO VITRI VALUES ('VT01', 'Thu Duc', ' Ho Chi Minh');
INSERT INTO VITRI VALUES ('VT02', 'Phu Nhuan', 'Ho Chi Minh');
INSERT INTO VITRI VALUES ('VT03', 'Ba Dinh', 'Ha Noi');

--Nhập dữ liệu cho quan hệ DANHGIA
INSERT INTO DANHGIA VALUES ('DG01', 3.5, 200000, 1531);
INSERT INTO DANHGIA VALUES ('DG02', 2.5, 550000, 324);
INSERT INTO DANHGIA VALUES ('DG03', 4.5, 420000, 83);
INSERT INTO DANHGIA VALUES ('DG04', 4.5, 80000, 815);

--3.Giá trung bình của các nhà hàng ở Ba Đình phải trên 50000 đồng
CREATE TRIGGER INSERT_NHAHANG 
ON dbo.NHAHANG FOR INSERT AS
BEGIN
	IF EXISTS (SELECT *
			   FROM (inserted AS I JOIN dbo.VITRI AS VT ON VT.MAVT = I.MAVT)
			   JOIN dbo.DANHGIA ON DANHGIA.MADG = I.MADG
			   WHERE VT.QUAN = 'Ba Dinh' AND GIATB <= 50000)
	BEGIN
		PRINT('Nha hang neu o Ba Dinh thi gia trung binh phai lon hon 50000 dong')
		ROLLBACK TRAN
	END 
END
GO

CREATE TRIGGER UPDATE_NHAHANG
ON dbo.NHAHANG FOR UPDATE AS
BEGIN
	IF UPDATE (MAVT) OR UPDATE (MADG)
	BEGIN
		IF EXISTS (SELECT *
				   FROM (inserted AS I JOIN dbo.VITRI AS VT ON VT.MAVT = I.MAVT)
				   JOIN dbo.DANHGIA ON DANHGIA.MADG = I.MADG
				   WHERE VT.QUAN = 'Ba Dinh' AND GIATB <= 50000)
		BEGIN
			PRINT('Nha hang neu o Ba Dinh thi gia trung binh phai tren 50000 dong')
			ROLLBACK TRAN
		END
	END
END
GO

CREATE TRIGGER UPDATE_VITRI
ON dbo.VITRI FOR UPDATE AS
BEGIN
	IF UPDATE (QUAN)
	BEGIN
		IF EXISTS (SELECT *
				   FROM (inserted AS I JOIN dbo.NHAHANG AS NH ON NH.MAVT = I.MAVT)
				   JOIN dbo.DANHGIA AS DG ON NH.MADG = DG.MADG
				   WHERE I.QUAN = 'Ba Dinh' AND GIATB <= 50000)
		BEGIN
			PRINT('Vi tri dang thoa nha hang o Ba Dinh co gia trung binh tren 50000 dong')
			ROLLBACK TRAN
		END
	END
END
GO

CREATE TRIGGER UPDATE_DANHGIA
ON dbo.DANHGIA FOR UPDATE AS
BEGIN
	IF UPDATE(GIATB)
	BEGIN
		IF EXISTS (SELECT *
				   FROM (inserted AS I JOIN dbo.NHAHANG AS NH ON NH.MADG = I.MADG)
				   JOIN dbo.VITRI AS VT ON VT.MAVT = NH.MAVT
				   WHERE VT.QUAN = 'Ba Dinh' AND I.GIATB <= 50000)
		BEGIN
			PRINT('Gia trung binh cua nha hang o Ba Dinh phai tren 50000 dong')
			ROLLBACK TRAN
		END
	END
END
GO

--4. Thêm vào thuộc tính GHICHU có kiểu dữ liệu varchar(40) cho quan hệ DANHGIA
ALTER TABLE DANHGIA ADD GHICHU varchar(40);

--5. In ra các nhà hàng (MANH, TENNH) phục vụ các món ăn của nền ẩm thực Mỹ
SELECT MANH, TENNH
FROM NHAHANG
WHERE AMTHUC = 'My';

--6. In ra các nhà hàng (MANH, TENNH, DANHGIA, GIATB, SLDG) ở thành phố Hồ Chí Minh theo thứ tự tăng dần về đánh giá và giảm dần về giá trung bình
SELECT MANH, TENNH, DANHGIA, GIATB, SLDG
FROM NHAHANG, VITRI, DANHGIA
WHERE NHAHANG.MAVT = VITRI.MAVT
AND NHAHANG.MADG = DANHGIA.MADG
AND THANHPHO = 'Ho Chi Minh'
ORDER BY DANHGIA ASC, GIATB DESC;


--7. In ra các vị trí (MAVT, QUAN, THANHPHO) không có nhà hàng nào được đánh giá
SELECT VITRI.MAVT, QUAN, THANHPHO
FROM VITRI LEFT JOIN NHAHANG
ON VITRI.MAVT = NHAHANG.MAVT
WHERE MADG = NULL;

--8. In ra số lượng nhà hàng có giá trung bình trên 500000 đông và số lượng nhà hàng có giá trung bình dưới 500000 đồng (SL_TREN, SL_DUOI)
SELECT COUNT(MANH) 'SL_TREN', (SELECT COUNT(MANH)
							   FROM NHAHANG, DANHGIA
							   WHERE NHAHANG.MADG = DANHGIA.MADG
							   AND GIATB < 500000) 'SL_DUOI'
FROM NHAHANG, DANHGIA
WHERE NHAHANG.MADG = DANHGIA.MADG
AND GIATB >= 500000;
