;0 = close,lock
;1 = open,unlock
;door close,unlock state 

Readystate:
    mov r0,#01H ;r0 = state1
    mov r1,#01H
    clr P1.2 ; disable ic ที่ควบคุมมอเตอร์ 
    JNB P0.1,Lock_state_close ;ถ้าบิทเป็น 0 ให้ไป state lock
    JB P0.0,Opening_State ;press open at smart phone
    JB P0.2,Opening_State ;press outside button
    JB P0.3,Opening_State ;press inside button
    sjmp Readystate

;input1,P1.1 
;input2,P1.2 
;กำหนดให้ input เหมือนกันคือเปิดประตู ต่างกันคือปิดประตู
;limit switch ค่าจะเป็น 0 เมื่อ switch ถูกกด
;ประตูเปิดอยู่ P1.3 จะเป็น 1 ,P1.4 จะถูดกดและเป็น 0
;ใช้ limit swith แบบ NC
Opening_State:
    mov r0,#02H ;r0 = state2
    clr P1.0
    clr P1.1 ;P1.0 และ P1.1 ถูกเซ็ตให้ค่าเป็น 0 เหมือนกันทำให้ มอเตอร์หมุนเปิด
    setb P1.2 ; enable ic ที่ควบคุมมอเตอร์ 
    mov r2, P1.3 ; นำค่าจาก limit switch มาเก็บที่ r2
    JNB r2,openedState ;ถ้าค่าที่ได้เป็น 0 ให้จั้มไปที่ openedState
    SJMP Opening_State ;รอประตูเปิดเสร็จ

Lock_state_close:
    mov r0,#00H ;r0 = state0
    JB P0.2,Opening_state;ถ้ากดปุ่มด้านใน ให้เปิดโดยไม่ต้อง unlock
    JB P0.1,Readystate ;ถ้าได้รับสัญญาณ unlock ให้ jump ไปที่ Readystate
    SJMP Lock_state_close

openedState:
    mov r0,#04H ;r0 = state4
    clr P1.2 ; disable ic ที่ควบคุมมอเตอร์ 
    JNB P0.1,Lock_state_open ;ถ้าบิทเป็น 0 ให้ไป state lock
    JB P0.0,Closing_State ;press close at smart phone
    JB P0.2,Closing_State ;press outside button
    JB P0.3,Closing_State ;press inside button
    SJMP openedState ;ลูปรอคำสั่ง

Lock_state_open:
    mov r0,#05H ;r0 = state5
    JB P0.1,openedState ;ถ้าได้รับสัญญาณ unlock ให้จั๊มไปที่ Readystate
    SJMP Lock_state_open ;ลูปรอคำสั่ง


Closing_state:
    mov r0,#03H ;r0 = state3
    clr P1.0
    setb P1.1 ;P1.0 และ P1.1 ถูกเซ็ตให้ค่าเป็น 0 และ 1 ซึ่งจะได้ค่าต่างกันทำให้ มอเตอร์หมุนปิด
    setb P1.2 ; enable ic ที่ควบคุมมอเตอร์ 
    mov r2, P1.4 ; นำค่าจาก limit switch มาเก็บที่ r2
    JNB r2,Readystate ;ถ้าค่าที่ได้เป็น 0 ให้จั้มไปที่ openedState
    SJMP Opening_State ;รอประตูเปิดเสร็จ