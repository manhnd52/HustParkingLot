--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

-- Started on 2024-06-05 10:45:25

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 238 (class 1255 OID 18661)
-- Name: addcustomer(boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addcustomer(type boolean) RETURNS integer
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


ALTER FUNCTION public.addcustomer(type boolean) OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 18662)
-- Name: addstudent(integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.addstudent(IN in_mssv integer, IN in_name character varying)
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


ALTER PROCEDURE public.addstudent(IN in_mssv integer, IN in_name character varying) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 18663)
-- Name: addvisitor(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.addvisitor() RETURNS character varying
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


ALTER FUNCTION public.addvisitor() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 18664)
-- Name: check_one_vehicle_per_student(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_one_vehicle_per_student() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Kiểm tra xem có xe nào của student vẫn đang được gửi
	
    IF EXISTS (
		SELECT 1
		FROM park JOIN now_vehicle USING(vehicleId)
		WHERE customerId = (SELECT customerId
							FROM now_vehicle n WHERE n.vehicleId = NEW.vehicleId)
			AND exit_time IS NULL
    ) THEN
        -- Nếu có, báo lỗi và không cho phép chèn bản ghi mới
        RAISE EXCEPTION 'Mỗi sinh viên chỉ được gửi một xe tại một thời điểm';
    END IF;
    -- Nếu không có xe nào đang gửi, cho phép chèn bản ghi mới
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_one_vehicle_per_student() OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 18665)
-- Name: delete_student(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_student() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
BEGIN 
	DELETE FROM customer WHERE customerid = OLD.customerid;
	RETURN OLD;
END;
$$;


ALTER FUNCTION public.delete_student() OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 18666)
-- Name: delete_visitor(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_visitor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
BEGIN 
	DELETE FROM customer WHERE customerid = OLD.customerid;
	RETURN OLD;
END;
$$;


ALTER FUNCTION public.delete_visitor() OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 18667)
-- Name: getavailablespots(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getavailablespots(input_parkinglotid integer, input_size integer) RETURNS integer
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
		ORDER BY parkingspotid
		LIMIT 1;
		RETURN spot_id;
	END;
$$;


ALTER FUNCTION public.getavailablespots(input_parkinglotid integer, input_size integer) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 18668)
-- Name: getcustomerid(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getcustomerid(input_mssv character varying) RETURNS integer
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


ALTER FUNCTION public.getcustomerid(input_mssv character varying) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 18669)
-- Name: getparkinglotid(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getparkinglotid(input_staffid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	parkinglot int;
BEGIN
	SELECT parkinglotid INTO parkinglot FROM staff where staffid = input_staffid;
	RETURN parkinglot;
END;
$$;


ALTER FUNCTION public.getparkinglotid(input_staffid integer) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 18670)
-- Name: getvehicleid(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getvehicleid(string character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$-- Hiện tại đang sai vì vehicle không còn là những xe đang đỗ
DECLARE
    o_vehicleId INT;
BEGIN
-- Nếu là mssv
    IF length(string) = 8 THEN
        SELECT vehicleid INTO o_vehicleId
        FROM now_vehicle
        WHERE customerid IN (
            SELECT customerid
            FROM student
            WHERE mssv = string
        );
-- Nếu là uuid
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


ALTER FUNCTION public.getvehicleid(string character varying) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 18671)
-- Name: is_occuppied(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.is_occuppied() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		UPDATE parking_spot
		SET occupied = TRUE
		WHERE parkingspotid = new.parkingspotid;
		RETURN NEW;
	END;
$$;


ALTER FUNCTION public.is_occuppied() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 18672)
-- Name: payin_log_func(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.payin_log_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   INSERT INTO transaction (customerid, amount, time, tranaction_type)
   VALUES (getCustomerId(NEW.mssv), 
		   abs(OLD.balance - NEW.balance), 
		   current_timestamp, 
		   (OLD.balance - NEW.balance) < 0);
   RETURN NEW;
END;
$$;


ALTER FUNCTION public.payin_log_func() OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 18673)
-- Name: trigger_function(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_function() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   INSERT INTO transaction (mssv, amount, time, tranaction_type)
   VALUES (NEW.mssv, NEW.balance - OLD.balance, 1);
   RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_function() OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 18674)
-- Name: update_capacity(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_capacity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE 
BEGIN
	UPDATE parking_lot 
	SET capacity = capacity + 1
	WHERE parkinglotid = OLD.parkinglotid;
	RETURN OLD;
END;
$$;


ALTER FUNCTION public.update_capacity() OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 18675)
-- Name: update_parking_spot_status(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_parking_spot_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Kiểm tra nếu exit_time được đặt (từ NULL sang một giá trị không NULL)
    IF NEW.exit_time IS NOT NULL AND OLD.exit_time IS NULL THEN
        -- Cập nhật bảng parking_spot, đặt occupied thành FALSE
		RAISE NOTICE 'REAL';
        UPDATE parking_spot
        SET occupied = FALSE
        WHERE parkingspotid = NEW.parkingspotid;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_parking_spot_status() OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 18676)
-- Name: vehicle_out(character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.vehicle_out(IN string character varying)
    LANGUAGE plpgsql
    AS $$DECLARE
	x int;
BEGIN
	IF length(string) = 8 THEN
		UPDATE park
		SET exit_time = now()
		FROM now_vehicle, student
		WHERE park.exit_time IS NULL
		AND park.vehicleId = now_vehicle.vehicleId
		AND now_vehicle.customerid = getCustomerId(string);
	ELSE
		-- Dành cho vé
		UPDATE park
		SET exit_time = now()
		WHERE park.vehicleid = (SELECT vehicleid FROM now_vehicle WHERE customerid = getCustomerId(string))
		RETURNING parkId INTO x;
		IF (x IS NULL) THEN RAISE 'Vé không đúng';
		END IF;
	END IF;
END;
$$;


ALTER PROCEDURE public.vehicle_out(IN string character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 18677)
-- Name: application; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application (
    id integer NOT NULL,
    fullname character(50) NOT NULL,
    datebirth date NOT NULL,
    email character(50) NOT NULL
);


ALTER TABLE public.application OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 18680)
-- Name: application_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.application_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.application_id_seq OWNER TO postgres;

--
-- TOC entry 4992 (class 0 OID 0)
-- Dependencies: 216
-- Name: application_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.application_id_seq OWNED BY public.application.id;


--
-- TOC entry 217 (class 1259 OID 18681)
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer (
    customerid integer NOT NULL,
    customertype boolean NOT NULL
);


ALTER TABLE public.customer OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 18684)
-- Name: customer_customerid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customer_customerid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_customerid_seq OWNER TO postgres;

--
-- TOC entry 4993 (class 0 OID 0)
-- Dependencies: 218
-- Name: customer_customerid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_customerid_seq OWNED BY public.customer.customerid;


--
-- TOC entry 219 (class 1259 OID 18685)
-- Name: customerid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.customerid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customerid_seq OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 18686)
-- Name: now_vehicle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.now_vehicle (
    vehicleid integer NOT NULL,
    vehicletypeid integer,
    license_plate character varying(15),
    color character varying(15),
    customerid integer
);


ALTER TABLE public.now_vehicle OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 18689)
-- Name: park; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.park (
    parkid integer NOT NULL,
    vehicleid integer NOT NULL,
    parkingspotid integer NOT NULL,
    entry_time timestamp without time zone DEFAULT now() NOT NULL,
    exit_time timestamp without time zone
);


ALTER TABLE public.park OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 18693)
-- Name: park_parkid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.park_parkid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.park_parkid_seq OWNER TO postgres;

--
-- TOC entry 4994 (class 0 OID 0)
-- Dependencies: 222
-- Name: park_parkid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.park_parkid_seq OWNED BY public.park.parkid;


--
-- TOC entry 223 (class 1259 OID 18694)
-- Name: parking_lot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parking_lot (
    parkinglotid integer NOT NULL,
    name character varying(16) NOT NULL,
    capacity integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.parking_lot OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 18698)
-- Name: parking_lot_parkinglotid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parking_lot_parkinglotid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parking_lot_parkinglotid_seq OWNER TO postgres;

