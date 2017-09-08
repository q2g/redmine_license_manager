class LicenseInvoicingService
  
  attr_reader :issues
  attr_accessor :result
  
  def initialize(issues)
    @issues = issues
    @result       = []
  end
  
  def invoice_licenses
    begin

      issues.each do |iss|

        # if this license is over the due_date set the status to closed
        if !iss.due_date.blank? && iss.due_date < Date.today then
          # TODO: is this correct
          iss.status_id = RLM::Setup::IssueStatus.inactive.id
          iss.save

          next
        end
        
        # getting maintaince period in days
        main_period = iss.maintenance_period.nil? ? 360 : iss.maintenance_period.to_i
        
        # getting maintaince price  
        main        = iss.maintenance_price
        # getting license price  
        lic         = iss.license_price
        
        # getting maintainance dates
        main_date     = iss.maintainance_date.to_date
        main_date_org = iss.maintainance_date.to_date
        
        # Maintaince Paid until
        main_paid_date = iss.maintenance_paid_until.try(:to_date)
        
        # Invoice reference      
        inv_ref = iss.customer_invoice_reference

        # wenn das Ticket niemanden Zugewiesen ist Konrad zuweisen
        # TODO: Dont use static id here
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
          
          te = TimeEntry.create(
            project_id: iss.project_id,
            issue_id: iss.id,
            user:User.find(iss.assigned_to_id),
            comments:iss.subject,
            spent_on:Date.today,
            # TODO: is this correct?
            activity_id: RLM::Setup::Activities.license.id,
            hours:0.0,
            easy_is_billable:true
          )
          
          te.reload
          
          te.amount = lic.to_s
          te.customer_invoice_reference = inv_ref
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
          activity_id: RLM::Setup::Activities.maintainance.id,
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

