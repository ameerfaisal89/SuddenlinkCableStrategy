LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

* Find correct max length of record;

DATA _NULL_;
	INFILE 'S:\2014 AY\Classes\MSIA 421\link\house_dim.txt'
		LRECL = 5000;
	INPUT;
RUN;

DATA SL.srv_bundle_mth_fact;
	LABEL
        MONTH_DIM_PK = "Primary Key to Month Dim"   
        HOUSE_DIM_PK = "Primary Key to House Dim"     
        CUSTOMER_DIM_PK = "Primary Key to Customer Dim"  
        SRV_BUNDLE_DIM_PK = "Primary Key to Bundle Dim, Desc all srv attr"
        ACCT_HIER_FA_DIM_PK = "Primary Key to Acct Hier Fa Dim"
        NODE_DIM_PK = "Primary Key to Node Dim"      
        VIDEO_PRC = "Monthly Recurring Charge for Video LOB"        
        HSD_PRC = "Monthly Recurring Charge for Data LOB"          
        PHONE_PRC = "Monthly Recurring Charge for Phone LOB"        
        OTHER_PRC = "Monthly Recurring Charge for Other" ;
	LENGTH
        MONTH_DIM_PK       8
        HOUSE_DIM_PK       8
        CUSTOMER_DIM_PK    8
        SRV_BUNDLE_DIM_PK   8
        ACCT_HIER_FA_DIM_PK   8
        NODE_DIM_PK        8
        VIDEO_PRC          6
        HSD_PRC            6
        PHONE_PRC          6
        OTHER_PRC          6 ;
    INFORMAT
        MONTH_DIM_PK     BEST3.
        HOUSE_DIM_PK     BEST7.
        CUSTOMER_DIM_PK  BEST7.
        SRV_BUNDLE_DIM_PK BEST8.
        ACCT_HIER_FA_DIM_PK BEST5.
        NODE_DIM_PK      BEST5.
        VIDEO_PRC        BEST6.
        HSD_PRC          BEST6.
        PHONE_PRC        BEST6.
        OTHER_PRC        BEST6. ;
    INFILE 'S:\2014 AY\Classes\MSIA 421\link\srv_bundle_mth_fact.txt'
        LRECL = 129
    	DLM = '|'
     	FIRSTOBS = 2
        MISSOVER
        DSD;
    INPUT
        MONTH_DIM_PK     
        HOUSE_DIM_PK     
        CUSTOMER_DIM_PK  
        SRV_BUNDLE_DIM_PK 
        ACCT_HIER_FA_DIM_PK 
        NODE_DIM_PK      
        VIDEO_PRC        
        HSD_PRC          
        PHONE_PRC        
        OTHER_PRC ;
RUN;

PROC SORT DATA = SL.srv_bundle_mth_fact;
	BY
		CUSTOMER_DIM_PK
		MONTH_DIM_PK
		/*HOUSE_DIM_PK*/ ;
		*One to one relationship between house and customer in this table;
RUN;

ODS RTF FILE = "Z:/output_srv_bundle_mth_fact.rtf";
PROC PRINT DATA = SL.srv_bundle_mth_fact (OBS = 100)
	DOUBLE
	LABEL;
RUN;

PROC CONTENTS DATA = SL.srv_bundle_mth_fact POSITION;
RUN;

PROC MEANS DATA = SL.srv_bundle_mth_fact;
	VAR VIDEO_PRC HSD_PRC PHONE_PRC OTHER_PRC;
RUN;

PROC FORMAT; /* create a format to group missing and nonmissing */
 VALUE $missfmt ' '='Missing' other='Not Missing';
 VALUE  missfmt  . ='Missing' other='Not Missing';
RUN;
 
PROC FREQ DATA = SL.srv_bundle_mth_fact; /*result shows if there is any missing value with in data*/
FORMAT _CHAR_ $missfmt.; /* apply format for the duration of this PROC */
TABLES _CHAR_ / missing missprint nocum nopercent;
FORMAT _NUMERIC_ missfmt.;
TABLES _NUMERIC_ / missing missprint nocum nopercent;
RUN;

ODS RTF CLOSE;
