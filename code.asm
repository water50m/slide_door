; Define GPIO pins based on the 8051 architecture
P1_LOCK_BTN   EQU P1.0   ; Lock/Unlock Button
P1_OPEN_BTN   EQU P1.1   ; Open/Close Button
P2_LOCK_ACTUATOR EQU P2.0 ; Lock Actuator
P2_DOOR_ACTUATOR EQU P2.1 ; Door Actuator

; Define UART pins for ESP8266 communication
UART_RX     EQU P3.0    ; RXD for ESP8266
UART_TX     EQU P3.1    ; TXD for ESP8266

; Main program start
START:
    ; Initialize UART for communication with ESP8266
    MOV SCON, #50H          ; 8-bit UART, variable baud rate
    MOV TMOD, #20H          ; Timer 1, mode 2 (auto-reload)
    MOV TH1, #0FDH          ; Set baud rate to 9600 (for 11.0592 MHz)
    SETB TR1                ; Start Timer 1

    ; Initialize system
    MOV STATE, 0x00       ; Start with the door locked state

MAIN_LOOP:
    ; Read the current button states
    MOV A, P1_LOCK_BTN    ; Read Lock/Unlock Button (P1.0)
    ANL A, #01H           ; Mask to get only the button state
    MOV R0, A             ; Store button state in R0

    MOV A, P1_OPEN_BTN    ; Read Open/Close Button (P1.1)
    ANL A, #01H           ; Mask to get only the button state
    MOV R1, A             ; Store button state in R1

    ; Check the current door state
    MOV A, STATE          ; Load current state into accumulator

    ; State handling
    CJNE A, #0x00, CHECK_UNLOCKED ; If state is not "Door Locked", check unlocked
    ; If locked, check unlock button
    JB P1_LOCK_BTN, DOOR_LOCKED   ; If unlock button is pressed, go to DOOR_LOCKED
    SJMP MAIN_LOOP         ; Repeat loop if no transition

CHECK_UNLOCKED:
    CJNE A, #0x01, CHECK_OPENING ; If state is not "Door Unlocked", check opening
    ; If unlocked, check open button
    JB P1_OPEN_BTN, DOOR_UNLOCKED ; If open button is pressed, go to DOOR_UNLOCKED
    JB P1_LOCK_BTN, LOCK_DOOR      ; If lock button is pressed, lock the door
    SJMP MAIN_LOOP         ; Repeat loop if no transition


CHECK_OPENING:
    CJNE A, #0x02, CHECK_OPEN ; If state is not "Door Opening", check open
    ; If opening, wait for completion
    CALL WAIT_ROUTINE       ; Wait for door to fully open
    MOV STATE, #0x03       ; Change state to Door Open
    SJMP MAIN_LOOP

CHECK_OPEN:
    CJNE A, #0x03, CHECK_CLOSING ; If state is not "Door Open", check closing
    ; If open, check close button
    JB P1_OPEN_BTN, CLOSE_DOOR ; If close button is pressed, close the door
    SJMP MAIN_LOOP

CHECK_CLOSING:
    CJNE A, #0x04, CHECK_CLOSED ; If state is not "Door Closing", check closed
    ; If closing, wait for completion
    CALL WAIT_ROUTINE       ; Wait for door to fully close
    MOV STATE, #0x05       ; Change state to Door Close
    SJMP MAIN_LOOP

CHECK_CLOSED:
    CJNE A, #0x05, DOOR_LOCKED ; If state is not "Door Close", check lock
    ; If closed, check lock button
    JB P1_LOCK_BTN, LOCK_DOOR   ; If lock button is pressed, lock the door
    SJMP MAIN_LOOP         ; Repeat loop if no transition

; Handling commands from ESP8266
RECEIVE_COMMAND:
    MOV A, UART_RX        ; Read command from ESP8266
    ANL A, #0x01          ; Mask to get only the least significant bit
    CJNE A, #0, HANDLE_COMMAND ; If there's a command, handle it
    SJMP MAIN_LOOP

HANDLE_COMMAND:
    ; Implement command handling based on the command received
    ; Example: 0x55 - Unlock, 0xAA - Lock, 0x66 - Open, 0x99 - Close
    MOV A, UART_RX        ; Read the command from RXD
    CJNE A, #0x55, CHECK_LOCK
    ; Unlock the door
    MOV P2_LOCK_ACTUATOR, #0x00 ; Send unlock signal to actuator (P2.0)
    MOV STATE, #0x01       ; Change state to Door Unlocked
    SJMP MAIN_LOOP

CHECK_LOCK:
    CJNE A, #0xAA, CHECK_OPEN_CMD
    ; Lock the door
    MOV P2_LOCK_ACTUATOR, #0x01 ; Send lock signal to actuator (P2.0)
    MOV STATE, #0x00       ; Change state to Door Locked
    SJMP MAIN_LOOP

CHECK_OPEN_CMD:
    CJNE A, #0x66, CHECK_CLOSE_CMD
    ; Start opening the door
    MOV P2_DOOR_ACTUATOR, #0x01 ; Send open signal to actuator (P2.1)
    MOV STATE, #0x02       ; Change state to Door Opening
    SJMP MAIN_LOOP

CHECK_CLOSE_CMD:
    CJNE A, #0x99, MAIN_LOOP
    ; Start closing the door
    MOV P2_DOOR_ACTUATOR, #0x00 ; Send close signal to actuator (P2.1)
    MOV STATE, #0x04       ; Change state to Door Closing
    SJMP MAIN_LOOP

DOOR_LOCKED:
    ; If door is locked, check for unlock button
    JB P1_LOCK_BTN, UNLOCK_DOOR
    SJMP MAIN_LOOP

DOOR_UNLOCKED:
    ; If door is unlocked, check for open button
    JB P1_OPEN_BTN, OPEN_DOOR
    ; Check lock button to lock the door again
    JB P1_LOCK_BTN, LOCK_DOOR
    SJMP MAIN_LOOP

UNLOCK_DOOR:
    ; Unlocking the door
    MOV P2_LOCK_ACTUATOR, #0x00 ; Send unlock signal to actuator (P2.0)
    MOV STATE, #0x01       ; Change state to Door Unlocked
    SJMP MAIN_LOOP

LOCK_DOOR:
    ; Locking the door
    MOV P2_LOCK_ACTUATOR, #0x01 ; Send lock signal to actuator (P2.0)
    MOV STATE, #0x00       ; Change state to Door Locked
    SJMP MAIN_LOOP

OPEN_DOOR:
    ; Start opening the door
    MOV P2_DOOR_ACTUATOR, #0x01 ; Send open signal to actuator (P2.1)
    MOV STATE, #0x02       ; Change state to Door Opening
    SJMP MAIN_LOOP

CLOSE_DOOR:
    ; Start closing the door
    MOV P2_DOOR_ACTUATOR, #0x00 ; Send close signal to actuator (P2.1)
    MOV STATE, #0x04       ; Change state to Door Closing
    SJMP MAIN_LOOP

WAIT_ROUTINE:
    ; Simulate a delay for door to open/close (can use a timer here)
    NOP                    ; No operation (for simplicity, real delay needed)
    NOP
    NOP
    RET                    ; Return to the main program
