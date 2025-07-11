.model small
.stack 400H
.data

; Coisas pra facilitar a vida

TARGET_POSIX EQU 1
; Criei essa variavel porque tem uma peculiaridade no terminador
; de linha que difere entre os sistemas que seguem o padrao POSIX
; e o Windows, especificamente. Sabendo disso, caso o arquivo de
; dados seja escrito no Linux/MacOS, tem que deixar esse EQU 1.
; Se for no Windows, coloca um 0.

UNSIGNED_DIVISION EQU 1
; This will turn the unsigned division operator (?) on
; and off, I created this to work around the remainder
; specs (Resto da divisao -> SIGNED OR NOT?). If it is
; unsigned, congratulations, one more op. If it is not,
; just turn the switch off.

ERASE_RESULT_EVERY_TIME EQU 0
; Will only show the final matrix

CR EQU 13
LF EQU 10
NULLCIFRAO EQU 36
NULL EQU 0
MAX_LINHAS EQU 100 ; Aqui eu to assumindo que eh 100 ne pq a gente nao aprendeu alocação dinamica de memoria
MAX_COLUNAS EQU 20

; Arquivos pra abrir
nome_arq_dados db "DADOS.TXT",NULL
nome_arq_expr db "EXP.TXT",NULL
nome_arq_res db "RESULT.TXT",NULL

handle_dados dw ?
handle_expr dw ?
handle_res dw ?

read_buffer db ? ; AQUI EH IMPORTANTE, TODA LEITURA VEM PRA CA

; Buffers de dados
buffer_linha db 140 DUP(?),NULLCIFRAO ; 20 colunas, 6 digitos no maximo em cada, 19 semicolons = 139, +1 pra deixar um '\0' no final + 1 pro caso do Windows

matriz dw 2000 DUP(?) ; MAX_LINHAS * MAX_COLUNAS,

op_source_one dw ?
op_source_two dw ?

; Mais dados
qtd_colunas dw ? ; Aqui vai a quantidade real de colunas que vao ser lidas do arquivo
qtd_linhas dw ? ; Eh bom saber a quantidade de linhas tambem

tudo_certo db "Operations done successfully!",NULLCIFRAO

error_flag db 0 ; 1-Numero de colunas errado

line_ending db CR,LF

operation db ? ; Each operation is represented by its 
               ; C op. character (e.g. & == AND)

matrix_must_be_print db 0


; Error handling data

row_counter db 0

erro_colunas db "Wrong number of columns in row: ",NULLCIFRAO
syntax_error_text db "Syntax error in line: ",NULLCIFRAO
bad_operation_error db "Unknown operation: ",NULLCIFRAO
bad_reference_error db "Invalid row: ",NULLCIFRAO

operation_or_reference_error_ending db CR,LF,"In line: ",NULLCIFRAO

; Area de testes

.code
    .startup ; MAIN FUNCTION

    problem_solved:

        LEA DX, nome_arq_res
        call create_file

        ; Read matrix
        LEA DI, matriz
        CALL read_matrix
        JC main_bad_ending
        MOV row_counter, 0

        MOV AL, 00h
        LEA DX, nome_arq_expr
        CALL open_file
        ; AX has now the expr file handle

        PUSH BP
        MOV BP, SP
        PUSH AX

    read_expressions_and_operate_loop:

        MOV AX, [BP - 2]

        CALL read_row
        JC main_good_ending

        CALL expression_parser
        JC main_bad_ending

        INC row_counter ; Error handling feature!!

        CALL iterator

        CALL print_matrix_wrapper

        JMP read_expressions_and_operate_loop

    read_expressions_and_operate_loop_end:


    main_bad_ending:
        CALL error_handling
        JMP main_whole_ending

    main_good_ending:
        MOV AH, 09h
        LEA DX, tudo_certo

        INT 21h

    main_whole_ending:
        POP BX
        POP BP
        ; HANDLE TEM QUE ESTAR NO BX
        CALL close_file

    .exit


; Subrotinas

; Passa um endereço de uma string no BX,
; (Pode passar tambem o endereço onde começa o numero)
; terminada em '$', NULL, CR, LF, ou ';'
; devolve através do AX o numero em 16 bits em comp. de 2,
; nem tenta passar um numero maior que isso que ele
; vai aceitar e ai o comportamente eh indefinido
;
; so pra deixar anotado, o provavel uso vai ser com um
; buffer de linha lida
;
; Vale lembrar tambem que no final o BX vai apontar
; pro caractere seguinte ao numero
atoi PROC NEAR
    PUSH SI ; Flag de negativo
    PUSH DI ; Tenho que passar o DL pra ele
    PUSH CX ; Multiplicador (MUL precisa de reg)
    PUSH DX ; retorno do eh_numero

    MOV CX, 10
    XOR AX, AX
    XOR DX, DX

