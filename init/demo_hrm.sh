#!/bin/bash
# =============================================================
#  demo_hrm.sh — Kịch bản chạy Demo luồng Realtime HRM
#
#  Kịch bản này sẽ liên tục giả lập hành vi của nhân viên để tạo 
#  ra dòng dữ liệu mới chèn vào MySQL (INSERT/UPDATE).
#  
#  Bạn có thể nhìn thấy dữ liệu này chảy ngang qua Flink UI và 
#  mở Trino / Superset ra truy vấn và thấy nó thay đổi liên tục.
# =============================================================

echo "================================================="
echo "   KỊCH BẢN GIẢ LẬP NHÂN SỰ REALTIME (DEMO)"
echo "   (Nhấn Ctrl+C để dừng kịch bản)"
echo "================================================="
echo ""

# Đếm số lượng transaction
COUNT=1

while true; do
  # Random một nhân viên từ 1 đến 10
  EMP_ID=$(( ( RANDOM % 10 )  + 1 ))
  
  # Random hành động (1: Check-in, 2: Check-out, 3: Đăng ký nghỉ, 4: Sửa lương)
  ACTION=$(( ( RANDOM % 4 )  + 1 ))
  
  CURRENT_TIME=$(date "+%Y-%m-%d %H:%M:%S")
  
  echo "[$COUNT] Thời gian: $CURRENT_TIME | Thực hiện hành động số $ACTION cho nhân viên EMP_ID: $EMP_ID..."
  
  case $ACTION in
    1)
      # Giả lập Check-in (có thể muộn hoặc đúng giờ)
      STATUS=("ON_TIME" "LATE")
      RAND_STATUS=${STATUS[$((RANDOM % 2))]}
      
      docker exec -i mysql mysql -uroot -p123 -e "
        USE hrm;
        INSERT INTO attendance (emp_id, check_in, status) 
        VALUES ($EMP_ID, '$CURRENT_TIME', '$RAND_STATUS');
      "
      echo "   👉 [CHẤM CÔNG] Nhân viên $EMP_ID vừa Check-in ($RAND_STATUS)."
      ;;
      
    2)
      # Giả lập Check-out (sửa log cũ nhất trong ngày chưa check-out, hoặc random)
      docker exec -i mysql mysql -uroot -p123 -e "
        USE hrm;
        UPDATE attendance 
        SET check_out = '$CURRENT_TIME' 
        WHERE emp_id = $EMP_ID AND check_out IS NULL 
        ORDER BY id DESC LIMIT 1;
      "
      echo "   👉 [CHẤM CÔNG] Nhân viên $EMP_ID vừa Check-out ra về."
      ;;
      
    3)
      # Giả lập gửi đơn nghỉ phép mới
      LEAVE_TYPES=("annual" "sick" "unpaid")
      RAND_LEAVE=${LEAVE_TYPES[$((RANDOM % 3))]}
      
      docker exec -i mysql mysql -uroot -p123 -e "
        USE hrm;
        INSERT INTO leave_requests (emp_id, leave_type, start_date, end_date, days, status, reason)
        VALUES ($EMP_ID, '$RAND_LEAVE', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY), 1, 'pending', 'Viec dot xuat realtime');
      "
      echo "   👉 [XIN NGHỈ VẮNG] Nhân viên $EMP_ID vừa nộp đơn nghỉ phép ($RAND_LEAVE)."
      ;;
      
    4)
      # Giả lập được thưởng nóng hoặc tăng lương để thấy bảng Payroll thay đổi
      BONUS=$(( 500000 + (RANDOM % 1500000) ))
      
      docker exec -i mysql mysql -uroot -p123 -e "
        USE hrm;
        UPDATE payroll 
        SET bonus = bonus + $BONUS, 
            net_salary = net_salary + $BONUS 
        WHERE emp_id = $EMP_ID AND month = '2026-04';
      "
      echo "   👉 [THƯỞNG LƯƠNG] Nhân viên $EMP_ID vừa được thưởng nóng: $BONUS VNĐ."
      ;;
  esac

  echo "-------------------------------------------------"
  COUNT=$((COUNT + 1))
  
  # Nghỉ 4 giây trước khi có sự kiện tiếp theo (cho giống thực tế nhưng đủ nhanh để demo)
  sleep 4
done
