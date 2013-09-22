options(stringsAsFactors=FALSE)

library(ggplot2)
library(stringr)
library(lubridate)
library(plyr)
library(reshape2)
library(quantreg)
library(ggmap)
library(MASS)
library(Hmisc)

stations <- read.csv('cabi-stations.csv')
dat <- read.csv("first_empties.csv")

dat <- mutate(dat,
              date = ymd(date),
              weekday = wday(date) %in% 2:6,
              frac_hour_cens = ifelse(is.finite(frac_hour), frac_hour, 24),
              date_int = as.numeric(date))


# what we want is the smoothed (over time) median for weekdays

dat_weekday <- subset(dat, subset=weekday)

# for a specific dock, find the mean over time
mean_over_time <- function(dockdat) {
    dockdat <- dockdat[order(dockdat$date),]
    dockdat.lo <- loess(frac_hour_cens ~ date_int, dockdat)
    dockdat$smoothed <- predict(dockdat.lo, se=FALSE)
    dockdat
}

qq <- mean_over_time(subset(dat_weekday, tfl_id==33))
fit.qr <- rq(frac_hour_cens ~ poly(date_int, 9), tau=c(.1,.25,.5), data=qq)
qr.pred <- as.data.frame(predict(fit.qr))
names(qr.pred) <- c('pctl10', 'pctl25', 'pctl50')
qq <- cbind(qq, qr.pred)
ggplot(qq, aes(date, frac_hour_cens)) + 
    geom_point() + 
    geom_line(aes(y=pctl25), color='blue') +
    scale_y_continuous("First Empty Time", breaks=(2:12)*2+1) +
    ggtitle("Dock 33 (14th and Park)")

# TODO: for every dock, get last 3 months, find quantiles and trend, then
# map
summarize_dock <- function(dock) {
    d <- subset(dock, date >= as.POSIXct(today() - months(3)) & weekday)
    mod <- lm(frac_hour_cens ~ date_int, d)
    data.frame(id=d$tfl_id[[1]],
               quant=c(.1,.25,.5),
               empty_time=quantile(d$frac_hour_cens,c(.1,.25,.5)),
               trend=coef(mod)[[2]])
}

sum_dat <- ddply(dat, .(tfl_id), summarize_dock)

sum_dat <- join(sum_dat, stations)

mm <- get_map(location='Washington, DC', zoom=12, source='osm', color='bw')
ggmap(mm, extent='device', darken=c(.5, 'black')) +
    geom_point(data=subset(sum_dat, quant==.5),
               mapping=aes(long,lat,color=empty_time),
               size=4) +
    scale_color_gradientn("Typical Empty Time", colours=rainbow(6),
                          values=c(0,.1,.2,.3,.4,1),
                          breaks=c(5,7,9,12,18,24))
ggmap(mm, extent='device', darken=c(.5, 'black')) +
    geom_point(data=subset(sum_dat, quant==.1),
               mapping=aes(long,lat,color=empty_time),
               size=4) +
    scale_color_gradientn("Safe Commute Time", colours=rainbow(6),
                          values=c(0,.1,.2,.3,.4,1),
                          breaks=c(5,7,9,12,18,24))

sum_dat$trend_trans <- log(abs(sum_dat$trend))*sign(sum_dat$trend)
sum_dat$trend_cut <- cut2(sum_dat$trend,g=3)
ggmap(mm, extent='device', darken=c(.5, 'black')) +
    geom_point(data=subset(sum_dat, quant==.1),
               mapping=aes(long,lat,color=trend_cut),
               size=4) +
    scale_color_brewer("Getting Worse",palette=5, labels=c('Worst','Middle','Best'))