atoi_teste_negativo:
    MOV DL, [BX]
    call eh_numero
    JC atoi_fim_def
    JNS atoi_nao_eh_neg

atoi_eh_negativo:
    MOV SI, 0
    INC BX
    JMP atoi_begin_loop

atoi_nao_eh_neg:
    MOV SI, 1
    JMP atoi_begin_loop

atoi_begin_loop:
    MOV DL, [BX]
    call eh_numero

    JC atoi_fim_loop
    ; aqui pra baixo supoe que tudo eh numero, se tiver
    ; escrito "43-222"; por ex., a culpa nao eh minha...

    MOV DI, DX

    MUL CX ; Esse aqui eh pra shiftar pra esquerda o que ja ta no AX
    ADD AX, DI

    INC BX
    JMP atoi_begin_loop

atoi_fim_loop:

    CMP SI, 1
    JZ atoi_fim_def

    NEG AX

atoi_fim_def:

    POP DX
    POP CX
    POP DI
    POP SI
    RET
atoi ENDP

; Testa se o caractere em DL eh numerico,
; ele pode ser um sinal de menos tambem.
; Devolve ele no DL, (o numero),
; se ele for um sinal de menos vai subir a flag de negativo,
; do contrario, a flag vai ser 0.
; Se ele NAO for um numero nem '-', sobe a flag de carry.
; SE for um numero a flag fica em zero
eh_numero PROC NEAR
    ; Empilhamentos
    PUSH AX

    LAHF ; Manda as flags pro AH pra gente fuçar
    AND AH, 7Eh ; zera a carry de flag e de negativo

    CMP DL, '-'
    JE eh_numero_sobe_flag_neg ; Se for um sinal de menos, arruma a flag

    SUB DL, 30H ; DL already holds the number
    CMP DL, 10
    JB eh_numero_fim
    JMP eh_numero_nao_eh_num

eh_numero_sobe_flag_neg:
    OR AH, 80h
    JMP eh_numero_fim

eh_numero_nao_eh_num:
    OR AH, 01h

eh_numero_fim:

    SAHF ; Volta as flags pro lugar

    ; Desempilhamentos
    POP AX

    RET
eh_numero ENDP


; Here and below I will use LOCAL in my subroutines, so that I can repeat my labels

; It will open a file
; THE INPUT IS AL with read or write, DX must have the file name
; AX will have the file handle
open_file PROC NEAR

    PUSH CX ; ctyme specifies INT 21h/3Dh returns something in CL

    MOV AH, 3Dh
    INT 21h

    POP CX

    RET

open_file ENDP

; It will close the file which handle is in BX
close_file PROC NEAR

    PUSHF
    PUSH AX
    PUSH DX

    MOV AH, 3Eh
    INT 21h

    POP DX
    POP AX
    POPF

    RET

close_file ENDP

; Passa pelo AX o handle do arquivo
skip_line_feed PROC NEAR

    PUSHF
    PUSH BX
    PUSH CX
    PUSH DX

    MOV BX, AX
    MOV AH, 42h
    MOV AL, 01h

    MOV CX, 00h
    MOV DX, 01h

    INT 21h

    MOV AX, BX

    POP DX
    POP CX
    POP BX
    POPF

    RET

skip_line_feed ENDP

; AX MUST HAVE THE FILE HANDLE
; If EOF or a blank space is read, CF flag become 1, else, remains 0
read_row PROC NEAR

    PUSH BX
    PUSH CX
    PUSH DX

    ; These will be used to copy the string
    PUSH SI
    PUSH DI

    LEA DX, read_buffer
    LEA DI, buffer_linha

    CLC

rr_file_is_open:
    MOV BX, AX
    MOV CX, 1

rr_begin_loop:
    MOV AH, 3Fh

    INT 21h
    CMP AX, 0
    JE rr_carriage_return_carry

    MOV AL, [read_buffer]
    CMP AL, 20h ; Blank space char
    JE rr_carriage_return_carry

; AQUI EH PRA ELE CONSEGUIR LER CERTO SENDO O ARQUIVO ESCRITO NO LINUX/MACOS
; OU NO WINDOWS
    IF TARGET_POSIX EQ 1
        CMP AL, LF
        JE rr_carriage_return

    ELSE
        CMP AL, CR
        JE rr_carriage_return
    ENDIF

    MOV [DI], AL
    INC DI

    JMP rr_begin_loop

