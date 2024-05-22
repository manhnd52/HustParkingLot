PGDMP      *                |            carPark    16.2    16.2 g    o           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            p           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            q           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            r           1262    17940    carPark    DATABASE     �   CREATE DATABASE "carPark" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE "carPark";
                postgres    false            �            1255    18369    addcustomer(boolean)    FUNCTION     �   CREATE FUNCTION public.addcustomer(type boolean) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare 
	id int;
begin
	INSERT INTO Customer(CustomerType)
	VALUES(type)
	RETURNING customerid INTO id;
	RETURN id;
end;
$$;
 0   DROP FUNCTION public.addcustomer(type boolean);
       public          postgres    false            �            1255    18374 &   addstudent(integer, character varying) 	   PROCEDURE     :  CREATE PROCEDURE public.addstudent(IN in_mssv integer, IN in_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
	id int;
BEGIN
	INSERT INTO Customer(customertype) 
	VALUES (false)
	RETURNING customerid INTO id;
	INSERT INTO Student(customerid, fullname, mssv) 
	VALUES (id, in_name, in_mssv);
END;
$$;
 T   DROP PROCEDURE public.addstudent(IN in_mssv integer, IN in_name character varying);
       public          postgres    false            �            1255    18372    addvisitor()    FUNCTION     >  CREATE FUNCTION public.addvisitor() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
declare 
	id int;
	ticket varchar;
begin
	INSERT INTO Customer(CustomerType)
	VALUES(true)
	RETURNING customerid INTO id;
	INSERT INTO Visitor(customerid)
	VALUES(id)
	RETURNING ticketid INTO ticket;
	RETURN ticket;
end;
$$;
 #   DROP FUNCTION public.addvisitor();
       public          postgres    false            �            1255    18561 #   getavailablespots(integer, integer)    FUNCTION     �  CREATE FUNCTION public.getavailablespots(input_parkinglotid integer, input_size integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		spot_id int;
	BEGIN
		SELECT parkingspotid INTO spot_id
		FROM parking_spot p
		WHERE 
			parkinglotid = input_parkinglotid
			AND input_size = (SELECT size FROM spot_type s WHERE p.spottypeid = s.spottypeid)
			AND NOT occupied 
		LIMIT 1;
		RETURN spot_id;
	END;
$$;
 X   DROP FUNCTION public.getavailablespots(input_parkinglotid integer, input_size integer);
       public          postgres    false            �            1255    18393     getcustomerid(character varying)    FUNCTION     �  CREATE FUNCTION public.getcustomerid(input_mssv character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	customer_id INT;
BEGIN
	IF length(input_mssv) = 8 THEN
		SELECT customerid INTO customer_id
		FROM student WHERE mssv = input_mssv;
	ELSE 
		SELECT customerid INTO customer_id
		FROM visitor WHERE ticketid::varchar = input_mssv;
	END IF;
	If customer_id IS NOT NULL then
			RETURN customer_id;
		ELSE
			RAISE 'Khong ton tai mssv';
		END IF;
END;
$$;
 B   DROP FUNCTION public.getcustomerid(input_mssv character varying);
       public          postgres    false            �            1255    18400    getparkinglotid(integer)    FUNCTION     �   CREATE FUNCTION public.getparkinglotid(input_staffid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	parkinglot int;
BEGIN
	SELECT parkinglotid INTO parkinglot FROM staff where staffid = input_staffid;
	RETURN parkinglot;
END;
$$;
 =   DROP FUNCTION public.getparkinglotid(input_staffid integer);
       public          postgres    false                       1255    18576    getvehicleid(character varying)    FUNCTION     �  CREATE FUNCTION public.getvehicleid(string character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    o_vehicleId INT;
BEGIN
    IF length(string) = 8 THEN
        SELECT vehicleid INTO o_vehicleId
        FROM now_vehicle
        WHERE customerid IN (
            SELECT customerid
            FROM student
            WHERE mssv = string
        );
	ELSE 
		SELECT vehicleid INTO o_vehicleId
		FROM now_vehicle 
		WHERE customerid IN (
			SELECT customerid
			FROM visitor
			WHERE ticketid::varchar = string
		);
	END IF;
	IF o_vehicleId IS NOT NULL THEN
    RETURN o_vehicleId;
	ELSE raise 'Không tìm thấy!';
	END IF;
END;
$$;
 =   DROP FUNCTION public.getvehicleid(string character varying);
       public          postgres    false                       1255    18562    is_occuppied()    FUNCTION     �   CREATE FUNCTION public.is_occuppied() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		UPDATE parking_spot
		SET occupied = TRUE
		WHERE parkingspotid = new.parkingspotid;
		RETURN NEW;
	END;
$$;
 %   DROP FUNCTION public.is_occuppied();
       public          postgres    false            �            1255    18237    payin_log_func()    FUNCTION        CREATE FUNCTION public.payin_log_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   INSERT INTO transaction (mssv, amount, time, tranaction_type)
   VALUES (NEW.mssv, NEW.balance - OLD.balance, current_timestamp, true);
   RETURN NEW;
END;
$$;
 '   DROP FUNCTION public.payin_log_func();
       public          postgres    false                       1255    18573    trigger_customer_out()    FUNCTION     9  CREATE FUNCTION public.trigger_customer_out() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	raise notice 'Đã vào trigger!';
	IF OLD.exit_time IS NULL THEN
		raise notice 'UPDATING';
		UPDATE parking_spot
		SET occupied = FALSE 
		WHERE parkingspotid = OLD.parkingspotid;
	END IF;
	RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.trigger_customer_out();
       public          postgres    false            �            1255    18235    trigger_function()    FUNCTION     �   CREATE FUNCTION public.trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   INSERT INTO transaction (mssv, amount, time, tranaction_type)
   VALUES (NEW.mssv, NEW.balance - OLD.balance, 1);
   RETURN NEW;
END;
$$;
 )   DROP FUNCTION public.trigger_function();
       public          postgres    false                       1255    18575    vehicle_out(integer) 	   PROCEDURE     �   CREATE PROCEDURE public.vehicle_out(IN vehicleid integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE park
  SET exit_time = now()
  WHERE vehicleid = input_vehicleid;
END;
$$;
 9   DROP PROCEDURE public.vehicle_out(IN vehicleid integer);
       public          postgres    false            �            1259    18076    customer    TABLE     \   CREATE TABLE public.customer (
    customerid integer NOT NULL,
    customertype boolean
);
    DROP TABLE public.customer;
       public         heap    postgres    false            �            1259    18075    customer_customerid_seq    SEQUENCE     �   CREATE SEQUENCE public.customer_customerid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.customer_customerid_seq;
       public          postgres    false    219            s           0    0    customer_customerid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.customer_customerid_seq OWNED BY public.customer.customerid;
          public          postgres    false    218            �            1259    18049    customerid_seq    SEQUENCE     w   CREATE SEQUENCE public.customerid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.customerid_seq;
       public          postgres    false            �            1259    18394    nhap    TABLE     9   CREATE TABLE public.nhap (
    data character varying
);
    DROP TABLE public.nhap;
       public         heap    postgres    false            �            1259    18141    now_vehicle    TABLE     �   CREATE TABLE public.now_vehicle (
    vehicleid integer NOT NULL,
    vehicletypeid integer,
    license_plate character varying(15),
    color character varying(15),
    customerid integer
);
    DROP TABLE public.now_vehicle;
       public         heap    postgres    false            �            1259    18205    park    TABLE     �   CREATE TABLE public.park (
    parkid integer NOT NULL,
    vehicleid integer,
    parkingspotid integer,
    entry_time timestamp without time zone,
    exit_time timestamp without time zone
);
    DROP TABLE public.park;
       public         heap    postgres    false            �            1259    18204    park_parkid_seq    SEQUENCE     �   CREATE SEQUENCE public.park_parkid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.park_parkid_seq;
       public          postgres    false    237            t           0    0    park_parkid_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.park_parkid_seq OWNED BY public.park.parkid;
          public          postgres    false    236            �            1259    18165    parking_lot    TABLE     }   CREATE TABLE public.parking_lot (
    parkinglotid integer NOT NULL,
    name character varying(16),
    capacity integer
);
    DROP TABLE public.parking_lot;
       public         heap    postgres    false            �            1259    18164    parking_lot_parkinglotid_seq    SEQUENCE     �   CREATE SEQUENCE public.parking_lot_parkinglotid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.parking_lot_parkinglotid_seq;
       public          postgres    false    231            u           0    0    parking_lot_parkinglotid_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.parking_lot_parkinglotid_seq OWNED BY public.parking_lot.parkinglotid;
          public          postgres    false    230            �            1259    18187    parking_spot    TABLE     �   CREATE TABLE public.parking_spot (
    parkingspotid integer NOT NULL,
    spottypeid integer,
    parkinglotid integer,
    occupied boolean DEFAULT false
);
     DROP TABLE public.parking_spot;
       public         heap    postgres    false            �            1259    18186    parking_spot_parkingspotid_seq    SEQUENCE     �   CREATE SEQUENCE public.parking_spot_parkingspotid_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.parking_spot_parkingspotid_seq;
       public          postgres    false    235            v           0    0    parking_spot_parkingspotid_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.parking_spot_parkingspotid_seq OWNED BY public.parking_spot.parkingspotid;
          public          postgres    false    234            �            1259    18158 	   spot_type    TABLE     V   CREATE TABLE public.spot_type (
    spottypeid integer NOT NULL,
    size smallint
);
    DROP TABLE public.spot_type;
       public         heap    postgres    false            �            1259    18157    spot_type_spottypeid_seq    SEQUENCE     �   CREATE SEQUENCE public.spot_type_spottypeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.spot_type_spottypeid_seq;
       public          postgres    false    229            w           0    0    spot_type_spottypeid_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.spot_type_spottypeid_seq OWNED BY public.spot_type.spottypeid;
          public          postgres    false    228            �            1259    18172    staff    TABLE       CREATE TABLE public.staff (
    staffid integer NOT NULL,
    fullname character varying(256),
    password character varying DEFAULT '12345678'::character varying,
    parkinglotid integer,
    CONSTRAINT staff_password_check CHECK ((length((password)::text) >= 8))
);
    DROP TABLE public.staff;
       public         heap    postgres    false            �            1259    18171    staff_staffid_seq    SEQUENCE     �   CREATE SEQUENCE public.staff_staffid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.staff_staffid_seq;
       public          postgres    false    233            x           0    0    staff_staffid_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.staff_staffid_seq OWNED BY public.staff.staffid;
          public          postgres    false    232            �            1259    18093    student    TABLE     �   CREATE TABLE public.student (
    customerid integer NOT NULL,
    fullname character varying(255),
    mssv character varying(8),
    balance integer DEFAULT 0,
    password character varying DEFAULT '123456'::character varying
);
    DROP TABLE public.student;
       public         heap    postgres    false            �            1259    18109    transaction    TABLE     �   CREATE TABLE public.transaction (
    transactionid integer NOT NULL,
    mssv character varying(8),
    amount integer,
    "time" timestamp without time zone,
    tranaction_type boolean
);
    DROP TABLE public.transaction;
       public         heap    postgres    false            �            1259    18108    transaction_transactionid_seq    SEQUENCE     �   CREATE SEQUENCE public.transaction_transactionid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.transaction_transactionid_seq;
       public          postgres    false    223            y           0    0    transaction_transactionid_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.transaction_transactionid_seq OWNED BY public.transaction.transactionid;
          public          postgres    false    222            �            1259    18121    vehicle_type    TABLE     �   CREATE TABLE public.vehicle_type (
    vehicletypeid integer NOT NULL,
    name character varying(15),
    price integer,
    size smallint,
    CONSTRAINT vehicle_type_price_check CHECK ((price >= 0))
);
     DROP TABLE public.vehicle_type;
       public         heap    postgres    false            �            1259    18120    vehicle_type_vehicletypeid_seq    SEQUENCE     �   CREATE SEQUENCE public.vehicle_type_vehicletypeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.vehicle_type_vehicletypeid_seq;
       public          postgres    false    225            z           0    0    vehicle_type_vehicletypeid_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.vehicle_type_vehicletypeid_seq OWNED BY public.vehicle_type.vehicletypeid;
          public          postgres    false    224            �            1259    18140    vehicle_vehicleid_seq    SEQUENCE     �   CREATE SEQUENCE public.vehicle_vehicleid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.vehicle_vehicleid_seq;
       public          postgres    false    227            {           0    0    vehicle_vehicleid_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.vehicle_vehicleid_seq OWNED BY public.now_vehicle.vehicleid;
          public          postgres    false    226            �            1259    18082    visitor    TABLE     n   CREATE TABLE public.visitor (
    customerid integer NOT NULL,
    ticketid uuid DEFAULT gen_random_uuid()
);
    DROP TABLE public.visitor;
       public         heap    postgres    false            �           2604    18079    customer customerid    DEFAULT     z   ALTER TABLE ONLY public.customer ALTER COLUMN customerid SET DEFAULT nextval('public.customer_customerid_seq'::regclass);
 B   ALTER TABLE public.customer ALTER COLUMN customerid DROP DEFAULT;
       public          postgres    false    219    218    219            �           2604    18144    now_vehicle vehicleid    DEFAULT     z   ALTER TABLE ONLY public.now_vehicle ALTER COLUMN vehicleid SET DEFAULT nextval('public.vehicle_vehicleid_seq'::regclass);
 D   ALTER TABLE public.now_vehicle ALTER COLUMN vehicleid DROP DEFAULT;
       public          postgres    false    226    227    227            �           2604    18208    park parkid    DEFAULT     j   ALTER TABLE ONLY public.park ALTER COLUMN parkid SET DEFAULT nextval('public.park_parkid_seq'::regclass);
 :   ALTER TABLE public.park ALTER COLUMN parkid DROP DEFAULT;
       public          postgres    false    237    236    237            �           2604    18168    parking_lot parkinglotid    DEFAULT     �   ALTER TABLE ONLY public.parking_lot ALTER COLUMN parkinglotid SET DEFAULT nextval('public.parking_lot_parkinglotid_seq'::regclass);
 G   ALTER TABLE public.parking_lot ALTER COLUMN parkinglotid DROP DEFAULT;
       public          postgres    false    231    230    231            �           2604    18190    parking_spot parkingspotid    DEFAULT     �   ALTER TABLE ONLY public.parking_spot ALTER COLUMN parkingspotid SET DEFAULT nextval('public.parking_spot_parkingspotid_seq'::regclass);
 I   ALTER TABLE public.parking_spot ALTER COLUMN parkingspotid DROP DEFAULT;
       public          postgres    false    235    234    235            �           2604    18161    spot_type spottypeid    DEFAULT     |   ALTER TABLE ONLY public.spot_type ALTER COLUMN spottypeid SET DEFAULT nextval('public.spot_type_spottypeid_seq'::regclass);
 C   ALTER TABLE public.spot_type ALTER COLUMN spottypeid DROP DEFAULT;
       public          postgres    false    229    228    229            �           2604    18175    staff staffid    DEFAULT     n   ALTER TABLE ONLY public.staff ALTER COLUMN staffid SET DEFAULT nextval('public.staff_staffid_seq'::regclass);
 <   ALTER TABLE public.staff ALTER COLUMN staffid DROP DEFAULT;
       public          postgres    false    233    232    233            �           2604    18112    transaction transactionid    DEFAULT     �   ALTER TABLE ONLY public.transaction ALTER COLUMN transactionid SET DEFAULT nextval('public.transaction_transactionid_seq'::regclass);
 H   ALTER TABLE public.transaction ALTER COLUMN transactionid DROP DEFAULT;
       public          postgres    false    222    223    223            �           2604    18124    vehicle_type vehicletypeid    DEFAULT     �   ALTER TABLE ONLY public.vehicle_type ALTER COLUMN vehicletypeid SET DEFAULT nextval('public.vehicle_type_vehicletypeid_seq'::regclass);
 I   ALTER TABLE public.vehicle_type ALTER COLUMN vehicletypeid DROP DEFAULT;
       public          postgres    false    224    225    225            Y          0    18076    customer 
   TABLE DATA           <   COPY public.customer (customerid, customertype) FROM stdin;
    public          postgres    false    219   ,�       l          0    18394    nhap 
   TABLE DATA           $   COPY public.nhap (data) FROM stdin;
    public          postgres    false    238   ��       a          0    18141    now_vehicle 
   TABLE DATA           a   COPY public.now_vehicle (vehicleid, vehicletypeid, license_plate, color, customerid) FROM stdin;
    public          postgres    false    227   ��       k          0    18205    park 
   TABLE DATA           W   COPY public.park (parkid, vehicleid, parkingspotid, entry_time, exit_time) FROM stdin;
    public          postgres    false    237   �       e          0    18165    parking_lot 
   TABLE DATA           C   COPY public.parking_lot (parkinglotid, name, capacity) FROM stdin;
    public          postgres    false    231   ��       i          0    18187    parking_spot 
   TABLE DATA           Y   COPY public.parking_spot (parkingspotid, spottypeid, parkinglotid, occupied) FROM stdin;
    public          postgres    false    235   ΄       c          0    18158 	   spot_type 
   TABLE DATA           5   COPY public.spot_type (spottypeid, size) FROM stdin;
    public          postgres    false    229   !�       g          0    18172    staff 
   TABLE DATA           J   COPY public.staff (staffid, fullname, password, parkinglotid) FROM stdin;
    public          postgres    false    233   K�       [          0    18093    student 
   TABLE DATA           P   COPY public.student (customerid, fullname, mssv, balance, password) FROM stdin;
    public          postgres    false    221   ��       ]          0    18109    transaction 
   TABLE DATA           [   COPY public.transaction (transactionid, mssv, amount, "time", tranaction_type) FROM stdin;
    public          postgres    false    223   S�       _          0    18121    vehicle_type 
   TABLE DATA           H   COPY public.vehicle_type (vehicletypeid, name, price, size) FROM stdin;
    public          postgres    false    225   ��       Z          0    18082    visitor 
   TABLE DATA           7   COPY public.visitor (customerid, ticketid) FROM stdin;
    public          postgres    false    220   ��       |           0    0    customer_customerid_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.customer_customerid_seq', 31, true);
          public          postgres    false    218            }           0    0    customerid_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.customerid_seq', 1, false);
          public          postgres    false    217            ~           0    0    park_parkid_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.park_parkid_seq', 11, true);
          public          postgres    false    236                       0    0    parking_lot_parkinglotid_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.parking_lot_parkinglotid_seq', 1, false);
          public          postgres    false    230            �           0    0    parking_spot_parkingspotid_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.parking_spot_parkingspotid_seq', 2300, true);
          public          postgres    false    234            �           0    0    spot_type_spottypeid_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.spot_type_spottypeid_seq', 1, false);
          public          postgres    false    228            �           0    0    staff_staffid_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.staff_staffid_seq', 3, true);
          public          postgres    false    232            �           0    0    transaction_transactionid_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.transaction_transactionid_seq', 8, true);
          public          postgres    false    222            �           0    0    vehicle_type_vehicletypeid_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.vehicle_type_vehicletypeid_seq', 1, false);
          public          postgres    false    224            �           0    0    vehicle_vehicleid_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.vehicle_vehicleid_seq', 32, true);
          public          postgres    false    226            �           2606    18081    customer customer_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customerid);
 @   ALTER TABLE ONLY public.customer DROP CONSTRAINT customer_pkey;
       public            postgres    false    219            �           2606    18210    park park_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_pkey PRIMARY KEY (parkid);
 8   ALTER TABLE ONLY public.park DROP CONSTRAINT park_pkey;
       public            postgres    false    237            �           2606    18170    parking_lot parking_lot_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.parking_lot
    ADD CONSTRAINT parking_lot_pkey PRIMARY KEY (parkinglotid);
 F   ALTER TABLE ONLY public.parking_lot DROP CONSTRAINT parking_lot_pkey;
       public            postgres    false    231            �           2606    18193    parking_spot parking_spot_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_pkey PRIMARY KEY (parkingspotid);
 H   ALTER TABLE ONLY public.parking_spot DROP CONSTRAINT parking_spot_pkey;
       public            postgres    false    235            �           2606    18163    spot_type spot_type_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.spot_type
    ADD CONSTRAINT spot_type_pkey PRIMARY KEY (spottypeid);
 B   ALTER TABLE ONLY public.spot_type DROP CONSTRAINT spot_type_pkey;
       public            postgres    false    229            �           2606    18180    staff staff_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staffid);
 :   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_pkey;
       public            postgres    false    233            �           2606    18101    student student_mssv_key 
   CONSTRAINT     S   ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_mssv_key UNIQUE (mssv);
 B   ALTER TABLE ONLY public.student DROP CONSTRAINT student_mssv_key;
       public            postgres    false    221            �           2606    18099    student student_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (customerid);
 >   ALTER TABLE ONLY public.student DROP CONSTRAINT student_pkey;
       public            postgres    false    221            �           2606    18390 "   now_vehicle vehicle_customerid_key 
   CONSTRAINT     c   ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_customerid_key UNIQUE (customerid);
 L   ALTER TABLE ONLY public.now_vehicle DROP CONSTRAINT vehicle_customerid_key;
       public            postgres    false    227            �           2606    18388    now_vehicle vehicle_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (vehicleid);
 B   ALTER TABLE ONLY public.now_vehicle DROP CONSTRAINT vehicle_pkey;
       public            postgres    false    227            �           2606    18127    vehicle_type vehicle_type_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.vehicle_type
    ADD CONSTRAINT vehicle_type_pkey PRIMARY KEY (vehicletypeid);
 H   ALTER TABLE ONLY public.vehicle_type DROP CONSTRAINT vehicle_type_pkey;
       public            postgres    false    225            �           2606    18087    visitor visitor_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.visitor
    ADD CONSTRAINT visitor_pkey PRIMARY KEY (customerid);
 >   ALTER TABLE ONLY public.visitor DROP CONSTRAINT visitor_pkey;
       public            postgres    false    220            �           2620    18574    park auto_isnot_occupied    TRIGGER     �   CREATE TRIGGER auto_isnot_occupied BEFORE UPDATE OF exit_time ON public.park FOR EACH ROW EXECUTE FUNCTION public.trigger_customer_out();
 1   DROP TRIGGER auto_isnot_occupied ON public.park;
       public          postgres    false    237    237    260            �           2620    18563    park auto_update_occupied    TRIGGER     u   CREATE TRIGGER auto_update_occupied AFTER INSERT ON public.park FOR EACH ROW EXECUTE FUNCTION public.is_occuppied();
 2   DROP TRIGGER auto_update_occupied ON public.park;
       public          postgres    false    257    237            �           2620    18238    student payin_log    TRIGGER     z   CREATE TRIGGER payin_log AFTER UPDATE OF balance ON public.student FOR EACH ROW EXECUTE FUNCTION public.payin_log_func();
 *   DROP TRIGGER payin_log ON public.student;
       public          postgres    false    221    221    240            �           2606    18211    park park_parkingspotid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_parkingspotid_fkey FOREIGN KEY (parkingspotid) REFERENCES public.parking_spot(parkingspotid);
 F   ALTER TABLE ONLY public.park DROP CONSTRAINT park_parkingspotid_fkey;
       public          postgres    false    235    4792    237            �           2606    18566    park park_vehicleid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_vehicleid_fkey FOREIGN KEY (vehicleid) REFERENCES public.now_vehicle(vehicleid) NOT VALID;
 B   ALTER TABLE ONLY public.park DROP CONSTRAINT park_vehicleid_fkey;
       public          postgres    false    227    4784    237            �           2606    18199 +   parking_spot parking_spot_parkinglotid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_parkinglotid_fkey FOREIGN KEY (parkinglotid) REFERENCES public.parking_lot(parkinglotid);
 U   ALTER TABLE ONLY public.parking_spot DROP CONSTRAINT parking_spot_parkinglotid_fkey;
       public          postgres    false    235    231    4788            �           2606    18194 )   parking_spot parking_spot_spottypeid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_spottypeid_fkey FOREIGN KEY (spottypeid) REFERENCES public.spot_type(spottypeid);
 S   ALTER TABLE ONLY public.parking_spot DROP CONSTRAINT parking_spot_spottypeid_fkey;
       public          postgres    false    235    229    4786            �           2606    18181    staff staff_parkinglotid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_parkinglotid_fkey FOREIGN KEY (parkinglotid) REFERENCES public.parking_lot(parkinglotid);
 G   ALTER TABLE ONLY public.staff DROP CONSTRAINT staff_parkinglotid_fkey;
       public          postgres    false    231    233    4788            �           2606    18102    student student_customerid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);
 I   ALTER TABLE ONLY public.student DROP CONSTRAINT student_customerid_fkey;
       public          postgres    false    221    219    4772            �           2606    18375 "   transaction transaction_mssv_fkey1    FK CONSTRAINT     �   ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_mssv_fkey1 FOREIGN KEY (mssv) REFERENCES public.student(mssv) ON DELETE CASCADE;
 L   ALTER TABLE ONLY public.transaction DROP CONSTRAINT transaction_mssv_fkey1;
       public          postgres    false    223    4776    221            �           2606    18147 #   now_vehicle vehicle_customerid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);
 M   ALTER TABLE ONLY public.now_vehicle DROP CONSTRAINT vehicle_customerid_fkey;
       public          postgres    false    227    4772    219            �           2606    18152 &   now_vehicle vehicle_vehicletypeid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_vehicletypeid_fkey FOREIGN KEY (vehicletypeid) REFERENCES public.vehicle_type(vehicletypeid);
 P   ALTER TABLE ONLY public.now_vehicle DROP CONSTRAINT vehicle_vehicletypeid_fkey;
       public          postgres    false    227    4780    225            �           2606    18088    visitor visitor_customerid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.visitor
    ADD CONSTRAINT visitor_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);
 I   ALTER TABLE ONLY public.visitor DROP CONSTRAINT visitor_customerid_fkey;
       public          postgres    false    220    4772    219            Y   D   x����0�jk��E��%u&��g� Y��i��af9��6�Ɋ4��EX����Z�od����      l      x�32�22������� >9      a   L   x�%ʻ�0C���l�dꔰ�
