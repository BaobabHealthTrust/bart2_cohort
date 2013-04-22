
class CohortController < ActionController::Base
  @@first_registration_date = nil
  
  def initialize

		@@first_registration_date = FlatCohortTable.find(
		  :first,
		  :conditions =>["voided = 0"],
		  :order => 'earliest_start_date ASC'
		).earliest_start_date.to_date rescue nil

	end

  def index
  end

  def select_date
  end

  def cohort    
  end

  def mastercard
  end

  def drill_down
    @patients = CohortPerson.find(:all, :conditions => ["person_id IN (?)",
        params[:field].split(",")]).collect{|p|
      [p.person_id, (p.names.first.given_name rescue "&nbsp;"),
        (p.names.first.family_name rescue "&nbsp;"), (p.birthdate rescue "&nbsp;"), p.gender]
    }

    # raise @patients.inspect
  end

  def current_site
    render :text => "Test Site"
  end

  def quarter(start_date=Time.now.strftime("%Y-%m-%d"), end_date=Time.now.strftime("%Y-%m-%d"), section=nil)
    startdate = Date.parse(start_date)
    enddate = Date.parse(end_date)

    retstr = ""

    if startdate.year == enddate.year
      if ((startdate.month - 1)/3) == ((enddate.month - 1)/3)
        q = ((startdate.month - 1)/3)

        case q.to_s
        when "0":
            retstr = startdate.year.to_s + " - 1<sup>st</sup> Quarter"
        when "1":
            retstr = startdate.year.to_s + " - 2<sup>nd</sup> Quarter"
        when "2":
            retstr = startdate.year.to_s + " - 3<sup>rd</sup> Quarter"
        when "3":
            retstr = startdate.year.to_s + " - 4<sup>th</sup> Quarter"
        end
      else
        retstr = startdate.strftime("%d/%b/%Y") + " to " + enddate.strftime("%d/%b/%Y")
      end
    else
      retstr = startdate.strftime("%d/%b/%Y") + " to " + enddate.strftime("%d/%b/%Y")
    end

    render :text => retstr
  end

  # Start Cohort queries
  def new_total_patients_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')  
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def cum_total_patients_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')        

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def new_total_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    patients = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    value = []

    @total_patients_reg = new_total_patients_reg(start_date,end_date)
    @total_patients_reg = [] if @total_patients_reg.blank?

    @total_patients_reg.each do |patient|
      patients << patient
    end

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_total_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    patients =  []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @total_patients_reg = cum_total_patients_reg(@@first_registration_date,end_date)
    @total_patients_reg = [] if @total_patients_reg.blank?

    @total_patients_reg.each do |patient|  
      patients << patient
    end

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_ft(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id
      FROM flat_table2 ft2 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = ft2.patient_id
      WHERE ft2.regimen_category IS NOT NULL AND ft2.current_hiv_program_state = 'On antiretrovirals'
      AND ft1.earliest_start_date >= '#{start_date}'
      AND ft1.earliest_start_date <= '#{end_date}'
      AND ft1.date_started_art IS NULL GROUP BY ft1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_ft(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')     
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id
      FROM flat_table2 ft2 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = ft2.patient_id
      WHERE ft2.regimen_category IS NOT NULL AND ft2.current_hiv_program_state = 'On antiretrovirals'
      AND ft1.earliest_start_date <= '#{end_date}'
      AND ft1.date_started_art IS NULL GROUP BY ft1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_re(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.taken_art_in_last_two_months = 'No' OR DATEDIFF(ftc.date_art_last_taken_v_date,ftc.date_art_last_taken) > 60)
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_re(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.taken_art_in_last_two_months = 'No' OR DATEDIFF(ftc.date_art_last_taken_v_date,ftc.date_art_last_taken) > 60)
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_ti(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.ever_registered_at_art = 'Yes'
                                            AND (ftc.taken_art_in_last_two_months = 'No' OR DATEDIFF(ftc.date_art_last_taken_v_date,ftc.date_art_last_taken) < 60)
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_ti(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.ever_registered_at_art = 'Yes'
                                            AND (ftc.taken_art_in_last_two_months = 'No' OR DATEDIFF(ftc.date_art_last_taken_v_date,ftc.date_art_last_taken) < 60)
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_males(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.gender = 'M'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_males(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.gender = 'M'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_non_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
        
    all_women = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                              WHERE ftc.earliest_start_date >= '#{start_date}'
                                              AND ftc.earliest_start_date <= '#{end_date}'
                                              AND ftc.gender = 'F'
                                              GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    pregnant_women = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.gender = 'F'
                                            AND ftc.pregnant_yes = 'Yes'
                                            AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) <= 30
                                            AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) > -1
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}
   
    patients = all_women - pregnant_women
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_non_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    all_women = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                              WHERE ftc.earliest_start_date <= '#{end_date}'
                                              AND ftc.gender = 'F'
                                              GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    pregnant_women = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                                    WHERE ftc.earliest_start_date <= '#{end_date}'
                                                    AND ftc.gender = 'F'
                                                    AND ftc.pregnant_yes = 'Yes'
                                                    AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) <= 30
                                                    AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) > -1
                                                    GROUP BY ftc.patient_id").collect{|p| p.patient_id}    
    
    patients = all_women - pregnant_women
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_preg_all_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                                    WHERE ftc.earliest_start_date >= '#{start_date}'
                                                    AND ftc.earliest_start_date <= '#{end_date}'
                                                    AND ftc.gender = 'F'
                                                    AND ftc.pregnant_yes = 'Yes'
                                                    AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) <= 30
                                                    AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) > -1
                                                    GROUP BY ftc.patient_id").collect{|p| p.patient_id}    

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_preg_all_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                                  WHERE ftc.earliest_start_date <= '#{end_date}'
                                                  AND ftc.gender = 'F'
                                                  AND ftc.pregnant_yes = 'Yes'
                                                  AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) <= 30
                                                  AND DATEDIFF(ftc.pregnant_yes_v_date,ftc.earliest_start_date) > -1
                                                  GROUP BY ftc.patient_id").collect{|p| p.patient_id}    
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_infants_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, age_in_months(ftc.birthdate, '#{end_date.to_date}') AS months
                                             FROM flat_cohort_table ftc 
                                             WHERE ftc.earliest_start_date >= '#{start_date}'
                                             AND ftc.earliest_start_date <= '#{end_date}'
                                             GROUP BY ftc.patient_id
                                             HAVING months BETWEEN 0 AND 23").collect{|p| p.patient_id}    

    value = patients unless patients.blank?
  end

  def cum_infants_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, age_in_months(ftc.birthdate, '#{end_date.to_date}') AS months
                                             FROM flat_cohort_table ftc 
                                             WHERE ftc.earliest_start_date <= '#{end_date}'
                                             GROUP BY ftc.patient_id
                                             HAVING months BETWEEN 0 AND 23").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def new_a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = new_infants_reg(start_date,end_date) 

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = cum_infants_reg(nil,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_children_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, age_in_months(ftc.birthdate, '#{end_date.to_date}') AS months
                                             FROM flat_cohort_table ftc 
                                             WHERE ftc.earliest_start_date >= '#{start_date}'
                                             AND ftc.earliest_start_date <= '#{end_date}'
                                             GROUP BY ftc.patient_id
                                             HAVING months BETWEEN 24 AND 168").collect{|p| p.patient_id}   

    value = patients unless patients.blank?
  end

  def cum_children_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, age_in_months(ftc.birthdate, '#{end_date.to_date}') AS months
                                             FROM flat_cohort_table ftc 
                                             WHERE ftc.earliest_start_date <= '#{end_date}'
                                             GROUP BY ftc.patient_id
                                             HAVING months BETWEEN 24 AND 168").collect{|p| p.patient_id}   


    value = patients unless patients.blank?
  end


  def new_b(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = new_children_reg(start_date,end_date) 

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_b(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = cum_children_reg(@@first_registration_date,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_adults_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, age_in_months(ftc.birthdate, '#{end_date.to_date}') AS months
                                             FROM flat_cohort_table ftc 
                                             WHERE ftc.earliest_start_date >= '#{start_date}'
                                             AND ftc.earliest_start_date <= '#{end_date}'
                                             GROUP BY ftc.patient_id
                                             HAVING months > 168").collect{|p| p.patient_id}   


    value = patients unless patients.blank?
  end

  def cum_adults_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, age_in_months(ftc.birthdate, '#{end_date.to_date}') AS months
                                             FROM flat_cohort_table ftc 
                                             WHERE ftc.earliest_start_date <= '#{end_date}'
                                             GROUP BY ftc.patient_id
                                             HAVING months > 168").collect{|p| p.patient_id}   


    value = patients unless patients.blank?
  end

  def new_c(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = new_adults_reg(start_date,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_c(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = cum_adults_reg(@@first_registration_date,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_unk_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    @newly_total_registered = new_total_patients_reg(start_date,end_date)
    @newly_total_adults_registered = new_adults_reg(start_date,end_date)
    @newly_total_children_registered = new_children_reg(start_date,end_date)
    @newly_total_infants_registered = new_infants_reg(start_date,end_date)
    
    @newly_total_registered = [] if @newly_total_registered.blank?
    @newly_total_adults_registered = [] if @newly_total_adults_registered.blank?
    @newly_total_children_registered = [] if @newly_total_children_registered.blank?
    @newly_total_infants_registered = [] if @newly_total_infants_registered.blank?
    
    patients = (@newly_total_registered - (@newly_total_adults_registered + @newly_total_children_registered + @newly_total_infants_registered))
    
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_unk_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    @cum_total_registered = cum_total_patients_reg || []
    @cum_total_adults_registered = cum_adults_reg || []
    @cum_total_children_registered = cum_children_reg || []
    @cum_total_infants_registered = cum_infants_reg || []

    patients = (@cum_total_registered - (@cum_total_adults_registered + @cum_total_children_registered + @cum_total_infants_registered))
    
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_pres_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                            
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting LIKE '%Presumed%'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_pres_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting LIKE '%Presumed%'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_conf_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting = 'HIV infected'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_conf_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting = 'HIV infected'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_1_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting LIKE '%CD4%'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_1_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting LIKE '%CD4%'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting = 'Lymphocyte count below threshold with who stage 2'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting = 'Lymphocyte count below threshold with who stage 2'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_children(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.reason_for_starting = 'WHO stage III peds' OR
                                                 ftc.reason_for_starting = 'WHO stage IV peds')
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_children(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.reason_for_starting = 'WHO stage III peds' OR
                                                 ftc.reason_for_starting = 'WHO stage IV peds')
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_breastfeed(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'Currently breastfeeding child'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_breastfeed(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'Currently breastfeeding child'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'Patient pregnant'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'Patient pregnant'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_3(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'WHO stage III adult'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_3(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'WHO stage III adult'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_4(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'WHO stage IV adult'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_4(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting  = 'WHO stage IV adult'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_other_reason(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting = 'Unknown'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_other_reason(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.reason_for_starting = 'Unknown'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_total_tb_w2yrs(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.pulmonary_tuberculosis_last_2_years = 'Yes'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}


    value = patients unless patients.blank?
  end

  def cum_total_tb_w2yrs(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.pulmonary_tuberculosis_last_2_years = 'Yes'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def new_total_current_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.pulmonary_tuberculosis = 'Yes' OR
                                                 ftc.extrapulmonary_tuberculosis = 'Yes')
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def cum_total_current_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.pulmonary_tuberculosis = 'Yes' OR
                                                 ftc.extrapulmonary_tuberculosis = 'Yes')
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def new_no_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []; @new_total_patients_reg = []; @new_total_tb_w2yrs_pat_ids = []
    @new_total_current_tb_pat_ids = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @new_total_patients_reg = new_total_patients_reg(start_date,end_date)
    @new_total_tb_w2yrs_pat_ids = new_total_tb_w2yrs(start_date,end_date)
    @new_total_current_tb_pat_ids = new_total_current_tb(start_date,end_date)

    @new_total_patients_reg = [] if @new_total_patients_reg.blank?
    @new_total_tb_w2yrs_pat_ids = [] if @new_total_tb_w2yrs_pat_ids.blank?
    @new_total_current_tb_pat_ids = [] if @new_total_tb_w2yrs_pat_ids.blank?

    patients = (@new_total_patients_reg.to_a - (@new_total_tb_w2yrs_pat_ids.to_a + @new_total_current_tb_pat_ids.to_a))

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_no_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []; @new_total_patients_reg = []; @new_total_tb_w2yrs_pat_ids = []
    @new_total_current_tb_pat_ids = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @new_total_patients_reg = cum_total_patients_reg(nil,end_date)
    @new_total_tb_w2yrs_pat_ids = cum_total_tb_w2yrs(nil,end_date)
    @new_total_current_tb_pat_ids = cum_total_current_tb(nil,end_date)

    if !@new_total_patients_reg
      @new_total_patients_reg = []
    end

    if !@new_total_tb_w2yrs_pat_ids
      !@new_total_tb_w2yrs_pat_ids = []
    end

    if !@new_total_current_tb_pat_ids
      @new_total_tb_w2yrs_pat_ids = []
    end

    patients = (@new_total_patients_reg.to_a - (@new_total_tb_w2yrs_pat_ids.to_a + @new_total_current_tb_pat_ids.to_a))

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_tb_w2yrs(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = new_total_tb_w2yrs(start_date,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_tb_w2yrs(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = cum_total_tb_w2yrs(@@first_registration_date,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_current_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = new_total_current_tb(start_date,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_current_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = cum_total_current_tb(@@first_registration_date, end_date)
 
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_ks(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date >= '#{start_date}' 
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.kaposis_sarcoma = 'Yes'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_ks(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.kaposis_sarcoma = 'Yes'
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def total_patients_alive_and_on_art(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_defaulted ||= total_defaulted_patients(nil,end_date)
		@patient_id_defaulted = @patients_defaulted
		@patient_id_defaulted = [0] if @patient_id_defaulted .blank?
	
    @total_defaulted_patients = @patient_id_defaulted.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, ftc.hiv_program_state FROM flat_cohort_table ftc
                                            WHERE ftc.hiv_program_state = 'On antiretrovirals'
                                            AND ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.patient_id NOT IN (#{@total_defaulted_patients})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def total_on_art(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    patients =  []
    
    @patients_alive_and_on_art = total_patients_alive_and_on_art(nil,end_date)
		@patients_alive_and_on_art = [] if @patients_alive_and_on_art.blank?
    
    patients = @patients_alive_and_on_art
    
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_1st_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Patient died'
                AND DATEDIFF(ftc.hiv_program_start_date, ftc.earliest_start_date) BETWEEN 0 AND 30.4375
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_2nd_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Patient died'
                AND DATEDIFF(ftc.hiv_program_start_date, ftc.earliest_start_date) BETWEEN 30.4375 AND 60.875
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_3rd_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Patient died'
                AND DATEDIFF(ftc.hiv_program_start_date, ftc.earliest_start_date) BETWEEN 60.875 AND 91.3125
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_after_3rd_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Patient died'
                AND DATEDIFF(ftc.hiv_program_start_date, ftc.earliest_start_date) BETWEEN 91.3125 AND 1000000
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def total_patients_died(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Patient died'
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def died_total(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = total_patients_died(nil,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def total_defaulted_patients(start_date=Time.now, end_date=Time.now, section=nil)
    #to be modified
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id, ftc.hiv_program_state, ftc.drug_auto_expire_date1, ftc.drug_auto_expire_date2, ftc.drug_auto_expire_date3, ftc.drug_auto_expire_date4, ftc.drug_auto_expire_date5
                              FROM flat_cohort_table ftc
                              WHERE ftc.hiv_program_state NOT IN ('Patient died','Treatment stopped','Patient transferred out')
                              AND ftc.earliest_start_date <= '#{end_date}'
                              AND (DATEDIFF('#{end_date}', ftc.drug_auto_expire_date1) > 56 OR 
                                   DATEDIFF('#{end_date}', ftc.drug_auto_expire_date2) > 56 OR
                                   DATEDIFF('#{end_date}', ftc.drug_auto_expire_date3) > 56 OR
                                   DATEDIFF('#{end_date}', ftc.drug_auto_expire_date4) > 56 OR
                                   DATEDIFF('#{end_date}', ftc.drug_auto_expire_date5) > 56 ) 
                              GROUP BY ftc.patient_id").each do |patient|
                                                        value << patient.patient_id
                              end
    return value
  end
  
  def defaulted(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    patients =  []
    
    total_defaulted_patients(nil,end_date).each do |patient|  
      patients << patient
    end
    
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def patients_stopped_treatment(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Treatment stopped'
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end
  
  def stopped(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = patients_stopped_treatment(nil,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def patients_transfered_out(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                WHERE ftc.earliest_start_date <= '#{end_date}'
                AND ftc.hiv_program_state = 'Patient transferred out'
                GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
  end

  def transfered(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = patients_transfered_out(nil,end_date)

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def unknown_outcome(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    #to be polished
    @total_registered = cum_total_patients_reg(nil,end_date)
		@patients_alive_and_on_art = total_patients_alive_and_on_art(nil,end_date)
		@dafaulted = total_defaulted_patients(nil,end_date)
		@died_total = total_patients_died(nil,end_date)
		@stopped_taking_arvs = patients_stopped_treatment(nil,end_date)
		@tranferred_out = patients_transfered_out(nil,end_date)

    patients = @patients_alive_and_on_art.to_a - (@total_registered.to_a + @dafaulted.to_a + @died_total.to_a + @stopped_taking_arvs.to_a + @tranferred_out.to_a )

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n1a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '1A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n1p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')
    
    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '1P'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n2a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '2A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n2p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '2P'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n3a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '3A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n3p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '3P'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n4a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '4A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n4p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '4P'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n5a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '5A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n6a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '6A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n7a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '7A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n8a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '8A'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n9p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = '9P'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def non_std(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT DISTINCT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.regimen_category = 'Unknown'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id ORDER BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def tb_no_suspect(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.tb_not_suspected = 'TB NOT suspected'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def tb_suspected(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')
    
    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.tb_suspected = 'TB suspected'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def tb_confirm_not_treat(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.confirmed_tb_not_on_treatment = 'Confirmed TB NOT on treatment'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def tb_confirmed(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')
    
    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.confirmed_tb_on_treatment = 'Confirmed TB on treatment'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def unknown_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND ftc.unknown_tb_status = 'Unknown'
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def side_effects(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art(@@first_registration_date,end_date)
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                            WHERE ftc.earliest_start_date <= '#{end_date}'
                                            AND (ftc.drug_induced_peripheral_neuropathy = 'Peripheral neuropathy'
                                                  OR ftc.drug_induced_leg_pain_numbness = 'Leg pain / numbness'
                                                  OR ftc.drug_induced_hepatitis = 'Hepatitis'
                                                  OR ftc.drug_induced_skin_rash = 'Skin rash'
                                                  OR ftc.drug_induced_jaundice = 'Jaundice')
                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                            GROUP BY ftc.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def missed_0_6(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')

    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                              WHERE ftc.earliest_start_date <= '#{end_date}'
                                              AND ((ftc.what_was_the_patient_adherence_for_this_drug1 BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug2 BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug3 BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug4 BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug5 BETWEEN 95 AND 105))
	                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                              GROUP BY ftc.patient_id").collect{|p| p.patient_id}
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def missed_7plus(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    @patients_alive_and_on_art ||= total_patients_alive_and_on_art
		@patient_id_on_art_and_alive = @patients_alive_and_on_art
		@patient_id_on_art_and_alive = [0] if @patient_id_on_art_and_alive.blank?
		
		@total_patients_alive_and_on_art = @patient_id_on_art_and_alive.join(',')
    
    patients = FlatCohortTable.find_by_sql("SELECT ftc.patient_id FROM flat_cohort_table ftc 
                                              WHERE ftc.earliest_start_date <= '#{end_date}'
                                              AND ((ftc.what_was_the_patient_adherence_for_this_drug1 NOT BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug2 NOT BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug3 NOT BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug4 NOT BETWEEN 95 AND 105) OR
	                                                 (ftc.what_was_the_patient_adherence_for_this_drug5 NOT BETWEEN 95 AND 105))
	                                            AND ftc.patient_id IN (#{@total_patients_alive_and_on_art})
                                              GROUP BY ftc.patient_id").collect{|p| p.patient_id}
 
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  # End cohort queries

  def cohort_field
    if params["field"]

      if params["start_date"]
        start_date = params["start_date"]
      else
        start_date = Time.now.strftime("%Y-%m-%d")
      end
      if params["end_date"]
        end_date = params["end_date"]
      else
        end_date = Time.now.strftime("%Y-%m-%d")
      end

      case params["field"]
      when "new_total_reg"
        new_total_reg(start_date, end_date, params["field"])
      when "cum_total_reg"
        cum_total_reg(start_date, end_date, params["field"])
      when "new_ft"
        new_ft(start_date, end_date, params["field"])
      when "cum_ft"
        cum_ft(start_date, end_date, params["field"])
      when "new_re"
        new_re(start_date, end_date, params["field"])
      when "cum_re"
        cum_re(start_date, end_date, params["field"])
      when "new_ti"
        new_ti(start_date, end_date, params["field"])
      when "cum_ti"
        cum_ti(start_date, end_date, params["field"])
      when "new_males"
        new_males(start_date, end_date, params["field"])
      when "cum_males"
        cum_males(start_date, end_date, params["field"])
      when "new_non_preg"
        new_non_preg(start_date, end_date, params["field"])
      when "cum_non_preg"
        cum_non_preg(start_date, end_date, params["field"])
      when "new_preg_all_age"
        new_preg_all_age(start_date, end_date, params["field"])
      when "cum_preg_all_age"
        cum_preg_all_age(start_date, end_date, params["field"])
      when "new_a"
        new_a(start_date, end_date, params["field"])
      when "cum_a"
        cum_a(start_date, end_date, params["field"])
      when "new_b"
        new_b(start_date, end_date, params["field"])
      when "cum_b"
        cum_b(start_date, end_date, params["field"])
      when "new_c"
        new_c(start_date, end_date, params["field"])
      when "cum_c"
        cum_c(start_date, end_date, params["field"])
      when "new_unk_age"
        new_unk_age(start_date, end_date, params["field"])
      when "cum_unk_age"
        cum_unk_age(start_date, end_date, params["field"])
      when "new_pres_hiv"
        new_pres_hiv(start_date, end_date, params["field"])
      when "cum_pres_hiv"
        cum_pres_hiv(start_date, end_date, params["field"])
      when "new_conf_hiv"
        new_conf_hiv(start_date, end_date, params["field"])
      when "cum_conf_hiv"
        cum_conf_hiv(start_date, end_date, params["field"])
      when "new_who_1_2"
        new_who_1_2(start_date, end_date, params["field"])
      when "cum_who_1_2"
        cum_who_1_2(start_date, end_date, params["field"])
      when "new_who_2"
        new_who_2(start_date, end_date, params["field"])
      when "cum_who_2"
        cum_who_2(start_date, end_date, params["field"])
      when "new_children"
        new_children(start_date, end_date, params["field"])
      when "cum_children"
        cum_children(start_date, end_date, params["field"])
      when "new_breastfeed"
        new_breastfeed(start_date, end_date, params["field"])
      when "cum_breastfeed"
        cum_breastfeed(start_date, end_date, params["field"])
      when "new_preg"
        new_preg(start_date, end_date, params["field"])
      when "cum_preg"
        cum_preg(start_date, end_date, params["field"])
      when "new_who_3"
        new_who_3(start_date, end_date, params["field"])
      when "cum_who_3"
        cum_who_3(start_date, end_date, params["field"])
      when "new_who_4"
        new_who_4(start_date, end_date, params["field"])
      when "cum_who_4"
        cum_who_4(start_date, end_date, params["field"])
      when "new_other_reason"
        new_other_reason(start_date, end_date, params["field"])
      when "cum_other_reason"
        cum_other_reason(start_date, end_date, params["field"])
      when "new_no_tb"
        new_no_tb(start_date, end_date, params["field"])
      when "cum_no_tb"
        cum_no_tb(start_date, end_date, params["field"])
      when "new_tb_w2yrs"
        new_tb_w2yrs(start_date, end_date, params["field"])
      when "cum_tb_w2yrs"
        cum_tb_w2yrs(start_date, end_date, params["field"])
      when "new_current_tb"
        new_current_tb(start_date, end_date, params["field"])
      when "cum_current_tb"
        cum_current_tb(start_date, end_date, params["field"])
      when "new_ks"
        new_ks(start_date, end_date, params["field"])
      when "cum_ks"
        cum_ks(start_date, end_date, params["field"])
      when "total_on_art"
        total_on_art(start_date, end_date, params["field"])
      when "died_1st_month"
        died_1st_month(start_date, end_date, params["field"])
      when "died_2nd_month"
        died_2nd_month(start_date, end_date, params["field"])
      when "died_3rd_month"
        died_3rd_month(start_date, end_date, params["field"])
      when "died_after_3rd_month"
        died_after_3rd_month(start_date, end_date, params["field"])
      when "died_total"
        died_total(start_date, end_date, params["field"])
      when "defaulted"
        defaulted(start_date, end_date, params["field"])
      when "stopped"
        stopped(start_date, end_date, params["field"])
      when "transfered"
        transfered(start_date, end_date, params["field"])
      when "unknown_outcome"
        unknown_outcome(start_date, end_date, params["field"])
      when "n1a"
        n1a(start_date, end_date, params["field"])
      when "n1p"
        n1p(start_date, end_date, params["field"])
      when "n2a"
        n2a(start_date, end_date, params["field"])
      when "n2p"
        n2p(start_date, end_date, params["field"])
      when "n3a"
        n3a(start_date, end_date, params["field"])
      when "n3p"
        n3p(start_date, end_date, params["field"])
      when "n4a"
        n4a(start_date, end_date, params["field"])
      when "n4p"
        n4p(start_date, end_date, params["field"])
      when "n5a"
        n5a(start_date, end_date, params["field"])
      when "n6a"
        n6a(start_date, end_date, params["field"])
      when "n7a"
        n7a(start_date, end_date, params["field"])
      when "n8a"
        n8a(start_date, end_date, params["field"])
      when "n9p"
        n9p(start_date, end_date, params["field"])
      when "non_std"
        non_std(start_date, end_date, params["field"])
      when "tb_no_suspect"
        tb_no_suspect(start_date, end_date, params["field"])
      when "tb_suspected"
        tb_suspected(start_date, end_date, params["field"])
      when "tb_confirm_not_treat"
        tb_confirm_not_treat(start_date, end_date, params["field"])
      when "tb_confirmed"
        tb_confirmed(start_date, end_date, params["field"])
      when "unknown_tb"
        unknown_tb(start_date, end_date, params["field"])
      when "current_site"
        current_site
      when "quarter"
        quarter(start_date, end_date, params["field"])
      when "side_effects"
        side_effects(start_date, end_date, params["field"])
      when "missed_0_6"
        missed_0_6(start_date, end_date, params["field"])
      when "missed_7plus"
        missed_7plus(start_date, end_date, params["field"])
      else
        reply(params["field"])
      end
    end
  end

end