--
-- TOC entry 4995 (class 0 OID 0)
-- Dependencies: 224
-- Name: parking_lot_parkinglotid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parking_lot_parkinglotid_seq OWNED BY public.parking_lot.parkinglotid;


--
-- TOC entry 225 (class 1259 OID 18699)
-- Name: parking_spot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parking_spot (
    parkingspotid integer NOT NULL,
    spottypeid integer NOT NULL,
    parkinglotid integer NOT NULL,
    occupied boolean DEFAULT false NOT NULL
);


ALTER TABLE public.parking_spot OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 18703)
-- Name: parking_spot_parkingspotid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parking_spot_parkingspotid_seq
    AS integer
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parking_spot_parkingspotid_seq OWNER TO postgres;

--
-- TOC entry 4996 (class 0 OID 0)
-- Dependencies: 226
-- Name: parking_spot_parkingspotid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parking_spot_parkingspotid_seq OWNED BY public.parking_spot.parkingspotid;


--
-- TOC entry 227 (class 1259 OID 18704)
-- Name: spot_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spot_type (
    spottypeid integer NOT NULL,
    size smallint NOT NULL
);


ALTER TABLE public.spot_type OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 18707)
-- Name: spot_type_spottypeid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.spot_type_spottypeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.spot_type_spottypeid_seq OWNER TO postgres;

--
-- TOC entry 4997 (class 0 OID 0)
-- Dependencies: 228
-- Name: spot_type_spottypeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.spot_type_spottypeid_seq OWNED BY public.spot_type.spottypeid;


--
-- TOC entry 229 (class 1259 OID 18708)
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    staffid integer NOT NULL,
    fullname character varying(256) NOT NULL,
    password character varying DEFAULT '12345678'::character varying NOT NULL,
    parkinglotid integer NOT NULL,
    CONSTRAINT staff_password_check CHECK ((length((password)::text) >= 8))
);


ALTER TABLE public.staff OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 18715)
-- Name: staff_staffid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_staffid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_staffid_seq OWNER TO postgres;

--
-- TOC entry 4998 (class 0 OID 0)
-- Dependencies: 230
-- Name: staff_staffid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_staffid_seq OWNED BY public.staff.staffid;


--
-- TOC entry 231 (class 1259 OID 18716)
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    customerid integer NOT NULL,
    fullname character varying(255) NOT NULL,
    mssv character varying(8) NOT NULL,
    balance integer DEFAULT 0 NOT NULL,
    password character varying DEFAULT '123456'::character varying NOT NULL
);


ALTER TABLE public.student OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 18723)
-- Name: transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction (
    transactionid integer NOT NULL,
    amount integer NOT NULL,
    "time" timestamp without time zone DEFAULT now() NOT NULL,
    tranaction_type boolean NOT NULL,
    customerid integer NOT NULL
);


ALTER TABLE public.transaction OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 18727)
-- Name: transaction_transactionid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_transactionid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_transactionid_seq OWNER TO postgres;

--
-- TOC entry 4999 (class 0 OID 0)
-- Dependencies: 233
-- Name: transaction_transactionid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_transactionid_seq OWNED BY public.transaction.transactionid;


--
-- TOC entry 234 (class 1259 OID 18728)
-- Name: vehicle_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_type (
    vehicletypeid integer NOT NULL,
    name character varying(15) NOT NULL,
    price integer DEFAULT 0 NOT NULL,
    size smallint NOT NULL,
    CONSTRAINT vehicle_type_price_check CHECK ((price >= 0))
);


ALTER TABLE public.vehicle_type OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 18733)
-- Name: vehicle_type_vehicletypeid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_type_vehicletypeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_type_vehicletypeid_seq OWNER TO postgres;

--
-- TOC entry 5000 (class 0 OID 0)
-- Dependencies: 235
-- Name: vehicle_type_vehicletypeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_type_vehicletypeid_seq OWNED BY public.vehicle_type.vehicletypeid;


--
-- TOC entry 236 (class 1259 OID 18734)
-- Name: vehicle_vehicleid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_vehicleid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_vehicleid_seq OWNER TO postgres;

--
-- TOC entry 5001 (class 0 OID 0)
-- Dependencies: 236
-- Name: vehicle_vehicleid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_vehicleid_seq OWNED BY public.now_vehicle.vehicleid;


