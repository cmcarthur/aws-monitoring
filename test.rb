require 'yaml'
require './aws/AWSDataGrabber'

config = YAML.load_file('config.yml')
dataGrabber = AWSDataGrabber.new(config)

dataGrabber.get_instance_metadata.each do |instance|
	dataGrabber.get_instance_metrics(instance[:id])
end