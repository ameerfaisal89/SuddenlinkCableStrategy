LIBNAME SL "/sscc/home/a/amk202/SuddenLink";

PROC FORMAT CNTLOUT = SL.formats;
* srv_bundle_dim formats;
PROC FORMAT;
	INVALUE $SRV_RGU_BUNDLE_DESCRfmt
			'BASIC+DIGITAL+HSD+PHONE' = '1'
			'BASIC+DIGITAL+HSD' = '2'
			'BASIC+HSD' = '3'
			'BASIC+HSD+PHONE' = '4'
			'HSD+PHONE' = '5'
			'BASIC+DIGITAL' = '6'
			'HSD' = '7'
			'DIGITAL+HSD' = '8'
			'BASIC+DIGITAL+PHONE' = '9'
			'DIGITAL+HSD+PHONE' = '10'
			'DIGITAL' = '11'
			'NO RGU' = '12'
			'BASIC+PHONE' = '13'
			'PHONE' = '14'
			'BASIC' = '15'
			'DIGITAL+PHONE' = '16';
	INVALUE $SRV_LOB_BUNDLE_DESCRfmt
			'VIDEO+DATA+PHONE' = '1'
			'VIDEO+DATA' = '2'
			'VIDEO' = '3'
			'DATA+PHONE' = '4'
			'DATA' = '5'
			'VIDEO+PHONE' = '6'
			'NO RGU' = '7'
			'PHONE' = '8' ;
	VALUE $SRV_RGU_BUNDLE_DESCRfmt
			'1' = 'BASIC+DIGITAL+HSD+PHONE'
			'2' = 'BASIC+DIGITAL+HSD'
			'3' = 'BASIC+HSD'
			'4' = 'BASIC+HSD+PHONE'
			'5' = 'HSD+PHONE'
			'6' = 'BASIC+DIGITAL'
			'7' = 'HSD'
			'8' = 'DIGITAL+HSD'
			'9' = 'BASIC+DIGITAL+PHONE'
			'10' = 'DIGITAL+HSD+PHONE'
			'11' = 'DIGITAL' 
			'12' = 'NO RGU'
			'13' = 'BASIC+PHONE'
			'14' = 'PHONE'
			'15' = 'BASIC'
			'16' = 'DIGITAL+PHONE' ;
	VALUE $SRV_LOB_BUNDLE_DESCRfmt
			'1' = 'VIDEO+DATA+PHONE'
			'2' = 'VIDEO+DATA'
			'3' = 'VIDEO'
			'4' = 'DATA+PHONE'
			'5' = 'DATA'
			'6' = 'VIDEO+PHONE'
			'7' = 'NO RGU'
			'8' = 'PHONE' ;
* house dim formats;
	VALUE $MARITAL_STATUS_IND
			'M' = 'Married'
			'S' = 'Single'
			'A' = 'Inferred Married'
			'B' = 'Inferred Single' ;
	VALUE EDUCATION 
			1 = 'High School'
			2 = 'College'
			3 = 'Grad School'
			4 = 'Attended Vocational/Techincal'
			. = 'Other' ;
	VALUE $OWNER_RENTER_IND
			'O' = 'home owner' 
			'R' = 'Renter' ;
	VALUE INCOME_HH
			1 = '<15K'
			2 = '15-20K'
			3 = '20-30K'
			4 = '30-40K'
			5 = '40-50K'
			6 = '50-75K'
			7 = '75-100K'
			8 = '100-125K'
			9 = '>125K'
			. = 'Unknown' ;
	VALUE $HOME_MARKET_VALUE 
			'A' = '1-25K' 
			'B' = '25-50K'
			'C' = '50-75K'
			'D' = '75-100K' 
			'E' = '100-125K' 
			'F' = '125-150K'
			'G' = '150-175K' 
			'L' = '275-300K' 
			'M' = '300-350K'
			'N' = '350-400K'
			'O' = '400-450K'
			'P' = '450-500K'
			'Q' = '500-750K'
			'R' = '750-1M'
			'S' = '>1M' ;
	VALUE $VEHICLE_DOM_LIFESTYLE_IND
			'A' = 'Luxury/Upper sporty' 
			'B' = 'Truck'
			'C' = 'SUV'
			'D' = 'Mini-van'
			'E' = 'Midsize/Small'
			'F' = 'Midsize/Large'
			'G' = 'Basic sporty' ;
	VALUE $GENDER_IND
			'M' = 'Male'
			'F' = 'Female'
			'' = 'Unknown' ;
RUN;
