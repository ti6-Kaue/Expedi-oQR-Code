# Regras do aplicativo de expedição

Este arquivo mostra onde está cada regra e o que ela faz.

## 1. Formato dos códigos

Arquivos:

- `backend/src/api.js`, função `normalizarCodigo`
- `lib/regras/regras.dart`, função `analisarCodigo`

O que faz:

- Código com 13 caracteres terminado em `BR` vai para o Portal Postal.
- Número com 5 ou 6 dígitos vai para Pedido de Venda.
- Outros códigos são ignorados e não são gravados.

## 2. Rastreio postal já utilizado

Arquivo: `backend/src/api.js`, dentro da função `salvarLeitura`.

O backend consulta `portalpostal.saida_objetos`. Se o rastreio já estiver
nessa tabela definitiva, a leitura é recusada como duplicada.

## 3. Não deixar bipar duas vezes

Arquivo: `backend/src/api.js`, dentro da função `salvarLeitura`.

Antes de inserir, o backend procura o código na tabela temporária de destino:

- `portalpostal.saida_objetos_temp`
- `talmax.pedido_de_venda_saida_temp`

Se encontrar o código, responde com erro `409` e não faz outro `INSERT`.

## 4. Contador de itens bipados

Arquivos:

- `lib/frontend/telas/pagina_inicial.dart`
- `lib/frontend/componentes/leitor_pela_camera.dart`

O contador aumenta somente depois que a API confirma a gravação. Código
duplicado, inválido ou com erro não aumenta a quantidade.

## 5. Histórico no celular

Arquivo: `lib/frontend/servicos/historico_de_leituras.dart`.

Salva no cache local o código, destino, data e horário. O botão **Limpar**
apaga somente esse histórico local; ele não exclui registros do banco.

## 6. Som de cada leitura

Arquivo: `lib/frontend/servicos/som_da_leitura.dart`.

- Leitura salva toca o som de correto.
- Duplicidade ou falha toca o som correspondente.
- Código fora das regras é ignorado sem bip.
