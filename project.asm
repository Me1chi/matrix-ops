.model small
.stack 400H
.data

; Coisas pra facilitar a vida
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
hanlde_res dw ?

read_buffer db ? ; AQUI EH IMPORTANTE, TODA LEITURA VEM PRA CA

; Buffers de dados
buffer_linha db 140 DUP(?) ; 20 colunas, 6 digitos no maximo em cada, 19 semicolons = 139, +1 pra deixar um '\0' no final

matriz dw 2000 DUP(?) ; MAX_LINHAS * MAX_COLUNAS,

; Mais dados
qtd_colunas dw ? ; Aqui vai a quantidade real de colunas que vao ser lidas do arquivo
qtd_linhas dw ? ; Eh bom saber a quantidade de linhas tambem



; Area de testes

teste_funcao db "12430sdfsuidhf",0


.code
    .startup

    MOV read_buffer, 63 ; 1
    call eh_numero
    JC fim_main
    JS fim_neg_main

    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    JMP fim_main

fim_neg_main:
    MOV DL, 'N'
    MOV AH, 02h
    INT 21h

fim_main:

    LEA BX, teste_funcao
    CALL atoi


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
atoi PROC NEAR
    PUSH SI ; Flag de negativo
    PUSH DI ; Tenho que passar o DL pra ele
    PUSH CX ; Multiplicador (MUL precisa de reg)
    PUSH DX ; retorno do eh_numero

    MOV CX, 10
    XOR AX, AX
    XOR DX, DX

teste_negativo:
    MOV DL, [BX]
    call eh_numero
    JC fim_def
    JNS nao_eh_neg

eh_negativo:
    MOV SI, 0
    INC BX
    JMP begin_loop

nao_eh_neg:
    MOV SI, 1
    JMP begin_loop

begin_loop:
    MOV DL, [BX]
    call eh_numero

    JC fim_loop
    ; aqui pra baixo supoe que tudo eh numero, se tiver
    ; escrito "43-222"; por ex., a culpa nao eh minha...

    MOV DI, DX

    MUL CX ; Esse aqui eh pra shiftar pra esquerda o que ja ta no AX
    ADD AX, DI

    INC BX
    JMP begin_loop

fim_loop:

    CMP SI, 1
    JZ fim_def

    NEG AX

fim_def:

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
    JE sobe_flag_neg ; Se for um sinal de menos, arruma a flag

    SUB DL, 30H ; DL already holds the number
    CMP DL, 10
    JB fim
    JMP nao_eh_num

sobe_flag_neg:
    OR AH, 80h
    JMP fim

nao_eh_num:
    OR AH, 01h

fim:

    SAHF ; Volta as flags pro lugar

    ; Desempilhamentos
    POP AX

    RET
eh_numero ENDP






read_matriz PROC NEAR



read_matriz ENDP




; Fim do programa

end



