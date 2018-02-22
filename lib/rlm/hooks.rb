module Rlm
  class Hooks < Redmine::Hook::ViewListener

    def view_issues_context_menu_end(context = {})
      
      has_licenses            = context[:issues].detect {|i| i.is_license_or_extension?}.present?
      has_non_license_tickets = context[:issues].detect {|i| !i.is_license_or_extension?}.present?
      has_closed_tickets      = context[:issues].detect {|i| i.closed? }.present?
      
      output = []
      
      if has_licenses
        if !(has_non_license_tickets || has_closed_tickets) 
      
          output = [content_tag(:li, context[:hook_caller].context_menu_link(l(:button_rlm_create_invoicing),
              rlm_licenses_invoice_licenses_path(:issue_ids => context[:issues].collect(&:id)), :class => 'icon icon-table', method: :patch),
            ),
            content_tag(:li, context[:hook_caller].context_menu_link(l(:button_rlm_update_lef),
            rlm_licenses_update_lef_path(:issue_ids => context[:issues].collect(&:id)), :class => 'icon', method: :patch))
          ]
          
          if context[:issues].size == 1 && context[:issues].first.is_license_extension? && context[:issues].first.license_count.to_i > 1
            output << content_tag(:li, context[:hook_caller].render("rlm/split_license_form_menu_entry", issue: context[:issues].first), class: "folder")
          end
            
        elsif has_non_license_tickets
          output << content_tag(:li, l(:label_rlm_non_license_tickets_selected))
        elsif has_closed_tickets
          output << content_tag(:li, l(:label_rlm_closed_tickets_selected))  
        end    
      end  
      
      return output.join
    end

  end
end