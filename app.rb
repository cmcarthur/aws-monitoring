require 'sinatra'
require 'json'

require './aws/AWSDataGrabber.rb'

aws = AWSDataGrabber.new(YAML.load_file('./config.yml'))


get '/api/instances.json' do
	JSON.generate(aws.get_instance_metadata)
end

get '/api/balancers.json' do
	JSON.generate(aws.get_elb_metadata)
end

get '/api/instance/:id/average_cpu/:hours.json' do |id, hours|
	content_type :json
	aws.get_avg_cpu(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/instance/:id/maximum_cpu/:hours.json' do |id, hours|
	content_type :json
	aws.get_max_cpu(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/instance/:id/network/in/:hours.json' do |id, hours|
	content_type :json
	aws.get_network_in_cpu(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/instance/:id/network/out/:hours.json' do |id, hours|
	content_type :json
	aws.get_network_out_cpu(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/balancer/:id/healthy.json' do |id|
	content_type :json
	aws.get_healthy_host_count(id).to_a.to_json
end

get '/api/balancer/:id/unhealthy.json' do |id|
	content_type :json
	aws.get_unhealthy_host_count(id).to_a.to_json
end

get '/api/balancer/:id/requests/good/:hours.json' do |id|
	content_type :json
	aws.get_successful_requests(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/balancer/:id/requests/bad/:hours.json' do |id|
	content_type :json
	aws.get_bad_requests(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/balancer/:id/requests/error/:hours.json' do |id|
	content_type :json
	aws.get_error_requests(id, hours.to_i * 60 * 60).to_a.to_json
end

get '/api/balancer/:id/requests/total/:hours.json' do |id|
	content_type :json
	aws.get_total_requests(id, hours.to_i * 60 * 60).to_a.to_json
end


get '/' do
	File.read(File.join('public', 'index.html'))
end

get '/:file' do |file|
	File.read(File.join('public', file))
end