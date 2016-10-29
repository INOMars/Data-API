# encoding: Windows-1252
require 'bundler/setup'
require "json"

Bundler.require

require 'sinatra/sequel'

Sequel.connect('postgres://127.0.0.1/samsheff')

class Company < Sequel::Model
  def to_json
    {
      name: name,
      short_name: short_name,
      inn: inn,
      type: type
    }.to_json
  end
end

class Region < Sequel::Model
  def to_json
    {
      name: name,
      type: type,
      oblast_code: oblast_code
    }.to_json
  end
end

class Street < Sequel::Model
end

class Activity < Sequel::Model
  def to_json
    {
      id: id,
      code: code,
      name: name
    }.to_json
  end
end

configure do
  set :database, 'postgres://127.0.0.1/samsheff'
end

before do
  content_type 'application/json; charset=utf-8'
  use_cross_origin
end

get "/" do
  { here: "Yes." }.to_json
end

get "/region/:oblast_id/markets/:query" do
  ids_array = database["SELECT id from activities WHERE name LIKE '#{params[:query]}%'"].to_a
  ids = []
  ids_array.each { |id| ids << id[:id] }
  database["SELECT COUNT(*) as companies_count, SUM(oblast_id) as oblast_sum FROM companies WHERE activities @> '{#{ids.join(',')}}'::int[] #{"AND oblast_id = #{params[:oblast_id]}" if params[:oblast_id].to_i != 0}"].to_a.to_json
end

get "/companies/:company_id" do
  Company[params[:company_id]].to_json
end

get "/markets/:market_id/companies" do
  database["SELECT * from companies WHERE activities @> '{#{params[:market_id]}}'::int[]"].to_a.to_json
end

get "/regions" do
  database[:oblasts].to_a.to_json
end

# JSONP Cross Origin Setup
def use_cross_origin
  cross_origin :allow_origin => '*',
    :allow_methods => [:get],
    :expose_headers => ['Content-Type', ]
end