rr_carriage_return_carry:

    STC
    JMP rr_carriage_return_carry_part_two

rr_carriage_return:

    CLC

rr_carriage_return_carry_part_two:

    MOV [DI], NULLCIFRAO

    JMP rr_ending

rr_ending:

    POP DI
    POP SI
    POP DX
    POP CX

    MOV AX, BX

    ; Mesma coisa de antes
    IF TARGET_POSIX EQ 0
        CALL skip_line_feed
    ENDIF

    POP BX

    RET

read_row ENDP


; This will set the CF = 1 if there's an error, also the error flag will 1.
; So it can be print the right message.
;
; Function takes:
; SI = buffer_linha
; DI = matrix[i] TEM QUE ESTAR NA LINHA CORRETA
;
; Returns: 
; DI = matrix[i + 1]
; or error
;  IF ERROR:
;   SI = -1
;
parse_row PROC NEAR

    CLC

    PUSH AX ; BP - 2
    PUSH BX ; BP - 4
    PUSH CX ; BP - 6
    PUSH DX ; BP - 8

pr_beginning:

    XOR CX, CX

    MOV BX, SI

pr_loop: ; Tem que chamar atoi primeiro
    CALL atoi

    MOV [DI], AX
    INC DI
    INC DI

    CMP byte ptr[BX], 3Bh ; The ';' char
    JNE pr_not_semicolon

    pr_is_semicolon:
    INC CX

    pr_not_semicolon:

    CMP [BX], NULLCIFRAO
    JE pr_end_loop

    INC BX

    JMP pr_loop

pr_end_loop:

    INC CX
    CMP CX, [qtd_colunas]
    JE pr_ending

    pr_carry:
    STC
    MOV SI, -1

pr_ending:
    POP DX
    POP CX
    POP BX
    POP AX

    RET

parse_row ENDP

; It will open the file, do its things and close it
; If the parse_row function throw an error the function
; will return early and set the carry flag
; after that, the program MUST be finished with an error message
;
; Arguments:
;   DI: matrix adress
;
; Returns:
;   full-filled matrix and maybe a CARRY FLAG
;
; PS:
;   IF THE CARRY FLAG IS SET, THE FAULTY ROW
;   WILL BE IN THE BX REGISTER
read_matrix PROC NEAR
    CLC

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

rm_open_file:

    MOV AL, 00h
    LEA DX, nome_arq_dados
    CALL open_file ; Handle do arquivo ta no AX

    LEA SI, buffer_linha
    LEA DI, qtd_colunas

    CALL read_row
    CALL parse_row ; Aqui ta um pouco melhor escrito mas
                   ; nada que quebre o codigo.
    LEA SI, buffer_linha

    LEA DI, matriz

    XOR CX, CX

    MOV row_counter, 0

rm_begin_loop:
    CALL read_row
    PUSHF

    CMP [buffer_linha], NULLCIFRAO
    JE rm_loop_test

    INC CX ; Gambiarra...
    CALL parse_row
    JC rm_bad_ending

rm_loop_test:
    POPF

    JC rm_ending_loop; SO SAI DO LOOP NESSA CONDICAO, O RESTO EH ERRO

    INC row_counter

    JMP rm_begin_loop

rm_ending_loop:
    CLC
    JMP rm_end

rm_bad_ending:
    STC

    MOV DX, SI

    INC SP
    INC SP

rm_end:
    MOV qtd_linhas, CX
    MOV BX, AX
    CALL close_file

    POP SI

    JNC rm_not_carry_flag_part_two

    MOV SI, DX

rm_not_carry_flag_part_two:

    POP DX
    POP CX
    POP BX

; Aqui vai preservar o BX se a carry flag nao tiver setada

    JNC rm_not_carry_flag

    MOV BL, row_counter
    XOR BH, BH

    STC

rm_not_carry_flag:
    POP AX

    RET

read_matrix ENDP


; This function will take a number in compliment of 2
; 16 bits.
; and format it to a string (in decimal, for sure)
;
; Arguments:
;   AX = the number
;   DI = the string adress
; WARNING:
; THE CALLER PUTS THE NULLCIFRAO TERMINATOR
; with MOV [DI], NULLCIFRAO
sprintf PROC NEAR

    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

spr_beginning:
    CMP AX, 0
    JNS spr_plus

spr_minus:
    MOV byte ptr [DI], '-'
    INC DI
    NEG AX

spr_plus:

    XOR CX, CX ; CX = 0
    MOV BX, 10 ; BX = 10

