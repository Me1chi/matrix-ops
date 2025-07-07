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
buffer_linha db 140 DUP(?),NULLCIFRAO ; 20 colunas, 6 digitos no maximo em cada, 19 semicolons = 139, +1 pra deixar um '\0' no final

matriz dw 2000 DUP(?) ; MAX_LINHAS * MAX_COLUNAS,

; Mais dados
qtd_colunas dw ? ; Aqui vai a quantidade real de colunas que vao ser lidas do arquivo
qtd_linhas dw ? ; Eh bom saber a quantidade de linhas tambem

erro_colunas db "ALGUMA LINHA TEM O NUMERO ERRADO DE COLUNAS",NULLCIFRAO

error_flag db ? ; 1-Numero de colunas errado
                ; 2-Referencia invalida
                ; 3-Operacao invalida

; Area de testes

teste_funcao db "12430sdfsuidhf",0


.code
    .startup

    MOV AL, 00h
    LEA DX, nome_arq_dados
    CALL open_file

le_linha_teste:
    CALL read_row
    PUSHF

    LEA DX, buffer_linha

    PUSH AX

    MOV AH, 09h

    INT 21h

    MOV DL, CR
    MOV AH, 2
    INT 21h
    MOV DL, LF
    MOV AH, 2
    INT 21h

    POP AX
    POPF

    JNC le_linha_teste

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
buffer_linha db 140 DUP(?),NULLCIFRAO ; 20 colunas, 6 digitos no maximo em cada, 19 semicolons = 139, +1 pra deixar um '\0' no final

matriz dw 2000 DUP(?) ; MAX_LINHAS * MAX_COLUNAS,

; Mais dados
qtd_colunas dw ? ; Aqui vai a quantidade real de colunas que vao ser lidas do arquivo
qtd_linhas dw ? ; Eh bom saber a quantidade de linhas tambem

erro_colunas db "ALGUMA LINHA TEM O NUMERO ERRADO DE COLUNAS",NULLCIFRAO

error_flag db ? ; 1-Numero de colunas errado
                ; 2-Referencia invalida
                ; 3-Operacao invalida

; Area de testes

teste_funcao db "12430sdfsuidhf",0


.code
    .startup

    MOV AL, 00h
    LEA DX, nome_arq_dados
    CALL open_file

le_linha_teste:
    CALL read_row
    PUSHF

    LEA DX, buffer_linha

    PUSH AX

    MOV AH, 09h

    INT 21h

    MOV DL, CR
    MOV AH, 2
    INT 21h
    MOV DL, LF
    MOV AH, 2
    INT 21h

    POP AX
    POPF

    JNC le_linha_teste

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

    PUSH AX
    MOV AH, 3Eh
    INT 21h

    POP AX

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

    CMP [BX], 3Bh ; The ';' char
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
    MOV error_flag, 1

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
read_matrix PROC NEAR
    CLC

    PUSH SI
    PUSH AX
    PUSH BX
    PUSH DX

rm_open_file:

    MOV AL, 00h
    LEA DX, nome_arq_dados
    CALL open_file ; Handle do arquivo ta no AX

    LEA SI, buffer_linha
    LEA DI, matriz

rm_begin_loop:
    CALL read_row
    JC rm_ending_loop ; SO SAI DO LOOP NESSA CONDICAO, O RESTO EH ERRO

    CALL parse_row
    JC rm_bad_ending

    JMP rm_begin_loop

rm_ending_loop:
    JMP rm_end

rm_bad_ending:
    MOV AH, 09h
    LEA DX, erro_colunas

    INT 21h

    STC

rm_end:
    MOV BX, AX
    CALL close_file

    POP DX
    POP BX
    POP AX
    POP SI

    RET

read_matrix ENDP




; Fim do programa

end



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

    PUSH AX
    MOV AH, 3Eh
    INT 21h

    POP AX

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

    PUSH AX
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
    POP AX

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

    CMP [BX], 3Bh ; The ';' char
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
    MOV error_flag, 1

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
read_matrix PROC NEAR
    CLC

    PUSH SI
    PUSH AX
    PUSH BX
    PUSH DX

rm_open_file:

    MOV AL, 00h
    LEA DX, nome_arq_dados
    CALL open_file ; Handle do arquivo ta no AX

    LEA SI, buffer_linha
    LEA DI, matriz

rm_begin_loop:
    CALL read_row
    JC rm_ending_loop ; SO SAI DO LOOP NESSA CONDICAO, O RESTO EH ERRO

    CALL parse_row
    JC rm_bad_ending

    JMP rm_begin_loop

rm_ending_loop:
    JMP rm_end

rm_bad_ending:
    MOV AH, 09h
    LEA DX, erro_colunas

    INT 21h

    STC

rm_end:
    MOV BX, AX
    CALL close_file

    POP DX
    POP BX
    POP AX
    POP SI

    RET

read_matrix ENDP




; Fim do programa

end



