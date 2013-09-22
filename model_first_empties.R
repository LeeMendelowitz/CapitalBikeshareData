options(stringsAsFactors=FALSE)

library(ggplot2)
library(stringr)
library(lubridate)
library(plyr)
library(reshape2)
library(quantreg)

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
