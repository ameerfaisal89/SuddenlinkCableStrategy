LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

PROC FORMAT CNTLIN = SL.formats;
RUN;

/* Create sample for LCA and export as csv */

PROC SQL;
	CREATE TABLE WORK.new_customers AS (
		SELECT DISTINCT bill.customer_dim_pk
		FROM SL.srv_bundle_mth_fact AS bill
		EXCEPT
		SELECT DISTINCT bill.customer_dim_pk
		FROM SL.srv_bundle_mth_fact AS bill
		WHERE bill.month_dim_pk = 157 );
QUIT;

PROC SQL;
	CREATE TABLE WORK.new_customers AS
		SELECT DISTINCT bill.customer_dim_pk, max( bill.month_dim_pk ) AS month_dim_pk
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
			  bill.month_dim_pk = min( cust.month_dim_pk, 177 )
		ORDER BY RANUNI( 12345 );
QUIT;

PROC EXPORT DATA = WORK.sample_lca DBMS = CSV 
			OUTFILE = "/sscc/home/a/amk202/SuddenLink/sample_lca_new.csv" REPLACE;
RUN;

/* Create dataset for video consumers not left censored for survival analysis */

PROC SQL;
	CREATE TABLE SL.video_consumers_new_raw AS
		SELECT bill.customer_dim_pk, bill.month_dim_pk,
			vid.lob_video_flag, vid.basic_flag, vid.expanded_basic_flag, vid.premium_flag,
			vid.digital_flag, vid.hdtv_flag, vid.dvr_flag, vid.tivo_flag,
			vid.hsd_flag, vid.telephone_flag, vid.hsd_down_speed, vid.lob_count,
			bill.video_prc, bill.hsd_prc, bill.phone_prc
		FROM SL.srv_bundle_mth_fact AS bill, SL.srv_bundle_dim AS vid
		WHERE vid.srv_bundle_dim_pk = bill.srv_bundle_dim_pk
		ORDER BY bill.customer_dim_pk, bill.month_dim_pk;
QUIT;

DATA SL.video_consumers_new_raw;
	SET SL.video_consumers_new_raw;
	BY customer_dim_pk;
	
	RETAIN del_flag;
	
	t_customer + 1;
	
	IF FIRST.customer_dim_pk THEN
		DO;
			del_flag = 0;
			t_customer = 0;
		END;
	
	IF FIRST.customer_dim_pk AND month_dim_pk = 157 THEN del_flag = 1;
	IF del_flag = 0;
	
	DROP del_flag;
RUN;
	
/*PROC PRINT DATA = SL.video_consumers_new ( OBS = 100 );
	*WHERE month_dim_pk = 157;
RUN;*/

PROC TRANSPOSE DATA = SL.video_consumers_new_raw OUT = SL.video_consumers_new ( DROP = _LABEL_ )
				NAME = var_name PREFIX = m_;
	BY customer_dim_pk;
	ID t_customer;
	VAR lob_video_flag basic_flag expanded_basic_flag premium_flag digital_flag hdtv_flag
		dvr_flag tivo_flag hsd_flag telephone_flag hsd_down_speed video_prc;
RUN;

PROC TRANSPOSE DATA = SL.video_consumers_new OUT = SL.video_consumers_new ( RENAME = ( COL1 = val ) )
				NAME = month;
	BY customer_dim_pk var_name NOTSORTED;
	VAR m_0 - m_23;
RUN;

/*PROC PRINT DATA = WORK.temp( OBS = 100 );
RUN;*/

PROC TRANSPOSE DATA = SL.video_consumers_new OUT = SL.video_consumers_new ( DROP = _NAME_ )
				DELIMITER = _;
	BY customer_dim_pk;
	ID var_name month;
	VAR val;
RUN;

/*PROC DATASETS LIBRARY = WORK;
	DELETE video_consumers2;
RUN;*/

/*PROC PRINT DATA = SL.video_consumers2 ( OBS = 100 );
RUN;*/

