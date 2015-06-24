class AppnexusApi::ContentCategoryService < AppnexusApi::Service

  def initialize(connection)
    @read_only = true
    super(connection)
  end

  def plural_name
    "content-categories"
  end

  def uri_suffix
    "content-category"
  end


end
