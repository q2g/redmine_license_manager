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
  
  # function to fetch the LEF from Qlik
  def self.read_lef_from_qlik(serial)
    url = URI.parse("http://lef1.qliktech.com/lefupdate/update_lef.asp?serial=#{serial}&chk=#{get_checksum(serial: serial)}")

    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

    return res.body
  end
  
  def self.sync_lefs_for_qlik
    result = []

    Issue.find_by_license_product_name("Qlik").where(tracker_id: ::RLM::Setup::Trackers.license.id, status_id: RLM::Setup::IssueStatuses.license_active.id ).each do |iss|
      serial  = iss.serialnumber
      lef     = iss.license_lef

      if serial.to_i > 1000000000000000
        new_lef = read_lef_from_qlik(serial)

        #check if the lef is really different. 
        # Qlik changes sometimes just the order  
        has_changed = (new_lef.strip.split("\n") - lef.strip.split("\n")).any?

        if has_changed && !new_lef.blank? && !new_lef.include?("INTERNAL_LEF_SERVER_ERROR")
          iss.init_journal(User.find_by_id(2))
          result.push("Update LEF for Issues ID: #"+iss.id.to_s);
          
          # storing new lef
          iss.update_attributes(custom_field_values: {::RLM::Setup::IssueCustomFields.license_lef.id => new_lef})
        end
      end
    end
    puts result.join("\n")
    return result
  end
  
  def self.get_checksum(params = {})
    chk = 4711

    params.values.join.split('').each  do |ch|
      chk *= 2;
      if chk >= 65536
        chk -= 65535
      end
      chk ^= ch.ord
    end
    
    chk.to_s
  end
  
  
  
  
end