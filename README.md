aws-monitoring
==============

This is a simple ruby app to allow monitoring of all EC2 instances in a given account.

### Installation

First, you'll need to create a `config.yml` file in the root directory of the repo, using the following format:

```ruby
access_key_id: <Your AWS Access Key>
secret_access_key: <Your AWS Secret Access Key>
```

Now, run:

```
bundle install
ruby app.rb
```

### Todo in future iterations

* Add support for ELB
* Allow changing time range
* Allow changing time resolution
* Allow multiple metrics
* Save/load dashboards
* Scalars
