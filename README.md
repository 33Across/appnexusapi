# Appnexus API Wrapper

An unofficial Ruby API Wrapper for the Appnexus Service APIs.

## Installation

Add this line to your application's Gemfile:

    gem 'appnexusapi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install appnexusapi

## Usage

Establish a connection:

    connection = AppnexusApi::Connection.new({
      # optionally pass a uri for the staging site
      # defaults to "http://api.adnxs.com/"
      # "uri" => "http://api.sand-08.adnxs.net",

      # print the request & response out to STDERR
      # "debug_log" => true,

      "username" => 'username',
      "password" => 'password'
    })

Use a Service:

    line_item_service = AppnexusApi::LineItemService.new(connection)
    # get always returns an array of results
    # and defaults "num_elements" to 100 and "start_element" to 0
    # and returns an AppnexusApi::Resource object which is a wrapper around the JSON
    line_item = line_item_service.get.first
    line_item = line_item_service.get({advertiser_id: 12345}).first

    # create a new object
    url_params  = { advertiser_id: 12345 }
    body_params = { name: "some line item", code: "line item code"}

    line_item = line_item_service.create(url_params, body_params)
    line_item.state


    # update an object
    update_params = { state: "inactive" }
    json_result = line_item.update(url_params, update_params)

    # delete an object
    line_item.delete(url_params)

    # this raises an AppnexusApi::UnprocessableEntity, not a 404 as it should
    line_item_service.get(line_item.id)


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make changes (with tests -- at least integration tests, please)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
