DROP FUNCTION IF EXISTS age_in_months;

DROP FUNCTION IF EXISTS age_in_months;                                          
                                                                                
DELIMITER $$                                                                     
CREATE FUNCTION age_in_months(birthdate varchar(10),visist_date varchar(10)) RETURNS INT
BEGIN                                                                           
                                                                                
DECLARE person_age_in_months INT;                                                          

DECLARE birth_month INT;                                                        
DECLARE birth_day INT;                                                          
DECLARE birth_year INT;                                                          
DECLARE years INT;                                                          
DECLARE months INT;                                                          
                                                                                
DECLARE cur_month INT;                                                          
DECLARE cur_year INT;                                                           
                                                                                
SET birth_month = (SELECT MONTH(FROM_DAYS(TO_DAYS(birthdate))));                
SET birth_day = (SELECT DAY(FROM_DAYS(TO_DAYS(birthdate))));                    
SET birth_year = (SELECT YEAR(FROM_DAYS(TO_DAYS(birthdate))));                    
                                                                                
SET cur_month = (SELECT MONTH(DATE(visist_date)));                                      
SET cur_year = (SELECT YEAR(DATE(visist_date)));                                      
                                                                                
SET years = (cur_year - birth_year);                                
SET months = (cur_month - birth_month);                            
SET person_age_in_months = ((years * 12) + months);  


RETURN person_age_in_months;
END$$                                                                           
DELIMITER ;