spr_stacking_loop:
    XOR DX, DX
    DIV BX ; AX = DX:AX/BX, DX = DX:AX%BX

    ADD DX, 30h
    PUSH DX
    INC CX

    CMP AX, 0
    JE spr_stacking_loop_end

    JMP spr_stacking_loop

spr_stacking_loop_end: ; ex: Para 714, na pilha tem 4 - 1 - 7 (TOPO PRA CA)

    POP DX
    MOV [DI], DL
    INC DI

    LOOP spr_stacking_loop_end

;spr_null_terminating:
;    MOV [DI], NULLCIFRAO
;    INC DI
;    VAMO DEIXAR PRO CHAMADOR DA FUNCAO FAZER ISSO


spf_ending:
    POP SI
    POP DX
    POP CX
    POP BX

    RET

sprintf ENDP



; Format an integer matrix row, into a printable buffer '$' terminated
; Arguments:
;   CX = collumns number
;   SI = matrix[i]
;   DI = buffer (string)
;
; Return:
;  CX = 0
;  SI = matrix[i + 1]
;  DI = ?????????
;
; e.g: the row 4 3 -1 7 becomes 4;3;-1;7$
row_to_buffer PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

rb_print_loop:
    MOV AX, [SI]
    INC SI
    INC SI

    CALL sprintf

    MOV byte ptr [DI], 3Bh ; Caractere ';'
    INC DI

    LOOP rb_print_loop

rb_final_adjust:
    DEC DI
    MOV byte ptr [DI], NULLCIFRAO
    INC DI

rb_ending:
    POP DX
    POP BX
    POP AX

    RET

row_to_buffer ENDP


; Print a matrix INTO A FILE
; Arguments:
;   BX = rows number
;   CX = collumns number
;   SI = matrix
;   DI = temporary_buffer
;   DS:DX = file name
print_matrix PROC NEAR

    PUSH BP
    MOV BP, SP

    PUSH AX

    SUB SP, 6 ; [BP - 4/6/8]
    ; 4 = collumns number
    ; 6 = DI (que guarda o buffer de string)
    ; 8 = rows number

    IF ERASE_RESULT_EVERY_TIME EQ 0
        MOV AL, 02h ; Read and write
        CALL open_file
        ; AX now has the file handle
        ; or CF is set

        JNC pm_file_exists
    ENDIF

pm_file_create:

    PUSH DX

    LEA DX, nome_arq_res
    CALL create_file

    POP DX

    MOV AL, 02h
    CALL open_file

    JMP pm_file_create_jump_label

pm_file_exists:

    CALL move_handle_ptr_to_end
    ; Now it won't overwrite the file content

pm_file_create_jump_label:


    MOV DX, DI

    MOV [BP - 8], BX
    MOV BX, AX

    MOV [BP - 4], CX
    MOV [BP - 6], DI

pm_main_loop:
    CALL row_to_buffer ; Returns CX = 0

    MOV DI, [BP - 6]
    pm_strlen_begin:
        CMP byte ptr [DI], NULLCIFRAO
        JE pm_strlen_end
        INC CX
        INC DI

        JMP pm_strlen_begin

    pm_strlen_end:

        IF TARGET_POSIX EQ 0
            MOV byte ptr [DI], CR
            INC CX ; Aqui eu vou reservar mais um byte no
            INC DI
                   ; buffer_linha, pra evitar invadir memoria
        ENDIF

        MOV byte ptr [DI], LF
        INC CX ; BX, CX and DX ready

        XOR AX, AX
        MOV AH, 40h

        INT 21h

    pm_row_written:

    MOV CX, [BP - 4]
    MOV DI, [BP - 6]

    DEC word ptr[BP - 8]
    CMP [BP - 8], 0
    JNE pm_main_loop

pm_main_loop_end:


pm_print_line_ending:

    PUSH AX
    PUSH CX
    PUSH DX

; Here it will print a line ending everytime a matrix is print
; So the RESULT.TXT will be less painful to read

    MOV AH, 40h
    MOV CX, 2 ; 2 Bytes in the TARGET_POSIX = 0 case
    LEA DX, line_ending

    IF TARGET_POSIX EQ 1
        MOV CX, 1 ; Will print one 1 byte...
        INC DX ; ...And it will be the second one (LF)
    ENDIF

    INT 21h

    POP DX
    POP CX
    POP AX


pm_file_closing:

    CALL close_file

pm_ending:
    ADD SP, 6

    POP AX

    POP BP

    RET

print_matrix ENDP

; This function is meant to always lseek
; to the end of the file, so it can append
; when printing, instead of overwriting
; AX = Handle
; This won't return anything and AX will
; keep the handle

move_handle_ptr_to_end PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