--
-- TOC entry 237 (class 1259 OID 18735)
-- Name: visitor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visitor (
    customerid integer NOT NULL,
    ticketid uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public.visitor OWNER TO postgres;

--
-- TOC entry 4758 (class 2604 OID 18739)
-- Name: application id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application ALTER COLUMN id SET DEFAULT nextval('public.application_id_seq'::regclass);


--
-- TOC entry 4759 (class 2604 OID 18740)
-- Name: customer customerid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer ALTER COLUMN customerid SET DEFAULT nextval('public.customer_customerid_seq'::regclass);


--
-- TOC entry 4760 (class 2604 OID 18741)
-- Name: now_vehicle vehicleid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.now_vehicle ALTER COLUMN vehicleid SET DEFAULT nextval('public.vehicle_vehicleid_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 18742)
-- Name: park parkid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park ALTER COLUMN parkid SET DEFAULT nextval('public.park_parkid_seq'::regclass);


--
-- TOC entry 4763 (class 2604 OID 18743)
-- Name: parking_lot parkinglotid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_lot ALTER COLUMN parkinglotid SET DEFAULT nextval('public.parking_lot_parkinglotid_seq'::regclass);


--
-- TOC entry 4765 (class 2604 OID 18744)
-- Name: parking_spot parkingspotid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot ALTER COLUMN parkingspotid SET DEFAULT nextval('public.parking_spot_parkingspotid_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 18745)
-- Name: spot_type spottypeid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spot_type ALTER COLUMN spottypeid SET DEFAULT nextval('public.spot_type_spottypeid_seq'::regclass);


--
-- TOC entry 4768 (class 2604 OID 18746)
-- Name: staff staffid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff ALTER COLUMN staffid SET DEFAULT nextval('public.staff_staffid_seq'::regclass);


--
-- TOC entry 4772 (class 2604 OID 18747)
-- Name: transaction transactionid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction ALTER COLUMN transactionid SET DEFAULT nextval('public.transaction_transactionid_seq'::regclass);


--
-- TOC entry 4774 (class 2604 OID 18748)
-- Name: vehicle_type vehicletypeid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_type ALTER COLUMN vehicletypeid SET DEFAULT nextval('public.vehicle_type_vehicletypeid_seq'::regclass);


--
-- TOC entry 4964 (class 0 OID 18677)
-- Dependencies: 215
-- Data for Name: application; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.application (id, fullname, datebirth, email) FROM stdin;
\.


--
-- TOC entry 4966 (class 0 OID 18681)
-- Dependencies: 217
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.customer (customerid, customertype) FROM stdin;
1	f
2	f
3	f
4	f
5	f
6	t
7	t
8	t
9	t
10	t
11	t
15	t
16	f
17	f
20	f
22	f
24	t
25	t
26	t
27	t
28	t
31	t
32	f
34	t
35	t
36	t
\.


--
-- TOC entry 4969 (class 0 OID 18686)
-- Dependencies: 220
-- Data for Name: now_vehicle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.now_vehicle (vehicleid, vehicletypeid, license_plate, color, customerid) FROM stdin;
67	1	37a	red	22
72	2	\N	blue	22
74	1	37a1	red	4
75	2	\N	brown	22
76	3	37a	red	22
77	3	37aaa	red	34
78	3	37A225	red	35
79	1	red	37a	22
\.


--
-- TOC entry 4970 (class 0 OID 18689)
-- Dependencies: 221
-- Data for Name: park; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.park (parkid, vehicleid, parkingspotid, entry_time, exit_time) FROM stdin;
52	77	2051	2024-05-31 09:07:54.438975	2024-05-31 09:09:27.270994
53	78	2051	2024-05-31 09:22:19.139139	2024-05-31 09:29:14.855839
54	79	1501	2024-05-31 09:30:21.983113	2024-05-31 09:32:54.269658
61	67	1501	2024-05-31 10:14:56.292069	2024-05-31 15:51:06.123483
62	67	1501	2024-05-31 16:10:00.280164	\N
34	67	1502	2024-05-25 12:24:01.498882	2024-05-31 08:57:14.418882
36	67	1502	2024-05-25 12:34:32.08139	2024-05-31 08:57:14.418882
40	67	1501	2024-05-25 12:52:57.018588	2024-05-31 08:57:14.418882
41	72	1501	2024-05-25 13:16:09.965423	2024-05-31 08:57:14.418882
42	72	1501	2024-05-25 13:17:11.695253	2024-05-31 08:57:14.418882
44	67	1501	2024-05-26 16:31:24.044915	2024-05-31 08:57:14.418882
45	74	1502	2024-05-26 16:32:50.827904	2024-05-31 08:57:14.418882
46	72	1501	2024-05-26 16:45:43.278512	2024-05-31 08:57:14.418882
48	75	1501	2024-05-26 22:43:48.71691	2024-05-31 08:57:14.418882
49	67	2051	2024-05-27 14:21:53.921852	2024-05-31 08:57:14.418882
50	67	2051	2024-05-27 14:24:53.631101	2024-05-31 08:57:14.418882
51	76	2051	2024-05-27 14:31:27.827354	2024-05-31 08:57:14.418882
\.


--
-- TOC entry 4972 (class 0 OID 18694)
-- Dependencies: 223
-- Data for Name: parking_lot; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parking_lot (parkinglotid, name, capacity) FROM stdin;
1	B1	300
3	D35	600
4	C7	800
\.


--
-- TOC entry 4974 (class 0 OID 18699)
-- Dependencies: 225
-- Data for Name: parking_spot; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parking_spot (parkingspotid, spottypeid, parkinglotid, occupied) FROM stdin;
2121	3	4	f
2122	3	4	f
2123	3	4	f
2124	3	4	f
2125	3	4	f
2126	3	4	f
2127	3	4	f
2128	3	4	f
1502	1	4	f
1501	1	4	t
2129	3	4	f
2130	3	4	f
2162	3	4	f
2163	3	4	f
2164	3	4	f
2165	3	4	f
2166	3	4	f
2167	3	4	f
2168	3	4	f
2169	3	4	f
2170	3	4	f
2171	3	4	f
2051	3	4	f
2172	3	4	f
2173	3	4	f
2174	3	4	f
2175	3	4	f
2176	3	4	f
2177	3	4	f
2178	3	4	f
2179	3	4	f
2180	3	4	f
2181	3	4	f
2182	3	4	f
2183	3	4	f
2184	3	4	f
2185	3	4	f
2186	3	4	f
2187	3	4	f
2188	3	4	f
2189	3	4	f
2190	3	4	f
2191	3	4	f
2192	3	4	f
2193	3	4	f
2194	3	4	f
2195	3	4	f
2196	3	4	f
2197	3	4	f
2198	3	4	f
2199	3	4	f
2200	3	4	f
2201	3	4	f
2202	3	4	f
2203	3	4	f
2204	3	4	f
2205	3	4	f
2206	3	4	f
2207	3	4	f
2208	3	4	f
2209	3	4	f
2210	3	4	f
2211	3	4	f
2212	3	4	f
2213	3	4	f
2214	3	4	f
2215	3	4	f
2216	3	4	f
2217	3	4	f
2218	3	4	f
2219	3	4	f
2220	3	4	f
2221	3	4	f
2222	3	4	f
2223	3	4	f
2224	3	4	f
2225	3	4	f
2226	3	4	f
2227	3	4	f
2228	3	4	f
2229	3	4	f
2230	3	4	f
2231	3	4	f
2232	3	4	f
2233	3	4	f
2234	3	4	f
2235	3	4	f
2236	3	4	f
2237	3	4	f
2238	3	4	f
2239	3	4	f
2240	3	4	f
2241	3	4	f
2242	3	4	f
2243	3	4	f
2244	3	4	f
2245	3	4	f
2246	3	4	f
2247	3	4	f
2248	3	4	f
2249	3	4	f
2250	3	4	f
2251	3	4	f
2252	3	4	f
2253	3	4	f
2254	3	4	f
2255	3	4	f
2256	3	4	f
2257	3	4	f
2258	3	4	f
2259	3	4	f
2260	3	4	f
2261	3	4	f
2262	3	4	f
2263	3	4	f
2264	3	4	f
2265	3	4	f
2266	3	4	f
2267	3	4	f
2268	3	4	f
2269	3	4	f
2270	3	4	f
2271	3	4	f
2272	3	4	f
2273	3	4	f
2274	3	4	f
2275	3	4	f
2276	3	4	f
2277	3	4	f
2278	3	4	f
2279	3	4	f
2280	3	4	f
2281	3	4	f
2282	3	4	f
2283	3	4	f
2284	3	4	f
2285	3	4	f
2286	3	4	f
2287	3	4	f
2288	3	4	f
2289	3	4	f
2290	3	4	f
2291	3	4	f
2292	3	4	f
2131	3	4	f
2132	3	4	f
2133	3	4	f
2134	3	4	f
2135	3	4	f
2136	3	4	f
2137	3	4	f
2138	3	4	f
2052	3	4	f
2139	3	4	f
2140	3	4	f
1	1	1	f
2	1	1	f
3	1	1	f
4	1	1	f
5	1	1	f
6	1	1	f
7	1	1	f
8	1	1	f
9	1	1	f
10	1	1	f
11	1	1	f
12	1	1	f
13	1	1	f
14	1	1	f
15	1	1	f
16	1	1	f
17	1	1	f
18	1	1	f
19	1	1	f
20	1	1	f
21	1	1	f
22	1	1	f
23	1	1	f
24	1	1	f
25	1	1	f
26	1	1	f
27	1	1	f
28	1	1	f
29	1	1	f
30	1	1	f
31	1	1	f
32	1	1	f
33	1	1	f
34	1	1	f
35	1	1	f
36	1	1	f
37	1	1	f
38	1	1	f
39	1	1	f
40	1	1	f
41	1	1	f
42	1	1	f
43	1	1	f
44	1	1	f
45	1	1	f
46	1	1	f
47	1	1	f
48	1	1	f
49	1	1	f
50	1	1	f
51	2	1	f
52	2	1	f
53	2	1	f
54	2	1	f
55	2	1	f
56	2	1	f
57	2	1	f
58	2	1	f
59	2	1	f
60	2	1	f
61	2	1	f
62	2	1	f
63	2	1	f
64	2	1	f
65	2	1	f
66	2	1	f
67	2	1	f
68	2	1	f
69	2	1	f
70	2	1	f
71	2	1	f
72	2	1	f
73	2	1	f
74	2	1	f
75	2	1	f
76	2	1	f
77	2	1	f
78	2	1	f
79	2	1	f
80	2	1	f
81	2	1	f
82	2	1	f
83	2	1	f
84	2	1	f
85	2	1	f
86	2	1	f
87	2	1	f
88	2	1	f
89	2	1	f
90	2	1	f
91	2	1	f
92	2	1	f
93	2	1	f
94	2	1	f
95	2	1	f
96	2	1	f
97	2	1	f
98	2	1	f
99	2	1	f
100	2	1	f
101	2	1	f
102	2	1	f
103	2	1	f
104	2	1	f
105	2	1	f
106	2	1	f
107	2	1	f
108	2	1	f
109	2	1	f
110	2	1	f
111	2	1	f
112	2	1	f
113	2	1	f
114	2	1	f
115	2	1	f
116	2	1	f
117	2	1	f
118	2	1	f
119	2	1	f
120	2	1	f
121	2	1	f
122	2	1	f
123	2	1	f
124	2	1	f
125	2	1	f
126	2	1	f
127	2	1	f
128	2	1	f
129	2	1	f
130	2	1	f
131	2	1	f
132	2	1	f
133	2	1	f
134	2	1	f
135	2	1	f
136	2	1	f
137	2	1	f
138	2	1	f
139	2	1	f
140	2	1	f
141	2	1	f
142	2	1	f
143	2	1	f
144	2	1	f
145	2	1	f
146	2	1	f
147	2	1	f
148	2	1	f
149	2	1	f
150	2	1	f
151	2	1	f
152	2	1	f
153	2	1	f
154	2	1	f
155	2	1	f
156	2	1	f
157	2	1	f
158	2	1	f
159	2	1	f
160	2	1	f
161	2	1	f
162	2	1	f
163	2	1	f
164	2	1	f
165	2	1	f
166	2	1	f
167	2	1	f
168	2	1	f
169	2	1	f
170	2	1	f
171	2	1	f
172	2	1	f
173	2	1	f
174	2	1	f
175	2	1	f
176	2	1	f
177	2	1	f
178	2	1	f
179	2	1	f
180	2	1	f
181	2	1	f
182	2	1	f
183	2	1	f
184	2	1	f
185	2	1	f
186	2	1	f
187	2	1	f
188	2	1	f
189	2	1	f
190	2	1	f
191	2	1	f
192	2	1	f
193	2	1	f
194	2	1	f
195	2	1	f
196	2	1	f
197	2	1	f
198	2	1	f
199	2	1	f
200	2	1	f
201	2	1	f
202	2	1	f
203	2	1	f
204	2	1	f
205	2	1	f
206	2	1	f
207	2	1	f
208	2	1	f
209	2	1	f
210	2	1	f
211	2	1	f
212	2	1	f
213	2	1	f
214	2	1	f
215	2	1	f
216	2	1	f
217	2	1	f
218	2	1	f
219	2	1	f
220	2	1	f
221	2	1	f
222	2	1	f
223	2	1	f
224	2	1	f
225	2	1	f
226	2	1	f
227	2	1	f
228	2	1	f
229	2	1	f
230	2	1	f
231	2	1	f
232	2	1	f
233	2	1	f
234	2	1	f
235	2	1	f
236	2	1	f
237	2	1	f
238	2	1	f
901	1	3	f
902	1	3	f
903	1	3	f
904	1	3	f
905	1	3	f
906	1	3	f
907	1	3	f
908	1	3	f
909	1	3	f
910	1	3	f
911	1	3	f
912	1	3	f
913	1	3	f
914	1	3	f
915	1	3	f
916	1	3	f
917	1	3	f
918	1	3	f
919	1	3	f
920	1	3	f
921	1	3	f
922	1	3	f
923	1	3	f
924	1	3	f
925	1	3	f
926	1	3	f
927	1	3	f
928	1	3	f
929	1	3	f
930	1	3	f
931	1	3	f
932	1	3	f
933	1	3	f
934	1	3	f
935	1	3	f
936	1	3	f
937	1	3	f
938	1	3	f
939	1	3	f
940	1	3	f
941	1	3	f
942	1	3	f
943	1	3	f
944	1	3	f
945	1	3	f
946	1	3	f
947	1	3	f
948	1	3	f
949	1	3	f
950	1	3	f
951	1	3	f
952	1	3	f
953	1	3	f
954	1	3	f
955	1	3	f
956	1	3	f
957	1	3	f
958	1	3	f
959	1	3	f
960	1	3	f
961	1	3	f
962	1	3	f
963	1	3	f
964	1	3	f
965	1	3	f
966	1	3	f
967	1	3	f
968	1	3	f
969	1	3	f
970	1	3	f
971	1	3	f
972	1	3	f
973	1	3	f
974	1	3	f
975	1	3	f
976	1	3	f
977	1	3	f
978	1	3	f
979	1	3	f
980	1	3	f
981	1	3	f
982	1	3	f
983	1	3	f
984	1	3	f
985	1	3	f
986	1	3	f
987	1	3	f
988	1	3	f
989	1	3	f
990	1	3	f
991	1	3	f
992	1	3	f
993	1	3	f
994	1	3	f
995	1	3	f
996	1	3	f
997	1	3	f
998	1	3	f
999	1	3	f
1000	1	3	f
1001	1	3	f
1002	1	3	f
1003	1	3	f
1004	1	3	f
1005	1	3	f
1006	1	3	f
1007	1	3	f
1008	1	3	f
1009	1	3	f
1010	1	3	f
1011	1	3	f
1012	1	3	f
1013	1	3	f
1014	1	3	f
1015	1	3	f
1016	1	3	f
1017	1	3	f
1018	1	3	f
1019	1	3	f
1020	1	3	f
1021	1	3	f
1022	1	3	f
1023	1	3	f
1024	1	3	f
1025	1	3	f
1026	1	3	f
1027	1	3	f
1028	1	3	f
1029	1	3	f
1030	1	3	f
1031	1	3	f
1032	1	3	f
1033	1	3	f
1034	1	3	f
1035	1	3	f
1036	1	3	f
1037	1	3	f
1038	1	3	f
1039	1	3	f
1040	1	3	f
1041	1	3	f
1042	1	3	f
1043	1	3	f
1044	1	3	f
1045	1	3	f
1046	1	3	f
1047	1	3	f
1048	1	3	f
1049	1	3	f
1050	1	3	f
1051	2	3	f
1052	2	3	f
1053	2	3	f
1054	2	3	f
1055	2	3	f
1056	2	3	f
1057	2	3	f
1058	2	3	f
1059	2	3	f
1060	2	3	f
1061	2	3	f
1062	2	3	f
1063	2	3	f
1064	2	3	f
1065	2	3	f
1066	2	3	f
1067	2	3	f
1068	2	3	f
1069	2	3	f
1070	2	3	f
1071	2	3	f
1072	2	3	f
1073	2	3	f
1074	2	3	f
1075	2	3	f
1076	2	3	f
1077	2	3	f
1078	2	3	f
1079	2	3	f
1080	2	3	f
1081	2	3	f
1082	2	3	f
1083	2	3	f
1084	2	3	f
1085	2	3	f
1086	2	3	f
1087	2	3	f
1088	2	3	f
1089	2	3	f
1090	2	3	f
1091	2	3	f
1092	2	3	f
1093	2	3	f
1094	2	3	f
1095	2	3	f
1096	2	3	f
1097	2	3	f
1098	2	3	f
1099	2	3	f
1100	2	3	f
1101	2	3	f
1102	2	3	f
1103	2	3	f
1104	2	3	f
1105	2	3	f
1106	2	3	f
1107	2	3	f
1108	2	3	f
1109	2	3	f
1110	2	3	f
1111	2	3	f
1112	2	3	f
1113	2	3	f
1114	2	3	f
1115	2	3	f
1116	2	3	f
1117	2	3	f
1118	2	3	f
1119	2	3	f
1120	2	3	f
1121	2	3	f
1122	2	3	f
1123	2	3	f
1124	2	3	f
1125	2	3	f
1126	2	3	f
1127	2	3	f
1128	2	3	f
1129	2	3	f
1130	2	3	f
1131	2	3	f
1132	2	3	f
1133	2	3	f
1134	2	3	f
1135	2	3	f
1136	2	3	f
1137	2	3	f
1138	2	3	f
1139	2	3	f
1140	2	3	f
1141	2	3	f
1142	2	3	f
1143	2	3	f
1144	2	3	f
1145	2	3	f
1146	2	3	f
1147	2	3	f
1148	2	3	f
1149	2	3	f
1150	2	3	f
1151	2	3	f
1152	2	3	f
1153	2	3	f
1154	2	3	f
1155	2	3	f
1156	2	3	f
1157	2	3	f
1158	2	3	f
1159	2	3	f
1160	2	3	f
1161	2	3	f
1162	2	3	f
1163	2	3	f
1164	2	3	f
1165	2	3	f
1166	2	3	f
1167	2	3	f
1168	2	3	f
1169	2	3	f
1170	2	3	f
1171	2	3	f
1172	2	3	f
1173	2	3	f
1174	2	3	f
1175	2	3	f
1176	2	3	f
1177	2	3	f
1178	2	3	f
1179	2	3	f
1180	2	3	f
1181	2	3	f
1182	2	3	f
1183	2	3	f
1184	2	3	f
1185	2	3	f
1186	2	3	f
1187	2	3	f
1188	2	3	f
1189	2	3	f
1190	2	3	f
1191	2	3	f
1192	2	3	f
1193	2	3	f
1194	2	3	f
1195	2	3	f
1196	2	3	f
1197	2	3	f
1198	2	3	f
1199	2	3	f
1200	2	3	f
1201	3	3	f
1202	3	3	f
1203	3	3	f
1204	3	3	f
1205	3	3	f
1206	3	3	f
1207	3	3	f
1208	3	3	f
1209	3	3	f
1210	3	3	f
1211	3	3	f
1212	3	3	f
1213	3	3	f
1214	3	3	f
1215	3	3	f
1216	3	3	f
1217	3	3	f
1218	3	3	f
1219	3	3	f
1220	3	3	f
1221	3	3	f
1222	3	3	f
1223	3	3	f
1224	3	3	f
1225	3	3	f
1226	3	3	f
1227	3	3	f
1228	3	3	f
1229	3	3	f
1230	3	3	f
1231	3	3	f
1232	3	3	f
1233	3	3	f
1234	3	3	f
1235	3	3	f
1236	3	3	f
1237	3	3	f
1238	3	3	f
1239	3	3	f
1240	3	3	f
1241	3	3	f
1242	3	3	f
1243	3	3	f
1244	3	3	f
1245	3	3	f
1246	3	3	f
1247	3	3	f
1248	3	3	f
1249	3	3	f
1250	3	3	f
1251	3	3	f
1252	3	3	f
1253	3	3	f
1254	3	3	f
1255	3	3	f
1256	3	3	f
1257	3	3	f
1258	3	3	f
1259	3	3	f
1260	3	3	f
1261	3	3	f
1262	3	3	f
1263	3	3	f
1264	3	3	f
1265	3	3	f
1266	3	3	f
1267	3	3	f
1268	3	3	f
1269	3	3	f
1270	3	3	f
1271	3	3	f
1272	3	3	f
1273	3	3	f
1274	3	3	f
1275	3	3	f
1276	3	3	f
1277	3	3	f
1278	3	3	f
1279	3	3	f
1280	3	3	f
1281	3	3	f
1282	3	3	f
1283	3	3	f
1284	3	3	f
1285	3	3	f
1286	3	3	f
1287	3	3	f
1288	3	3	f
1289	3	3	f
1290	3	3	f
1291	3	3	f
1292	3	3	f
1293	3	3	f
1294	3	3	f
1295	3	3	f
1296	3	3	f
1297	3	3	f
1298	3	3	f
1299	3	3	f
1300	3	3	f
1301	3	3	f
1302	3	3	f
1303	3	3	f
1304	3	3	f
1305	3	3	f
1306	3	3	f
1307	3	3	f
1308	3	3	f
1309	3	3	f
1310	3	3	f
1311	3	3	f
1312	3	3	f
1313	3	3	f
1314	3	3	f
1315	3	3	f
1316	3	3	f
1317	3	3	f
1318	3	3	f
1319	3	3	f
1320	3	3	f
1321	3	3	f
1322	3	3	f
1323	3	3	f
1324	3	3	f
1325	3	3	f
1326	3	3	f
1327	3	3	f
1328	3	3	f
1329	3	3	f
1330	3	3	f
1331	3	3	f
1332	3	3	f
1333	3	3	f
1334	3	3	f
1335	3	3	f
1336	3	3	f
1337	3	3	f
1338	3	3	f
1339	3	3	f
1340	3	3	f
1341	3	3	f
1342	3	3	f
1343	3	3	f
1344	3	3	f
1345	3	3	f
1346	3	3	f
1347	3	3	f
1348	3	3	f
1349	3	3	f
1350	3	3	f
1351	4	3	f
1352	4	3	f
1353	4	3	f
1354	4	3	f
1355	4	3	f
1356	4	3	f
1357	4	3	f
1358	4	3	f
1359	4	3	f
1360	4	3	f
1361	4	3	f
1362	4	3	f
1363	4	3	f
1364	4	3	f
1365	4	3	f
1366	4	3	f
1367	4	3	f
1368	4	3	f
1369	4	3	f
1370	4	3	f
1371	4	3	f
1372	4	3	f
1373	4	3	f
1374	4	3	f
1375	4	3	f
1376	4	3	f
1377	4	3	f
1378	4	3	f
1379	4	3	f
1380	4	3	f
1381	4	3	f
1382	4	3	f
1383	4	3	f
1384	4	3	f
1385	4	3	f
1386	4	3	f
1387	4	3	f
1388	4	3	f
1389	4	3	f
1390	4	3	f
1392	4	3	f
1393	4	3	f
1394	4	3	f
1395	4	3	f
1396	4	3	f
1397	4	3	f
1399	4	3	f
1400	4	3	f
1401	4	3	f
1402	4	3	f
1403	4	3	f
1404	4	3	f
1405	4	3	f
1406	4	3	f
1407	4	3	f
1408	4	3	f
1409	4	3	f
1410	4	3	f
1411	4	3	f
1412	4	3	f
1413	4	3	f
1414	4	3	f
1415	4	3	f
1416	4	3	f
1417	4	3	f
1418	4	3	f
1419	4	3	f
1420	4	3	f
1421	4	3	f
1422	4	3	f
1423	4	3	f
1424	4	3	f
1425	4	3	f
1426	4	3	f
1427	4	3	f
1428	4	3	f
1429	4	3	f
1430	4	3	f
1431	4	3	f
1432	4	3	f
1433	4	3	f
1434	4	3	f
1435	4	3	f
1436	4	3	f
1437	4	3	f
1438	4	3	f
1439	4	3	f
1440	4	3	f
1441	4	3	f
1442	4	3	f
1443	4	3	f
1444	4	3	f
1445	4	3	f
1446	4	3	f
1447	4	3	f
1448	4	3	f
1449	4	3	f
1450	4	3	f
1451	4	3	f
1452	4	3	f
1453	4	3	f
1454	4	3	f
1455	4	3	f
1456	4	3	f
1457	4	3	f
1458	4	3	f
1459	4	3	f
1460	4	3	f
1461	4	3	f
1462	4	3	f
1463	4	3	f
1464	4	3	f
1465	4	3	f
1466	4	3	f
1467	4	3	f
1468	4	3	f
1469	4	3	f
1470	4	3	f
1471	4	3	f
1472	4	3	f
1473	4	3	f
1474	4	3	f
1475	4	3	f
1476	4	3	f
1477	4	3	f
2141	3	4	f
2142	3	4	f
2143	3	4	f
2144	3	4	f
2145	3	4	f
2146	3	4	f
2147	3	4	f
2148	3	4	f
2149	3	4	f
2150	3	4	f
2151	3	4	f
2152	3	4	f
2153	3	4	f
2154	3	4	f
2155	3	4	f
2156	3	4	f
2157	3	4	f
2158	3	4	f
2159	3	4	f
2160	3	4	f
2161	3	4	f
239	2	1	f
240	2	1	f
241	2	1	f
242	2	1	f
243	2	1	f
244	2	1	f
245	2	1	f
246	2	1	f
247	2	1	f
248	2	1	f
249	2	1	f
250	2	1	f
251	2	1	f
252	2	1	f
253	2	1	f
254	2	1	f
255	2	1	f
256	2	1	f
257	2	1	f
258	2	1	f
259	2	1	f
260	2	1	f
261	2	1	f
262	2	1	f
263	2	1	f
264	2	1	f
265	2	1	f
266	2	1	f
267	2	1	f
268	2	1	f
269	2	1	f
270	2	1	f
271	2	1	f
272	2	1	f
273	2	1	f
274	2	1	f
275	2	1	f
276	2	1	f
277	2	1	f
278	2	1	f
279	2	1	f
280	2	1	f
281	2	1	f
282	2	1	f
283	2	1	f
284	2	1	f
285	2	1	f
286	2	1	f
287	2	1	f
288	2	1	f
289	2	1	f
290	2	1	f
291	2	1	f
292	2	1	f
293	2	1	f
294	2	1	f
295	2	1	f
296	2	1	f
297	2	1	f
298	2	1	f
299	2	1	f
300	2	1	f
1478	4	3	f
1479	4	3	f
1480	4	3	f
1481	4	3	f
1482	4	3	f
1483	4	3	f
1484	4	3	f
1485	4	3	f
1486	4	3	f
1487	4	3	f
1488	4	3	f
1489	4	3	f
1490	4	3	f
1491	4	3	f
1492	4	3	f
1493	4	3	f
1494	4	3	f
1495	4	3	f
1496	4	3	f
1497	4	3	f
1498	4	3	f
1499	4	3	f
1500	4	3	f
1504	1	4	f
1505	1	4	f
1506	1	4	f
1507	1	4	f
1508	1	4	f
1509	1	4	f
1510	1	4	f
1511	1	4	f
1512	1	4	f
1513	1	4	f
1514	1	4	f
1515	1	4	f
1516	1	4	f
1517	1	4	f
1518	1	4	f
1519	1	4	f
1520	1	4	f
1521	1	4	f
1522	1	4	f
1523	1	4	f
1524	1	4	f
1525	1	4	f
1526	1	4	f
1527	1	4	f
1528	1	4	f
1529	1	4	f
1530	1	4	f
1531	1	4	f
1532	1	4	f
1533	1	4	f
1534	1	4	f
1535	1	4	f
1536	1	4	f
1537	1	4	f
1538	1	4	f
1539	1	4	f
1540	1	4	f
1541	1	4	f
1542	1	4	f
1543	1	4	f
1544	1	4	f
1545	1	4	f
1546	1	4	f
1547	1	4	f
1548	1	4	f
1549	1	4	f
1550	1	4	f
1551	2	4	f
1552	2	4	f
1553	2	4	f
1554	2	4	f
1555	2	4	f
1556	2	4	f
1557	2	4	f
1558	2	4	f
1559	2	4	f
1560	2	4	f
1561	2	4	f
1562	2	4	f
1563	2	4	f
1564	2	4	f
1565	2	4	f
1566	2	4	f
1567	2	4	f
1568	2	4	f
1569	2	4	f
1570	2	4	f
1571	2	4	f
1572	2	4	f
1573	2	4	f
1574	2	4	f
1575	2	4	f
1576	2	4	f
1577	2	4	f
1578	2	4	f
1579	2	4	f
1580	2	4	f
1581	2	4	f
1582	2	4	f
1583	2	4	f
1503	1	4	f
1584	2	4	f
1585	2	4	f
1586	2	4	f
1587	2	4	f
1588	2	4	f
1589	2	4	f
1590	2	4	f
1591	2	4	f
1592	2	4	f
1593	2	4	f
1594	2	4	f
1595	2	4	f
1596	2	4	f
1597	2	4	f
1598	2	4	f
1599	2	4	f
1600	2	4	f
1601	2	4	f
1602	2	4	f
1603	2	4	f
1604	2	4	f
1605	2	4	f
1606	2	4	f
1607	2	4	f
1608	2	4	f
1609	2	4	f
1610	2	4	f
1611	2	4	f
1612	2	4	f
1613	2	4	f
1614	2	4	f
1615	2	4	f
1616	2	4	f
1617	2	4	f
1618	2	4	f
1619	2	4	f
1620	2	4	f
1621	2	4	f
1622	2	4	f
1623	2	4	f
1624	2	4	f
1625	2	4	f
1626	2	4	f
1627	2	4	f
1628	2	4	f
1629	2	4	f
1630	2	4	f
1631	2	4	f
1632	2	4	f
1633	2	4	f
1634	2	4	f
1635	2	4	f
1636	2	4	f
1637	2	4	f
1638	2	4	f
1639	2	4	f
1640	2	4	f
1641	2	4	f
1642	2	4	f
1643	2	4	f
1644	2	4	f
1645	2	4	f
1646	2	4	f
1647	2	4	f
1648	2	4	f
1649	2	4	f
1650	2	4	f
1651	2	4	f
1652	2	4	f
1653	2	4	f
1654	2	4	f
1655	2	4	f
1656	2	4	f
1657	2	4	f
1658	2	4	f
1659	2	4	f
1660	2	4	f
1661	2	4	f
1662	2	4	f
1663	2	4	f
1664	2	4	f
1665	2	4	f
1666	2	4	f
1667	2	4	f
1668	2	4	f
1669	2	4	f
1670	2	4	f
1671	2	4	f
1672	2	4	f
1673	2	4	f
1674	2	4	f
1675	2	4	f
1676	2	4	f
1677	2	4	f
1678	2	4	f
1679	2	4	f
1680	2	4	f
1681	2	4	f
1682	2	4	f
1683	2	4	f
1684	2	4	f
1685	2	4	f
1686	2	4	f
1687	2	4	f
1688	2	4	f
1689	2	4	f
1690	2	4	f
1691	2	4	f
1692	2	4	f
1693	2	4	f
1694	2	4	f
1695	2	4	f
1696	2	4	f
1697	2	4	f
1698	2	4	f
1699	2	4	f
1700	2	4	f
1701	2	4	f
1702	2	4	f
1703	2	4	f
1704	2	4	f
1705	2	4	f
1706	2	4	f
1707	2	4	f
1708	2	4	f
1709	2	4	f
1710	2	4	f
1711	2	4	f
1712	2	4	f
1713	2	4	f
1714	2	4	f
1715	2	4	f
1716	2	4	f
1717	2	4	f
1718	2	4	f
1719	2	4	f
1720	2	4	f
1721	2	4	f
1722	2	4	f
1723	2	4	f
1724	2	4	f
1725	2	4	f
1726	2	4	f
1727	2	4	f
1728	2	4	f
1729	2	4	f
1730	2	4	f
1731	2	4	f
1732	2	4	f
1733	2	4	f
1734	2	4	f
1735	2	4	f
1736	2	4	f
1737	2	4	f
1738	2	4	f
1739	2	4	f
1740	2	4	f
1741	2	4	f
1742	2	4	f
1743	2	4	f
1744	2	4	f
1745	2	4	f
1746	2	4	f
1747	2	4	f
1748	2	4	f
1749	2	4	f
1750	2	4	f
1751	2	4	f
1752	2	4	f
1753	2	4	f
1754	2	4	f
1755	2	4	f
1756	2	4	f
1757	2	4	f
1758	2	4	f
1759	2	4	f
1760	2	4	f
1761	2	4	f
1762	2	4	f
1763	2	4	f
1764	2	4	f
1765	2	4	f
1766	2	4	f
1767	2	4	f
1768	2	4	f
1769	2	4	f
1770	2	4	f
1771	2	4	f
1772	2	4	f
1773	2	4	f
1774	2	4	f
1775	2	4	f
1776	2	4	f
1777	2	4	f
1778	2	4	f
1779	2	4	f
1780	2	4	f
1781	2	4	f
1782	2	4	f
1783	2	4	f
1784	2	4	f
1785	2	4	f
1786	2	4	f
1787	2	4	f
1788	2	4	f
1789	2	4	f
1790	2	4	f
1791	2	4	f
1792	2	4	f
1793	2	4	f
1794	2	4	f
1795	2	4	f
1796	2	4	f
1797	2	4	f
1798	2	4	f
1799	2	4	f
1800	2	4	f
1801	2	4	f
1802	2	4	f
1803	2	4	f
1804	2	4	f
1805	2	4	f
1806	2	4	f
1807	2	4	f
1808	2	4	f
1809	2	4	f
1810	2	4	f
1811	2	4	f
1812	2	4	f
1813	2	4	f
1814	2	4	f
1815	2	4	f
1816	2	4	f
1817	2	4	f
1818	2	4	f
1819	2	4	f
1820	2	4	f
1821	2	4	f
1822	2	4	f
1823	2	4	f
1824	2	4	f
1825	2	4	f
1826	2	4	f
1827	2	4	f
1828	2	4	f
1829	2	4	f
1830	2	4	f
1831	2	4	f
1832	2	4	f
1833	2	4	f
1834	2	4	f
1835	2	4	f
1836	2	4	f
1837	2	4	f
1838	2	4	f
1839	2	4	f
1840	2	4	f
1841	2	4	f
1842	2	4	f
1843	2	4	f
1844	2	4	f
1845	2	4	f
1846	2	4	f
1848	2	4	f
1849	2	4	f
1850	2	4	f
1851	2	4	f
1852	2	4	f
1853	2	4	f
1854	2	4	f
1855	2	4	f
1856	2	4	f
1857	2	4	f
1858	2	4	f
1859	2	4	f
1860	2	4	f
1861	2	4	f
1862	2	4	f
1863	2	4	f
1864	2	4	f
1865	2	4	f
1866	2	4	f
1867	2	4	f
1868	2	4	f
1869	2	4	f
1870	2	4	f
1871	2	4	f
1872	2	4	f
1873	2	4	f
1874	2	4	f
1875	2	4	f
1876	2	4	f
1877	2	4	f
1878	2	4	f
1879	2	4	f
1880	2	4	f
1881	2	4	f
1882	2	4	f
1883	2	4	f
1884	2	4	f
1885	2	4	f
1886	2	4	f
1887	2	4	f
1888	2	4	f
1889	2	4	f
1890	2	4	f
1891	2	4	f
1892	2	4	f
1893	2	4	f
1894	2	4	f
1895	2	4	f
1896	2	4	f
1897	2	4	f
1898	2	4	f
1899	2	4	f
1900	2	4	f
1901	2	4	f
1902	2	4	f
1903	2	4	f
1904	2	4	f
1905	2	4	f
1906	2	4	f
1907	2	4	f
1908	2	4	f
1909	2	4	f
1910	2	4	f
1911	2	4	f
1912	2	4	f
1913	2	4	f
1914	2	4	f
1915	2	4	f
1916	2	4	f
1917	2	4	f
1918	2	4	f
1919	2	4	f
1920	2	4	f
1921	2	4	f
1922	2	4	f
1923	2	4	f
1924	2	4	f
1925	2	4	f
1926	2	4	f
1927	2	4	f
1928	2	4	f
1929	2	4	f
1930	2	4	f
1931	2	4	f
1932	2	4	f
1933	2	4	f
1934	2	4	f
1935	2	4	f
1936	2	4	f
1937	2	4	f
1938	2	4	f
1939	2	4	f
1940	2	4	f
1941	2	4	f
1942	2	4	f
1943	2	4	f
1944	2	4	f
1945	2	4	f
1946	2	4	f
1947	2	4	f
1948	2	4	f
1949	2	4	f
1950	2	4	f
1951	2	4	f
1952	2	4	f
1953	2	4	f
1955	2	4	f
1956	2	4	f
1957	2	4	f
1958	2	4	f
1959	2	4	f
1960	2	4	f
1961	2	4	f
1962	2	4	f
1963	2	4	f
1964	2	4	f
1965	2	4	f
1966	2	4	f
1967	2	4	f
1968	2	4	f
1969	2	4	f
1970	2	4	f
1971	2	4	f
1972	2	4	f
1973	2	4	f
1974	2	4	f
1975	2	4	f
1976	2	4	f
1977	2	4	f
1978	2	4	f
1979	2	4	f
1980	2	4	f
1981	2	4	f
1982	2	4	f
1983	2	4	f
1984	2	4	f
1985	2	4	f
1986	2	4	f
1987	2	4	f
1988	2	4	f
1989	2	4	f
1990	2	4	f
1991	2	4	f
1992	2	4	f
1993	2	4	f
1994	2	4	f
1995	2	4	f
1996	2	4	f
1997	2	4	f
1998	2	4	f
1999	2	4	f
2000	2	4	f
2036	2	4	f
2037	2	4	f
2038	2	4	f
2039	2	4	f
2040	2	4	f
2041	2	4	f
2042	2	4	f
2043	2	4	f
2044	2	4	f
2045	2	4	f
2046	2	4	f
2047	2	4	f
2048	2	4	f
2049	2	4	f
2050	2	4	f
2053	3	4	f
2054	3	4	f
2055	3	4	f
2056	3	4	f
2057	3	4	f
2058	3	4	f
2059	3	4	f
2060	3	4	f
2061	3	4	f
2062	3	4	f
2063	3	4	f
2064	3	4	f
2065	3	4	f
2066	3	4	f
2067	3	4	f
2068	3	4	f
2069	3	4	f
2070	3	4	f
2071	3	4	f
2072	3	4	f
2073	3	4	f
2074	3	4	f
2075	3	4	f
2076	3	4	f
2077	3	4	f
2078	3	4	f
2079	3	4	f
2080	3	4	f
2081	3	4	f
2082	3	4	f
2083	3	4	f
2084	3	4	f
2085	3	4	f
2086	3	4	f
2087	3	4	f
2088	3	4	f
2089	3	4	f
2090	3	4	f
2091	3	4	f
2092	3	4	f
2093	3	4	f
2094	3	4	f
2095	3	4	f
2096	3	4	f
2097	3	4	f
1398	4	3	f
1954	2	4	f
2098	3	4	f
2099	3	4	f
2100	3	4	f
2101	3	4	f
2102	3	4	f
2103	3	4	f
2104	3	4	f
2105	3	4	f
2106	3	4	f
2107	3	4	f
2108	3	4	f
2109	3	4	f
2110	3	4	f
2111	3	4	f
2112	3	4	f
2113	3	4	f
2114	3	4	f
2115	3	4	f
2116	3	4	f
2117	3	4	f
2118	3	4	f
2119	3	4	f
2120	3	4	f
1391	4	3	f
1847	2	4	f
2001	2	4	f
2002	2	4	f
2003	2	4	f
2004	2	4	f
2005	2	4	f
2006	2	4	f
2007	2	4	f
2008	2	4	f
2009	2	4	f
2010	2	4	f
2011	2	4	f
2012	2	4	f
2013	2	4	f
2014	2	4	f
2015	2	4	f
2016	2	4	f
2017	2	4	f
2018	2	4	f
2019	2	4	f
2020	2	4	f
2021	2	4	f
2022	2	4	f
2023	2	4	f
2024	2	4	f
2025	2	4	f
2026	2	4	f
2027	2	4	f
2028	2	4	f
2029	2	4	f
2030	2	4	f
2031	2	4	f
2032	2	4	f
2033	2	4	f
2034	2	4	f
2035	2	4	f
2293	3	4	f
2294	3	4	f
2295	3	4	f
2296	3	4	f
2297	3	4	f
2298	3	4	f
2299	3	4	f
2300	3	4	f
\.


--
-- TOC entry 4976 (class 0 OID 18704)
-- Dependencies: 227
-- Data for Name: spot_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spot_type (spottypeid, size) FROM stdin;
1	1
2	1
3	2
4	2
\.


--
-- TOC entry 4978 (class 0 OID 18708)
-- Dependencies: 229
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff (staffid, fullname, password, parkinglotid) FROM stdin;
2	Nguyễn Nhân Viên	12345678	1
3	Nguyễn Đức Quân	12345678	4
5	Nguyễn Đức Nghĩa	12345678	4
\.


--
-- TOC entry 4980 (class 0 OID 18716)
-- Dependencies: 231
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student (customerid, fullname, mssv, balance, password) FROM stdin;
5	Pham Thi Mai Anh\n	20225884	87000	123456
4	Tran Minh Tuan	20225883	0	123456
36	Ngô Anh Tú	20220029	100000	123456
22	Nguyễn Văn Mạnh	20225880	146000	123456
3	Le Van Anh	20225882	100000	123456
17	Nguyễn Văn Dũng	20225879	100000	123456
20	Nguyễn Hồng Nhung	20221555	100000	123456
32	Văn Đức Cường	20220021	100000	123456
\.


--
-- TOC entry 4981 (class 0 OID 18723)
-- Dependencies: 232
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction (transactionid, amount, "time", tranaction_type, customerid) FROM stdin;
51	-3000	2024-05-31 10:14:56.292069	t	22
52	50000	2024-05-31 10:22:04.041037	f	22
53	23000	2024-05-31 10:24:03.542639	t	22
54	3000	2024-05-31 16:10:00.280164	f	22
55	20000	2024-06-01 10:08:38.238722	t	22
56	20000	2024-06-01 10:10:04.135523	t	22
57	100000	2024-06-01 10:12:25.073966	t	36
\.


--
-- TOC entry 4983 (class 0 OID 18728)
-- Dependencies: 234
-- Data for Name: vehicle_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle_type (vehicletypeid, name, price, size) FROM stdin;
1	Xe máy	3000	1
2	Xe đạp	2000	1
3	Ô tô	5000	2
\.


--
-- TOC entry 4986 (class 0 OID 18735)
-- Dependencies: 237
-- Data for Name: visitor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visitor (customerid, ticketid) FROM stdin;
8	50e27aeb-f96a-49ab-a673-f7bfbb63717b
9	d4cf6761-34e8-4cf5-9083-d197ac563bca
10	d1a86334-898f-4d86-9a1f-156e84d28101
11	0ef8665b-2c8d-4653-ad7d-a08807b6ed42
15	5749c5b8-c8bc-468b-b578-5cbd7831f6bf
24	325cc84e-fad2-4d7f-a420-93b2592c913e
25	34c54b78-7c77-416c-b6df-302409d341b5
26	f2975886-45ae-44a6-84e2-3785d4da6ac9
27	eeb3670d-6942-4993-9cc5-34a57e858d11
28	9d6be76d-8ccf-446e-b23d-9b72e67622cb
31	373b4f8e-395b-4327-a43f-1ca05928061d
34	3d065c0d-00f2-43b5-a00c-0b2567e0273c
35	f12d390f-4c30-4716-912c-d098ed1f48f7
\.


--
-- TOC entry 5002 (class 0 OID 0)
-- Dependencies: 216
-- Name: application_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.application_id_seq', 1, true);


--
-- TOC entry 5003 (class 0 OID 0)
-- Dependencies: 218
-- Name: customer_customerid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_customerid_seq', 36, true);


--
-- TOC entry 5004 (class 0 OID 0)
-- Dependencies: 219
-- Name: customerid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customerid_seq', 1, false);


--
-- TOC entry 5005 (class 0 OID 0)
-- Dependencies: 222
-- Name: park_parkid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.park_parkid_seq', 62, true);


--
-- TOC entry 5006 (class 0 OID 0)
-- Dependencies: 224
-- Name: parking_lot_parkinglotid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parking_lot_parkinglotid_seq', 2, true);


--
-- TOC entry 5007 (class 0 OID 0)
-- Dependencies: 226
-- Name: parking_spot_parkingspotid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parking_spot_parkingspotid_seq', 2300, true);


--
-- TOC entry 5008 (class 0 OID 0)
-- Dependencies: 228
-- Name: spot_type_spottypeid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spot_type_spottypeid_seq', 1, false);


--
-- TOC entry 5009 (class 0 OID 0)
-- Dependencies: 230
-- Name: staff_staffid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.staff_staffid_seq', 6, true);


--
-- TOC entry 5010 (class 0 OID 0)
-- Dependencies: 233
-- Name: transaction_transactionid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_transactionid_seq', 57, true);


--
-- TOC entry 5011 (class 0 OID 0)
-- Dependencies: 235
-- Name: vehicle_type_vehicletypeid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_type_vehicletypeid_seq', 1, false);


--
-- TOC entry 5012 (class 0 OID 0)
-- Dependencies: 236
-- Name: vehicle_vehicleid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_vehicleid_seq', 81, true);


--
-- TOC entry 4781 (class 2606 OID 18750)
-- Name: application application_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id);


--
-- TOC entry 4783 (class 2606 OID 18752)
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customerid);


--
-- TOC entry 4787 (class 2606 OID 18754)
-- Name: park park_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_pkey PRIMARY KEY (parkid);


--
-- TOC entry 4789 (class 2606 OID 18756)
-- Name: parking_lot parking_lot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_lot
    ADD CONSTRAINT parking_lot_pkey PRIMARY KEY (parkinglotid);


--
-- TOC entry 4791 (class 2606 OID 18758)
-- Name: parking_spot parking_spot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_pkey PRIMARY KEY (parkingspotid);


--
-- TOC entry 4793 (class 2606 OID 18760)
-- Name: spot_type spot_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spot_type
    ADD CONSTRAINT spot_type_pkey PRIMARY KEY (spottypeid);


--
-- TOC entry 4795 (class 2606 OID 18762)
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staffid);


