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

	def get_instance_metrics(instance_id)
		cw = AWS::Cloudwatch::Base.new(@config)

		puts cw.get_metric_statistics(
			namespace: 'AWS/EC2',
			measure_name: 'CPUUtilization',
			statistics: 'Average',
			start_time: (Time.new.gmtime - 1000),
			dimensions: "InstanceId=#{instance_id}"
		)
	end
end