DATA SL.video_consumers_new;
	SET SL.video_consumers_new;
	
	ARRAY lob_vid_m{ 0:23 } lob_video_flag_m_0 - lob_video_flag_m_23;
	ARRAY basic_m{ 0:23 } basic_flag_m_0 - basic_flag_m_23;
	ARRAY exp_basic_m{ 0:23 } expanded_basic_flag_m_0 - expanded_basic_flag_m_23;
	ARRAY premium_m{ 0:23 } premium_flag_m_0 - premium_flag_m_23;
	ARRAY digital_m{ 0:23 } digital_flag_m_0 - digital_flag_m_23;
	ARRAY hdtv_m{ 0:23 } hdtv_flag_m_0 - hdtv_flag_m_23;
	ARRAY dvr_m{ 0:23 } dvr_flag_m_0 - dvr_flag_m_23;
	ARRAY tivo_m{ 0:23 } tivo_flag_m_0 - tivo_flag_m_23;
	ARRAY hsd_m{ 0:23 } hsd_flag_m_0 - hsd_flag_m_23;
	ARRAY phone_m{ 0:23 } telephone_flag_m_0 - telephone_flag_m_23;
	ARRAY hsd_down_m{ 0:23 } hsd_down_speed_m_0 - hsd_down_speed_m_23;
	ARRAY vid_prc_m{ 0:23 } video_prc_m_0 - video_prc_m_23;
	
	ARRAY lv_m{ 0:23 } lv_m_0 - lv_m_23;
	ARRAY bf_m{ 0:23 } bf_m_0 - bf_m_23;
	ARRAY xf_m{ 0:23 } xf_m_0 - xf_m_23;
	ARRAY pf_m{ 0:23 } pf_m_0 - pf_m_23;
	ARRAY df_m{ 0:23 } df_m_0 - df_m_23;
	ARRAY hd_m{ 0:23 } hd_m_0 - hd_m_23;
	ARRAY dv_m{ 0:23 } dv_m_0 - dv_m_23;
	ARRAY tf_m{ 0:23 } tf_m_0 - tf_m_23;
	ARRAY hf_m{ 0:23 } hf_m_0 - hf_m_23;
	ARRAY tp_m{ 0:23 } tp_m_0 - tp_m_23;
	ARRAY ds_m{ 0:23 } ds_m_0 - ds_m_23;
	ARRAY vp_m{ 0:23 } vp_m_0 - vp_m_23;
	
	DO t = 0 TO 23;
		IF lob_vid_m{ t } = ' ' THEN lv_m{ t } = -1;
		ELSE lv_m{ t } = lob_vid_m{ t } + 0;
		
		IF basic_m{ t } = ' ' THEN bf_m{ t } = -1;
		ELSE bf_m{ t } = basic_m{ t } + 0;

		IF exp_basic_m{ t } = ' ' THEN xf_m{ t } = -1;
		ELSE xf_m{ t } = exp_basic_m{ t } + 0;
		
		IF premium_m{ t } = ' ' THEN pf_m{ t } = -1;
		ELSE pf_m{ t } = premium_m{ t } + 0;
		
		IF digital_m{ t } = ' ' THEN df_m{ t } = -1;
		ELSE df_m{ t } = digital_m{ t } + 0;
		
		IF hdtv_m{ t } = ' ' THEN hd_m{ t } = -1;
		ELSE hd_m{ t } = hdtv_m{ t } + 0;
		
		IF dvr_m{ t } = ' ' THEN dv_m{ t } = -1;
		ELSE dv_m{ t } = dvr_m{ t } + 0;
		
		IF tivo_m{ t } = ' ' THEN tf_m{ t } = -1;
		ELSE tf_m{ t } = tivo_m{ t } + 0;
		
		IF hsd_m{ t } = ' ' THEN hf_m{ t } = -1;
		ELSE hf_m{ t } = hsd_m{ t } + 0;

		IF phone_m{ t } = ' ' THEN tp_m{ t } = -1;
		ELSE tp_m{ t } = phone_m{ t } + 0;
		
		IF hsd_down_m{ t } = ' ' THEN ds_m{ t } = 0;
		ELSE ds_m{ t } = hsd_down_m{ t } + 0;

		IF vid_prc_m{ t } = ' ' THEN vp_m{ t } = 0;
		ELSE vp_m{ t } = vid_prc_m{ t } + 0;
	END;
	
	DROP lob_video_flag_m_0-lob_video_flag_m_23 basic_flag_m_0 - basic_flag_m_23
		 expanded_basic_flag_m_0 - expanded_basic_flag_m_23
		 premium_flag_m_0-premium_flag_m_23 digital_flag_m_0-digital_flag_m_23
		 hdtv_flag_m_0-hdtv_flag_m_23 dvr_flag_m_0-dvr_flag_m_23
		 tivo_flag_m_0-tivo_flag_m_23 hsd_flag_m_0-hsd_flag_m_23
		 telephone_flag_m_0 - telephone_flag_m_23 hsd_down_speed_m_0 - hsd_down_speed_m_23
		 video_prc_m_0 - video_prc_m_23 t;
	RENAME lv_m_0 - lv_m_23 = lob_video_flag_m_0 - lob_video_flag_m_23;
	RENAME bf_m_0 - bf_m_23 = basic_flag_m_0 - basic_flag_m_23;
	RENAME xf_m_0 - xf_m_23 = expanded_basic_flag_m_0 - expanded_basic_flag_m_23;
	RENAME pf_m_0 - pf_m_23 = premium_flag_m_0 - premium_flag_m_23;
	RENAME df_m_0 - df_m_23 = digital_flag_m_0 - digital_flag_m_23;
	RENAME hd_m_0 - hd_m_23 = hdtv_flag_m_0 - hdtv_flag_m_23;
	RENAME dv_m_0 - dv_m_23 = dvr_flag_m_0 - dvr_flag_m_23;
	RENAME tf_m_0 - tf_m_23 = tivo_flag_m_0 - tivo_flag_m_23;
	RENAME hf_m_0 - hf_m_23 = hsd_flag_m_0 - hsd_flag_m_23;
	RENAME tp_m_0 - tp_m_23 = telephone_flag_m_0 - telephone_flag_m_23;
	RENAME ds_m_0 - ds_m_23 = hsd_down_speed_m_0 - hsd_down_speed_m_23;
	RENAME vp_m_0 - vp_m_23 = video_prc_m_0 - video_prc_m_23;
