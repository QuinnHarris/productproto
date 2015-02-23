class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  UAP = UserAgentParser::Parser.new

  before_filter :access_log
  def access_log
    uap = UAP.parse request.env['HTTP_USER_AGENT']
    if uap.device.to_s == 'Spider'
      logger.info("Spider")
      return
    end

    parameters = respond_to?(:filter_parameters) ? filter_parameters(params) : params.dup
    access_attributes = {
      address: request.remote_ip,
      secure: (request.protocol == "https://"),
      controller: parameters.delete(:controller),
      action: parameters.delete(:action),
    }

    if parameters[:id] && parameters[:id].match(/^\d+$/)
      access_attributes[:id] = Integer(parameters.delete(:id))
    end

    spam_email = nil
    if r = parameters[:r]
      spam_email = SpamEmail.find_by_ref_id(r)
      parameters.delete(:r) if spam_email
    end

    access_attributes[:params] = parameters.to_hash unless parameters.empty?

    unless request.referer.blank?
      our_prefix = request.protocol + request.host
      unless request.referer.start_with?(our_prefix)
        access_attributes[:referer] = request.referer
      end
    end

    AccessRequest.db.transaction(synchronous: !session[:s_id]) do
      unless session[:s_id]
        session_record = AccessSession.create(
            user_agent: request.env['HTTP_USER_AGENT'],
            language:   request.env['HTTP_ACCEPT_LANGUAGE']
        )
        session[:s_id] = session_record.id
      end

      @request = AccessRequest.create(access_attributes.merge(session_id: session[:s_id]))

      spam_email.add_access_request(@request) if spam_email
    end

    redirect_to request.path, params.except(:r) if spam_email
  end
end
