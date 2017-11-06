require 'net/http'
require 'csv'
require 'time'

EQ_DATA_URL = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv'
LA_LAT = 34.0522
LA_LON = -118.2437


module UsgsDataService
  def earthquake_data
    CSV.new(ingest_data, :headers => true, :header_converters => :symbol)
       .map do |eq|
         eq.to_hash
         {
           time: Time.parse(eq[:time]),
           place: (/.*of (.*)/.match(eq[:place])
                              .captures
                              .first rescue eq[:place]),
           magnitude: eq[:mag].to_f,
           distance_from_la: distance_from_la(
             eq[:latitude].to_f,
             eq[:longitude].to_f
           )
         }
       end
  end

  def first_10_felt_by_los_angeles(start_date, end_date)
    earthquake_data.select do |eq|
      (start_date.to_time..(end_date + 1).to_time - 1).include? eq[:time]
    end
    .select{ |eq| eq[:distance_from_la] < eq[:magnitude] * 100 }
    .sort_by!{ |eq| eq[:time] }
    .take(10)
  end

  private

  def distance_from_la(lat, lon)
    d_lat = to_rads(LA_LAT - lat)
    d_lon = to_rads(LA_LON - lon)

    a = Math.sin(d_lat / 2) ** 2 + Math.cos(to_rads(LA_LAT)) *
        Math.cos(to_rads(lat)) * Math.sin(d_lon / 2) ** 2

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    d = 3959 * c
  end

  def to_rads(degrees)
     degrees * Math::PI / 180
  end

  def ingest_data
    uri = URI(EQ_DATA_URL)
    raw_data = Net::HTTP.get(uri)
  end
end
