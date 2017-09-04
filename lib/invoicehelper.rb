module RedmineInvoiceHelper
  class InvoiceHelper

    def self.fill_cf_fields

      init_cf

      result=Array.new

      tes = TimeEntry.where("easy_locked = false")

      tes.each do |te|
        begin
          result.push(te.id.to_s)

          te.save

          te=TimeEntry.find(te.id)

          te_changed=false

          if te.custom_value_for(@cf_timeentry_invoice_user).value.blank? then
            te.custom_value_for(@cf_timeentry_invoice_user).value=te.user.id
          end

          if te.custom_value_for(@cf_timeentry_billing_date).value.blank? then
            te.custom_value_for(@cf_timeentry_billing_date).value=te.spent_on
          end
          te.save
        rescue => error
          result.push(error)
        end
      end
      return result
    end


    def self.init_cf
      #	@cf_issue_customer=IssueCustomField.where(:internal_name => 'issue_customer').select(:id).first
      @cf_issue_license_price=IssueCustomField.where(:internal_name => 'issue_license_price').select(:id).first
      @cf_issue_license_serialnumber=IssueCustomField.where(:internal_name => 'issue_license_serialnumber').select(:id).first
      @cf_issue_license_controlnumber=IssueCustomField.where(:internal_name => 'issue_license_controlnumber').select(:id).first
      @cf_issue_maintenance_date=IssueCustomField.where(:internal_name => 'issue_maintenance_date').select(:id).first
      @cf_issue_license_purchase_price=IssueCustomField.where(:internal_name => 'issue_license_purchase_price').select(:id).first
      @cf_issue_maintenance_price=IssueCustomField.where(:internal_name => 'issue_maintenance_price').select(:id).first
      @cf_issue_maintenance_purchase_price=IssueCustomField.where(:internal_name => 'issue_maintenance_purchase_price').select(:id).first
      @cf_issue_maintenance_period=IssueCustomField.where(:internal_name => 'issue_maintenance_period').select(:id).first
      @cf_issue_sales_quote_number=IssueCustomField.where(:internal_name => 'issue_sales_quote_number').select(:id).first
      @cf_issue_license_lef=IssueCustomField.where(:internal_name => 'issue_license_lef').select(:id).first
      @cf_issue_customer_invoice_reference=IssueCustomField.where(:internal_name => 'issue_customer_invoice_reference').select(:id).first
      @cf_issue_maintenance_paid_until=IssueCustomField.where(:internal_name => 'issue_maintenance_paid_until').select(:id).first

      @cf_timeentry_billing_date=TimeEntryCustomField.where(:internal_name => 'time_entry_billing_date').select(:id).first
      @cf_timeentry_count=TimeEntryCustomField.where(:internal_name => 'time_entry_count').select(:id).first
      @cf_timeentry_link_issue=TimeEntryCustomField.where(:internal_name => 'time_entry_link_issue').select(:id).first
      @cf_timeentry_real_hours=TimeEntryCustomField.where(:internal_name => 'time_entry_real_hours').select(:id).first
      @cf_timeentry_invoice_user=TimeEntryCustomField.where(:internal_name => 'time_entry_invoice_user').select(:id).first
      @cf_timeentry_amount=TimeEntryCustomField.where(:internal_name => 'time_entry_amount').select(:id).first
      @cf_timeentry_customer_invoice_reference=TimeEntryCustomField.where(:internal_name => 'time_entry_customer_invoice_reference').select(:id).first

      @cf_project_customer_invoice_reference=ProjectCustomField.where(:internal_name => 'project_customer_invoice_reference').select(:id).first
    end


    def self.invoice_licenses

      init_cf

      begin

        result=Array.new

        #        lic_iss = Issue.where('id = 3122')
        lic_iss = Issue.where('(tracker_id = 6 or tracker_id = 9) and (status_id = 8 or status_id = 9) and  start_date <= ?', DateTime.now)

        lic_iss.each do |iss|

          # if this license is over the due_date set the status to closed
          if !iss.due_date.blank? && iss.due_date < Date.today then
            iss.status_id = 5
            iss.save

            next
          end

          #result.push(iss.id.to_s)
          main_period_cfv=iss.custom_value_for(@cf_issue_maintenance_period)
          if main_period_cfv.nil? then
            main_period = 365
          else
            main_period = main_period_cfv.value.to_i
          end
          main=iss.custom_value_for(@cf_issue_maintenance_price).value
          lic=iss.custom_value_for(@cf_issue_license_price).value
          main_date_cfv=iss.custom_value_for(@cf_issue_maintenance_date)
          main_date=main_date_cfv.value.to_date
          main_date_org = main_date_cfv.value.to_date
          main_paid_date_cfv=iss.custom_value_for(@cf_issue_maintenance_paid_until)
          if main_paid_date_cfv.value.blank? then
            main_paid_date=nil
          else
            main_paid_date=main_paid_date_cfv.value.to_date
          end
            
          inv_ref=iss.custom_value_for(@cf_issue_customer_invoice_reference).value

          # wenn das Ticket niemanden Zugewiesen ist Konrad zuweisen
          if iss.assigned_to_id.blank? then
            iss.assigned_to_id=3
            iss.save
          end

          # wenn das maintanance date in der Vergangenheit liegt
          # so lange 1 jahr / 1 monat addieren bis es im aktuellen monat oder
          # der Zukunft liegt
          while (main_date <= Date.today.end_of_month) && (iss.due_date.blank? ||  main_date < iss.due_date)  do
            if main_period == 30 then
              main_date = main_date.next_month.end_of_month
            else
              if main_period == 90 then
                main_date = main_date.next_month.next_month.next_month.end_of_month
              else
                if main_period == 365 then
                  main_date = main_date.next_year.end_of_month
                else
                  # TODO auch andere perioden z.B. Teilbar durch 7 -> Wochen sollen gehen
                  # TODO dazu muss aber unten auch die Anteilsberechnung angepasst werden
                  main_date = main_date.next_year.end_of_month
                end
              end
            end
          end

          if main_date_org != main_date then
            main_date_cfv.value=main_date
            iss.save
          end

          # hier wird die Verrechnung der Lizenz erstellt
          if main_paid_date.blank? then
            result.push("Lizenz berechnen #"+iss.id.to_s+" "+iss.subject+" "+lic.to_s)
            te = TimeEntry.new(project_id: iss.project_id,
            issue_id: iss.id,
            user:User.find(iss.assigned_to_id),
            comments:iss.subject,
            spent_on:Date.today,
            activity_id: 36,
            hours:0.0,
            easy_is_billable:true)

            te.save
            te=TimeEntry.find(te.id)
            te.custom_value_for(@cf_timeentry_amount).value=lic.to_s
            te.custom_value_for(@cf_timeentry_customer_invoice_reference).value=inv_ref
            te.save

            if iss.start_date.mday== 1
              main_paid_date=iss.start_date.prev_day
            else
              main_paid_date=iss.start_date.end_of_month
            end

            iss=Issue.find(iss.id)
            iss.custom_value_for(@cf_issue_maintenance_paid_until).value=main_paid_date.to_s
            iss.save
          end

          # hier wird die Wartung Berechnet
          if  main_paid_date < main_date then
            months = (main_date.year * 12 + main_date.month) - (main_paid_date.year * 12 + main_paid_date.month)

            te = TimeEntry.new(project_id: iss.project_id,
            issue_id: iss.id,
            user:User.find(iss.assigned_to_id),
            comments: iss.subject + " Wartung "+main_paid_date.next_day.to_s+" bis "+main_date.to_s,
            spent_on:Date.today,
            activity_id: 37,
            hours:0.0,
            easy_is_billable:true)

            result.push("Wartung berechnen #"+iss.id.to_s+" "+te.comments)

            if te.save then

              te=TimeEntry.find(te.id)

              te.custom_value_for(@cf_timeentry_amount).value=((main.to_f*months)/12.0).round(2).to_s
              te.custom_value_for(@cf_timeentry_customer_invoice_reference).value=inv_ref

              if te.save then
                iss=Issue.find(iss.id)
                iss.custom_value_for(@cf_issue_maintenance_paid_until).value=main_date.to_s
                iss.save
              else
                result.push(te.errors.full_messages)
              end
            else
              result.push(te.errors.full_messages)
            end
          end

          # Lizenz / Wartungstickets nach der Berechnung immer an Konrad zuweisen.
          if iss.assigned_to_id != 3 then
            iss.assigned_to_id=3
            iss.save
          end

        end

      rescue Exception => msg
        # display the system generated error message  
        result.push(msg)
      end

      return result

    end

    
  end
end
