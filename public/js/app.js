'use strict';

angular
	.module('AwsMonitoringApp', [])
	.factory('localApiService', ['$http', '$q', function(http, Q) {
		var toReturn = {};

		toReturn.getAllInstances = function() {
			var deferred = Q.defer();

			http.get('/api/instances.json').success(function(result) {
				deferred.resolve(result);
			}).error(function(error) {
				deferred.reject(error);
			});

			return deferred.promise;
		}

		toReturn.getInstanceMetric = function(instance_id, metric_name) {
			var deferred = Q.defer();

			http.get('/api/instance/'+instance_id+'/'+metric_name+'/12.json').success(function(result) {
				deferred.resolve(result);
			}).error(function(error) {
				deferred.reject(error);
			});

			return deferred.promise;
		}

		return toReturn;
	}]);

function AwsDashboardController(scope, localApiService, timeout) {
	scope.showOverview = true;
	scope.instances = [];
	scope.metric_list = [
			{
				'name': 'Average CPU Utilization',
				'endpoint': 'average_cpu',
				'operation': 'average'
			},
			{
				'name': 'Maximum CPU Utilization',
				'endpoint': 'maximum_cpu',
				'operation': 'maximum'
			},
			{
				'name': 'Network in',
				'endpoint': 'network_in',
				'operation': 'sum'
			},
			{
				'name': 'Network out',
				'endpoint': 'network_out',
				'operation': 'sum'
			},
		]

	scope.getMetricByEndpoint = function(instance, endpoint) {
		for (var i = instance.metrics.length - 1; i >= 0; i--) {
			if(instance.metrics[i].endpoint == endpoint)
				return instance.metrics[i];
		};

		console.error("No metric for endpoint " + endpoint);
	}

	scope.getInstanceById = function(id) {
		for (var i = scope.instances.length - 1; i >= 0; i--) {
			if(scope.instances[i].id == id)
				return scope.instances[i];
		};

		console.error("No instance for id " + id);
	}

	scope.buildSeriesFromMetric = function(metric) {
		var to_return = [];

		for (var i = metric.values.length - 1; i >= 0; i--) {
			var value = metric.values[i];
			if(metric.endpoint == 'network_out' || metric.endpoint == 'network_in')
				to_return.push([(value['time']*1000), (value[metric.operation]/1000)]);
			else
				to_return.push([(value['time']*1000), value[metric.operation]]);
		};

		return to_return;
	}

	scope.populateChart = function(instance_id, endpoint) {
		var instance = scope.getInstanceById(instance_id);
		var metric = scope.getMetricByEndpoint(instance, endpoint);

		timeout(function() {
			$('.'+instance_id+'.'+endpoint).highcharts({
				chart: {
					type: 'line'
				},
				title: {
					text: metric.name
				},
				xAxis: {
					type: 'datetime'
				},
				yAxis: {
					title: { enabled: false },
					min: 0,
					labels: {
						formatter: function() {
							var unit = '';
							switch(metric.values[0]['unit']) {
								case 'Percent':
									unit = '%';
									break;
								default:
									break;
							}

							if(metric.endpoint == 'network_out' || metric.endpoint == 'network_in')
								unit = 'K';

							return this.value + unit;
						}
					}
				},
				series: [{ name: 'data', data: scope.buildSeriesFromMetric(metric) }],
				plotOptions: { line: { marker: { enabled: false } } },
				legend: { enabled: false }
			});
		});
	}

	scope.fetchInstanceReports = function(instances) {
		angular.forEach(instances, function(instance) {
			instance.metrics = [];

			angular.forEach(scope.metric_list, function(metric, index) {
				localApiService.getInstanceMetric(instance.id, metric.endpoint).then(
					function(success_result) {
						var new_metric = {
							name: metric.name,
							operation: metric.operation,
							endpoint: metric.endpoint,
							values: success_result
						}

						instance.metrics[index] = new_metric;
					}, function(error_result) {
						console.error(error_result);
					});
			})
		});
	}

	localApiService.getAllInstances().then(
		function(success_result) {
			scope.instances = success_result;
			scope.fetchInstanceReports(scope.instances);
		},
		function(error_result) {
			console.error(error_result);
		}
	);


}

AwsDashboardController.$inject = ['$scope', 'localApiService', '$timeout'];
