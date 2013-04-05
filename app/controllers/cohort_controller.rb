
class CohortController < ActionController::Base

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

  def new_total_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1 
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}
    
    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_total_reg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1 
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_ft(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = t1.patient_id 
      WHERE t1.regimen_category IS NOT NULL 
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2 
                           WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' 
      AND ft1.ever_registered_at_art_clinic = 'No' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_ft(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')        
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
                           WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date <= '#{end_date}' 
      AND ft1.ever_registered_at_art_clinic = 'No' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_re(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = t1.patient_id 
      WHERE t1.regimen_category IS NOT NULL 
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2 
                           WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' 
      AND (DATEDIFF(ft1.date_created,ft1.date_art_last_taken) > 60)
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_re(start_date=Time.now, end_date=Time.now, section=nil)
    value = 0
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
                           WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' 
      AND (DATEDIFF(date_created,ft1.date_art_last_taken) > 60)
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_ti(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = t1.patient_id 
      WHERE t1.regimen_category IS NOT NULL 
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2 
                           WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' 
      AND ft1.ever_registered_at_art_clinic = 'Yes'
      AND (DATEDIFF(date_created,ft1.date_art_last_taken) > 60) OR (ft1.taken_art_in_last_two_months = 'No')
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_ti(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 LEFT OUTER JOIN flat_table1 ft1 ON ft1.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
                           WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' 
      AND ft1.ever_registered_at_art_clinic = 'Yes'
      AND (DATEDIFF(date_created,ft1.date_art_last_taken) > 60) OR (ft1.taken_art_in_last_two_months = 'No')
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_males(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')


    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.gender = 'M'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_males(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.gender = 'M'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_non_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.gender = 'F'
      AND t1.pregnant_no IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_non_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.gender = 'F'
      AND t1.pregnant_no IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_preg_all_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.gender = 'F'
      AND t1.pregnant_yes IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_preg_all_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.gender = 'F'
      AND t1.pregnant_yes IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id, 
      age_in_months(t3.dob,'#{end_date.to_date}') AS months
      FROM flat_table2 t1 INNER JOIN flat_table1 t3 ON t3.patient_id =  t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id 
      HAVING months BETWEEN 0 AND 23").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id, 
      age_in_months(t3.dob,'#{end_date.to_date}') AS months
      FROM flat_table2 t1 INNER JOIN flat_table1 t3 ON t3.patient_id =  t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id 
      HAVING months BETWEEN 0 AND 23").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_b(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id, 
      age_in_months(t3.dob,'#{end_date.to_date}') AS months
      FROM flat_table2 t1 INNER JOIN flat_table1 t3 ON t3.patient_id =  t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id 
      HAVING months BETWEEN 24 AND 168").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_b(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id, 
      age_in_months(t3.dob,'#{end_date.to_date}') AS months
      FROM flat_table2 t1 INNER JOIN flat_table1 t3 ON t3.patient_id =  t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id 
      HAVING months BETWEEN 24 AND 168").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_c(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                        
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id, 
      age_in_months(t3.dob,'#{end_date.to_date}') AS months
      FROM flat_table2 t1 INNER JOIN flat_table1 t3 ON t3.patient_id =  t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}' 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id 
      HAVING months > 168").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_c(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id, 
      age_in_months(t3.dob,'#{end_date.to_date}') AS months
      FROM flat_table2 t1 INNER JOIN flat_table1 t3 ON t3.patient_id =  t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) 
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id 
      HAVING months > 168").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_unk_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = 0

    render :text => value
  end

  def cum_unk_age(start_date=Time.now, end_date=Time.now, section=nil)
    value = 0

    render :text => value
  end

  def new_pres_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')                            
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility LIKE '%Presumed%'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_pres_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS reason
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND reason_for_eligibility LIKE '%Presumed%'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' 
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_conf_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')
    
    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'HIV infected'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_conf_hiv(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'HIV infected'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_1_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility LIKE '%CD4%'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_1_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility LIKE '%CD4%'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Lymphocyte count below threshold with who stage 2'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_2(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Lymphocyte count below threshold with who stage 2'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_children(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND (t.reason_for_eligibility = 'WHO stage III peds' OR
           t.reason_for_eligibility = 'WHO stage IV peds')
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_children(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND (t.reason_for_eligibility = 'WHO stage III peds' OR
           t.reason_for_eligibility = 'WHO stage IV peds')
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_breastfeed(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Currently breastfeeding child'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_breastfeed(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Currently breastfeeding child'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Patient pregnant'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_preg(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Patient pregnant'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_3(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'WHO stage III adult'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_3(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'WHO stage III adult'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_who_4(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'WHO stage IV adult'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_who_4(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'WHO stage IV adult'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_other_reason(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Unknown'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_other_reason(start_date=Time.now, end_date=Time.now, section=nil)
    value = []
    
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id
      FROM flat_table2 t1 INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.reason_for_eligibility = 'Unknown'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}'
      GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_no_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND (t.pulmonary_tuberculosis = 'No'
      OR t.extrapulmonary_tuberculosis = 'No')
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_no_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND (t.pulmonary_tuberculosis = 'No'
      OR t.extrapulmonary_tuberculosis = 'No')
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_tb_w2yrs(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.pulmonary_tuberculosis_last_2_years = 'Yes'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_tb_w2yrs(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL
      AND t.pulmonary_tuberculosis_last_2_years = 'Yes'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_current_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND (t.pulmonary_tuberculosis = 'Yes'
      OR t.extrapulmonary_tuberculosis = 'Yes')
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_current_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND (t.pulmonary_tuberculosis = 'Yes'
      OR t.extrapulmonary_tuberculosis = 'Yes')
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def new_ks(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')


    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.kaposis_sarcoma = 'Yes'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def cum_ks(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      INNER JOIN flat_table1 t
      ON t.patient_id = t1.patient_id
      WHERE t1.regimen_category IS NOT NULL AND t.kaposis_sarcoma = 'Yes'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def total_on_art(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id FROM flat_table2 t1
      WHERE t1.regimen_category IS NOT NULL
      AND t1.current_hiv_program_state = 'On antiretrovirals'
      AND t1.visit_date = (SELECT MIN(t2.visit_date)
      FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id)
      AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_1st_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id FROM flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' 
        AND t1.visit_date <= '2013-03-31' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Patient died'
    AND DATEDIFF(ft2.current_hiv_program_start_date,registration_date.visit_date) BETWEEN 0 AND 30.4375
    GROUP BY ft2.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_2nd_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            

    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id FROM flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' 
        AND t1.visit_date <= '2013-03-31' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Patient died'
    AND DATEDIFF(ft2.current_hiv_program_start_date,registration_date.visit_date) BETWEEN 30.4375 AND 60.875
    GROUP BY ft2.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_3rd_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id FROM flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' 
        AND t1.visit_date <= '2013-03-31' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Patient died'
    AND DATEDIFF(ft2.current_hiv_program_start_date,registration_date.visit_date) BETWEEN 60.875 AND 91.3125
    GROUP BY ft2.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_after_3rd_month(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id FROM flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' 
        AND t1.visit_date <= '2013-03-31' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Patient died'
    AND DATEDIFF(ft2.current_hiv_program_start_date,registration_date.visit_date) BETWEEN 91.3125 AND 1000000
    GROUP BY ft2.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def died_total(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id AS patient_id FROM flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Patient died'").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end
  
  def defaulted(start_date=Time.now, end_date=Time.now, section=nil)
    value = 0

    render :text => value
  end


  def stopped(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id from flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Treatment stopped'").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def transfered(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')                            
    
    patients = FlatTable2.find_by_sql("SELECT ft2.patient_id from flat_table2 ft2
      LEFT OUTER JOIN (SELECT t1.patient_id, visit_date FROM flat_table2 t1 
        WHERE t1.regimen_category IS NOT NULL AND t1.visit_date = (SELECT MIN(t2.visit_date) 
        FROM flat_table2 t2 WHERE t2.patient_id = t1.patient_id) AND t1.visit_date <= '#{end_date}' GROUP BY t1.patient_id) AS registration_date ON registration_date.patient_id = ft2.patient_id
    WHERE registration_date.visit_date <= '#{end_date}'
    AND ft2.current_hiv_program_state = 'Patient transferred out'").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def unknown_outcome(start_date=Time.now, end_date=Time.now, section=nil)
    value = 0

    render :text => value
  end

  def n1a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '1A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n1p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '1P' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n2a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '2A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n2p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '2P' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n3a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '3A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n3p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '3P' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n4a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '4A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n4p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '4P' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n5a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '5A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n6a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '6A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n7a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '7A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n8a(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '8A' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def n9p(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = '9P' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def non_std(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    start_date = start_date.to_date.strftime('%Y-%m-%d 00:00:00')
    end_date = end_date.to_date.strftime('%Y-%m-%d 23:59:59')

    patients = FlatTable2.find_by_sql("SELECT t1.patient_id AS patient_id
      FROM flat_table2 t1 WHERE t1.regimen_category IS NOT NULL
      AND t1.visit_date = (SELECT MIN(t2.visit_date) FROM flat_table2 t2
      WHERE t2.patient_id = t1.patient_id) AND t1.visit_date >= '#{start_date}'
      AND t1.visit_date <= '#{end_date}' AND t1.regimen_category = 'Unknown' GROUP BY t1.patient_id").collect{|p| p.patient_id}

    value = patients unless patients.blank?
    render :text => value.to_json
  end

  def tb_no_suspect(start_date=Time.now, end_date=Time.now, section=nil)
    value = 0

    render :text => value
  end

  def tb_suspected(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
  end

  def tb_confirm_not_treat(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
  end

  def tb_confirmed(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
  end

  def unknown_tb(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
  end

  def side_effects(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
  end

  def missed_0_6(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
  end

  def missed_7plus(start_date=Time.now, end_date=Time.now, section=nil)
    value = []

    render :text => value
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