move_pointer:
    MOV BX, AX ; Passa o handle pro BX

    MOV AH, 42h
    MOV AL, 02h ; lseek a partir do fim do arquivo

    MOV CX, 00h
    MOV DX, 00h ; Offset = 0

    INT 21h

move_pointer_done:

    POP DX
    POP CX
    POP BX
    POP AX

    RET

move_handle_ptr_to_end ENDP

; Creates a file with a given name
; (Do not use it if there exist an imporant file w the same name)
;
; Arguments:
;   DS:DX = File name
;
; It will NOT return the handle, you have to open it again
; with the opening function
create_file PROC NEAR
    PUSH AX
    PUSH CX

    MOV AH, 3Ch
    MOV CX, 0

    INT 21h

    POP CX
    POP AX

    RET
create_file ENDP


; Function to prepare BX, DI, SI to do matrix ops
; Arguments:
;   BX = Dst row
;   DI = Src_1 row
;   SI = Src_2 row
;
; Returns:
;   All the above LEAd with the rows adresses
prepare_rows PROC NEAR
    PUSH BP
    MOV BP, SP

    PUSH AX ; [BP - 2]
    PUSH CX ; [BP - 4]
    PUSH DX ; [BP - 6]

    SUB SP, 2 ; [BP - 8]
    MOV [BP - 8], AX

    LEA CX, matriz

pl_bx:

    MOV AX, qtd_colunas
    MOV DX, 2
    MUL DX
    MUL BX
    ADD AX, CX

    MOV BX, AX
    XOR DX, DX

pl_bx_end:

    MOV AX, [BP - 8]
    CMP AH, 1
    JE pl_di_end

pl_di:
    MOV AX, qtd_colunas
    MOV DX, 2
    MUL DX
    MUL DI
    ADD AX, CX

    MOV DI, AX
    XOR DX, DX

pl_di_end:

    MOV AX, [BP - 8]
    CMP AL, 1
    JE pl_si_end

pl_si:
    MOV AX, qtd_colunas
    MOV DX, 2
    MUL DX
    MUL SI
    ADD AX, CX

    MOV SI, AX
    XOR DX, DX

pl_si_end:

pl_ending:

    ADD SP, 2
    POP DX
    POP CX
    POP AX
    POP BP

    RET
prepare_rows ENDP


; Function to iterate through a row of a matrix
; to do a set of operations (SIMD alike)
;
; Arguments:
;   AH/L = 1 if H-src1, L-src2 -> Constant; 0 if row reference 
;   BX = dst row
;   DI = src1 row
;   SI = src2 row
;   DS:operation = Operation to be done
;
; No return
iterator PROC NEAR
    PUSH BP
    MOV BP, SP

    PUSH CX ; [BP - 2]
    MOV CX, qtd_colunas

    CALL prepare_rows

    CMP AX, 0000h
    JE it_case_0 ; No constant

    CMP AX, 0100h
    JE it_case_1 ; src1 constant

    CMP AX, 0001h
    JE it_case_2 ; src2 costant

    CMP AX, 0101h
    JE it_case_3 ; both constants

it_case_0:

    it_case_0_loop:
        CALL operate
        ADD BX, 2
        ADD DI, 2
        ADD SI, 2

        LOOP it_case_0_loop

    it_case_0_loop_end:

    JMP it_def_ending

it_case_2: ; Removi a minh gambiarra do commit anterior
           ; porque dava pau quando a op. nao era comutativa
    MOV op_source_two, SI
    LEA SI, op_source_two

    it_case_2_loop:
        CALL operate
        ADD BX, 2
        ADD DI, 2

        LOOP it_case_2_loop

    it_case_2_loop_end:

    MOV SI, op_source_two

    JMP it_def_ending

it_case_1:
    MOV op_source_one, DI
    LEA DI, op_source_one

    it_case_1_loop:
        CALL operate
        ADD BX, 2
        ADD SI, 2

        LOOP it_case_1_loop

    it_case_1_loop_end:

    MOV DI, op_source_one

    JMP it_def_ending

it_case_3:

    MOV op_source_one, DI
    MOV op_source_two, SI

    LEA DI, op_source_one
    LEA SI, op_source_two

    it_case_3_loop:
        CALL operate
        ADD BX, 2

        LOOP it_case_3_loop

    it_case_3_loop_end:

    MOV DI, op_source_one
    MOV SI, op_source_two

it_def_ending:

    POP CX
    POP BP

    RET
iterator ENDP


