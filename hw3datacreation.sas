LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

PROC FORMAT CNTLIN = SL.formats;
RUN;

/* Create sample and export as csv */

PROC SURVEYSELECT DATA = SL.customer_dim
	METHOD = srs
	N = 200000
	OUT = SL.sample_customers
	SEED = 12345;
	ID customer_dim_pk;
RUN;

PROC SQL;
	CREATE TABLE WORK.sample_srv AS
		SELECT DISTINCT bill.customer_dim_pk, bill.month_dim_pk, vid.*, bill.video_prc
		FROM WORK.sample_customers AS sample, SL.srv_bundle_mth_fact AS bill,
			SL.srv_bundle_dim AS vid
		WHERE sample.customer_dim_pk = bill.customer_dim_pk
			AND vid.srv_bundle_dim_pk = bill.srv_bundle_dim_pk;
QUIT;

PROC EXPORT DATA = WORK.sample_srv DBMS = CSV 
			OUTFILE = "/sscc/home/a/amk202/SuddenLink/sample_srv.csv" REPLACE;
RUN;

/* Create sample for LCA and export as csv */

PROC SQL OUTOBS = 200000;
	CREATE TABLE WORK.sample_lca AS
		SELECT bill.customer_dim_pk, bill.month_dim_pk, vid.*, bill.video_prc
		FROM SL.srv_bundle_mth_fact AS bill, SL.srv_bundle_dim AS vid
		WHERE vid.srv_bundle_dim_pk = bill.srv_bundle_dim_pk
		ORDER BY RANUNI( 12345 );
QUIT;

PROC EXPORT DATA = WORK.sample_lca DBMS = CSV 
			OUTFILE = "/sscc/home/a/amk202/SuddenLink/sample_lca.csv" REPLACE;
RUN;

/* Create dataset for all video consumers for survival analysis */

PROC SQL;
	CREATE TABLE SL.video_consumers AS
		SELECT sample.customer_dim_pk, bill.month_dim_pk,
			vid.lob_video_flag, vid.basic_flag, vid.expanded_basic_flag, vid.premium_flag,
			vid.digital_flag, vid.hdtv_flag, vid.dvr_flag, vid.tivo_flag,
			vid.hsd_flag, vid.telephone_flag, bill.video_prc
		FROM SL.srv_bundle_mth_fact AS bill, SL.srv_bundle_dim AS vid,
				SL.sample_customers AS sample
		WHERE sample.customer_dim_pk = bill.customer_dim_pk AND
				vid.srv_bundle_dim_pk = bill.srv_bundle_dim_pk
		ORDER BY sample.customer_dim_pk, bill.month_dim_pk;
QUIT;

DATA SL.video_consumers;
	SET SL.video_consumers;
	BY customer_dim_pk;
	
	t_customer + 1;
	IF FIRST.customer_dim_pk THEN t_customer = 0;
	
	*cancelnow = 0;
	*IF LAST.customer_dim_pk AND month_dim_pk < 181 THEN cancelnow = 1;
	*??? ELSE IF LAST.customer_dim_pk;
RUN;
	
PROC PRINT DATA = SL.video_consumers ( OBS = 100 );
RUN;

PROC TRANSPOSE DATA = SL.video_consumers OUT = SL.video_consumers2 ( DROP = _LABEL_ )
				NAME = var_name PREFIX = m_;
	BY customer_dim_pk;
	ID t_customer;
	VAR lob_video_flag basic_flag expanded_basic_flag premium_flag digital_flag hdtv_flag
		dvr_flag tivo_flag hsd_flag telephone_flag video_prc;
RUN;

PROC TRANSPOSE DATA = SL.video_consumers2 OUT = SL.video_consumers2 ( RENAME = ( COL1 = val ) )
				NAME = month;
	BY customer_dim_pk var_name NOTSORTED;
	VAR m_0 - m_24;
RUN;

/*PROC PRINT DATA = WORK.temp( OBS = 100 );
RUN;*/

