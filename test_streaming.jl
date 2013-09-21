#!/usr/bin/env julia

using DataFrames

ds = DataFrames.IODataStream(STDIN, ",",
               '"', [],
               false, ["tfl_id", "bikes", "spaces", "timestamp"], 1)

i = 0

for df in ds
	print(df)
	i = i+1
	if i == 5
		break
	end
end