RUN;

DATA SL.video_consumers_new;
	SET SL.video_consumers_new;
	
	ARRAY lob_vid_flag_m{ 0:23 } lob_video_flag_m_0 - lob_video_flag_m_23;
	ARRAY basic_flag_m{ 0:23 } basic_flag_m_0 - basic_flag_m_23;
	ARRAY expanded_basic_flag_m{ 0:23 } expanded_basic_flag_m_0 - expanded_basic_flag_m_23;
	ARRAY premium_flag_m{ 0:23 } premium_flag_m_0 - premium_flag_m_23;
	ARRAY digital_flag_m{ 0:23 } digital_flag_m_0 - digital_flag_m_23;
	ARRAY hdtv_flag_m{ 0:23 } hdtv_flag_m_0 - hdtv_flag_m_23;
	ARRAY dvr_flag_m{ 0:23 } dvr_flag_m_0 - dvr_flag_m_23;
	ARRAY tivo_flag_m{ 0:23 } tivo_flag_m_0 - tivo_flag_m_23;
	ARRAY hsd_flag_m{ 0:23 } hsd_flag_m_0 - hsd_flag_m_23;
	ARRAY telephone_flag_m{ 0:23 } telephone_flag_m_0 - telephone_flag_m_23;
	ARRAY hsd_down_m{ 0:23 } hsd_down_speed_m_0 - hsd_down_speed_m_23;
	ARRAY vid_prc_m{ 0:23 } video_prc_m_0 - video_prc_m_23;
	
	basic_flag = basic_flag_m{ 0 };
	expanded_basic_flag = expanded_basic_flag_m{ 0 };
	premium_flag = premium_flag_m{ 0 };
	digital_flag = digital_flag_m{ 0 };
	hdtv_flag = hdtv_flag_m{ 0 };
	dvr_flag = dvr_flag_m{ 0 };
	tivo_flag = tivo_flag_m{ 0 };
	hsd_flag = hsd_flag_m{ 0 };
	telephone_flag = telephone_flag_m{ 0 };
	hsd_down_speed = hsd_down_m{ 0 };
	video_prc = vid_prc_m{ 0 };
	
	cancelnow = 0;
	
	IF lob_vid_flag_m{ 0 } = 1 THEN
		DO;
			video_t = 0;
			t = 0;
			*OUTPUT;
		END;
	ELSE video_t = -1;
	
	DO t = 1 to 23;
		basic_flag = basic_flag_m{ t - 1 };
		expanded_basic_flag = expanded_basic_flag_m{ t - 1 };
		premium_flag = premium_flag_m{ t - 1 };
		digital_flag = digital_flag_m{ t - 1 };
		hdtv_flag = hdtv_flag_m{ t - 1 };
		dvr_flag = dvr_flag_m{ t - 1 };
		tivo_flag = tivo_flag_m{ t - 1 };
		hsd_flag = hsd_flag_m{ t - 1 };
		telephone_flag = telephone_flag_m{ t - 1 };
		hsd_down_speed = hsd_down_m{ t - 1 };
		video_prc = vid_prc_m{ t - 1 };
		
		IF lob_vid_flag_m{ t } = 1 THEN
			DO;
				video_t = video_t + 1;				
				cancelnow = 0;
				IF video_t > 0 THEN OUTPUT;
			END;
		
		ELSE IF lob_vid_flag_m{ t } ~= 1 AND lob_vid_flag_m{ t - 1 } = 1 THEN
			DO;
				video_t = video_t + 1;
				cancelnow = 1;
				OUTPUT;
			END;
			
		ELSE IF lob_vid_flag_m{ t } ~= 1 AND lob_vid_flag_m{ t - 1 } ~= 1 THEN
			video_t = -1;
	END;
	
	KEEP customer_dim_pk video_t basic_flag expanded_basic_flag premium_flag
		 digital_flag hdtv_flag dvr_flag tivo_flag hsd_flag telephone_flag hsd_down_speed
		 video_prc cancelnow t;
RUN;

PROC PRINT DATA = SL.video_consumers_new ( OBS = 1000 );
RUN;
