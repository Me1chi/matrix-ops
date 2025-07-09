# Trabalho de Programação – Processador INTEL – 2025/1

## Descrição Geral

Este projeto consiste em um programa escrito em linguagem de montagem para o processador **INTEL x86**, desenvolvido para o ambiente **MASM + DOSBox**. O objetivo do programa é:

- Ler dois arquivos:
  - `DADOS.TXT`: contendo uma matriz de números.
  - `EXP.TXT`: contendo expressões aritméticas.
- Executar as expressões aritméticas indicadas, utilizando os dados da matriz.
- Gerar um arquivo `RESULT.TXT` com os resultados solicitados.

Todos os números são tratados como inteiros com sinal representados em complemento de 2 com 16 bits. Operações que resultarem em overflow devem ser truncadas para 16 bits.

---

## Formato do Arquivo `DADOS.TXT`

- Primeira linha: número de colunas da matriz (`N`), com `1 ≤ N ≤ 20`. Valores fora desse intervalo devem ser tratados como erro.
- Linhas seguintes: `N` números inteiros (com sinal), separados por `;`, sem espaços ou tabulações.

**Regras:**

- Linhas vazias não ocorrem (exceto possivelmente a última).
- Linhas com quantidade incorreta de colunas devem ser tratadas como erro e encerram o programa.
- Números fora do intervalo de 16 bits com sinal devem ser considerados inválidos.

**Exemplo:**
```
3
10;123;-15
2;-3;54
```

---

## Formato do Arquivo `EXP.TXT`

Cada linha representa uma expressão aritmética, com até 100 expressões no total. Expressões seguem o formato:

```
[linha_resultado]=[operação e operandos]
```

- `linha_resultado`: linha da matriz que receberá o resultado. Pode ser prefixada com `*` para indicar que o resultado deve ir para `RESULT.TXT`.
- Operandos: constantes (em complemento de 2 com 16 bits) ou referências a outras linhas da matriz (entre colchetes).

**Exemplos válidos:**
```
[0]=[0]+[2]
*[1]=5*[0]
[10]=[2]+15
```

**Erros a serem tratados:**

- Índices de linha negativos.
- Referência a linhas inexistentes.
- Operadores inválidos.

---

## Operações Suportadas

As expressões devem implementar as seguintes operações, conforme instruções do processador:

| Símbolo | Operação                     |
|--------:|------------------------------|
| `+`     | Soma                         |
| `-`     | Subtração                    |
| `*`     | Multiplicação com sinal      |
| `/`     | Divisão com sinal (16/16)    |
| `%`     | Resto da divisão (16/16)     |
| `&`     | Operação lógica AND          |
| `\|`     | Operação lógica OR           |
| `^`     | Operação lógica XOR          |

**Nota:** Não há suporte a parênteses. Expressões compostas devem ser divididas em múltiplas expressões intermediárias.

---

## Geração do Arquivo `RESULT.TXT`

- Apenas expressões com prefixo `*` geram saída no arquivo.
- Cada grupo de resultado é composto por:
  1. A linha da expressão original (ex: `*[0]=[0]+[2]`)
  2. As `N` linhas correspondentes ao resultado da operação aplicada à matriz.
