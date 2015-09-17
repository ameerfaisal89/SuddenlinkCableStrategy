LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

PROC SQL;
	create table SL.hsd_usage_info as (
		select H.month_dim_pk, H.customer_dim_pk, H.house_dim_pk, H.srv_dim_pk, H.usage_amt, S.consumption_limit
		from SL.hsd_usage as H, SL.srv as S
		where H.srv_dim_pk = S.srv_dim_pk
	);
QUIT;

DATA SL.hsd_usage_info;
	SET SL.hsd_usage_info;
	LABEL
		overage = "Overage"
		utilization = "Utilization";

	month_dim_pk = month_dim_pk - 166;

	overage = usage_amt - consumption_limit;
	overage = max( overage, 0 );
	utilization = usage_amt / consumption_limit;
RUN;

/*PROC SORT DATA = SL.hsd_usage_info;
	BY month_dim_pk;
RUN;

DATA WORK.hsd_usage_info;
	SET SL.hsd_usage_info;
	IF overage = 0 THEN DELETE;
RUN;*/

PROC MEANS DATA = SL.hsd_usage_info NOPRINT NWAY;
	CLASS customer_dim_pk;
	VAR utilization;
	OUTPUT OUT = WORK.hsd_means MEAN = util_mean;
RUN;

PROC UNIVARIATE DATA = WORK.hsd_means;
	VAR util_mean;
	HISTOGRAM util_mean;
RUN;

PROC UNIVARIATE DATA = WORK.hsd_means;
	VAR util_mean;
RUN;

PROC MEANS DATA = WORK.hsd_means;
	VAR util_mean;
RUN;

PROC REG DATA = SL.hsd_usage_info NOPRINT OUTEST = WORK.hsd_reg (DROP = _MODEL_ _TYPE_ );
	BY customer_dim_pk;
	MODEL usage_amt = month_dim_pk;
RUN;

PROC UNIVARIATE DATA = WORK.hsd_reg;
	VAR month_dim_pk;
RUN;

DATA sample_customer_overall_info_3;
	SET SL.srv_bundle_mth_fact;
	BY customer_dim_pk;

	IF LAST.customer_dim_pk;
RUN;

PROC SQL;
	create table sample_customer_overall_info_3 as (
		select sample.*, reg.month_dim_pk as Slope
		from sample_customer_overall_info_3 as sample, hsd_reg as reg
		where sample.customer_dim_pk = reg.customer_dim_pk
	);
QUIT;

PROC SQL;
	create table sample_customer_overall_info_3 as (
		select sample.*, means.util_mean as Avg_Utilization
		from sample_customer_overall_info_3 as sample, hsd_means as means
		where sample.customer_dim_pk = means.customer_dim_pk
	);
QUIT;

PROC SQL;
	create table sample_customer_overall_info_3 as (
		select *
		from sample_customer_overall_info_3 natural join SL.srv_bundle_dim
	);
QUIT;

PROC SQL;
	create table sample_customer_overall_info_3 as (
		select *
		from sample_customer_overall_info_3 natural join SL.house_dim
	);
QUIT;

PROC SURVEYSELECT DATA = sample_customer_overall_info_3
	METHOD = srs
	N = 100000
	OUT = sample_customer_overall_info_3
	SEED = 12345;
	WHERE -58.50 < slope < 58;
RUN;

PROC EXPORT DATA = sample_customer_overall_info_3
	OUTFILE = 'Z:\sample.csv'
	DBMS = CSV
	REPLACE;
RUN;
