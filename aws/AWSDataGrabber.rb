require 'aws-sdk'

class AWSDataGrabber
	def initialize(config)
		@config = {
			:access_key_id => config["access_key_id"],
			:secret_access_key => config["secret_access_key"]
		}
	end

	def get_instance_metadata
		ec2 = AWS::EC2.new(@config)

		AWS.memoize do
			metadata = Array.new

			ec2.instances.each do |instance|
				instance_meta = Hash.new
				instance_meta[:id] = instance.id
				instance_meta[:launch_time] = instance.launch_time
				instance_meta[:status] = instance.status

				instance.tags.each_pair do |tag_name, tag_value|
					if tag_name == "scalr-role-name"
						instance_meta[:role] = tag_value
					elsif tag_name == "scalr-farm-name"
						instance_meta[:farm] = tag_value
					elsif tag_name == "Name"
						instance_meta[:number] = tag_value.split.last
					end
				end

				metadata.push(instance_meta)
			end

			return metadata
		end
	end

	def get_elb_metadata
		elb = AWS::ELB.new(@config)

		AWS.memoize do
			metadata = Array.new

			elb.load_balancers.each do |lb|
				lb_meta = Hash.new

				lb_meta[:name] = lb.name

				metadata.push(lb_meta)
			end

			return metadata
		end
	end

	def get_avg_cpu(instance_id, history_in_seconds)
		return get_instance_metrics(instance_id, history_in_seconds, 'CPUUtilization', 'Average')
	end

	def get_max_cpu(instance_id, history_in_seconds)
		return get_instance_metrics(instance_id, history_in_seconds, 'CPUUtilization', 'Maximum')
	end

	def get_network_in(instance_id, history_in_seconds)
		return get_instance_metrics(instance_id, history_in_seconds, 'NetworkIn', 'Sum')
	end

	def get_network_out(instance_id, history_in_seconds)
		return get_instance_metrics(instance_id, history_in_seconds, 'NetworkOut', 'Sum')
	end

	def get_healthy_host_count(elb_name)
		return get_elb_metrics(elb_name, 20, 'HealthyHostCount', 'Maximum')
	end

	def get_unhealthy_host_count(elb_name)
		return get_elb_metrics(elb_name, 20, 'UnHealthyHostCount', 'Maximum')
	end

	def get_successful_requests(elb_name, history_in_seconds)
		return get_elb_metrics(elb_name, history_in_seconds, 'HTTPCode_Backend_2XX', 'Sum')
	end

	def get_bad_requests(elb_name, history_in_seconds)
		return get_elb_metrics(elb_name, history_in_seconds, 'HTTPCode_Backend_4XX', 'Sum')
	end

	def get_error_requests(elb_name, history_in_seconds)
		return get_elb_metrics(elb_name, history_in_seconds, 'HTTPCode_Backend_5XX', 'Sum')
	end

	def get_total_requests(elb_name, history_in_seconds)
		return get_elb_metrics(elb_name, history_in_seconds, 'RequestCount', 'Sum')
	end

	def get_instance_metrics(instance_id, history_in_seconds, metric_name, statistic_name)
		cw = AWS::CloudWatch.new(@config)

		return cw.client.get_metric_statistics(
			namespace: 'AWS/EC2',
			metric_name: metric_name,
			statistics: [ statistic_name ],
			start_time: (Time.new.gmtime - history_in_seconds).iso8601,
			end_time: (Time.new.gmtime.iso8601),
			period: 60,
			dimensions: [
				{ :name => "InstanceId", :value => instance_id }
			]
		).datapoints
	end

	def get_elb_metrics(elb_name, history_in_seconds, metric_name, statistic_name)
		cw = AWS::CloudWatch.new(@config)

		return cw.client.get_metric_statistics(
			namespace: 'AWS/ELB',
			metric_name: metric_name,
			statistics: [ statistic_name ],
			start_time: (Time.new.gmtime - history_in_seconds).iso8601,
			end_time: (Time.new.gmtime.iso8601),
			period: 60,
			dimensions: [
				{ :name => "LoadBalancerName", :value => elb_name }
			]
		)
	end
end