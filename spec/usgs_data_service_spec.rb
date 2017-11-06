require 'spec_helper'

describe UsgsDataService do
  describe "#earthquake_data" do
    it 'returns an array of hashes' do
      VCR.use_cassette("earthquake_data") do
        data = UsgsDataService.earthquake_data
        expect(data.is_a? Array).to be true
        expect(data.map{|el| el.is_a? Hash}.uniq.first).to be true
      end
    end

    it "only returns the correct attributes" do
      required_attrs = [:time, :place, :magnitude, :distance_from_la]
      VCR.use_cassette("earthquake_data") do
        data = UsgsDataService.earthquake_data
        expect(data.first.keys).to eq required_attrs
      end
    end
  end

  describe "#first_10_felt_by_los_angeles" do
    it 'returns data on 10 earthquakes' do
      start_date = Date.today - 30
      end_date = Date.today
      VCR.use_cassette("earthquake_data") do
        data = UsgsDataService.first_10_felt_by_los_angeles(
          start_date, end_date
        )
        expect(data.count).to eq(10)
      end
    end

    it 'should be sorted by time' do
      start_date = Date.today - 30
      end_date = Date.today
      VCR.use_cassette("earthquake_data") do
        data = UsgsDataService.first_10_felt_by_los_angeles(
          start_date, end_date
        )
        expect(data.sort_by!{ |eq| eq[:time] }).to eq(data)
      end
    end

    it 'should only include earthquakes felt by LA' do
      start_date = Date.today - 30
      end_date = Date.today
      VCR.use_cassette("earthquake_data") do
        data = UsgsDataService.first_10_felt_by_los_angeles(
          start_date, end_date
        )
        expect(
          data.select{ |eq| eq[:distance_from_la] < eq[:magnitude] * 100 }
        ).to eq(data)
      end
    end

    it 'should only include earthquakes within given timeframe' do
      start_date = Date.today - 30
      end_date = Date.today
      VCR.use_cassette("earthquake_data") do
        data = UsgsDataService.first_10_felt_by_los_angeles(
          start_date, end_date
        )
        expect(
          data.select do |eq|
            (start_date.to_time..(end_date + 1).to_time - 1).include? eq[:time]
          end
        ).to eq(data)
      end
    end
  end

  describe "#distance_from_la" do
    it "calculates the distance between the provided lat/lon pairs" do
      new_york_city = [40.71427, -74.00597]
      santiago_chile = [-33.42628, -70.56656]

      new_york_dist = UsgsDataService.send(:distance_from_la, new_york_city[0],
                                           new_york_city[1])
      santiago_dist = UsgsDataService.send(:distance_from_la, santiago_chile[0],
                                           santiago_chile[1])

      expect(round_to(4, new_york_dist)).to eq(2445.7052)
      expect(round_to(4, santiago_dist)).to eq(5594.1268)
    end
  end

  describe "#to_rads" do
    it "calculates radian conversion for given degrees" do
      expect(UsgsDataService.send(:to_rads, 180)).to eq(Math::PI)
      expect(UsgsDataService.send(:to_rads, 360)).to eq(2 * Math::PI)
    end
  end

  describe "#ingest_data" do
    it "correctly ingests data from the USGS" do
      VCR.use_cassette("earthquake_data") do
          response = Net::HTTP.get_response(URI('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv'))
          method_response = UsgsDataService.send(:ingest_data)
          expect(method_response).to eq response.body
        end
      end
  end

  def round_to(precision, num)
    (num * 10**precision).round.to_f / 10**precision
  end
end
