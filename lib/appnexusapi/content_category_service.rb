class AppnexusApi::ContentCategoryService < AppnexusApi::Service

  def initialize(connection)
    @read_only = true
    super(connection)
  end

  def uri_name
    "content-category"
  end

  def plural_name
    "content-categories"
  end

  def plural_uri_name
    "content-categories"
  end


end
