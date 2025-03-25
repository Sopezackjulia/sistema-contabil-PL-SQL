# Controle Financeiro - Banco de Dados

Esse é um projeto para a criação e manutenção de um sistema de controle financeiro usando PL/SQL. O sistema inclui funcionalidades de gerenciamento de contas, saldos e lançamentos contábeis, com validações e atualizações automáticas.

## Funcionalidades

O projeto inclui os seguintes principais recursos:

**Criação das Tabelas**:
    - Tabela `tb_conta`: Armazena informações sobre as contas contábeis.
    - Tabela `tb_saldo`: Armazena os saldos das contas para cada ano e mês.

**Alteração das Tabelas**:
    - Adição de **chaves primárias** e **chaves estrangeiras** para garantir a integridade referencial.

**Função `fn_separa`**:
    - Função responsável por separar uma conta contábil e encontrar a conta pai.

**Função `fn_lanca_saldo`**:
    - Função que permite lançar valores (débito ou crédito) em uma conta.
    - Realiza a validação dos parâmetros e ajusta o saldo da conta informada e das contas superiores, até chegar à conta principal.

**Validações**:
    - Verificação de que a conta informada é válida e não é uma conta pai.
    - O valor do lançamento deve ser maior que zero.
    - O tipo de lançamento deve ser "D" (débito) ou "C" (crédito).
    - Lançamentos de saldo são feitos mês a mês até o mês 12 do ano.

