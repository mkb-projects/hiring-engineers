require 'rubygems'
require 'dogapi'
require 'pry'

api_key = '5f3327ba307129d4814e7dd8b328b44d'
app_key = '59daf7a8a96081cae2d7e026bcf06dbb74cc9f89'

dog = Dogapi::Client.new(api_key, app_key)
# Create a timeboard.
title = 'Datadog Assignment Metrics'
description = 'My custom metric scoped over my host. Also includes a metric from database integration with the anomoly function applied.'
graphs = [{
    "definition" => {
        "events" => [],
        "requests" => [{
            "q" => "my_metric{host:precise64}",
            "q" => "anomalies(mongodb.connections.current{*}, 'basic', 2)"        
        }],
        "viz" => "timeseries"
    },
    "title" => "My metric and a metric from database with anomoly function"
}]
template_variables = [{
    "name" => "host1",
    "prefix" => "host",
    "default" => "host:my-host"
}]

newTimeboard = dog.create_dashboard(title, description, graphs, template_variables)
# binding.pry
