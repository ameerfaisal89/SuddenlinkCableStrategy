LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

* Query to check for matching customers between hsd_usage_fact and srv_bundle_mth_fact;

PROC SQL;
	select count( temp.customer_dim_pk )
	from (	select distinct S.customer_dim_pk
			from SL.srv_bundle_mth_fact as S
			where S.month_dim_pk = 174
			except
			select distinct H.customer_dim_pk
			from SL.hsd_usage_fact as H
			where H.month_dim_pk = 174
	) as temp;
QUIT;

DATA sample_customer_overall_info;
	SET SL.srv_bundle_mth_fact;
	BY customer_dim_pk;

	IF LAST.customer_dim_pk;
RUN;

PROC SURVEYSELECT DATA = sample_customer_overall_info
	METHOD = srs
	N = 100000
	OUT = sample_customer_overall_info
	SEED = 12345;
RUN;

PROC SQL;
	create table sample_customer_overall_info as (
		select *
		from sample_customer_overall_info natural join SL.srv_bundle_dim
	);
QUIT;

PROC SQL;
	create table sample_customer_overall_info as (
		select *
		from sample_customer_overall_info natural join SL.house_dim
	);
QUIT;

/*DATA customer_overall_info;
	SET SL.customer_overall_info;
	BY customer_dim_pk;

	IF LAST.customer_dim_pk;
	
	new_vod_enabled_flag = input( vod_enabled_flag, 3.0 );
	DROP vod_enabled_flag;
	RENAME new_vod_enabled_flag = vod_enabled_flag
	vod_enabled_flag = 10 * vod_enabled_flag;
RUN;

PROC SURVEYSELECT DATA = customer_overall_info
	METHOD = srs
	N = 100000
	OUT = sample_customer_overall_info
	SEED = 12345;
RUN;*/

%MACRO doclus(dat, varlist, first, last);
	%DO numclus = &first %TO &last;

		PROC FASTCLUS DATA=&dat MAXITER=100
			CONVERGE=0 DRIFT MAXC=&numclus
			out=clusout&numclus;
			VAR &varlist;
		RUN;

		PROC FREQ DATA=clusout&numclus;
			TABLES cluster;
		RUN;

		DATA _long;
			SET clusout&numclus;
			LENGTH varname $8;
			%LET i = 1;
			%LET varname = %SCAN(&varlist, &i);
			%DO %WHILE(%LENGTH(&varname)>0);
				varname = "&varname";
				x = &varname;
				OUTPUT;
				KEEP cluster varname x;
				%LET i = %EVAL(&i+1);
				%LET varname = %SCAN(&varlist, &i);
			%END;
		RUN;

		PROC SGPANEL DATA=_long;
			PANELBY cluster / LAYOUT=columnlattice;
			DOT varname / RESPONSE=x STAT=mean;
			REFLINE 0 / AXIS=x;
			ROWAXIS DISPLAY=(nolabel);
		RUN;

	%END; /* DO numclus */
%MEND;

%LET varlist = hsd_prc phone_prc video_prc vod_enabled_flag;

%doclus( sample_customer_overall_info, &varlist, 8, 9 );

* Visualizing Clusters;

PROC CANDISC DATA = clusters OUT = SL.can NOPRINT;
	CLASS cluster;
	VAR &varlist;
RUN;

PROC SGPLOT DATA = clusters;
   SCATTER Y = VIDEO_PRC X = PHONE_PRC / GROUP = Cluster;
RUN;

PROC SORT DATA = clusters;
	BY cluster;

PROC MEANS DATA = clusters NWAY NOPRINT;
	VAR
		hsd_prc
		video_prc
		phone_prc;
	BY	cluster;
	OUTPUT OUT = summclus MEAN = ;
RUN; 

PROC TRANSPOSE DATA = summclus OUT = profdata( RENAME = ( COL1 = var_value ) ) NAME = var_name;
	VAR
		hsd_prc
		phone_prc
		video_prc;
	BY	cluster;
RUN; 

legend1 label=('Cluster:') across=7;
symbol1 v=none i=join l=1 c=red w=2;
symbol2 v=none i=join l=1 c=green w=2;
symbol3 v=none i=join l=1 c=blue w=2;
symbol4 v=none i=join l=1 c=orange w=2;
symbol5 v=none i=join l=1 c=cyan w=2;
symbol6 v=none i=join l=1 c=brown w=2;
symbol7 v=none i=join l=1 c=black w=2;
proc gplot data=profdata;
 plot var_value * var_name = cluster / frame autohref lautohref=2 cautohref=gray
 vaxis=axis1 haxis=axis2 legend=legend1;
run;
quit;

proc gchart data=profdata;
 star var_name / discrete type=sum sumvar=var_value noconnect coutline=black
 group=cluster across=3 down=2 slice=outside value=none noheading;
run;
quit; 
