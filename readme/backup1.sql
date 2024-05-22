--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.2

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
-- Name: availablespots(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.availablespots(inputparkinglotid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	count int;
BEGIN
	SELECT INTO count SUM(CASE WHEN occupied = TRUE THEN 0 ELSE 1 END) FROM parking_spot WHERE parkinglotid = inputParkingLotID;
	RETURN count;
END;
$$;


ALTER FUNCTION public.availablespots(inputparkinglotid integer) OWNER TO postgres;

--
-- Name: availablespots(integer, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.availablespots(input_parkinglot integer, input_vehicletype boolean) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	count int;
BEGIN
		SELECT COUNT(*) INTO count 
		FROM parking_spot NATURAL JOIN spot_type 
		WHERE 	parkinglotid = input_ParkingLot 
				AND vehicleType = input_vehicletype;
		RETURN count;
END;
$$;


ALTER FUNCTION public.availablespots(input_parkinglot integer, input_vehicletype boolean) OWNER TO postgres;

--
-- Name: payin_log_func(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.payin_log_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   INSERT INTO transaction (mssv, amount, time, tranaction_type)
   VALUES (NEW.mssv, NEW.balance - OLD.balance, current_timestamp, true);
   RETURN NEW;
END;
$$;


ALTER FUNCTION public.payin_log_func() OWNER TO postgres;

--
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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.customer (
    customerid integer NOT NULL,
    customertype boolean
);


ALTER TABLE public.customer OWNER TO postgres;

--
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
-- Name: customer_customerid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.customer_customerid_seq OWNED BY public.customer.customerid;


--
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
-- Name: park; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.park (
    parkid integer NOT NULL,
    vehicleid integer,
    parkingspotid integer,
    entry_time timestamp without time zone,
    exit_time timestamp without time zone
);


ALTER TABLE public.park OWNER TO postgres;

--
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
-- Name: park_parkid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.park_parkid_seq OWNED BY public.park.parkid;


--
-- Name: parking_lot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parking_lot (
    parkinglotid integer NOT NULL,
    name character varying(16),
    capacity integer
);


ALTER TABLE public.parking_lot OWNER TO postgres;

--
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
-- Name: parking_lot_parkinglotid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parking_lot_parkinglotid_seq OWNED BY public.parking_lot.parkinglotid;


--
-- Name: parking_spot; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parking_spot (
    parkingspotid integer NOT NULL,
    spottypeid integer,
    parkinglotid integer,
    occupied boolean DEFAULT false
);


ALTER TABLE public.parking_spot OWNER TO postgres;

--
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
-- Name: parking_spot_parkingspotid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parking_spot_parkingspotid_seq OWNED BY public.parking_spot.parkingspotid;


--
-- Name: spot_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.spot_type (
    spottypeid integer NOT NULL,
    vehicletype boolean,
    isprivileged boolean
);


ALTER TABLE public.spot_type OWNER TO postgres;

--
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
-- Name: spot_type_spottypeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.spot_type_spottypeid_seq OWNED BY public.spot_type.spottypeid;


--
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    staffid integer NOT NULL,
    fullname character varying(256),
    password character varying DEFAULT '12345678'::character varying,
    parkinglotid integer,
    CONSTRAINT staff_password_check CHECK ((length((password)::text) >= 8))
);


ALTER TABLE public.staff OWNER TO postgres;

--
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
-- Name: staff_staffid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_staffid_seq OWNED BY public.staff.staffid;


--
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    customerid integer NOT NULL,
    fullname character varying(255),
    mssv character varying(8),
    balance integer DEFAULT 0,
    password character varying DEFAULT '123456'::character varying
);


ALTER TABLE public.student OWNER TO postgres;

--
-- Name: transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction (
    transactionid integer NOT NULL,
    mssv character varying(8),
    amount integer,
    "time" timestamp without time zone,
    tranaction_type boolean
);


ALTER TABLE public.transaction OWNER TO postgres;

--
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
-- Name: transaction_transactionid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_transactionid_seq OWNED BY public.transaction.transactionid;


--
-- Name: vehicle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle (
    vehicleid integer NOT NULL,
    vehicletypeid integer,
    license_plate character varying(15),
    color character varying(15),
    customerid integer
);


ALTER TABLE public.vehicle OWNER TO postgres;

--
-- Name: vehicle_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_type (
    vehicletypeid integer NOT NULL,
    name character varying(15),
    price integer,
    CONSTRAINT vehicle_type_price_check CHECK ((price >= 0))
);


ALTER TABLE public.vehicle_type OWNER TO postgres;

--
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
-- Name: vehicle_type_vehicletypeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_type_vehicletypeid_seq OWNED BY public.vehicle_type.vehicletypeid;


--
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
-- Name: vehicle_vehicleid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_vehicleid_seq OWNED BY public.vehicle.vehicleid;


--
-- Name: visitor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.visitor (
    customerid integer NOT NULL,
    ticketid uuid DEFAULT gen_random_uuid()
);


ALTER TABLE public.visitor OWNER TO postgres;

--
-- Name: customer customerid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer ALTER COLUMN customerid SET DEFAULT nextval('public.customer_customerid_seq'::regclass);


--
-- Name: park parkid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park ALTER COLUMN parkid SET DEFAULT nextval('public.park_parkid_seq'::regclass);


--
-- Name: parking_lot parkinglotid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_lot ALTER COLUMN parkinglotid SET DEFAULT nextval('public.parking_lot_parkinglotid_seq'::regclass);


--
-- Name: parking_spot parkingspotid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot ALTER COLUMN parkingspotid SET DEFAULT nextval('public.parking_spot_parkingspotid_seq'::regclass);


--
-- Name: spot_type spottypeid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spot_type ALTER COLUMN spottypeid SET DEFAULT nextval('public.spot_type_spottypeid_seq'::regclass);


--
-- Name: staff staffid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff ALTER COLUMN staffid SET DEFAULT nextval('public.staff_staffid_seq'::regclass);


--
-- Name: transaction transactionid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction ALTER COLUMN transactionid SET DEFAULT nextval('public.transaction_transactionid_seq'::regclass);


--
-- Name: vehicle vehicleid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle ALTER COLUMN vehicleid SET DEFAULT nextval('public.vehicle_vehicleid_seq'::regclass);


--
-- Name: vehicle_type vehicletypeid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_type ALTER COLUMN vehicletypeid SET DEFAULT nextval('public.vehicle_type_vehicletypeid_seq'::regclass);


--
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
\.


--
-- Data for Name: park; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.park (parkid, vehicleid, parkingspotid, entry_time, exit_time) FROM stdin;
1	1	1	\N	\N
\.


--
-- Data for Name: parking_lot; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parking_lot (parkinglotid, name, capacity) FROM stdin;
1	B1	300
2	D9	600
3	D35	600
4	C7	800
\.


--
-- Data for Name: parking_spot; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parking_spot (parkingspotid, spottypeid, parkinglotid, occupied) FROM stdin;
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
301	4	2	f
302	4	2	f
303	4	2	f
304	4	2	f
305	4	2	f
306	4	2	f
307	4	2	f
308	4	2	f
309	4	2	f
310	4	2	f
311	4	2	f
312	4	2	f
313	4	2	f
314	4	2	f
315	4	2	f
316	4	2	f
317	4	2	f
318	4	2	f
319	4	2	f
320	4	2	f
321	4	2	f
322	4	2	f
323	4	2	f
324	4	2	f
325	4	2	f
326	4	2	f
327	4	2	f
328	4	2	f
329	4	2	f
330	4	2	f
331	4	2	f
332	4	2	f
333	4	2	f
334	4	2	f
335	4	2	f
336	4	2	f
337	4	2	f
338	4	2	f
339	4	2	f
340	4	2	f
341	4	2	f
342	4	2	f
343	4	2	f
344	4	2	f
345	4	2	f
346	4	2	f
347	4	2	f
348	4	2	f
349	4	2	f
350	4	2	f
351	4	2	f
352	4	2	f
353	4	2	f
354	4	2	f
355	4	2	f
356	4	2	f
357	4	2	f
358	4	2	f
359	4	2	f
360	4	2	f
361	4	2	f
362	4	2	f
363	4	2	f
364	4	2	f
365	4	2	f
366	4	2	f
367	4	2	f
368	4	2	f
369	4	2	f
370	4	2	f
371	4	2	f
372	4	2	f
373	4	2	f
374	4	2	f
375	4	2	f
376	4	2	f
377	4	2	f
378	4	2	f
379	4	2	f
380	4	2	f
381	4	2	f
382	4	2	f
383	4	2	f
384	4	2	f
385	4	2	f
386	4	2	f
387	4	2	f
388	4	2	f
389	4	2	f
390	4	2	f
391	4	2	f
392	4	2	f
393	4	2	f
394	4	2	f
395	4	2	f
396	4	2	f
397	4	2	f
398	4	2	f
399	4	2	f
400	4	2	f
401	4	2	f
402	4	2	f
403	4	2	f
404	4	2	f
405	4	2	f
406	4	2	f
407	4	2	f
408	4	2	f
409	4	2	f
410	4	2	f
411	4	2	f
412	4	2	f
413	4	2	f
414	4	2	f
415	4	2	f
416	4	2	f
417	4	2	f
418	4	2	f
419	4	2	f
420	4	2	f
421	4	2	f
422	4	2	f
423	4	2	f
424	4	2	f
425	4	2	f
426	4	2	f
427	4	2	f
428	4	2	f
429	4	2	f
430	4	2	f
431	4	2	f
432	4	2	f
433	4	2	f
434	4	2	f
435	4	2	f
436	4	2	f
437	4	2	f
438	4	2	f
439	4	2	f
440	4	2	f
441	4	2	f
442	4	2	f
443	4	2	f
444	4	2	f
445	4	2	f
446	4	2	f
447	4	2	f
448	4	2	f
449	4	2	f
450	4	2	f
451	4	2	f
452	4	2	f
453	4	2	f
454	4	2	f
455	4	2	f
456	4	2	f
457	4	2	f
458	4	2	f
459	4	2	f
460	4	2	f
461	4	2	f
462	4	2	f
463	4	2	f
464	4	2	f
465	4	2	f
466	4	2	f
467	4	2	f
468	4	2	f
469	4	2	f
470	4	2	f
471	4	2	f
472	4	2	f
473	4	2	f
474	4	2	f
475	4	2	f
476	4	2	f
477	4	2	f
478	4	2	f
479	4	2	f
480	4	2	f
481	4	2	f
482	4	2	f
483	4	2	f
484	4	2	f
485	4	2	f
486	4	2	f
487	4	2	f
488	4	2	f
489	4	2	f
490	4	2	f
491	4	2	f
492	4	2	f
493	4	2	f
494	4	2	f
495	4	2	f
496	4	2	f
497	4	2	f
498	4	2	f
499	4	2	f
500	4	2	f
501	4	2	f
502	4	2	f
503	4	2	f
504	4	2	f
505	4	2	f
506	4	2	f
507	4	2	f
508	4	2	f
509	4	2	f
510	4	2	f
511	4	2	f
512	4	2	f
513	4	2	f
514	4	2	f
515	4	2	f
516	4	2	f
517	4	2	f
518	4	2	f
519	4	2	f
520	4	2	f
521	4	2	f
522	4	2	f
523	4	2	f
524	4	2	f
525	4	2	f
526	4	2	f
527	4	2	f
528	4	2	f
529	4	2	f
530	4	2	f
531	4	2	f
532	4	2	f
533	4	2	f
534	4	2	f
535	4	2	f
536	4	2	f
537	4	2	f
538	4	2	f
539	4	2	f
540	4	2	f
541	4	2	f
542	4	2	f
543	4	2	f
544	4	2	f
545	4	2	f
546	4	2	f
547	4	2	f
548	4	2	f
549	4	2	f
550	4	2	f
551	4	2	f
552	4	2	f
553	4	2	f
554	4	2	f
555	4	2	f
556	4	2	f
557	4	2	f
558	4	2	f
559	4	2	f
560	4	2	f
561	4	2	f
562	4	2	f
563	4	2	f
564	4	2	f
565	4	2	f
566	4	2	f
567	4	2	f
568	4	2	f
569	4	2	f
570	4	2	f
571	4	2	f
572	4	2	f
573	4	2	f
574	4	2	f
575	4	2	f
576	4	2	f
577	4	2	f
578	4	2	f
579	4	2	f
580	4	2	f
581	4	2	f
582	4	2	f
583	4	2	f
584	4	2	f
585	4	2	f
586	4	2	f
587	4	2	f
588	4	2	f
589	4	2	f
590	4	2	f
591	4	2	f
592	4	2	f
593	4	2	f
594	4	2	f
595	4	2	f
596	4	2	f
597	4	2	f
598	4	2	f
599	4	2	f
600	4	2	f
601	4	2	f
602	4	2	f
603	4	2	f
604	4	2	f
605	4	2	f
606	4	2	f
607	4	2	f
608	4	2	f
609	4	2	f
610	4	2	f
611	4	2	f
612	4	2	f
613	4	2	f
614	4	2	f
615	4	2	f
616	4	2	f
617	4	2	f
618	4	2	f
619	4	2	f
620	4	2	f
621	4	2	f
622	4	2	f
623	4	2	f
624	4	2	f
625	4	2	f
626	4	2	f
627	4	2	f
628	4	2	f
629	4	2	f
630	4	2	f
631	4	2	f
632	4	2	f
633	4	2	f
634	4	2	f
635	4	2	f
636	4	2	f
637	4	2	f
638	4	2	f
639	4	2	f
640	4	2	f
641	4	2	f
642	4	2	f
643	4	2	f
644	4	2	f
645	4	2	f
646	4	2	f
647	4	2	f
648	4	2	f
649	4	2	f
650	4	2	f
651	4	2	f
652	4	2	f
653	4	2	f
654	4	2	f
655	4	2	f
656	4	2	f
657	4	2	f
658	4	2	f
659	4	2	f
660	4	2	f
661	4	2	f
662	4	2	f
663	4	2	f
664	4	2	f
665	4	2	f
666	4	2	f
667	4	2	f
668	4	2	f
669	4	2	f
670	4	2	f
671	4	2	f
672	4	2	f
673	4	2	f
674	4	2	f
675	4	2	f
676	4	2	f
677	4	2	f
678	4	2	f
679	4	2	f
680	4	2	f
681	4	2	f
682	4	2	f
683	4	2	f
684	4	2	f
685	4	2	f
686	4	2	f
687	4	2	f
688	4	2	f
689	4	2	f
690	4	2	f
691	4	2	f
692	4	2	f
693	4	2	f
694	4	2	f
695	4	2	f
696	4	2	f
697	4	2	f
698	4	2	f
699	4	2	f
700	4	2	f
701	4	2	f
702	4	2	f
703	4	2	f
704	4	2	f
705	4	2	f
706	4	2	f
707	4	2	f
708	4	2	f
709	4	2	f
710	4	2	f
711	4	2	f
712	4	2	f
713	4	2	f
714	4	2	f
715	4	2	f
716	4	2	f
717	4	2	f
718	4	2	f
719	4	2	f
720	4	2	f
721	4	2	f
722	4	2	f
723	4	2	f
724	4	2	f
725	4	2	f
726	4	2	f
727	4	2	f
728	4	2	f
729	4	2	f
730	4	2	f
731	4	2	f
732	4	2	f
733	4	2	f
734	4	2	f
735	4	2	f
736	4	2	f
737	4	2	f
738	4	2	f
739	4	2	f
740	4	2	f
741	4	2	f
742	4	2	f
743	4	2	f
744	4	2	f
745	4	2	f
746	4	2	f
747	4	2	f
748	4	2	f
749	4	2	f
750	4	2	f
751	4	2	f
752	4	2	f
753	4	2	f
754	4	2	f
755	4	2	f
756	4	2	f
757	4	2	f
758	4	2	f
759	4	2	f
760	4	2	f
761	4	2	f
762	4	2	f
763	4	2	f
764	4	2	f
765	4	2	f
766	4	2	f
767	4	2	f
768	4	2	f
769	4	2	f
770	4	2	f
771	4	2	f
772	4	2	f
773	4	2	f
774	4	2	f
775	4	2	f
776	4	2	f
777	4	2	f
778	4	2	f
779	4	2	f
780	4	2	f
781	4	2	f
782	4	2	f
783	4	2	f
784	4	2	f
785	4	2	f
786	4	2	f
787	4	2	f
788	4	2	f
789	4	2	f
790	4	2	f
791	4	2	f
792	4	2	f
793	4	2	f
794	4	2	f
795	4	2	f
796	4	2	f
797	4	2	f
798	4	2	f
799	4	2	f
800	4	2	f
801	4	2	f
802	4	2	f
803	4	2	f
804	4	2	f
805	4	2	f
806	4	2	f
807	4	2	f
808	4	2	f
809	4	2	f
810	4	2	f
811	4	2	f
812	4	2	f
813	4	2	f
814	4	2	f
815	4	2	f
816	4	2	f
817	4	2	f
818	4	2	f
819	4	2	f
820	4	2	f
821	4	2	f
822	4	2	f
823	4	2	f
824	4	2	f
825	4	2	f
826	4	2	f
827	4	2	f
828	4	2	f
829	4	2	f
830	4	2	f
831	4	2	f
832	4	2	f
833	4	2	f
834	4	2	f
835	4	2	f
836	4	2	f
837	4	2	f
838	4	2	f
839	4	2	f
840	4	2	f
841	4	2	f
842	4	2	f
843	4	2	f
844	4	2	f
845	4	2	f
846	4	2	f
847	4	2	f
848	4	2	f
849	4	2	f
850	4	2	f
851	4	2	f
852	4	2	f
853	4	2	f
854	4	2	f
855	4	2	f
856	4	2	f
857	4	2	f
858	4	2	f
859	4	2	f
860	4	2	f
861	4	2	f
862	4	2	f
863	4	2	f
864	4	2	f
865	4	2	f
866	4	2	f
867	4	2	f
868	4	2	f
869	4	2	f
870	4	2	f
871	4	2	f
872	4	2	f
873	4	2	f
874	4	2	f
875	4	2	f
876	4	2	f
877	4	2	f
878	4	2	f
879	4	2	f
880	4	2	f
881	4	2	f
882	4	2	f
883	4	2	f
884	4	2	f
885	4	2	f
886	4	2	f
887	4	2	f
888	4	2	f
889	4	2	f
890	4	2	f
891	4	2	f
892	4	2	f
893	4	2	f
894	4	2	f
895	4	2	f
896	4	2	f
897	4	2	f
898	4	2	f
899	4	2	f
900	4	2	f
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
1391	4	3	f
1392	4	3	f
1393	4	3	f
1394	4	3	f
1395	4	3	f
1396	4	3	f
1397	4	3	f
1398	4	3	f
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
1501	1	4	f
1502	1	4	f
1503	1	4	f
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
1847	2	4	f
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
1954	2	4	f
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
2051	3	4	f
2052	3	4	f
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
2121	3	4	f
2122	3	4	f
2123	3	4	f
2124	3	4	f
2125	3	4	f
2126	3	4	f
2127	3	4	f
2128	3	4	f
2129	3	4	f
2130	3	4	f
2131	3	4	f
2132	3	4	f
2133	3	4	f
2134	3	4	f
2135	3	4	f
2136	3	4	f
2137	3	4	f
2138	3	4	f
2139	3	4	f
2140	3	4	f
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
-- Data for Name: spot_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spot_type (spottypeid, vehicletype, isprivileged) FROM stdin;
3	t	t
2	f	f
1	f	t
4	t	f
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff (staffid, fullname, password, parkinglotid) FROM stdin;
2	Nguyễn Nhân Viên	12345678	1
3	Nguyễn Đức Quân	12345678	4
\.


--
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student (customerid, fullname, mssv, balance, password) FROM stdin;
3	Le Van Anh	20225882	0	123456
4	Tran Minh Tuan	20225883	100000	123456
5	Pham Thi Mai Anh\n	20225884	100000	123456
17	Nguyễn Văn Dũng	20225879	0	123456
20	Nguyễn Hồng Nhung	20221555	0	123456
22	Nguyễn Đức Mạnh	20225880	100000	1234567
\.


--
-- Data for Name: transaction; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction (transactionid, mssv, amount, "time", tranaction_type) FROM stdin;
7	20225880	100000	2024-05-10 18:02:45.921968	t
\.


--
-- Data for Name: vehicle; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle (vehicleid, vehicletypeid, license_plate, color, customerid) FROM stdin;
1	2	37A-89205	red	1
\.


--
-- Data for Name: vehicle_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle_type (vehicletypeid, name, price) FROM stdin;
1	Xe máy\n	3000
2	Xe đạp	2000
3	Ô tô	5000
\.


--
-- Data for Name: visitor; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.visitor (customerid, ticketid) FROM stdin;
6	4bfd3dd5-0d4c-4ba0-bd1d-d9ea08a17144
7	7839a369-ad6e-449a-8e9e-fd3aa88d49f9
8	50e27aeb-f96a-49ab-a673-f7bfbb63717b
9	d4cf6761-34e8-4cf5-9083-d197ac563bca
10	d1a86334-898f-4d86-9a1f-156e84d28101
11	0ef8665b-2c8d-4653-ad7d-a08807b6ed42
15	5749c5b8-c8bc-468b-b578-5cbd7831f6bf
\.


--
-- Name: customer_customerid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customer_customerid_seq', 23, true);


--
-- Name: customerid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.customerid_seq', 1, false);


--
-- Name: park_parkid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.park_parkid_seq', 1, false);


--
-- Name: parking_lot_parkinglotid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parking_lot_parkinglotid_seq', 1, false);


--
-- Name: parking_spot_parkingspotid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parking_spot_parkingspotid_seq', 2300, true);


--
-- Name: spot_type_spottypeid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.spot_type_spottypeid_seq', 1, false);


--
-- Name: staff_staffid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.staff_staffid_seq', 3, true);


--
-- Name: transaction_transactionid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_transactionid_seq', 7, true);


--
-- Name: vehicle_type_vehicletypeid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_type_vehicletypeid_seq', 1, false);


--
-- Name: vehicle_vehicleid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_vehicleid_seq', 1, false);


--
-- Name: customer customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.customer
    ADD CONSTRAINT customer_pkey PRIMARY KEY (customerid);


--
-- Name: park park_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_pkey PRIMARY KEY (parkid);


--
-- Name: parking_lot parking_lot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_lot
    ADD CONSTRAINT parking_lot_pkey PRIMARY KEY (parkinglotid);


--
-- Name: parking_spot parking_spot_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_pkey PRIMARY KEY (parkingspotid);


--
-- Name: spot_type spot_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.spot_type
    ADD CONSTRAINT spot_type_pkey PRIMARY KEY (spottypeid);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staffid);


--
-- Name: student student_mssv_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_mssv_key UNIQUE (mssv);


--
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (customerid);


--
-- Name: vehicle vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (vehicleid);


--
-- Name: vehicle_type vehicle_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_type
    ADD CONSTRAINT vehicle_type_pkey PRIMARY KEY (vehicletypeid);


--
-- Name: visitor visitor_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitor
    ADD CONSTRAINT visitor_pkey PRIMARY KEY (customerid);


--
-- Name: student payin_log; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER payin_log AFTER UPDATE OF balance ON public.student FOR EACH ROW EXECUTE FUNCTION public.payin_log_func();


--
-- Name: park park_parkingspotid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_parkingspotid_fkey FOREIGN KEY (parkingspotid) REFERENCES public.parking_spot(parkingspotid);


--
-- Name: park park_vehicleid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.park
    ADD CONSTRAINT park_vehicleid_fkey FOREIGN KEY (vehicleid) REFERENCES public.vehicle(vehicleid);


--
-- Name: parking_spot parking_spot_parkinglotid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_parkinglotid_fkey FOREIGN KEY (parkinglotid) REFERENCES public.parking_lot(parkinglotid);


--
-- Name: parking_spot parking_spot_spottypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_spot
    ADD CONSTRAINT parking_spot_spottypeid_fkey FOREIGN KEY (spottypeid) REFERENCES public.spot_type(spottypeid);


--
-- Name: staff staff_parkinglotid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_parkinglotid_fkey FOREIGN KEY (parkinglotid) REFERENCES public.parking_lot(parkinglotid);


--
-- Name: student student_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);


--
-- Name: transaction transaction_mssv_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_mssv_fkey1 FOREIGN KEY (mssv) REFERENCES public.student(mssv) ON DELETE CASCADE;


--
-- Name: vehicle vehicle_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle
    ADD CONSTRAINT vehicle_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);


--
-- Name: vehicle vehicle_vehicletypeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle
    ADD CONSTRAINT vehicle_vehicletypeid_fkey FOREIGN KEY (vehicletypeid) REFERENCES public.vehicle_type(vehicletypeid);


--
-- Name: visitor visitor_customerid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.visitor
    ADD CONSTRAINT visitor_customerid_fkey FOREIGN KEY (customerid) REFERENCES public.customer(customerid);


--
-- PostgreSQL database dump complete
--