--
-- TOC entry 4797 (class 2606 OID 18764)
-- Name: student student_mssv_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_mssv_key UNIQUE (mssv);


--
-- TOC entry 4778 (class 2606 OID 18765)
-- Name: student student_password_check; Type: CHECK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE public.student
    ADD CONSTRAINT student_password_check CHECK ((length((password)::text) >= 6)) NOT VALID;


--
-- TOC entry 4799 (class 2606 OID 18767)
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (mssv);


--
-- TOC entry 4785 (class 2606 OID 18769)
-- Name: now_vehicle vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (vehicleid);


--
-- TOC entry 4801 (class 2606 OID 18771)
-- Name: vehicle_type vehicle_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_type
    ADD CONSTRAINT vehicle_type_pkey PRIMARY KEY (vehicletypeid);


--
-- TOC entry 4803 (class 2606 OID 18830)
-- Name: visitor visitor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitor
    ADD CONSTRAINT visitor_pkey PRIMARY KEY (ticketid);


--
-- TOC entry 4814 (class 2620 OID 18772)
-- Name: park auto_update_occupied; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER auto_update_occupied AFTER INSERT ON public.park FOR EACH ROW WHEN ((new.exit_time IS NULL)) EXECUTE FUNCTION public.is_occuppied();


--
-- TOC entry 4818 (class 2620 OID 18773)
-- Name: student delete_student; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_student AFTER DELETE ON public.student FOR EACH ROW EXECUTE FUNCTION public.delete_student();


