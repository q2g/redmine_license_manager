class RlmLefAccessLog < ActiveRecord::Base
  
  validates_presence_of :ip, :status, :request_params
  
  scope :failed, -> { where(status: 'NOT_OK') } 
  
  def self.check_if_ip_allowed(ip)
    
    for_ip = self.where(ip: ip).where("created_at > ?", Time.now-1.hour)

    for_ip.group(:request_params).group(:request_params).select('count(*) as count').to_a.size < 10 && for_ip.failed.size < 3
    
  end
  
end