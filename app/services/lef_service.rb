class LefService
  
  # can return 
  # - nil   - serial not found
  # - fase  - worng checksum
  # - Issue - everthing is fine
  def self.issue_from_serial_and_checksum(params = {})
    [:serial, :chk].each do |p|
      raise ArgumentError, "Missing mandatory param :#{p}" if params[p].nil?
    end
    
    if get_checksum(params.except(:chk, :controller, :action, :locale, :id)) == params[:chk]
      Issue.find_by_serialnumber(params[:serial]).first
    else
      return false
    end
  end
  
  def self.issue_lefs_as_jsonp(params = {})
    [:serial, :chk, :callback].each do |p|
      raise ArgumentError, "Missing mandatory param :#{p}" if params[p].nil?
    end
    
    json_status = {
      success: false,
      status: 'unknown',
      status_code: 200,
      licenses: []
    }
    
    if get_checksum(params.except(:chk, :controller, :action, :locale, :callback, :id)) == params[:chk] || Rails.env.development?
      issues = Issue.find_by_serialnumber(params[:serial])
      if issues.empty?
        json_status[:status] = 'no licenses found'
        json_status[:status_code] = 404
      else
        json_status[:status]   = 'ok'
        json_status[:licenses] = issues.map {|i| i.license_lef }
        json_status[:success]  = true
      end
    else
      json_status[:status] = 'checksum validation failed'
      json_status[:status_code] = 403
    end
    
    return json_status.to_json
  end
  
  # function to fetch the LEF from Qlik
  def self.read_lef_from_qlik(serial)

    uri = URI.parse("http://lef1.qliktech.com/lefupdate/update_lef.aspx?serial=#{serial}&chk=#{get_checksum(serial: serial)}")
    request = Net::HTTP::Get.new(uri)

    response = Net::HTTP.start(uri.host, uri.port) {|http| http.request(request) }
    Rails.logger.error "http://lef1.qliktech.com/lefupdate/update_lef.aspx?serial=#{serial}&chk=#{get_checksum(serial: serial)}"
    Rails.logger.error response.body
    case response.code
    when "500", "404", "403"
      return nil
    else
      return response.body
    end  
  end
  
  def self.sync_lefs_for_qlik(issue_ids = [])
    result = []
    issues = Issue.find_by_license_product_name("Qlik").where(tracker_id: ::RLM::Setup::Trackers.license.id, status_id: RLM::Setup::IssueStatuses.license_active.id )
    
    if issue_ids.any?
      issues = issues.where(id: issue_ids)
    end
    result << "Updating #{issues.size} licenses"
    
    issues.each do |iss|
      serial  = iss.serialnumber
      lef     = iss.license_lef

      if serial.to_i > 1000000000000000 && (new_lef = read_lef_from_qlik(serial)).present?

        #check if the lef is really different. 
        # Qlik changes sometimes just the order  
        # the last line will always change so it is exccluded from the comparing
        has_changed = (new_lef.strip.split("\n")[0..-2] - lef.strip.split("\n")[0..-2]).any?

        if has_changed && !new_lef.blank? && !new_lef.include?("INTERNAL_LEF_SERVER_ERROR")
          iss.init_journal(User.find_by_id(2))
          result.push("Update LEF for Issues ID: #"+iss.id.to_s);
          
          # storing new lef
          iss.update_attributes(custom_field_values: {::RLM::Setup::IssueCustomFields.license_lef.id => new_lef})
        end
      else
        result << "- cant update ##{iss.id}"
      end
    end
    puts result.join("\n")
    return result
  end
  
  def self.get_checksum(params = {})
    chk = 4711
    params.slice(:serial).values.join.split('').each  do |ch|
      chk *= 2;
      if chk >= 65536
        chk -= 65535
      end
      chk ^= ch.ord
    end
    
    chk.to_s
  end
  
  
  
  
end