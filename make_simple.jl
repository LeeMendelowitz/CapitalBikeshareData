#!/usr/bin/env julia

# process the enormous file
# result should be a DF/file with, foreach station and date, the time at which it became empty, or NA

using DataFrames
using Calendar

# main data structure:
# array of hashes, with the array the station ID, and the hash keyed by the date, pointing to 
# a fractional hour (hour + minute/60)

function get_first_empties(fh)
	curdate = ymd(1990,1,1) # update when we switch to the next day
	res = Dict{String, Dict{CalendarTime, Float64}}()
	for line in eachline(fh)
		tfl_id, bikes, spaces, ts = split(line, ",")
		ts = timezone(Calendar.parse("yyyy-MM-dd HH:mm:ss", ts, "GMT"), "EST")
		if day(ts) != day(curdate)
			# add NA to docks that were never empty
			for dock in keys(res)
				if !haskey(res[dock], curdate)
					res[dock][curdate] = Inf
				end
			end
			println(STDERR, curdate)
			curdate = ts
		end
		#println(STDERR, bikes)
		if bikes == "0" && hour(ts) >= 5
			#print(STDERR, "0 ")
			if !haskey(res, tfl_id) 
				res[tfl_id] = Dict{CalendarTime, Float64}()	
				#print(STDERR, "$tfl_id ")
			end
			if !haskey(res[tfl_id], curdate)
				res[tfl_id][curdate] = hour(ts) + minute(ts)/60
				#println(STDERR, "$(res[tfl_id][curdate]) ")
			end
			#print(STDERR, "\n")
		end
	end
	res
end

ret = get_first_empties(STDIN)

# output results
println("tfl_id,date,frac_hour")
for tfl_id in keys(ret)
	for date in keys(ret[tfl_id])
		datestr = format("yyyy-MM-dd", date)
		println("$tfl_id,$datestr,$(ret[tfl_id][date])")
	end
end




