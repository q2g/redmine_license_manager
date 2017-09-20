class RlmLicensesController < ApplicationController
  
  skip_before_filter :require_login, :require_admin
  
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
  
  def invoice_licenses
    invoicing = LicenseInvoicingService.new(Issue.where(id: params[:issue_ids])).invoice_licenses
    invoicing.invoice_licenses
    
    flash[:notice] = invoicing.result.join("<br />").html_safe if invoicing.result.any?
    flash[:error]  = invoicing.errors.join("<br />").html_safe if invoicing.errors.any?
    redirect_to :back
  end
  
  private
  
  def check_access_permission
    if RlmLefAccessLog.check_if_ip_allowed(request.ip)
      return true
    else
      render status: '403', text: 'BLOCKED'
    end
  end
  
  def log_lef_access!(status = 'OK')
    RlmLefAccessLog.create(ip: request.ip, status: status, request_params: params.except(:controller, :action).to_json)
  end
  
end