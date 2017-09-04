class LefService
  
  
  def self.get_checksum(serial)
    chk = 4711

    (serial+'201').split('').each  do |ch|
      chk *= 2;
      if chk >= 65536
        chk -= 65535
      end
      chk ^= ch.ord
    end
    
    chk.to_s
  end
  
  # can return 
  # - nil   - serial not found
  # - fase  - worng checksum
  # - Issue - everthing is fine
  def self.issue_from_serial_and_checksum(serial, checksum)
    if get_checksum(serial) == checksum
      Issue.find_by_serial_number(serial).first
    else
      return false
    end
  end
  
  # function to fetch the LEF from Qlik
  def self.read_lef_from_qlik(serial)
    url = URI.parse("http://lef1.qliktech.com/lefupdate/update_lef.asp?serial=#{serial}&user=&org=&cause=201&chk=#{get_checksum(serial)}")

    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http| http.request(req) }

    return res.body
  end
  
  def self.sync_lefs_for_qlik
    result = []

    Issue.find_by_license_product_name.where(tracker_id: ::RLM::Setup::Trackers.license.id, status_id: RLM::Setup::IssueStatuses.license_active.id ).each do |iss|
      serial  = iss.serial_number
      lef     = iss.lev

      if serial.to_i > 1000000000000000
        new_lef = read_lef_from_qlik(serial)

        #check if the lef is really different. 
        # Qlik changes sometimes just the order  
        has_changed = (new_lef.strip.split("\n") - lef.strip.split("\n")).any?

        if has_changed && !new_lef.blank? && !new_lef.include?("INTERNAL_LEF_SERVER_ERROR")
          iss.init_journal(User.find_by_id(2))
          result.push("Update LEF for Issues ID: #"+iss.id.to_s);
          
          # storing new lef
          iss.update_attributes(custom_field_values: {::RLM::Setup::IssueCustomFields.lef.id => new_lef})

        end
      end
    end
    return result
  end
  
  
  
end