--
-- TOC entry 4820 (class 2620 OID 18774)
-- Name: visitor delete_visitor; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER delete_visitor AFTER DELETE ON public.visitor FOR EACH ROW EXECUTE FUNCTION public.delete_visitor();


--
-- TOC entry 4819 (class 2620 OID 18775)
-- Name: student payin_log; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER payin_log AFTER UPDATE OF balance ON public.student FOR EACH ROW EXECUTE FUNCTION public.payin_log_func();


--
-- TOC entry 4815 (class 2620 OID 18776)
-- Name: park set_exit_time_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER set_exit_time_trigger AFTER UPDATE OF exit_time ON public.park FOR EACH ROW WHEN (((old.exit_time IS NULL) AND (new.exit_time IS NOT NULL))) EXECUTE FUNCTION public.update_parking_spot_status();


--
-- TOC entry 4816 (class 2620 OID 18777)
-- Name: park trigger_check_one_vehicle_per_student; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_check_one_vehicle_per_student BEFORE INSERT ON public.park FOR EACH ROW EXECUTE FUNCTION public.check_one_vehicle_per_student();


--
-- TOC entry 4817 (class 2620 OID 18778)
-- Name: parking_spot update_capacity; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_capacity AFTER INSERT ON public.parking_spot FOR EACH ROW EXECUTE FUNCTION public.update_capacity();


