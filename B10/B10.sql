-- 2
DELIMITER &&

CREATE PROCEDURE GetDoctorDetails (
    IN input_doctor_id INT
)
BEGIN
    SELECT 
        d.name AS doctor_name,
        d.specialization,
        COUNT(DISTINCT a.patient_id) AS total_patients,
        COUNT(a.appointment_id) AS total_appointments,
        COUNT(p.prescription_id) AS total_medicines_prescribed
    FROM doctors d
    JOIN appointments a ON d.doctor_id = a.doctor_id
    JOIN prescriptions p ON a.appointment_id = p.appointment_id
    WHERE d.doctor_id = input_doctor_id
    GROUP BY d.doctor_id, d.name, d.specialization;
END &&

DELIMITER &&;

-- 3
CREATE TABLE cancellation_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    log_message VARCHAR(255),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
-- 4
CREATE TABLE appointment_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    log_message VARCHAR(255),
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);


-- 5
DELIMITER &&

CREATE TRIGGER after_appointment_delete
AFTER DELETE ON appointments
FOR EACH ROW
BEGIN
    -- Xóa các đơn thuốc liên quan đến cuộc hẹn bị xóa
    DELETE FROM prescriptions WHERE appointment_id = OLD.appointment_id;

    -- Nếu cuộc hẹn bị hủy, ghi log vào bảng cancellation_logs
    IF OLD.status = 'Cancelled' THEN
        INSERT INTO cancellation_logs (appointment_id, log_message)
        VALUES (OLD.appointment_id, 'Cancelled appointment was deleted');
    END IF;

    -- Nếu cuộc hẹn đã hoàn thành, ghi log vào bảng appointment_logs
    IF OLD.status = 'Completed' THEN
        INSERT INTO appointment_logs (appointment_id, log_message)
        VALUES (OLD.appointment_id, 'Completed appointment was deleted');
    END IF;
END &&

DELIMITER &&;



-- 6
CREATE VIEW FullRevenueReport AS
SELECT 
    d.doctor_id,
    d.name AS doctor_name,
    COUNT(a.appointment_id) AS total_appointment,
    COUNT(DISTINCT a.patient_id) AS total_patient,
    SUM(d.salary) AS total_revenue,
    COUNT(p.prescription_id) AS total_medicine
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
LEFT JOIN prescriptions p ON a.appointment_id = p.appointment_id
GROUP BY d.doctor_id, d.name;



-- 7
CALL GetDoctorDetails(1); 

-- 8
DELETE FROM appointments WHERE appointment_id = 3;

DELETE FROM appointments WHERE appointment_id = 1;


-- 9
SELECT * FROM FullRevenueReport;