class ApplicationController < ActionController::Base
  helper :all
  include ExceptionNotifiable
  include Authorization
  filter_parameter_logging "password"

  before_filter :allow_to, :check_user, :set_profile, :login_from_cookie, :login_required, :check_permissions
  after_filter :store_location
  layout 'application'

  def pagination_defaults(options = {})
    options = {} unless options.is_a?(Hash)
    { :page => params[:page] || 1,
      :per_page => params[:per_page] || (RAILS_ENV=='test' ? 1 : 40)
    }.merge(options)
  end

  def set_profile
    @p = @u.profile if @u && @u.profile
    Time.zone = @p.time_zone if @p && @p.time_zone
    @p.update_attribute :last_activity_at, Time.now if @p
  end

  helper_method :flickr, :flickr_images
  # API objects that get built once per request
  def flickr(user_name = nil, tags = nil )
    @flickr_object ||= Flickr.new(FLICKR_CACHE, FLICKR_KEY, FLICKR_SECRET)
  end

  def flickr_images(user_name = "", tags = "")
    unless RAILS_ENV == "test"# || RAILS_ENV == "development"
      begin
        flickr.photos.search(user_name.blank? ? nil : user_name, tags.blank? ? nil : tags , nil, nil, nil, nil, nil, nil, nil, nil, 20)
      rescue
        nil
      rescue Timeout::Error
        nil
      end
    end
  end
end
