--Criação das tabelas

Create table tb_conta (id_conta integer not null,
					  nm_conta varchar(30) not null,
					  ds_conta_extensa varchar(30) not null);
					  
create table tb_saldo (id_conta integer not null,
					  vl_debito numeric not null,
					  vl_credito numeric not null,
					  nu_ano integer,
					  nu_mes integer check (nu_mes > 0 and nu_mes < 13));
		
--Alteração das tabelas
	--adição de primary key
alter table tb_conta add constraint pk_conta primary key(id_conta);
alter table tb_saldo add constraint pk_saldo primary key(id_conta, nu_ano, nu_mes);
	--adição de foreign key
alter table tb_saldo add constraint fk_saldo_conta foreign key (id_conta) references tb_conta;


-- Inserção nas tabelas
insert into tb_conta values (1, 'ATIVO', '1'), (2, 'CIRCULANTE', '1.1'), (3, 'Caixa', '1.1.1'), 
									(4, 'Caixa Geral', '1.1.1.01'), (5, 'Bancos Conta Movimento', '1.1.2'), (6, 'Banco alfa', '1.1.2.01');

--criação da função que separa as contas, até chegar na conta pai
create or replace function fn_separa (conta varchar) returns varchar
language plpgsql
as
$$
	declare 
		i integer := 0;
	begin
		for i in reverse length(conta)..1 loop
			if(substr(conta, i, 1) = '.') then
				return substr (conta, 1, i - 1);
			end if;
		end loop;
		return 'fim';
	end
$$

--Criação da função lança saldo
Create or replace function fn_lanca_saldo(p_conta integer, p_valor numeric,
										  p_lancamento char, p_ano integer, p_mes integer) returns varchar
language plpgsql
as
$$
	declare
		aux_conta tb_conta.ds_conta_extensa%type;
		p_contador integer;
		aux_vl_debito numeric := 0;
		aux_vl_credito numeric := 0;
		total integer := 0;
		aux_id_conta integer;
		aux_nu_ano  integer = p_ano;
		aux_nu_mes integer = p_mes;
		i integer;
	begin
		--Verifica se a conta existe
		select ds_conta_extensa into aux_conta from tb_conta where id_conta = p_conta;

		if not found then
			raise exception 'A conta informada não é válida!';
		end if;

		--Verifica se o valor lançado é menor ou igual a zero
		if p_valor <= 0 then
			raise exception 'O valor deve ser maior que zero!';
		end if;

		--Verifica se o lançamento é 'C' ou 'D'
		if p_lancamento not in ('D', 'C') then
			raise exception 'O lançamento deve ser D ou C';
		end if;

		--Verifica se a conta possui filhos
		select count(*) into p_contador from tb_conta where ds_conta_extensa like aux_conta || '.%';

		if p_contador > 0 then
			raise exception 'A conta informada é uma conta pai, deve ser informada uma conta filho!';
		end if;

		--Verifica se a operação é crédito ou débito e adiciona os valores
		if p_lancamento = 'C' then
			aux_vl_credito := p_valor;
		else
			aux_vl_debito := p_valor;
		end if;
		
		loop
			--Pega o id da conta
			select id_conta into aux_id_conta from tb_conta where ds_conta_extensa = aux_conta;

			--Verifica se o id da conta é nulo
			if aux_id_conta is null then
				raise exception 'O id da conta não pode ser nulo!';
			end if;


			--Vê quantos lançamentos tem em uma conta
			for i in p_mes..12 loop
			
			--Verifica se o mês atual é maior ou menor que o mês fornecido por parâmetro
			if i >= p_mes then
			--Conta quantos lnaçamentos existem para uma conta
			select count(*) into total from tb_saldo where id_conta = aux_id_conta and nu_mes = p_mes and nu_ano = p_ano;
			
			end if;
			--se não houver lançamento, insere um novo lançamento
			if total = 0 then
				insert into tb_saldo values (aux_id_conta, aux_vl_debito, aux_vl_credito, p_ano, p_mes);
			--Caso exista um lançamento, ele atualiza
			else
				update tb_saldo set vl_debito = vl_debito + aux_vl_debito,
									vl_credito = vl_credito + aux_vl_credito
									where id_conta = aux_id_conta and nu_mes = p_mes and nu_ano = p_ano;
			end if;
			
			--Incrementa o mês de acordo com o loop
			p_mes := p_mes + 1;
			
			end loop;
			--Reinicia o valor de p_mes
			p_mes := aux_nu_mes;
		
			--Pega as próximas contas pai
			aux_conta = fn_separa(aux_conta);

			--Termina quando chegar na conta pai de todas
			exit when aux_conta = 'fim';

		end loop;

		return 'OK';
	end;
$$
