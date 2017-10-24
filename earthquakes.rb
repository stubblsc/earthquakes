#!/usr/bin/env ruby
require './usgs_data_service'

include UsgsDataService

start_date = Date.parse(ARGV[0]) || Date.today-30
end_date = Date.parse(ARGV[1]) || Date.today

puts UsgsDataService.first_10_felt_by_los_angeles(start_date, end_date)
