proc datasets lib = SL;
run;


PROC PRINT DATA = SL.video_consumers2 ( OBS = 100 );
RUN;

proc datasets library = SL;
   change video_consumers3 = video_consumers2;
run;

proc sql;
	select count( * )
	from work.sample_lca
	where month_dim_pk = 157;
quit;

proc print data = sl.params_grm (obs = 100);
run;

PROC MEANS DATA = SL.video_consumers_new;
      CLASS premium_flag tivo_flag dvr_flag digital_flag expanded_basic_flag;
      VAR video_prc;
RUN;

PROC MEANS DATA = SL.video_consumers_new_raw;
      CLASS lob_video_flag premium_flag month_dim_pk;
      VAR video_prc;
RUN;

/*DATA WORK.video_consumers_new;
	SET SL.video_consumers_new;
	
	IF video_t > 18 THEN
		DO;
			log_t = log( video_t );
			video_t = 19; 
		END;
	ELSE log_t = 0;
RUN;*/

PROC LOGISTIC DATA = SL.video_consumers_new DESCENDING OUTEST = SL.params_grm;
	CLASS video_t / PARAM = REF;
	MODEL cancelnow = video_t premium_flag hdtv_flag tivo_flag dvr_flag;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

%MACRO clv_calc( hd, ti, dv );
%DO pr = 0 %TO 1;
	DATA WORK.video_clv_&pr;
		SET SL.params_grm ( DROP = _LINK_ _TYPE_ _STATUS_ _NAME_ _LNLIKE_ _ESTTYPE_ );
		SET SL.params_srm ( DROP = _LINK_ _TYPE_ _STATUS_ _NAME_ _LNLIKE_ _ESTTYPE_ 
							RENAME = ( intercept = intercept_srm
									   premium_flag = premium_flag_srm ) );
		SET SL.vid_means ( WHERE = ( pr = 0 AND hd = &hd AND ti = &ti AND dv = &dv )
						   /*KEEP = video_prc*/
						   RENAME = ( video_prc = m_mean premium_flag = pr hdtv_flag = hd
										tivo_flag = ti dvr_flag = dv) );
		
		RETAIN d S S_prev r r_prev t;
		
		ARRAY beta_m{ 1:22 } video_t1 - video_t22;
	
		IF _N_ = 1 THEN 
			DO;
				t = 0;
				S_prev = 0;
				S = 1;
	
				r = 0;
				r_prev = 1;
			END;
		
		d = 0.01;
		
		DO t = 1 TO 500;
			IF t < 23 THEN
				r = 1 - ( 1 / ( 1 + exp( -( intercept + beta_m{ t } + &pr * premium_flag
							+ &hd * hdtv_flag + &ti * tivo_flag + &dv * dvr_flag ) ) ) );
			ELSE
				r = 1 - ( 1 / ( 1 + exp( -( intercept_srm + &pr * premium_flag_srm
							+ &hd * hdtv_flag + &ti * tivo_flag + &dv * dvr_flag ) ) ) );
				/*r = 1 - ( 1 / ( 1 + exp( -( intercept + &pr * premium_flag_srm
							+ &hd * hdtv_flag + &ti * tivo_flag + &dv * dvr_flag ) ) ) );*/
			
			m_prev = m_mean / ( 1 + d ) ** ( t - 1 );
			
			val = m_prev * S;
			
			IF t > 1 THEN S = S_prev * r_prev;
			
			S_prev = S;
			r_prev = r;
			
			OUTPUT;
		END;
		
		KEEP t r S m_prev val;
	RUN;
%END;
	
PROC SQL;
	SELECT ( CLV_Premium - CLV_Non_Premium ) AS CLV_Delta, ( T_Premium - T_Non_Premium ) AS T_Delta
	FROM ( SELECT sum( val ) AS CLV_Non_Premium, sum( S ) AS T_Non_Premium
		   FROM WORK.video_clv_0 ) as nonpremium,
		 ( SELECT sum( val ) AS CLV_Premium, sum( S ) AS T_Premium
		FROM WORK.video_clv_1 ) AS premium;
QUIT;
%MEND;

%clv_calc( 0, 0, 0 );
%clv_calc( 1, 1, 1 );

proc print data = work.params_grm;
run;

PROC LOGISTIC DATA = SL.video_consumers_new DESCENDING;
	CLASS video_t / PARAM = REF;
	MODEL cancelnow = video_t premium_flag digital_flag hdtv_flag tivo_flag dvr_flag;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

PROC SQL;
	CREATE TABLE WORK.new_customers AS
		SELECT DISTINCT bill.customer_dim_pk
		FROM SL.srv_bundle_mth_fact AS bill
		EXCEPT
		SELECT DISTINCT bill.customer_dim_pk
		FROM SL.srv_bundle_mth_fact AS bill
		WHERE bill.month_dim_pk = 157;
QUIT;

PROC SQL;
	CREATE TABLE WORK.new_customers AS
		SELECT DISTINCT bill.customer_dim_pk, min( bill.month_dim_pk ) AS month_dim_pk
		FROM SL.srv_bundle_mth_fact AS bill, WORK.new_customers AS cust
		WHERE bill.customer_dim_pk = cust.customer_dim_pk
		GROUP BY bill.customer_dim_pk;
QUIT;

PROC SQL; *OUTOBS = 400000;
	CREATE TABLE WORK.sample_lca AS
		SELECT bill.customer_dim_pk, bill.month_dim_pk, vid.*, bill.video_prc,
			   bill.phone_prc, bill.hsd_prc
		FROM SL.srv_bundle_mth_fact AS bill, SL.srv_bundle_dim AS vid,
				WORK.new_customers AS cust
		WHERE vid.srv_bundle_dim_pk = bill.srv_bundle_dim_pk AND
			  bill.customer_dim_pk = cust.customer_dim_pk AND
			  bill.month_dim_pk = cust.month_dim_pk
		ORDER BY RANUNI( 12345 );
QUIT;

PROC FREQ DATA = WORK.sample_lca;
	TABLES premium_flag hdtv_flag tivo_flag dvr_flag;
RUN;

PROC SQL;
	SELECT max( month_dim_pk )
	FROM sample_lca;
QUIT;