; This function applies an operation in the following way:
; [BX]  = [DI]   + [SI], meaning...
; [dst] = [src1] + [src2]
;
; Note: The operation done symbol must be
; put into the operation global variable
;
; NOTE PART TWO AND VERY IMPORTANT:
; If trying to perform a division by 0 (zero), it will
; just output 0 (zero) to the dst, no errors will be
; emmited, neither the program will crash. May you
; feel warned...
operate PROC NEAR

    PUSH AX
    PUSH CX
    PUSH DX

    MOV AX, [DI]
    MOV CX, [SI]
    XOR DX, DX

op_switch:
    ; Dealing with NO possible division by zero operations first

    CMP operation, '+'
    JE op_sum

    CMP operation, '-'
    JE op_sub

    CMP operation, '*'
    JE op_imul

    CMP operation, '&'
    JE op_and

    CMP operation, '|'
    JE op_or

    CMP operation, '^'
    JE op_xor

op_dealing_with_possible_div_by_zero:
    CMP CX, 0
    JNE op_no_division_by_zero_all_ok
    MOV [BX], 0
    JMP op_no_changes_end

op_no_division_by_zero_all_ok: ; Perfect, no more division by 0
    CMP operation, '?' ; Easter egg hehehe
    JE op_remainder

    CWD ; Change word to double word, my remainders were
        ; weird and I found it surfing the forums

    CMP operation, '/'
    JE op_idiv

    CMP operation, '%'
    JE op_signed_remainder

    JMP op_no_changes_end

op_sum:
    ADD AX, CX

op_sum_end:
    JMP op_def_end

op_sub:
    SUB AX, CX

op_sub_end:
    JMP op_def_end

op_imul:
    IMUL CX

op_imul_end:
    JMP op_def_end

op_idiv:
    IDIV CX

op_idiv_end:
    JMP op_def_end

op_remainder:
    DIV CX
    MOV AX, DX

op_remainder_end:
    JMP op_def_end

op_signed_remainder:
    IDIV CX
    MOV AX, DX

op_signed_remainder_end:
    JMP op_def_end

op_and:
    AND AX, CX

op_and_end: ; lol and and
    JMP op_def_end

op_or:
    OR AX, CX

op_or_end:
    JMP op_def_end

op_xor:
    XOR AX, CX

op_xor_end:
    JMP op_def_end

op_def_end:
    MOV [BX], AX

op_no_changes_end:

    POP DX
    POP CX
    POP AX

    RET
operate ENDP


