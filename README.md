# Sequel::SimpleJson

Provides extremely simple JSON serialization for Sequel. Only supports direct columns.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sequel-simple_json', git: 'git@git.noxqsapp.nl:gems/sequel-simple_json.git'
```

And then execute:

    $ bundle

## Usage

Example model:

```ruby
  class User < Sequel::Model
    plugin :simple_json

    json_properties :firstname, :lastname, :email
  end

  # Perferms a select statement, to avoid serializing every single instance.
  User.to_json
  User.where{age > 10}.to_json

  # Performs a select on the values hash, to avoid another database query.
  User[1].to_json
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/sequel-simple_json/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
