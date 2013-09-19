"""
Code for parsing capital bikeshare data.
"""
import pandas
from pandas import isnull
from datetime import datetime, date, time, timedelta

def parseDate(dateStr):
    strFormat = '%Y-%m-%d'
    return datetime.strptime(dateStr, strFormat).date()

def fracHourToTime(frac):
    frac = float(frac)
    hour = int(frac)
    minutes = int((frac - hour)*60.0)
    return time(hour, minutes)

def readFirstEmpties():
    '''
    Read the first empties data file
    '''
    df = pandas.read_csv('first-empties.csv')
    numRows = df.shape[0]
    emptyTime = pandas.Series([None]*numRows)
    df['didEmpty'] = df.frac_hour != 'Inf'
    emptyTime[df.didEmpty] = [fracHourToTime(h) for h in df.frac_hour[df.didEmpty]]
    df['emptyTime'] = emptyTime
    return df

def setStationEmptyCounts(stations, empties):
    from collections import Counter
    C = Counter(empties.tfl_id[empties.didEmpty])
    stations['numEmpties'] = pandas.Series(C, dtype=float)
    stations['numEmptiesRatio'] = stations.numEmpties/stations.daysOpen

def readStations():
    '''
    Read the stations data file
    '''
    df = pandas.read_csv('cabi-stations.csv', index_col=0)

    # Add the date of open
    df.installDate = [date.fromtimestamp(t) for t in df.installDate/1000.0]

    # Add the date of removal
    df.removalDate = [None if isnull(rd) else date.fromtimestamp(rd) for rd in df.removalDate/1000.0]

    curDate = date.today()
    endDate = df.removalDate
    endDate[endDate.isnull()] = curDate
    df['daysOpen'] = [delta.days for delta in (endDate - df.installDate)]
    return df
