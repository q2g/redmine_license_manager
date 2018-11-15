class RlmLicensesController < ApplicationController
  
  skip_filter *_process_action_callbacks.map(&:filter), only: [:index, :get_lefs_json]
  
  before_filter :check_access_permission
  
  def index
    result = ::LefService.issue_from_serial_and_checksum(params)
    
    if result.nil?
      log_lef_access!('NOT_OK')
      render status: '404', text: 'NOT FOUND'
    elsif result == false  
      log_lef_access!('NOT_OK')
      render status: '403', text: 'DENIED'
    else
      log_lef_access!('OK')
      render status: '200', text: result.license_lef
    end  
  end
  
  def get_lefs_json
    @result = ::LefService.issue_lefs_as_jsonp(params)
    #response.headers['Access-Control-Allow-Origin'] = '*'
    render template: "rlm/get_lefs_json"
  end
  
  def invoice_licenses
    invoicing = LicenseInvoicingService.new(Issue.where(id: params[:issue_ids]))
    invoicing.invoice_licenses
    
    flash[:notice] = invoicing.result.join("<br />").html_safe if invoicing.result.any?
    flash[:error]  = invoicing.errors.join("<br />").html_safe if invoicing.errors.any?
    redirect_to :back
  end
  
  def update_lef
    result = LefService.sync_lefs_for_qlik(params[:issue_ids])
    flash[:notice] = result.join("<br />")
    redirect_to :back
  end
  
  def merge
    new_license = Issue.merge_license_extensions(params[:issue_ids], User.current)
    if new_license.present? && new_license.errors.empty?
      redirect_to issue_path(new_license)
    else
      redirect_to :back
    end
  end
  
  def split
    issue = Issue.find(params[:id])
    new_license = issue.create_splitted_license(params[:split_license][:license_count], User.current)
    if new_license.persisted?
      redirect_to issue_path(new_license)
    else
      flash[:error] = new_license.errors.full_messages
      redirect_to :back
    end
  end
  
  private
  
  def check_access_permission
    # TODO: currently disabled - check if it should be enabled again
    # florianeck - Wed Nov 14 13:40:44 CET 2018
    #if RlmLefAccessLog.check_if_ip_allowed(request.ip) || Rails.env.development?
    #  return true
    #else
    #  render status: '403', text: 'BLOCKED'
    #end
    RlmLefAccessLog.check_if_ip_allowed(request.ip)
    return true
  end
  
  def log_lef_access!(status = 'OK')
    RlmLefAccessLog.create(ip: request.ip, status: status, request_params: params.except(:controller, :action).to_json)
  end
  
end