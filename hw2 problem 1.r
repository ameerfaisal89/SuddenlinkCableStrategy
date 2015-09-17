library( ggplot2 );

summary.kmeans = function(fit)
{
  p = ncol(fit$centers)
  k = nrow(fit$centers)
  n = sum(fit$size)
  sse = sum(fit$withinss)
  xbar = t(fit$centers)%*%fit$size/n
  ssb = sum(fit$size*(fit$centers - rep(1,k) %*% t(xbar))^2)
  print(data.frame(
    n=c(fit$size, n),
    Pct=(round(c(fit$size, n)/n,2)),
    round(rbind(fit$centers, t(xbar)), 2),
    RMSE = round(sqrt(c(fit$withinss/(p*fit$size-1), sse/(p*(n-k)))), 4)
  ))
  cat("SSE = ", sse, "; SSB = ", ssb, "\n")
  cat("R-Squared = ", ssb/(ssb+sse), "\n")
  cat("Pseudo F = ", (ssb/(k-1))/(sse/(n-k)), "\n\n");
  invisible(list(sse=sse, ssb=ssb, Rsqr=ssb/(ssb+sse), F=(ssb/(k-1))/(sse/(n-k))))
}

plot.kmeans = function(fit,boxplot=F)
{
  require(lattice)
  p = ncol(fit$centers)
  k = nrow(fit$centers)
  plotdat = data.frame(
    mu=as.vector(fit$centers),
    clus=factor(rep(1:k, p)),
    var=factor( 0:(p*k-1) %/% k, labels=colnames(fit$centers))
  )
  print(dotplot(var~mu|clus, data=plotdat,
                panel=function(...){
                  panel.dotplot(...)
                  panel.abline(v=0, lwd=.1)
                },
                layout=c(k,1),
                xlab="Cluster Mean"
  ))
  invisible(plotdat)
}

setwd( "S:/421 Group 5/" );
data = data.frame( read.csv( "Data/sample_customer_info.csv", header = T ) );

k = 5:10;

clusters = list( );
summaryCluster = list( );

clusterInfo = data.frame( k = integer( ), SSE = numeric( ), SSB = numeric( ),
                          Rsqr = numeric( ), Fstat = numeric( ) );

variables = c( "HSD_PRC", "PHONE_PRC", "VIDEO_PRC" );
scaled_data = scale( data[ , variables ] );

for ( i in 1:length( k ) ) {
  set.seed( 1 );
#  clusters[[ i ]] = kmeans( data[ , variables ], k[ i ], nstart = 10 );
  clusters[[ i ]] = kmeans( scaled_data[ , variables ], k[ i ], nstart = 20 );
  print( k[ i ] );
}

for ( i in 1:length( k ) ) {
  summaryCluster[[ i ]] = summary( clusters[[ i ]] );

  clusterInfo[ i, "k" ] = k[ i ];
  clusterInfo[ i, "SSE" ] = summaryCluster[[ i ]][[ "sse" ]];
  clusterInfo[ i, "SSB" ] = summaryCluster[[ i ]][[ "ssb" ]];
  clusterInfo[ i, "Rsqr" ] = summaryCluster[[ i ]][[ "Rsqr" ]];
  clusterInfo[ i, "Fstat" ] = summaryCluster[[ i ]][[ "F" ]];
}

summary( clusters[[ 1 ]] );
plot( clusters[[ 1 ]] );

ggplot( data = clusterInfo, aes( x = k, y = Fstat ) ) + geom_line( ) + geom_point( );
ggplot( data = clusterInfo, aes( x = k, y = SSB ) ) + geom_line( ) + geom_point( );
ggplot( data = clusterInfo, aes( x = k, y = SSE ) ) + geom_line( ) + geom_point( );
ggplot( data = clusterInfo, aes( x = k, y = Rsqr ) ) + geom_line( ) + geom_point( );

index = 7 - k[ 1 ] + 1;

clust_data = cbind( data, Cluster = clusters[[ index ]]$cluster );

cbind( Count = sapply( 1:max( clusters[[ index ]]$cluster ), function( g ) sum( clusters[[ index ]]$cluster == g ) ), 
       aggregate( cbind( HSD_PRC, PHONE_PRC, VIDEO_PRC, AGE_2YR_INC, NUM_CHILDREN,
                         NUM_ADULT_HH, HH_SIZE, LENGTH_RES ) ~ Cluster,
                  data = clust_data, FUN = mean ) );

cbind( Count = sapply( 1:max( clusters[[ index ]]$cluster ), function( g ) sum( clusters[[ index ]]$cluster == g ) ), 
       aggregate( cbind( HSD_PRC, PHONE_PRC, VIDEO_PRC, BASIC_FLAG, DIGITAL_FLAG, EXPANDED_BASIC_FLAG, PREMIUM_FLAG,
                         HDTV_FLAG, DVR_FLAG, HSD_DOWN_SPEED, LOB_COUNT, SEASNAL_FLAG, TIVO_FLAG, WIFI_FLAG,
                         VOD_ENABLED_FLAG ) ~ Cluster,
                  data = clust_data, FUN = mean ) );

prop.table( table( clust_data[ , "Cluster" ], clust_data[ , "SERVICE_STATE" ] ), 2 );
