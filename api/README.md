# API local do leitor

Toda a configuração fica no arquivo `../configuracao.env`.

1. Preencha o IP deste computador e os dados do MySQL em `configuracao.env`.
2. Execute `npm install` nesta pasta na primeira instalação.
3. Abra `iniciar_api.cmd` e mantenha a janela aberta.
4. Para gerar o aplicativo com o IP configurado, abra `../gerar_apk.cmd`.

A API cria a tabela `scans` automaticamente. Teste a conexão abrindo
`http://localhost:3000/health`; o retorno esperado é `{ "ok": true }`.

Nos celulares, use o IPv4 deste computador, por exemplo
`http://192.168.1.50:3000`, nunca `localhost`.

## Rotas disponiveis

| Metodo | Rota | O que faz |
| --- | --- | --- |
| GET | `/` | Mostra a pagina para baixar o aplicativo. |
| GET | `/download` | Baixa o APK no celular. |
| GET | `/health` | Testa se a API consegue acessar o MySQL. |
| GET | `/scans` | Lista as 100 leituras mais recentes. |
| POST | `/scans` | Salva uma nova leitura no banco. |

O arquivo `src/routes/scans.js` possui observacoes em cada etapa para explicar
a validacao dos campos, a gravacao no MySQL e a resposta devolvida ao aplicativo.
