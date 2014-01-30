class ValidationRule < ActiveRecord::Base





  #........................user story 2 (Supervision tools)....................

  def self.data_consistency_checks
    return self.incomplete_visits
  end


  private

  def self.dead_patients_with_visits
    
  end

  def self.incomplete_visits
    patients_records = {}
    FlatTable2.find(:all,
      :select => "f.ever_received_art,flat_table2.*",
      :joins => "INNER JOIN flat_table1 f ON f.patient_id = flat_table2.patient_id",
      :conditions => ["flat_table2.visit_date = ?",'2013-01-01'],
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
      'patient_present_yes', weight_for_height,missed_hiv_drug_construct1,
      current_hiv_program_state,drug_quantity1,drug_order_id1,
      tb_status_tb_suspected,appointment_date, height_for_age, ever_received_art'
    ]

    rules['20'] = [
      'patient_present_yes, weight_for_height,missed_hiv_drug_construct1,
      current_hiv_program_state,drug_quantity1,drug_order_id1,
      tb_status_tb_not_suspected, appointment_date, 
      height_for_age, ever_received_art'
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

