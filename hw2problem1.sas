LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

/*DATA srv_bundle_mth_fact;
	SET SL.srv_bundle_mth_fact;
	BY customer_dim_pk;

	IF LAST.customer_dim_pk;
RUN;

PROC SURVEYSELECT DATA = SL.srv_bundle_mth_fact
	METHOD = srs
	N = 100000
	OUT = SL.sample_srv_bundle_mth_fact
	SEED = 12345;
RUN;*/

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

%LET varlist = hsd_prc phone_prc video_prc;

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

%doclus( SL.sample_srv_bundle_mth_fact, &varlist, 3, 9 );

/*PROC FASTCLUS DATA = SL.sample_srv_bundle_mth_fact MAXCLUSTERS = 7 MAXITER = 100 OUT = SL.clusters;
	VAR
		hsd_prc
		video_prc
		phone_prc;
RUN;*/

* Visualizing Clusters;

PROC CANDISC DATA = SL.clusters OUT = SL.can NOPRINT;
	CLASS cluster;
	VAR &varlist;
RUN;

PROC SGPLOT DATA = SL.clusters;
   SCATTER Y = VIDEO_PRC X = PHONE_PRC / GROUP = Cluster;
RUN;

PROC SORT DATA = SL.clusters;
	BY cluster;

PROC MEANS DATA = SL.clusters NWAY NOPRINT;
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