--
-- TOC entry 4812 (class 2606 OID 18779)
-- Name: transaction Customer; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT "Customer" FOREIGN KEY (customerid) REFERENCES public.customer(customerid) NOT VALID;


--
-- TOC entry 4806 (class 2606 OID 18784)
-- Name: park park_parkingspotid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_parkingspotid_fkey FOREIGN KEY (parkingspotid) REFERENCES public.parking_spot(parkingspotid);


--
-- TOC entry 4807 (class 2606 OID 18789)
-- Name: park park_vehicleid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_vehicleid_fkey FOREIGN KEY (vehicleid) REFERENCES public.now_vehicle(vehicleid) NOT VALID;


--
-- TOC entry 4808 (class 2606 OID 18794)
-- Name: parking_spot parking_spot_parkinglotid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_parkinglotid_fkey FOREIGN KEY (parkinglotid) REFERENCES public.parking_lot(parkinglotid);


--
-- TOC entry 4809 (class 2606 OID 18799)
-- Name: parking_spot parking_spot_spottypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_spottypeid_fkey FOREIGN KEY (spottypeid) REFERENCES public.spot_type(spottypeid);


--
-- TOC entry 4810 (class 2606 OID 18804)
-- Name: staff staff_parkinglotid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_parkinglotid_fkey FOREIGN KEY (parkinglotid) REFERENCES public.parking_lot(parkinglotid);


--
-- TOC entry 4811 (class 2606 OID 18809)
-- Name: student student_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);


--
-- TOC entry 4804 (class 2606 OID 18814)
-- Name: now_vehicle vehicle_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);


--
-- TOC entry 4805 (class 2606 OID 18819)
-- Name: now_vehicle vehicle_vehicletypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.now_vehicle
    ADD CONSTRAINT vehicle_vehicletypeid_fkey FOREIGN KEY (vehicletypeid) REFERENCES public.vehicle_type(vehicletypeid);


--
-- TOC entry 4813 (class 2606 OID 18824)
-- Name: visitor visitor_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitor
    ADD CONSTRAINT visitor_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);


-- Completed on 2024-06-05 10:45:25

--
-- PostgreSQL database dump complete
--

