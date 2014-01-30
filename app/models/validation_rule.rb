class ValidationRule < ActiveRecord::Base





  #........................user story 2 (Supervision tools)....................

  def self.data_consistency_checks(date = Date.today)
    data_consistency_checks = {}
    data_consistency_checks['Incomplete visits'] = self.incomplete_visits(date)
    data_consistency_checks['Dead patients with visits'] = self.dead_patients_with_visits
    data_consistency_checks['Male patients with pregnant observation'] = self.male_patients_with_pregnant_observation
    data_consistency_checks['Male patients with breastfeeding observation'] = self.male_patients_with_pregnant_observation
    data_consistency_checks['Male patients with breastfeeding as a reason for starting'] = self.male_patients_with_breastfeeding_as_a_reason_for_starting
    data_consistency_checks["Male patients with pregnant as a reason for starting"] = self.male_patients_with_pregnant_as_a_reason_for_starting
    data_consistency_checks["Patients with ARV dispensations before their ART start dates"] = self.patients_with_arv_dispensations_before_their_art_start_dates
    data_consistency_checks["Patients with missing dispensations"] = self.prescription_without_dispensation

    return data_consistency_checks
  end


  private

  def self.male_patients_with_pregnant_observation
    ValidationRule.find_by_sql("
    SELECT t.person_id FROM person t
    INNER JOIN flat_table1 t2 ON t.person_id = t2.patient_id
    INNER JOIN flat_table2 t3 ON t2.patient_id = t3.patient_id AND t.gender = 'M' 
    WHERE UCASE(t3.pregnant_yes) ='YES';").map(&:person_id)
  end

  def self.male_patients_with_breastfeeding_observation
    ValidationRule.find_by_sql("
    SELECT t.person_id FROM person t
    INNER JOIN flat_table1 t2 ON t.person_id = t2.patient_id
    INNER JOIN flat_table2 t3 ON t2.patient_id = t3.patient_id AND t.gender = 'M' 
    WHERE UCASE(t3.breastfeeding_yes) ='YES'").map(&:person_id)
  end

  def self.male_patients_with_breastfeeding_as_a_reason_for_starting
    ValidationRule.find_by_sql("
    SELECT t.person_id FROM person t
    INNER JOIN flat_table1 t2 ON t.person_id = t2.patient_id
    INNER JOIN flat_table2 t3 ON t2.patient_id = t3.patient_id AND t.gender = 'M' 
    WHERE reason_for_eligibility LIKE '%breastfeeding%';").map(&:person_id)
  end

  def self.male_patients_with_pregnant_as_a_reason_for_starting
    ValidationRule.find_by_sql("
    SELECT t.person_id FROM person t
    INNER JOIN flat_table1 t2 ON t.person_id = t2.patient_id
    INNER JOIN flat_table2 t3 ON t2.patient_id = t3.patient_id AND t.gender = 'M' 
    WHERE reason_for_eligibility LIKE '%pregnant%';").map(&:person_id)
  end

  def self.patients_with_arv_dispensations_before_their_art_start_dates
    ValidationRule.find_by_sql("
    SELECT patient_id FROM flat_table1
    WHERE earliest_start_date < date_started_art;").map(&:person_id)
  end

  def self.prescription_without_dispensation
    ValidationRule.find_by_sql("
    SELECT patient_id FROM flat_table2 
    WHERE (drug_order_id1 IS NOT NULL AND drug_quantity1 IS NULL)
    OR (drug_order_id2 IS NOT NULL AND drug_quantity2 IS NULL)
    OR (drug_order_id3 IS NOT NULL AND drug_quantity3 IS NULL)
    OR (drug_order_id4 IS NOT NULL AND drug_quantity4 IS NULL)
    OR (drug_order_id5 IS NOT NULL AND drug_quantity5 IS NULL);").map(&:patient_id)
  end

  def self.dead_patients_with_visits
    ValidationRule.find_by_sql("SELECT t.person_id FROM person t
      INNER JOIN flat_table2 t2 ON t.person_id = t2.patient_id
      WHERE t.dead = 1 AND t.death_date IS NOT NULL
      AND t.death_date < t2.visit_date
      GROUP BY t2.patient_id").map(&:person_id) 
  end

  def self.incomplete_visits(set_visit_date)
    patients_records = {}

    #This block is assign the number of a encounters a patient had on a speciefied date
    FlatTable2.find(:all,
      :select => "f.ever_received_art,flat_table2.*",
      :joins => "INNER JOIN flat_table1 f ON f.patient_id = flat_table2.patient_id",
      :conditions => ["flat_table2.visit_date = ?",set_visit_date.to_date],
      :group => "flat_table2.patient_id").each do |r|
      patients_records[r.patient_id] = 0
      patients_records[r.patient_id] += 1 unless r.tb_status_tb_not_suspected.blank?
      patients_records[r.patient_id] += 1 unless r.tb_status_tb_suspected.blank?
      patients_records[r.patient_id] += 1 unless r.tb_status_confirmed_tb_not_on_treatment.blank?
      patients_records[r.patient_id] += 1 unless r.tb_status_confirmed_tb_on_treatment.blank?
      patients_records[r.patient_id] += 1 unless r.tb_status_unknown.blank?
      patients_records[r.patient_id] += 1 unless r.patient_present_yes.blank?
      patients_records[r.patient_id] += 1 unless r.guardian_present_yes.blank?
      patients_records[r.patient_id] += 1 unless r.drug_order_id1.blank?
      patients_records[r.patient_id] += 1 unless r.drug_quantity1.blank?
      patients_records[r.patient_id] += 1 unless r.Weight.blank?
      patients_records[r.patient_id] += 1 unless r.Height.blank?
      patients_records[r.patient_id] += 1 unless r.BMI.blank?
      patients_records[r.patient_id] += 1 unless r.weight_for_height.blank?
      patients_records[r.patient_id] += 1 unless r.height_for_age.blank?
      patients_records[r.patient_id] += 1 unless r.ever_received_art.blank?
      patients_records[r.patient_id] += 1 unless r.appointment_date.blank?
      patients_records[r.patient_id] += 1 unless r.missed_hiv_drug_construct1.blank?
      patients_records[r.patient_id] += 1 unless r.amount_of_drug1_brought_to_clinic.blank?
      patients_records[r.patient_id] += 1 unless r.what_was_the_patient_adherence_for_this_drug1.blank?
      patients_records[r.patient_id] += 1 unless r.current_hiv_program_state.blank?
    end

    rules = self.rules
    incomplete_visits = []

    #This block is checking for patients with the least minimum number of encounter
    #on the set date and pushing their id to the array incomplete_visits 
    (patients_records || {}).each do |patient_id, num_of_enc|
      (rules.sort_by { |k, v| v.join.length } || {}).each do |rule, possible_enc|
        if num_of_enc < possible_enc.length
          incomplete_visits << patient_id
          break
        end
      end
    end

    return incomplete_visits
  end

  def self.rules
    rules = {}
    #a normal adult clinical visits
    rules['1'] = [
      'patient_present_yes', 'weight', 'bmi','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_not_suspected','appointment_date'
    ]

    rules['2'] = [
      'patient_present_yes', 'weight', 'bmi','missed_hiv_drug_construct1',
      'current_hiv_program_state', 'drug_quantity1', 'drug_order_id1',
      'appointment_date', 'tb_status_tb_suspected'
    ]

    rules['3'] = [
      'patient_present_yes', 'weight', 'bmi', 'missed_hiv_drug_construct1',
      'current_hiv_program_state', 'drug_quantity1', 'drug_order_id1',
      'appointment_date', 'tb_status_confirmed_tb_not_on_treatment',
      'appointment_date' 
    ]

    rules['4'] = [
      'patient_present_yes', 'weight', 'bmi', 'missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'appointment_date', 'tb_status_confirmed_tb_on_treatment',
      'appointment_date'
    ]

    rules['5'] = [
      'patient_present_yes', 'weight', 'bmi','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'appointment_date', 'tb_status_unknown','appointment_date' 
    ]
    #.................................................................

    #a normal pediatrics clinical visit
    rules['6'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_not_suspected','appointment_date', 'height_for_age'
    ]

    rules['7'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_suspected', 'appointment_date', 'height_for_age'
    ]

    rules['8'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_not_on_treatment','appointment_date', 'height_for_age'
    ]

    rules['9'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_on_treatment', 'appointment_date', 'height_for_age'
    ]

    rules['10'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_unknown','appointment_date', 'height_for_age'
    ]
    #.................................................................

    #a normal guardian clinical visit
    rules['11'] = [
      'guardian_present_yes', 'missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_not_suspected','appointment_date'
    ]

    rules['12'] = [
      'guardian_present_yes' ,'missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_suspected', 'appointment_date'
    ]

    rules['13'] = [
      'guardian_present_yes', 'missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_not_on_treatment','appointment_date'
    ]

    rules['14'] = [
      'guardian_present_yes', 'missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_on_treatment', 'appointment_date'
    ]

    rules['15'] = [
      'guardian_present_yes', 'missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_unknown','appointment_date'
    ]
    #.................................................................

    #a normal pediatrics first time clinical visit
    rules['16'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_unknown','appointment_date', 'height_for_age', 'ever_received_art'
    ]

    rules['17'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_on_treatment', 'appointment_date', 
      'height_for_age', 'ever_received_art'
    ]

    rules['18'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_not_on_treatment', 'appointment_date', 
      'height_for_age', 'ever_received_art'
    ]

    rules['19'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_suspected','appointment_date', 'height_for_age', 'ever_received_art'
    ]

    rules['20'] = [
      'patient_present_yes', 'weight_for_height','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_not_suspected', 'appointment_date', 'height_for_age', 'ever_received_art'
    ]

    #.................................................................


    #a normal adult first clinical visit
    rules['21'] = [
      'patient_present_yes', 'weight', 'bmi','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_unknown', 'appointment_date', 'ever_received_art'
    ]

    rules['22'] = [
      'patient_present_yes', 'weight', 'bmi','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_confirmed_tb_on_treatment', 'appointment_date', 'ever_received_art'
    ]

    rules['23'] = [
      'patient_present_yes', 'weight', 'bmi,missed_hiv_drug_construct1',
      'current_hiv_program_state', 'drug_quantity1', 'drug_order_id1',
      'tb_status_confirmed_tb_not_on_treatment',
      'appointment_date', 'ever_received_art'
    ]

    rules['24'] = [
      'patient_present_yes', 'weight', 'bmi', 'missed_hiv_drug_construct1',
      'current_hiv_program_state', 'drug_quantity1', 'drug_order_id1',
      'tb_status_tb_not_suspected', 'appointment_date', 'ever_received_art'
    ]

    rules['25'] = [
      'patient_present_yes', 'weight', 'bmi','missed_hiv_drug_construct1',
      'current_hiv_program_state','drug_quantity1','drug_order_id1',
      'tb_status_tb_suspected', 'appointment_date', 'ever_received_art'
    ]

    #.................................................................

    return rules
  end

end

=begin
    follow up
      - tb_status_tb_not_suspected
      - tb_status_tb_suspected
      - tb_status_confirmed_tb_not_on_treatment
      - tb_status_confirmed_tb_on_treatment
      - tb_status_unknown

    Reception
     - patient_present_yes
     - guardian_present_yes

    prescription and dispensation
     - drug_order_id1 
     - drug_quantity1 


    vitals
      - Weight
      - Height
      - BMI
      - weight_for_height
      - weight_for_age
      - height_for_age


    First visit
    - ever_received_art
    - earliest_start_date
    - date_art_last_taken
    - agrees_to_followup

    Appointment
    - appointment_date

    Adherence
    - missed_hiv_drug_construct1
    - amount_of_drug1_brought_to_clinic
    - what_was_the_patient_adherence_for_this_drug1

    Outcome
    - current_hiv_program_state
    - current_hiv_program_start_date
    
    
    tb_status_tb_not_suspected = nil
    tb_status_tb_suspected = nil
    tb_status_confirmed_tb_not_on_treatment = nil
    tb_status_confirmed_tb_on_treatment = nil
    tb_status_unknown = nil
    patient_present_yes = nil
    guardian_present_yes = nil
    drug_order_id1 = nil
    drug_quantity1 = nil
    weight = nil
    height = nil
    bmi = nil
    weight_for_height = nil
    height_for_age = nil
    ever_received_art = nil
    appointment_date = nil
    missed_hiv_drug_construct1 = nil
    amount_of_drug1_brought_to_clinic = nil
    what_was_the_patient_adherence_for_this_drug1 = nil
    current_hiv_program_state = nil


=end

