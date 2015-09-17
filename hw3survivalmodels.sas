LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

PROC FORMAT CNTLIN = SL.formats;
RUN;

PROC LOGISTIC DATA = SL.video_consumers DESCENDING;
	CLASS t_customer / PARAM = REF;
	MODEL cancelnow = ;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

/* SRM */

PROC LOGISTIC DATA = SL.video_consumers_new DESCENDING OUTEST = SL.params_srm;
	CLASS video_t / PARAM = REF;
	MODEL cancelnow = premium_flag;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

/* GRM */

PROC LOGISTIC DATA = SL.video_consumers3 DESCENDING;
	CLASS video_t / PARAM = REF;
	MODEL cancelnow = video_t;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

/* Time-varying Covariates */

PROC LOGISTIC DATA = SL.video_consumers3 DESCENDING;
	CLASS video_t / PARAM = REF;
	MODEL cancelnow = video_t premium_flag digital_flag hdtv_flag tivo_flag;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

PROC LOGISTIC DATA = SL.video_consumers_new DESCENDING OUTEST = SL.params_grm;
	CLASS video_t / PARAM = REF;
	MODEL cancelnow = video_t premium_flag hdtv_flag tivo_flag dvr_flag;
	OUTPUT OUT = probs PREDICTED = phat;
RUN;

PROC MEANS DATA = SL.video_consumers_new;
	CLASS premium_flag;
	VAR video_prc;
	OUTPUT OUT = SL.vid_means;
RUN;

PROC MEANS DATA = SL.video_consumers_new;
      CLASS premium_flag hdtv_flag tivo_flag dvr_flag;
      VAR video_prc;
      OUTPUT OUT = SL.vid_means MEAN =;
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
				r = 1 - ( 1 / ( 1 + exp( -( intercept_srm + &pr * premium_flag_srm ) ) ) );
				*r = 1 - ( 1 / ( 1 + exp( -( intercept + &pr * premium_flag_srm
							+ &hd * hdtv_flag + &ti * tivo_flag + &dv * dvr_flag ) ) ) );
			
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
	SELECT CLV_Non_Premium, CLV_Premium, ( CLV_Premium - CLV_Non_Premium ) AS CLV_Delta,
		   T_Non_Premium, T_Premium, ( T_Premium - T_Non_Premium ) AS T_Delta
	FROM ( SELECT sum( val ) AS CLV_Non_Premium, sum( S ) AS T_Non_Premium
		   FROM WORK.video_clv_0 ) as nonpremium,
		 ( SELECT sum( val ) AS CLV_Premium, sum( S ) AS T_Premium
		FROM WORK.video_clv_1 ) AS premium;
QUIT;
%MEND;

%clv_calc( 0, 0, 0 );
%clv_calc( 1, 1, 1 );
