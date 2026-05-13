;*****************************************************************************
; Author: Felix McGowan
; Date: 5/1/2026
; Revision: 1.0
;
; Description:
;   This is my final project, a repeating calculator 
; 
; Notes:
;   
;
; Register Usage:
; R0 Strings and temp variables
; R1 User input A
; R2 user input B / digit counter
; R3 loop counters / temp math storage
; R4 register for calculations
; R5 control flags
; R6 Calculation result
; R7 return address for subroutines
;****************************************************************************
.ORIG x3000

ContProgram
    JSR ClearRegisters

    ;Get first number
    LEA R0, prompt1
    PUTS
    JSR ReadInput
    ADD R1, R0, #0    

    ;Power check
    LEA R0, prompt4
    PUTS
    GETC
    OUT
    ADD R0, R0, #-16
    ADD R0, R0, #-16
    ADD R0, R0, #-16  
    BRz SetupPower    

    ;Get second number
    LEA R0, prompt2
    PUTS
    JSR ReadInput
    ADD R2, R0, #0   
    
    GETC
    ;Get operator
    LEA R0, prompt3
    PUTS
    GETC
    OUT               
    
    ;Pointer to bypass the 9-bit offset error
    LD R5, PtrToAddCheck  

    LDR R3, R5, #0    ; '+'
    ADD R4, R0, R3
    BRz addProblem
    LDR R3, R5, #1    ; '-'
    ADD R4, R0, R3
    BRz subProblem
    LDR R3, R5, #2    ; '*'
    ADD R4, R0, R3
    BRz multProblem
    LDR R3, R5, #3    ; '/'
    ADD R4, R0, R3
    BRz divProblem
    BRnzp ContProgram 

SetupPower
    LEA R0, prompt5   
    PUTS
    JSR ReadInput
    ADD R2, R0, #0    
    BRnzp powerProblem

PtrToAddCheck .FILL addCheck
Neg100        .FILL #-100
Pos100        .FILL #100
Neg10         .FILL #-10
Pos10         .FILL #10
SaveR1_R      .FILL #0

; *************************************************************************
; MATH OPERATIONS
; *************************************************************************

;*************************************************************************
; Description: If user wants to raise to a power, uses nested loops to
;              perform multiple multiplications
; 
; Register Usage:
; R1 - Base value
; R2 - Exponent value
; R3 - Outer loop counter (Exponent)
; R4 - Intermediate multiplication sum
; R5 - Inner loop counter (Base)
; R6 - Resulting value (Product)
;*************************************************************************
powerProblem
    AND R6, R6, #0
    ADD R6, R6, #1    
    ADD R3, R2, #0    
    BRz probComplete  
OuterPower
    AND R4, R4, #0    
    ADD R5, R1, #0    
InnerPower
    ADD R4, R4, R6    
    ADD R5, R5, #-1
    BRp InnerPower
    ADD R6, R4, #0    
    ADD R3, R3, #-1   
    BRp OuterPower
    BRnzp probComplete
    

;*************************************************************************
; Description: Adds the two numbers given by the user and returns
; 
; 
; Register Usage:
; R1 - First added
; R2 - Second added
; R6 - Resulting sum
;*************************************************************************
addProblem    
    ADD R6, R1, R2
    BRnzp probComplete


;*************************************************************************
; Description: Sets one user input to negative and adds it to the other
;              input.
; 
; Register Usage:
; R1 - Input to subtract
; R2 - Input to subtract
; R3 - Temporary storage for negative R2
; R6 - Resulting difference
;*************************************************************************
subProblem    
    NOT R3, R2
    ADD R3, R3, #1    
    ADD R6, R1, R3    
    BRnzp probComplete


;*************************************************************************
; Description: Calculates the product of the two inputs by repeated
;              addition.
; 
; Register Usage:
; R1 - user input A
; R2 - user input B
; R3 - Loop counter
; R6 - Resulting product
;*************************************************************************
multProblem   
    AND R6, R6, #0
    ADD R3, R2, #0    
MultLoop      
    ADD R6, R6, R1
    ADD R3, R3, #-1
    BRp MultLoop
    BRnzp probComplete


;*************************************************************************
; Description: calculates the quotient of the two user inputs by continued
;              subtraction.
; 
; Register Usage:
; R1 - user input A
; R2 - user input B
; R3 - Remainder/Running total
; R4 - Negative divisor
; R6 - Resulting quotient
;*************************************************************************
divProblem     
    AND R6, R6, #0
    ADD R3, R1, #0     
    NOT R4, R2
    ADD R4, R4, #1