<�Ʋ��:nWX'����|�$O<��-�jt��Ԫ�ӂf���c#�ǻt      k   �   x�}���0cT�0��cE\���S�x���$MBHE��81���!\)b�Cu����b��y�$���ݟ-�	`�_�"���H��{��2<��vch���? 2�>X�����(�?��1�'�7�      e   ,   x�3�t2�460�2�t��42�9]�M�,NgsN #F��� �P      i      x�E�K�9���b�?Aw�ǽ��<)u�5ȃ�
̀`V<���������������ϟ���kX˺��|>�`%�X�zX�5�e�#`��0F�#a$���0F�H	#a$��Q0
F�(�`��Q0F�h�a4���0F�x`<0�����x`<0���80���80�c`��10��c`���0��Xca,���0.��¸0.<�����<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������<?x~���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������|���~���?!���������������{r�'�{r�'�{r�'�{r�'�{r�'����\����\����\�����������	�'�{r�'�{r�'�{������o�;������}���?�����|ޓ�{�yO>���=��'���yO���yO���yO���yO���yO���}O���}O���}O���}O���}O�����|ߓ�{�}O����=��'�����|ߓ��a+Y�j��:�a-F�#`��0F�	#a$���0F�H	#a��Q0
F�(�`���0F�h�a4���0�oqsuwy{}��������������������������������������������������������������������������������������������������������������������������������������������ϋ��{���)�w���{���)�w���{���)�w���{���)�w���{���)�w���{���)�w���{���)�w���{���)�w���{���)�w���{���)�w���{�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�(�5�w��]�x�h�5��������������������������������������������������ﯞ���+�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�7�/Wb��sWb�˕X��r�{�܃�,�`��=X��r�{�܃�,�`��=X��r�{�܃�,�`��=X��r�{�܃�,�`��=X��r�{�܃�,�`��=X��r�{�܃�����/�_ҿ�I�%������U�f=��ֲ�~^P�-#`��0F�	#a$���0F�H	#a��Q0
F�(�`���0F�h�a4���0����x`<0���q`Ɓq`Ɓq`c`��10��c`,���0��Xca,��qa\ƅqa\ƅqaܗ����t�����8ǹNi!-�����BZHi!-������RZJKi)-����V�JZI+i%�����V�JZKki-�������ZZKki���g��Lg9��8�s��̟���v�iGڑv�iGڑ6�F�Hi#m����6�F�J[i+m������V�J[iWڕv�]iWڕv�]iWڅ���<��t�����8ǹNi!-�����BZHi!-������RZJKi)-����V�JZI+i%�����V�JZKki-�������ZZKki�4[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[����/���,g;�q�s����%Li!-�����BZHi)-������RZJKi)-����V�JZI+i%�������ZZKki-�������Z�#��H{�=�i��G�#�v�iGڑv�iGڑv�i#m����6�F�Hi#m������V�J[i+m����v�]iWڕv�]iWڕv�]h_�g:����y��\�4[R��lIْ�%eKʖ�-)[R��lIْ�%eKʖ�-)[R��lIْ�%eKʖ�-)[R��lIْ�%eKʖ�-)[R��lIْ�%eKʖ�-)[��W\ߙ�r��q�8�y�?��)�H;Ҏ�#�H;Ҏ�#m����6�F�Hi#m������V�J[i+m�����Ү�+�J�Ү�+�J�Ү����ľ3��,g;�q�s��BZHi!-�����BZHKi)-������RZJKi)�����V�JZI+i%�������ZZKki-�������i��mIے�%mKږ�-i[Ҷ�mIے�%mKږ�-i[Ҷ�mIے�%mKږ�-i[Ҷ�mIے�%mKږ�-i[Ҷ�mIے�%mKږ�-i[Ҷ�mIے�%mKږ�-i[Ҷ�%���j����8ǹ���yZ��p����BZHi!-������RZJKi)-����V�JZI+i%�����V�JZKki-�������ZZKki�����Lg9��8�s��̟��v�iGڑv�iGڑ6�F�Hi#m����6�F�J[i+m�}�+\�+x������+�
����+�J�Ү��|>�p����|��9�uJi!-�����BZHi!-������RZJKi)-����V�JZI+i%�����V�ZZKki-�������ZZK{���cV�Y9f嘕cV�Y9f嘕cV�Y9f嘕cV�Y9f嘕cV�Y9f嘕cV�Y9f嘕cV�Y9f嘕cV�Y9f嘕cK�-9��ؒcK�-9��ؒcK�-9��ؒcK�-9��ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-[2�dl�ؒ�%cKƖ�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒ�%kK֖�-Y[��dm�ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���ڒkK�-���Ғ�В�В�В�В�В�В�В >  �В�В�|�����BZHi!-������RZJKi)-������RZI+i%�����V�JZI+i-�������ZZKki-��=�~����,g;�q�s����|g8�iGڑv�iGڑ6�F�Hi#m����6�F�J[i+m������V�J[iWڕv�]iWڕv�]iWڅ��3��,g;�q�s��BZHi!-�����BZHKi)-������RZJKi)�����V�JZI+i%�������ZZKki-�������i�4[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-	[�$lIؒ�%aK�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%iKҖ�-I[��$mIڒ�%����߿��>ې      c      x�3�4�2bcN#. ����� u�      g   B   x�3��K/�|��5O�/��<���ë�8��ML��-8��*�Lx�{e�B`)P!B�	W� c�      [   �   x�3��IUK�Sp���42022��0�4�442615�2�)J�f�e(��&���s� L�)g@Fb�BHF��ob&Ȱ�Z4���~饕w��)�i�Sp9�2/���a��B���ݓ���2J�JMMM��!���p��d߇�"�d d 9+F��� ��EV      ]   H   x�u���0����g� ������d+���#���k���[X�5i��=��:g�,nux?~����c      _   :   x�3�HU�=��������Ӑ�$pd��]8� BƜ��(���i
�q��qqq �5�      Z     x��ɍE!Ϗ\�ޝ�\���0[j�R��<h�$��;a�\˛�d�r��\WM�'b:A��]���ǚ_��J����]!���D�s����Z�<�U%�X�`�5��>-�4�X�q��Cy��yB�9He�Ӻ�w �R�|����k6ㄠD	�Xt�G\���̀�����3�x���b��[ϲ0o���@���[w�@��IR��z#�J�-v\���_��1m�ǅ�@"5D��r���(����	���ǯ�|?|����c�7UlR     