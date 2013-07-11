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

function AwsDashboardController(scope, localApiService) {
	scope.showOverview = true;
	scope.instances = [];

	scope.fetchInstanceReports = function(instances) {
		var metric_list = [
			{
				'name': 'Average CPU Utilization',
				'endpoint': 'average_cpu',
				'operation': 'average'
			}
		]

		angular.forEach(instances, function(instance) {
			instance.metrics = [];
			instance.metrics.values = [];

			angular.forEach(metric_list, function(metric) {
				localApiService.getInstanceMetric(instance.id, metric.endpoint).then(
					function(success_result) {
						var new_metric = {
							name: metric.name,
							operation: metric.operation,
							endpoint: metric.endpoint,
							values: success_result
						}

						instance.metrics.push(new_metric);
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

AwsDashboardController.$inject = ['$scope', 'localApiService'];
