# Erro ao conectar com a API

Use este guia quando o aplicativo mostrar uma destas mensagens:

- `Não foi possível conectar com a API.`
- `A API demorou para responder.`
- A leitura fica processando e termina com erro.

## Verificação rápida

Confira nesta ordem:

1. O computador onde está o backend está ligado.
2. O backend está em execução.
3. O celular e o computador estão na mesma rede.
4. O IP do computador não mudou.
5. O APK foi gerado usando o IP correto.
6. A porta `3001` está liberada no Firewall do Windows.

## 1. Ligar o backend

Abra o PowerShell e execute:

```powershell
cd "C:\Users\ti6\Desktop\Desvolvimento\Expedição-flutter\backend"
npm run iniciar
```

Quando estiver correto, aparecerá:

```text
API disponível em http://0.0.0.0:3001
```

Deixe esse terminal aberto enquanto o aplicativo estiver sendo usado.

## 2. Testar a API e o banco

No navegador do computador, abra:

```text
http://127.0.0.1:3001/saude
```

O resultado esperado é:

```json
{
  "backend": "ok",
  "banco": "ok"
}
```

Se esse endereço não abrir, o backend está desligado ou apresentou erro.
Confira a mensagem exibida no terminal onde foi executado `npm run iniciar`.

## 3. Conferir o IP do computador

Execute:

```powershell
ipconfig
```

Procure o `Endereço IPv4` da conexão Ethernet ou Wi-Fi usada pelo celular.
Atualmente, o endereço usado no projeto é:

```text
192.168.168.226
```

O IP pode mudar quando o computador ou roteador for reiniciado.

## 4. Testar pelo endereço da rede

Substitua o IP abaixo se ele tiver mudado:

```text
http://192.168.168.226:3001/saude
```

Teste esse endereço primeiro no computador e depois no navegador do celular.

- Se funcionar no computador, mas não no celular, confira a rede e o firewall.
- Se não funcionar em nenhum dos dois, confira o backend e o IP.

## 5. Gerar o APK com o endereço correto

O APK instalado no celular não deve usar `127.0.0.1`. Esse endereço, dentro
do celular, aponta para o próprio celular e não para o computador.

Na pasta principal do projeto, execute:

```powershell
flutter build apk --debug --dart-define=ENDERECO_API=http://192.168.168.226:3001
```

Se o IP tiver mudado, altere o comando antes de gerar o APK.

O arquivo será criado em:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## 6. Baixar o APK no celular

Com o backend ligado, abra no celular:

```text
http://192.168.168.226:3001/baixar-apk
```

Depois, instale a nova versão por cima da anterior.

## 7. Conferir a porta 3001

No PowerShell, execute:

```powershell
Get-NetTCPConnection -LocalPort 3001 -State Listen
```

Se não aparecer nenhum resultado, não existe uma API escutando nessa porta.

## Causas mais comuns

### Backend desligado

Ocorre ao fechar o terminal do Node.js ou reiniciar o computador.

Solução: execute novamente `npm run iniciar` na pasta `backend`.

### APK usando `127.0.0.1`

O APK foi gerado sem o parâmetro `--dart-define=ENDERECO_API=...`.

Solução: gere e instale novamente o APK usando o IP do computador.

### IP do computador mudou

O roteador pode fornecer outro IP ao computador.

Solução: consulte `ipconfig` e gere novamente o APK com o novo IP.

### Celular em outra rede

O celular pode estar usando dados móveis ou outra rede Wi-Fi.

Solução: conecte o celular e o computador à mesma rede.

### Firewall bloqueando

A API funciona no computador, mas não abre pelo celular.

Solução: permita o Node.js em redes privadas no Firewall do Windows e
libere a entrada TCP na porta `3001`.

### Banco de dados indisponível

A API inicia, mas a rota `/saude` retorna erro.

Solução: confira a conexão de rede com o banco e as configurações no arquivo
`database/.env`. Não compartilhe a senha presente nesse arquivo.

## Resumo dos comandos

```powershell
# Descobrir o IP
ipconfig

# Ligar a API
cd "C:\Users\ti6\Desktop\Desvolvimento\Expedição-flutter\backend"
npm run iniciar

# Testar a API
Invoke-RestMethod http://192.168.168.226:3001/saude

# Gerar o APK
cd "C:\Users\ti6\Desktop\Desvolvimento\Expedição-flutter"
flutter build apk --debug --dart-define=ENDERECO_API=http://192.168.168.226:3001
```