PROC TRANSPOSE DATA = SL.video_consumers2 OUT = SL.video_consumers2 ( DROP = _NAME_ )
				DELIMITER = _;
	BY customer_dim_pk;
	ID var_name month;
	VAR val;
RUN;

/*PROC DATASETS LIBRARY = WORK;
	DELETE video_consumers2;
RUN;*/

PROC PRINT DATA = SL.video_consumers2 ( OBS = 100 );
RUN;

DATA SL.video_consumers3;
	SET SL.video_consumers2;
	
	ARRAY lob_vid_m{ 0:24 } lob_video_flag_m_0 - lob_video_flag_m_24;
	ARRAY basic_m{ 0:24 } basic_flag_m_0 - basic_flag_m_24;
	ARRAY exp_basic_m{ 0:24 } expanded_basic_flag_m_0 - expanded_basic_flag_m_24;
	ARRAY premium_m{ 0:24 } premium_flag_m_0 - premium_flag_m_24;
	ARRAY digital_m{ 0:24 } digital_flag_m_0 - digital_flag_m_24;
	ARRAY hdtv_m{ 0:24 } hdtv_flag_m_0 - hdtv_flag_m_24;
	ARRAY dvr_m{ 0:24 } dvr_flag_m_0 - dvr_flag_m_24;
	ARRAY tivo_m{ 0:24 } tivo_flag_m_0 - tivo_flag_m_24;
	ARRAY hsd_m{ 0:24 } hsd_flag_m_0 - hsd_flag_m_24;
	ARRAY phone_m{ 0:24 } telephone_flag_m_0 - telephone_flag_m_24;
	ARRAY vid_prc_m{ 0:24 } video_prc_m_0 - video_prc_m_24;
	
	ARRAY lv_m{ 0:24 } lv_m_0 - lv_m_24;
	ARRAY bf_m{ 0:24 } bf_m_0 - bf_m_24;
	ARRAY xf_m{ 0:24 } xf_m_0 - xf_m_24;
	ARRAY pf_m{ 0:24 } pf_m_0 - pf_m_24;
	ARRAY df_m{ 0:24 } df_m_0 - df_m_24;
	ARRAY hd_m{ 0:24 } hd_m_0 - hd_m_24;
	ARRAY dv_m{ 0:24 } dv_m_0 - dv_m_24;
	ARRAY tf_m{ 0:24 } tf_m_0 - tf_m_24;
	ARRAY hf_m{ 0:24 } hf_m_0 - hf_m_24;
	ARRAY tp_m{ 0:24 } tp_m_0 - tp_m_24;
	ARRAY vp_m{ 0:24 } vp_m_0 - vp_m_24;
	
	DO t = 0 TO 24;
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

		IF vid_prc_m{ t } = ' ' THEN vp_m{ t } = 0;
		ELSE vp_m{ t } = vid_prc_m{ t } + 0;
	END;

	DROP lob_video_flag_m_0-lob_video_flag_m_24 basic_flag_m_0 - basic_flag_m_24
		 expanded_basic_flag_m_0 - expanded_basic_flag_m_24
		 premium_flag_m_0-premium_flag_m_24 digital_flag_m_0-digital_flag_m_24
		 hdtv_flag_m_0-hdtv_flag_m_24 dvr_flag_m_0-dvr_flag_m_24
		 tivo_flag_m_0-tivo_flag_m_24 hsd_flag_m_0-hsd_flag_m_24
		 telephone_flag_m_0 - telephone_flag_m_24 video_prc_m_0 - video_prc_m_24 t;
	RENAME lv_m_0 - lv_m_24 = lob_video_flag_m_0 - lob_video_flag_m_24;
	RENAME bf_m_0 - bf_m_24 = basic_flag_m_0 - basic_flag_m_24;
	RENAME xf_m_0 - xf_m_24 = expanded_basic_flag_m_0 - expanded_basic_flag_m_24;
	RENAME pf_m_0 - pf_m_24 = premium_flag_m_0 - premium_flag_m_24;
	RENAME df_m_0 - df_m_24 = digital_flag_m_0 - digital_flag_m_24;
	RENAME hd_m_0 - hd_m_24 = hdtv_flag_m_0 - hdtv_flag_m_24;
	RENAME dv_m_0 - dv_m_24 = dvr_flag_m_0 - dvr_flag_m_24;
	RENAME tf_m_0 - tf_m_24 = tivo_flag_m_0 - tivo_flag_m_24;
	RENAME hf_m_0 - hf_m_24 = hsd_flag_m_0 - hsd_flag_m_24;
	RENAME tp_m_0 - tp_m_24 = telephone_flag_m_0 - telephone_flag_m_24;
	RENAME vp_m_0 - vp_m_24 = video_prc_m_0 - video_prc_m_24;