DivLoop        
    ADD R3, R3, R4
    BRn EndDiv
    
    ADD R6, R6, #1
    BRnzp DivLoop
EndDiv             
    BRnzp probComplete

; *************************************************************************
; 3-DIGIT PRINTER
; divides the result by 100s, 10s, and 1s in order to to display three
; digit numbers.
; *************************************************************************

probComplete
    LEA R0, result1
    PUTS
    
    ADD R1, R6, #0    ; R1 = The number to print
    AND R5, R5, #0    ; R5 = Flag to hide leading zeros

    ; --- Hundreds ---
    AND R2, R2, #0    ; Counter
    LD R3, Neg100
Count100
    ADD R1, R1, R3
    BRn End100
    ADD R2, R2, #1
    BRnzp Count100
End100
    LD R3, Pos100
    ADD R1, R1, R3    ; Restore remainder
    ADD R2, R2, #0    ; Check if hundreds exists
    BRz Skip100
    JSR PrintR2Digit
    ADD R5, R5, #1    ; Set flag that we printed something
Skip100

    ; --- Tens ---
    AND R2, R2, #0    ; Counter
    LD R3, Neg10
Count10
    ADD R1, R1, R3
    BRn End10
    ADD R2, R2, #1
    BRnzp Count10
End10
    LD R3, Pos10
    ADD R1, R1, R3    ; Restore remainder
    
    ADD R5, R5, #0    ; If we printed hundreds, we MUST print tens (even if 0)
    BRp ForcePrint10
    ADD R2, R2, #0    ; If no hundreds, only print if tens > 0
    BRz Skip10
ForcePrint10
    JSR PrintR2Digit
Skip10

    ; --- Ones ---
    ADD R2, R1, #0    ; The remainder is the ones digit
    JSR PrintR2Digit
    
    ; --- Continue Logic ---
    LEA R0, endStrg
    PUTS
    GETC
    OUT
    ADD R0, R0, #-16
    ADD R0, R0, #-16
    ADD R0, R0, #-16  
    BRz ContProgram
    HALT

PrintR2Digit
    ST R0, SaveR0_Temp
    ADD R0, R2, #15
    ADD R0, R0, #15
    ADD R0, R0, #15
    ADD R0, R0, #3
    OUT
    LD R0, SaveR0_Temp
    RET
SaveR0_Temp .FILL #0

; *************************************************************************
; SUBROUTINES & STRINGS
; *************************************************************************

;*************************************************************************
; Description: Reads the multi-input and converts the ASCII string to an
;              single integer value.
; 
; Register Usage:
; R0 - Character input from GETC
; R1 - integer value (Output)
; R2 - Temporary digit storage / Calculation
; R3 - Copy of R1 for multiplication
; R4 - Temporary storage for (R1 * 2)
;*************************************************************************
ReadInput
    ST R1, SaveR1_R
    AND R1, R1, #0    
ReadLoop
    GETC
    OUT
    ADD R2, R0, #-10  
    BRz ReadDone
    ADD R0, R0, #-16
    ADD R0, R0, #-16
    ADD R0, R0, #-16  
    ADD R2, R0, #0    
    ADD R3, R1, #0    
    ADD R1, R1, R1    
    ADD R4, R1, #0    
    ADD R1, R1, R1    
    ADD R1, R1, R1    
    ADD R1, R1, R4    
    ADD R1, R1, R2    
    BRnzp ReadLoop
ReadDone
    ADD R0, R1, #0
    LD R1, SaveR1_R
    RET


;*************************************************************************
; Description: Resets all integers for continued use
;              
; Register Usage:
; R1 - Reset
; R2 - Reset
; R3 - Reset
; R4 - Reset
; R5 - Reset
; R6 - Reset
;*************************************************************************
ClearRegisters
    AND R1, R1, #0
    AND R2, R2, #0
    AND R3, R3, #0
    AND R4, R4, #0
    AND R5, R5, #0
    AND R6, R6, #0
    RET


prompt1     .STRINGZ "\nInput first number: "
prompt2     .STRINGZ "\nInput second number: "
prompt3     .STRINGZ "\nInput operation (+, -, *, /): "
prompt4     .STRINGZ "\nPower? Yes = 0, No = 1: "
prompt5     .STRINGZ "\nInput exponent: "
result1     .STRINGZ "\nAnswer = "
endStrg     .STRINGZ "\nContinue? Yes = 0, No = 1: "

addCheck    .FILL #-43
subCheck    .FILL #-45
multCheck   .FILL #-42
divCheck    .FILL #-47
.END