class LicenseInvoicingService
  
  attr_reader :issues
  attr_accessor :result, :errors
  
  def initialize(issues)
    @issues = issues
      .where(status_id: [RLM::Setup::IssueStatuses.license_active.id, RLM::Setup::IssueStatuses.license_ordered.id])
      .where(tracker_id: [RLM::Setup::Trackers.license.id, RLM::Setup::Trackers.license_extension.id])
      .where("start_date <= ?", DateTime.now)
      
    @result       = []
    @errors       = []
  end
  
  def invoice_licenses

      issues.each do |iss|
        begin
          # if this license is over the due_date set the status to closed
          if iss.due_date.present? && iss.due_date < Date.today
            # TODO: find correct closed status
            iss.status_id = RLM::Setup::IssueStatuses.license_inactive.id
            iss.save
            result.push("Issue #{iss.id} set to inactive")
            next
          end
        
          # getting maintaince period in days
          main_period = iss.maintainance_period.nil? ? 365 : iss.maintainance_period.to_i
        
          # getting maintaince price  
          main        = iss.maintainance_price
        
          # getting maintainance dates
          main_date     = iss.maintainance_date.to_date
          main_date_org = iss.maintainance_date.to_date
        
          # Maintaince Paid until
          main_paid_date = iss.maintainance_paid_until.presence.try(:to_date)
        
          # Invoice reference      
          inv_ref = iss.customer_invoice_reference

          # wenn das Ticket niemanden Zugewiesen ist Konrad zuweisen
          # TODO: Put this into a config field later
          if iss.assigned_to_id.blank?
            iss.assigned_to_id = 3
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
            iss.maintainance_date = main_date
            iss.save
          end

          # hier wird die Verrechnung der Lizenz erstellt
          if main_paid_date.blank? then
            result.push("Lizenz berechnen #" + iss.id.to_s + " " +iss.subject+ " " + iss.license_price.to_s)
          
            te = TimeEntry.new(
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

            te.save(validate: false)

            te.amount = iss.license_price
            te.customer_invoice_reference = inv_ref

            if iss.start_date.mday== 1
              main_paid_date=iss.start_date.prev_day
            else
              main_paid_date=iss.start_date.end_of_month
            end

            iss.maintainance_paid_until = main_paid_date.to_s
          end

          # hier wird die Wartung Berechnet
          if  main_paid_date < main_date then
            months = (main_date.year * 12 + main_date.month) - (main_paid_date.year * 12 + main_paid_date.month)

            te = TimeEntry.new(project_id: iss.project_id,
            issue_id: iss.id,
            user:User.find(iss.assigned_to_id),
            comments: iss.subject + " Wartung "+main_paid_date.next_day.to_s+" bis "+main_date.to_s,
            spent_on:Date.today,

            # TODO: is that right?
            activity_id: RLM::Setup::Activities.maintainance.id,
            hours:0.0,
            easy_is_billable:true)

            result.push("Wartung berechnen #"+iss.id.to_s+" "+te.comments)

            if te.save(validate: false)
            
              te.amount                     = ((main.to_f*months)/12.0).round(2).to_s
              te.customer_invoice_reference = inv_ref
            
              iss.maintainance_paid_until = main_date.to_s
            else
              errors.push(te.errors.full_messages)
            end
          end

          # Lizenz / Wartungstickets nach der Berechnung immer an Konrad zuweisen.
          # TODO: dont use static ids here
          if iss.assigned_to_id != 3 then
            iss.assigned_to_id=3
            iss.save
          end
        rescue Exception => e
          errors.push("ISSUE #{iss.id} failed")
          errors.push(e.try(:exception))
          errors.push(e.try(:backtrace).try(:join, "\n"))
        end

      end

    
    return result

  end

    
end