RUN;

DATA SL.video_consumers3;
	SET SL.video_consumers3;
	
	ARRAY lob_vid_flag_m{ 0:24 } lob_video_flag_m_0 - lob_video_flag_m_24;
	ARRAY basic_flag_m{ 0:24 } basic_flag_m_0 - basic_flag_m_24;
	ARRAY expanded_basic_flag_m{ 0:24 } expanded_basic_flag_m_0 - expanded_basic_flag_m_24;
	ARRAY premium_flag_m{ 0:24 } premium_flag_m_0 - premium_flag_m_24;
	ARRAY digital_flag_m{ 0:24 } digital_flag_m_0 - digital_flag_m_24;
	ARRAY hdtv_flag_m{ 0:24 } hdtv_flag_m_0 - hdtv_flag_m_24;
	ARRAY dvr_flag_m{ 0:24 } dvr_flag_m_0 - dvr_flag_m_24;
	ARRAY tivo_flag_m{ 0:24 } tivo_flag_m_0 - tivo_flag_m_24;
	ARRAY hsd_flag_m{ 0:24 } hsd_flag_m_0 - hsd_flag_m_24;
	ARRAY telephone_flag_m{ 0:24 } telephone_flag_m_0 - telephone_flag_m_24;
	ARRAY vid_prc_m{ 0:24 } video_prc_m_0 - video_prc_m_24;
	
	basic_flag = basic_flag_m{ 0 };
	expanded_basic_flag = expanded_basic_flag_m{ 0 };
	premium_flag = premium_flag_m{ 0 };
	digital_flag = digital_flag_m{ 0 };
	hdtv_flag = hdtv_flag_m{ 0 };
	dvr_flag = dvr_flag_m{ 0 };
	tivo_flag = tivo_flag_m{ 0 };
	hsd_flag = hsd_flag_m{ 0 };
	telephone_flag = telephone_flag_m{ 0 };
	video_prc = vid_prc_m{ 0 };
	
	cancelnow = 0;
	
	IF lob_vid_flag_m{ 0 } = 1 THEN
		DO;
			video_t = 0;
			t = 0;
			*OUTPUT;
		END;
	ELSE video_t = -1;
	
	DO t = 1 to 24;
		basic_flag = basic_flag_m{ t - 1 };
		expanded_basic_flag = expanded_basic_flag_m{ t - 1 };
		premium_flag = premium_flag_m{ t - 1 };
		digital_flag = digital_flag_m{ t - 1 };
		hdtv_flag = hdtv_flag_m{ t - 1 };
		dvr_flag = dvr_flag_m{ t - 1 };
		tivo_flag = tivo_flag_m{ t - 1 };
		hsd_flag = hsd_flag_m{ t - 1 };
		telephone_flag = telephone_flag_m{ t - 1 };
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
		 digital_flag hdtv_flag dvr_flag tivo_flag hsd_flag telephone_flag
		 video_prc cancelnow t;
RUN;

PROC PRINT DATA = SL.video_consumers3 ( OBS = 1000 );
RUN;

/*DATA SL.sample_srv
	SET SL.sample_srv
	
	IF LAST.customer_dim_pk AND month_dim_pk < 188 AND video_flag = "1"
		THEN cancelnow = 1;
	ELSE cancelnow = 0;
RUN;*/