; This function won't require any arguments
; but it suppose the file is open for reading at least
; it will set the correct values for:
;   BX = Dst
;   DI = Src1
;   SI = Src2
;
; Annnd.... 
;   DS:operation = the op. to be done
;   DS:matrix_must_be_print = true/false (refer to README)
;
; WARNING !!!
;   If the carry flag is set == ERROR:
;     BX = Line with the error
;     DI = Wrong operation char or impossible reference
;     SI = If = 1, syntax error, If = 0, Wrong operation
;       If = 2, impossible reference
;
; Moreover:
;   The function require the file to be well written,
;   it can correct logic mistakes, but not syntax.
;   That said, when I find a bracket, I will assume
;   it is closed elsewhere. Whatever I can, in fact,
;   detect this kind of mistakes easily, but it won't
;   be pertinent to this project. Sorry ;(
;   *PS: I created a function to parse for things like
;   open but not closed brackets. I'm now using in this
;   function
;
; Also:
;   It will report the first found mistake, NOT ALL of them
;   Remember, I'm not the god of Assembly, YET ;)
expression_parser PROC NEAR

; Colinha pra eu lembrar o formato da expressao:
; *[atoi_1]=[atoi_2]~[atoi_3]$

    PUSH BP
    MOV BP, SP

    PUSH CX ; [BP - 2]
    PUSH DX ; [BP - 4]

    MOV CX, 0101h ; Assuming both srcs are constants

    SUB SP, 6 ; [BP - 6/8/10] -> dst/src1/src2

; Mais anotacao minha:
;   Vou passar a funcao de BX pro DX pq o
;   atoi por alguma razao do alem usa o BX,
;   e isso mostra porque a escolha da passagem dos
;   argumentos tem que ser tecnica, nao levada
;   pelo senso de humor...
;   PS: MUDEI DE IDEIA E PASSEI PRA PILHA

ep_test_for_syntax_error:
    CALL well_formed_exp_test
    JC ep_bad_ending_syntax_error

    LEA BX, buffer_linha

ep_test_printing:
    CMP byte ptr [BX], '*'
    JNE ep_no_print_this_time

    INC BX

    MOV matrix_must_be_print, 1
    JMP ep_print_jump

ep_no_print_this_time:
    MOV matrix_must_be_print, 0
ep_print_jump:

; Now for sure I'm on an opening bracket
    CMP byte ptr [BX], '['
    JNE ep_bad_ending_syntax_error
    INC BX

; Now for sure I'm on a number (dst)
    CALL atoi

    CMP AX, 0
    JS ep_bad_ending_reference_error

    CMP AX, qtd_linhas
    JNL ep_bad_ending_reference_error

    MOV [BP - 6], AX

; Ok now on a closing bracket 
    CMP byte ptr [BX], ']'
    JNE ep_bad_ending_syntax_error
    INC BX

; Equal sign...
    CMP byte ptr [BX], '='
    JNE ep_bad_ending_syntax_error
    INC BX

; Now I don't know, it can be either a number or a [
; so... We start to pray for our wfe tester to work
    CMP byte ptr [BX], '['
    JNE ep_is_src_one
    INC BX
    MOV CH, 0

ep_is_src_one:
    CALL atoi

    CMP CH, 01h
    JE ep_is_src_one_skip_validation

    CMP AX, 0
    JS ep_bad_ending_reference_error

    CMP AX, qtd_linhas
    JNL ep_bad_ending_reference_error

ep_is_src_one_skip_validation:

    MOV [BP - 8], AX

    ; Now we can either be on a closing bracket
    ; or the operator

    CMP byte ptr [BX], ']'
    JNE ep_is_operator
    INC BX

ep_is_operator:
    CALL is_operation_listed
    JC ep_bad_ending_bad_operation

    MOV operation, AL

    CMP byte ptr [BX], '['
    JNE ep_is_src_two
    INC BX
    MOV CL, 0

ep_is_src_two:
    CALL atoi

    CMP CL, 01h
    JE ep_is_src_two_skip_validation

    CMP AX, 0
    JS ep_bad_ending_reference_error

    CMP AX, qtd_linhas
    JNL ep_bad_ending_reference_error

ep_is_src_two_skip_validation:

    MOV [BP - 10], AX

    JMP ep_good_ending

ep_bad_ending_syntax_error:
    XOR BX, BX
    MOV BL, row_counter
    MOV SI, 1

    JMP ep_whole_ending
ep_bad_ending_reference_error:
    XOR BX, BX
    MOV BL, row_counter
    MOV SI, 2
    MOV DI, AX

    JMP ep_whole_ending
ep_bad_ending_bad_operation:
    XOR BX, BX
    MOV BL, row_counter
    MOV SI, 0
    MOV DI, AX

    JMP ep_whole_ending
ep_good_ending:

    MOV BX, [BP - 6]
    MOV DI, [BP - 8]
    MOV SI, [BP - 10]

    MOV AX, CX
    JMP ep_whole_ending_but_good

ep_whole_ending:
    ADD SP, 6
    STC
JMP ep_dont_double_free

ep_whole_ending_but_good:
    ADD SP, 6

ep_dont_double_free:

    POP DX
    POP CX
    POP BP

    RET

expression_parser ENDP


; This function will try to find some things
; like: [3=[3]+[4]. Did you get it?
;
; If a missing bracket is found -> CARRY FLAG
well_formed_exp_test PROC NEAR
    PUSH BX

    LEA BX, buffer_linha

    JMP wfe_loop_begin

wfe_a_little_inc:
    INC BX

wfe_loop_begin:
    CMP byte ptr [BX], NULLCIFRAO
    JE wfe_good_ending

    CMP byte ptr [BX], ']'
    JE wfe_bad_ending

    CMP byte ptr [BX], '['
    JE wfe_first_found

    INC BX
    JMP wfe_loop_begin

    wfe_first_found:
        INC BX
        wfe_first_found_loop:
            CMP byte ptr [BX], NULLCIFRAO
            JE wfe_bad_ending

            CMP byte ptr [BX], '['
            JE wfe_bad_ending

            CMP byte ptr [BX], ']'
            JE wfe_a_little_inc

            INC BX
            JMP wfe_first_found_loop

wfe_good_ending:

    CLC
    JMP wfe_ending

wfe_bad_ending:

    STC

wfe_ending:

    POP BX

    RET

well_formed_exp_test ENDP

; It will grab a single character byte ptr [BX] and put aside
; with the operations table to test if it exists.
;
; Returns the char in AX and BX Incremented
; If it does not exist -> CARRY FLAG
is_operation_listed PROC NEAR

    MOV AL, byte ptr [BX]
    XOR AH, AH

    IF UNSIGNED_DIVISION EQ 1
        CMP AX, '?'
        JE iol_good_ending
    ENDIF

    CMP AX, '+'
    JE iol_good_ending

    CMP AX, '-'
    JE iol_good_ending

    CMP AX, '*'
    JE iol_good_ending

    CMP AX, '/'
    JE iol_good_ending

    CMP AX, '%'
    JE iol_good_ending

    CMP AX, '&'
    JE iol_good_ending

    CMP AX, '|'
    JE iol_good_ending

    CMP AX, '^'
    JE iol_good_ending

    JMP iol_bad_ending

iol_good_ending:
    CLC
    JMP iol_whole_ending

iol_bad_ending:
    STC

iol_whole_ending:

    INC BX

    RET
is_operation_listed ENDP

; This is a wrapper to print the line that called a print
; above the matrix printed
print_matrix_wrapper PROC NEAR

    CMP matrix_must_be_print, 0
    JE pmw_no_print

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    PUSH DX

pmw_printing_line:

    MOV AL, 02h
    LEA DX, nome_arq_res
    CALL open_file

    CALL move_handle_ptr_to_end

    MOV BX, AX
    LEA DI, buffer_linha
    XOR CX, CX
    MOV DX, DI

    pmw_strlen_begin:
        CMP byte ptr [DI], NULLCIFRAO
        JE pmw_strlen_end
        INC CX
        INC DI

        JMP pmw_strlen_begin

    pmw_strlen_end:

        IF TARGET_POSIX EQ 0
            MOV byte ptr [DI], CR
            INC CX ; Aqui eu vou reservar mais um byte no
            INC DI
                   ; buffer_linha, pra evitar invadir memoria
        ENDIF

        MOV byte ptr [DI], LF
        INC CX ; BX, CX and DX ready

        XOR AX, AX
        MOV AH, 40h

        INT 21h


    call close_file

pmw_printing_matrix:
    MOV BX, [qtd_linhas]
    MOV CX, [qtd_colunas]
    LEA SI, matriz
    LEA DI, buffer_linha
    LEA DX, nome_arq_res

    CALL print_matrix

    POP DX
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX

pmw_no_print:

    RET
print_matrix_wrapper ENDP


; This function will handle the errors (the carry flags)
; you wouldn't have to worry about the arguments, bc
; everytime a function throw the error, the detailed
; logs will already be in the right registers
error_handling PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV CX, BX

    CMP SI, -1
    JE eh_wrong_column_number_error

    CMP SI, 1
    JE eh_bad_syntax_error

    CMP SI, 0
    JE eh_bad_operation_error

    CMP SI, 2
    JE eh_bad_reference_error

    JMP eh_error_handling_end

eh_wrong_column_number_error:

    MOV AH, 09h
    LEA DX, erro_colunas
    INT 21h

    MOV AX, CX
    LEA DI, buffer_linha

    CALL sprintf
    MOV byte ptr [DI], NULLCIFRAO

    LEA DX, buffer_linha
    MOV AH, 09h
    INT 21h

    JMP eh_error_handling_end

eh_bad_reference_error:

    MOV AH, 09h
    LEA DX, bad_reference_error
    INT 21h

    MOV AX, DI
    LEA DI, buffer_linha

    CALL sprintf
    MOV [DI], NULLCIFRAO

    LEA DX, buffer_linha
    MOV AH, 09h
    INT 21h

    MOV AH, 09h
    LEA DX, operation_or_reference_error_ending
    INT 21h

    MOV AX, CX
    LEA DI, buffer_linha

    CALL sprintf
    MOV [DI], NULLCIFRAO

    LEA DX, buffer_linha
    MOV AH, 09h
    INT 21h

    JMP eh_error_handling_end

eh_bad_operation_error:

    MOV AH, 09h
    LEA DX, bad_operation_error
    INT 21h

    MOV DX, DI
    XOR DH, DH
    MOV AH, 02h
    INT 21h

    MOV AH, 09h
    LEA DX, operation_or_reference_error_ending
    INT 21h

    MOV AX, CX
    LEA DI, buffer_linha

    CALL sprintf
    MOV [DI], NULLCIFRAO

    LEA DX, buffer_linha
    MOV AH, 09h
    INT 21h

    JMP eh_error_handling_end

eh_bad_syntax_error:

    MOV AH, 09h
    LEA DX, syntax_error_text

    INT 21h

    MOV AX, CX
    LEA DI, buffer_linha

    CALL sprintf
    MOV [DI], NULLCIFRAO

    LEA DX, buffer_linha
    MOV AH, 09h
    INT 21h

    JMP eh_error_handling_end

eh_error_handling_end:

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET
error_handling ENDP


; Fim do programa

end



