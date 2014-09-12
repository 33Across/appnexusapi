require 'spec_helper'

describe "line items" do
  it "does stuff" do
    connection = AppnexusApi::Connection.new({
      "uri" => "http://sand.api.appnexus.com",
      "username" => 'username',
      "password" => 'password'
    })
    connection.login

    category = AppnexusApi::CategoryService.new(connection)
    debugger
    category.get

  end
end