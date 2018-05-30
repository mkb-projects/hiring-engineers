## Prerequisites - Setup the environment

* You can spin up a fresh linux VM via Vagrant or other tools so that you don’t run into any OS or dependency issues.

**Answer**: I set up a virual machine using Vagrant and Virtual Box per the instructions on this page: [https://www.vagrantup.com/intro/getting-started/](https://www.vagrantup.com/intro/getting-started/). I then SSH into this machine using `vagrant ssh`. I installed the Datadog agent using the Ubuntu instructions found here: [https://docs.datadoghq.com/agent/](https://docs.datadoghq.com/agent/). I also had another instance of the agent running on my local machine (OS X) for comparison purposes. I started the Agent and confirmed its status by running `sudo service datadog-agent status`.

## Collecting Metrics:
* Add tags in the Agent config file and show us a screenshot of your host and its tags on the Host Map page in Datadog.

**Answer**: I edited the datadog.yaml file using VIM in the virtual machine to include the following tags:

```
tags: region:east, region:nw, application:database, database:primary, role:sobotka
```

Here is the Host Map page displaying the tags:
![Agent tags](/supporting-files/agent_config_tags.png?raw=true)

* Install a database on your machine (MongoDB, MySQL, or PostgreSQL) and then install the respective Datadog integration for that database.

**Answer**: I installed MongoDB on my VM using these instruction for Ubuntu: [https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/).

Per the [Datadog MongoDB integration docs](https://docs.datadoghq.com/integrations/mongo/), I entered the mongo shell and created a read-only user for the Datadog Agent in the admin database:

```
use admin

db.createUser({
  "user":"datadog",
  "pwd": "mypass",
  "roles" : [
    {role: 'read', db: 'admin' },
    {role: 'clusterMonitor', db: 'admin'},
    {role: 'read', db: 'local' }
  ]
})

```

I received this response:

```
Successfully added user: {
	"user" : "datadog",
	"roles" : [
		{
			"role" : "read",
			"db" : "admin"
		},
		{
			"role" : "clusterMonitor",
			"db" : "admin"
		},
		{
			"role" : "read",
			"db" : "local"
		}
	]
}
```

And edited the `mongodb.d/conf.yaml` to start gathering MongoDB metrics:

```
init_config:
	instances:
 	 - server: mongodb://datadog:mypass@localhost:27017/admin
    additional_metrics:
      - collection   
      - metrics.commands
      - tcmalloc
      - top
    tags:
      - region: east
```

I restarted the Agent and ran the `sudo service datadog-agent status` command to validate the installation. `mongo` appeared in the Checks section.
![Database integration check](/supporting-files/mongo-checks.png?raw=true)

* Create a custom Agent check that submits a metric named my_metric with a random value between 0 and 1000.

**Answer**: Per the instructions on [Writing an Agent Check](https://docs.datadoghq.com/developers/agent_checks/), I created a `metric_check.py` file (see attached file) that submits a metric with a random value between 0 and 1000. I also wrote its corresponding configuration file `metric_check.yaml`.

I validated that the metric is working by looking at the Metrics summary in the UI and by running `sudo service datadog-agent status`, where metric_check appeared under Checks.

![my_metric check](/supporting-files/my_metric-2.png?raw=true)

* Change your check's collection interval so that it only submits the metric once every 45 seconds.

**Answer**: Per the [Writing an Agent Check](https://docs.datadoghq.com/developers/agent_checks/) page, I added the collection interval to the instance in the configuration file and set it to 45.

`min_collection_interval: 45`

* Bonus Question Can you change the collection interval without modifying the Python check file you created?

**Answer**: Per the current docs, it was suggested to add a parameter to the instance in the .yaml file, which seemed more straightforward than modifying the Python check file.

## Visualizing Data:
Utilize the Datadog API to create a Timeboard that contains:

* Your custom metric scoped over your host.
* Any metric from the Integration on your Database with the anomaly function applied.

**Answer**: I used the [Datadog API](https://docs.datadoghq.com/api/?lang=python#create-a-timeboard) to create a Timeboard that was scoped to my host and inserted some [sample data](https://docs.mongodb.com/manual/reference/bios-example-collection/) into my database. I used the `mongodb.connections.current` metric, which measures the number of connections to the database server from clients. I found [this post](https://www.datadoghq.com/blog/monitor-mongodb-performance-with-datadog/) helpful in providing an overview of MongoDB performance monitoring (and in deciding which metric to use).

See the attached create_timeboard.rb file.

![timeboard](/supporting-files/timeboard.png?raw=true)

* Set the Timeboard's timeframe to the past 5 minutes
* Take a snapshot of this graph and use the @ notation to send it to yourself.

![timeboard](/supporting-files/timeboard-snapshot-2.png?raw=true)

* Bonus Question: What is the Anomaly graph displaying?

**Answer**: Anomoly detection (also called outlier detection) identifies items, events, or observations that do not conform to the expected pattern and are therefore outliers in the dataset. The anomoly graph helps us identify when a metric is behaving differently than it has in the past. In this case, the graph distinguishes outlying behavior in the number of connections to the database server from clients. This could help us troubleshoot networking or connectivity issues, as well as database performance issues.

## Final Question:

* The Datadog community has written a substantial number of high quality integrations and libraries. Select one from this page. With this selection in mind, write a blog post that announces your selection and explains the benefits it offers our users/community. The post should cover installation, configuration, usage, and best practices along with code samples where applicable. You should also thank the contributor for their effort.

**Answer:**
### Introducing dogstatsd-ruby, A Ruby Client for DogStatsD

Datadog is excited to announce the addition of dogstatsd-ruby, a client for DogStatsD and an extension of the StatsD metric server for Datadog. dogstatsd-ruby is a simple library that easily allows you to submit custom metrics from your Ruby apps into Datadog.

StatsD is a network daemon developed and released by Etsy in 2011. It runs on the Node.js platform and listens for statistics (gauges, counters, timing summary statistics, and sets, among others) over protocols such as TCP and UDP. The daemon then aggregates those metrics and sends them to a backend service (Datadog). For an in-depth explanation of StatsD and how it can enhance your devops toolchain, see this [blog post](https://www.datadoghq.com/blog/statsd/).

[DogStatsD](https://docs.datadoghq.com/developers/dogstatsd/) is our own StatsD daemon within the Datadog Agent, and the easiest way to get your custom metrics into Datadog. The daemon has Datadog-specific extensions, including histogram metric type, service checks, and events tagging. dogstatsd-ruby is an extension of the general StatsD client to work with that server.

dogstatsd-ruby is forked from Rien Henrichs’s [original Statsd client](https://github.com/reinh/statsd). Mr. Heinrich describes the client as: “A Ruby Statsd client that isn't a direct port of the Python example code. Because Ruby isn't Python.” We recognize the importance of supporting a StatsD integration for language-specific libraries.

dogstatsd-ruby allows seamless communication between your Ruby app and StatsD. To get started, follow the steps below.

#### Installation
Ensure that you have the Datadog agent [installed and running](https://docs.datadoghq.com/agent/).

Install the library:

`gem install dogstatsd-ruby`

#### Configuration

Load the dogstats module:

`require 'datadog/statsd'`

Create a stats instance:

`statsd = Datadog::Statsd.new('localhost', 8125)`

You can also create a statsd class if you need a drop in replacement:

```
class Statsd < Datadog::Statsd
end
```

#### Usage

Here are some of the things that you can do with dogstatsd-ruby:

Increment a counter.

`statsd.increment('page.views')`

Record a gauge 50% of the time.

`statsd.gauge('users.online', 123, :sample_rate=>0.5)`

Sample a histogram.

`statsd.histogram('file.upload.size', 1234)`

Time a block of code.

```
statsd.time('page.render') do
  render_page('home.html')
end
```

Send several metrics at the same time (all metrics will be buffered and sent in one packet when the block completes).

```
statsd.batch do |s|
  s.increment('page.views')
  s.gauge('users.online', 123)
end
```

Tag a metric.

`statsd.histogram('query.time', 10, :tags => ["version:1"])`

#### Best practices

A few tips when using dogstatsd-ruby:

**Use Tags**

Tags are a way of adding dimensions to metrics to allow for easier aggregation and comparison, and helps you to scope aggregated data. You can add tags to any metric, event, or service check. Learn more about using tags [here](https://docs.datadoghq.com/getting_started/tagging/).

**Take advantage of DogStatsD special features**

While StatsD only accepts metrics, DogStatsD accepts all three major data types Datadog supports: metrics, events, and service checks. Histogram metrics, specific to Datadog, calculate the statistical distribution of any kind of value. You can measure and track distributions for almost anything, like the file size that users upload to your site.

If you are not already a Datadog user, sign up for a [14-day free trial](https://www.datadoghq.com/lpg6/) to start monitoring your Ruby applications.  

#### Acknowledgments

We’d like to thank Rien Henrich for this contribution.
