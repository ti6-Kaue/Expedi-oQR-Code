# Como gerar e baixar o APK pela rede

## 1. Descobrir o IP do computador

Abra o PowerShell e execute:

```powershell
ipconfig
```

Procure o endereço `IPv4` da conexão Ethernet ou Wi-Fi.

Exemplo usado atualmente:

```text
192.168.168.226
```

> OBS: se o IP mudar, substitua o endereço nos comandos abaixo.

## 2. Gerar o APK

Abra um terminal na pasta principal do projeto:

```powershell
cd "C:\Users\ti6\Desktop\Desvolvimento\Expedição-flutter"
flutter pub get
flutter build apk --debug --dart-define=ENDERECO_API=http://192.168.168.226:3001
```

O APK será gerado em:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

> OBS: `ENDERECO_API` informa ao aplicativo onde está o backend que grava as leituras no banco.

## 3. Ligar o backend

Abra outro terminal e execute:

```powershell
cd "C:\Users\ti6\Desktop\Desvolvimento\Expedição-flutter\backend"
npm run iniciar
```

Se aparecer que a porta `3001` já está sendo usada, a API provavelmente já está ligada.

## 4. Baixar no celular

Conecte o celular na mesma rede do computador e abra este endereço no navegador:

```text
http://192.168.168.226:3001/baixar-apk
```

O navegador baixará o arquivo `expedicao.apk`.

## 5. Instalar no Android

Abra o APK baixado. Se o Android solicitar, permita que o navegador instale aplicativos desconhecidos.

## Resumo para as próximas atualizações

Depois de alterar o aplicativo, normalmente basta executar novamente:

```powershell
cd "C:\Users\ti6\Desktop\Desvolvimento\Expedição-flutter"
flutter build apk --debug --dart-define=ENDERECO_API=http://192.168.168.226:3001
```

Não é necessário reiniciar o backend depois de gerar um novo APK. A rota de download entregará o arquivo atualizado.

## Se o celular não conseguir baixar

Confira:

- O celular e o computador estão na mesma rede.
- O backend está ligado.
- O IP do computador continua sendo `192.168.168.226`.
- A porta `3001` está liberada no Firewall do Windows.
- O endereço abre no navegador do computador: `http://192.168.168.226:3001/baixar-apk`.
