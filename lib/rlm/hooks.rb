module Rlm
  class Hooks < Redmine::Hook::ViewListener

    def view_issues_context_menu_end(context = {})
      
      has_licenses            = context[:issues].detect {|i| i.is_license_or_extension?}.present?
      has_non_license_tickets = context[:issues].detect {|i| !i.is_license_or_extension?}.present?
      has_closed_tickets      = context[:issues].detect {|i| i.closed? }.present?
      
      if has_licenses
        if !(has_non_license_tickets || has_closed_tickets) 
      
          content_tag(:li, context[:hook_caller].context_menu_link(l(:button_rlm_create_invoicing),
              rlm_licenses_invoice_licenses_path(:issue_ids => context[:issues].collect(&:id)), :class => 'icon icon-table', method: :patch),
              
            )
        elsif has_non_license_tickets
          content_tag(:li, l(:label_rlm_non_license_tickets_selected))
        elsif has_closed_tickets
          content_tag(:li, l(:label_rlm_closed_tickets_selected))  
        end    
      end  
      
    end

  end
end