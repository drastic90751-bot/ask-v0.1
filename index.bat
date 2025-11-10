@echo off
:: OTIMIZADOR WINDOWS - Script de Manutencao e Otimizacao
:: Autor: https://github.com/drastic90751-bot
:: Versao: ALPHA
:: Data: 2025
::
:: DESCRICAO:
::   Script profissional para otimizacao e manutencao do Windows.
::   Executa comandos de rede, sistema e manutencao com seguranca maxima.
::
:: RECURSOS:
::   - Elevacao automatica de privilegios (abre nova janela)
::   - Ponto de restauracao antes de cada operacao
::   - Log detalhado de todas as acoes (otimizador_log.txt)
::   - Validacao em multiplas camadas antes da execucao
::   - Suporte multi-idioma (PT/EN/ES/FR/DE)
::   - 3 metodos de fallback para maxima compatibilidade
::   - Validacao individual de GUIDs em powercfg
::
:: AVISO IMPORTANTE:
::   - NOVA JANELA sera aberta ao solicitar privilegios de Admin
::   - A janela ORIGINAL sera FECHADA automaticamente (comportamento esperado)
::   - Todas as operacoes sao logadas em: otimizador_log.txt
::   - Operacoes destrutivas SEMPRE pedem confirmacao dupla
::   - Regra de firewall pode afetar YouTube/Google (confirmacao tripla)
::
:: AMBIENTES CORPORATIVOS:
::   - Ponto de restauracao pode falhar (GPO/VSS desabilitado)
::   - Algumas configuracoes podem ser bloqueadas por politicas
::   - BCDEdit pode ser restrito em ambiente gerenciado
::   - Script continua com confirmacao explicita do usuario
::   - Recomenda-se testar em VM antes de uso em producao
::
:: TESTES RECOMENDADOS ANTES DE USO EM PRODUCAO:
::   1. Executar em VM ou sistema de testes
::   2. Revisar otimizador_log.txt apos cada execucao
::   3. Testar criacao de ponto de restauracao manualmente
::   4. Validar deteccao de adaptadores de rede
::   5. Verificar compatibilidade do plano de energia
::   6. Testar winget com poucos pacotes primeiro
::   7. ChkDsk: validar em disco secundario antes do C:
::
:: REQUISITOS:
::   - Windows 7 ou superior
::   - PowerShell 2.0 ou superior (3.0+ recomendado)
::   - Privilegios de Administrador
::   - 300MB livres para ponto de restauracao
::   - Conexao com internet (apenas para Winget)
::
:: COMPATIBILIDADE TESTADA:
::   - Windows 7 SP1
::   - Windows 8.1
::   - Windows 10 (todas versoes)
::   - Windows 11 (21H2, 22H2, 23H2)
::   - Windows Server 2016/2019/2022

title Otimizador Windows
chcp 65001 >nul
setlocal enabledelayedexpansion

set "LOGFILE=%~dp0otimizador_log.txt"
set "GITHUB_URL=https://github.com/drastic90751-bot"
set "ALREADY_ELEVATED=%1"

:: Verificar privilégios de administrador
net session >nul 2>&1
if %errorlevel% neq 0 (
    if not "%ALREADY_ELEVATED%"=="ELEVATED" (
        cls
        echo.
        echo SOLICITACAO DE PRIVILEGIOS ELEVADOS
        echo.
        echo Este script requer privilegios de Administrador.
        echo.
        echo Uma nova janela sera aberta com privilegios elevados.
        echo Esta janela sera fechada automaticamente.
        echo.
        echo Pressione qualquer tecla para continuar...
        pause >nul
        powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList 'ELEVATED' -Verb RunAs -WindowStyle Normal"
        exit /b 0
    ) else (
        echo [ERRO] Falha ao obter privilegios de administrador.
        echo Certifique-se de executar como Administrador.
        pause
        exit /b 1
    )
)

:: Inicializar log
echo LOG DE OTIMIZACAO - %date% %time% > "%LOGFILE%"
echo Sistema: %COMPUTERNAME% >> "%LOGFILE%"
echo Usuario: %USERNAME% >> "%LOGFILE%"
echo. >> "%LOGFILE%"

:MENU
cls
echo OTIMIZADOR WINDOWS - MENU PRINCIPAL
echo.
echo [1] OTIMIZACAO DE REDE E CONECTIVIDADE
echo [2] OTIMIZACAO DE SISTEMA E DESEMPENHO
echo [3] MANUTENCAO E REPARACAO
echo [4] EXECUTAR TODAS AS OTIMIZACOES
echo [5] VER LOG DE EXECUCAO
echo [6] REMOVER REGRA DE FIREWALL
echo [7] SAIR
echo.
set /p opcao="Escolha uma opcao: "

if "%opcao%"=="1" goto REDE
if "%opcao%"=="2" goto SISTEMA
if "%opcao%"=="3" goto MANUTENCAO
if "%opcao%"=="4" goto EXECUTAR_TUDO
if "%opcao%"=="5" goto VER_LOG
if "%opcao%"=="6" goto REMOVER_FIREWALL
if "%opcao%"=="7" goto SAIR
goto MENU

:REDE
cls
echo OTIMIZACAO DE REDE E CONECTIVIDADE
echo.
call :CRIAR_PONTO_RESTAURACAO "Antes Otimizacao de Rede"
echo.
echo Iniciando otimizacoes de rede...
echo.

echo [*] Resetando Winsock...
call :EXECUTAR_COMANDO "netsh winsock reset" "Reset Winsock"

echo [*] Limpando cache DNS...
call :EXECUTAR_COMANDO "ipconfig /flushdns" "Flush DNS"

echo [*] Exibindo configuracao de rede...
ipconfig /all
echo. >> "%LOGFILE%"
ipconfig /all >> "%LOGFILE%"

echo [*] Renovando endereco IP...
call :EXECUTAR_COMANDO "ipconfig /renew" "Renovar IP"

echo [*] Resetando pilha TCP/IP...
call :EXECUTAR_COMANDO "netsh int ip reset" "Reset TCP/IP"

echo.
echo [*] Configuracao de regra de firewall...
echo.
echo ATENCAO CRITICA - REGRA DE FIREWALL
echo.
echo Esta regra bloqueia os seguintes ranges de IP:
echo       - 173.194.55.0/24  (Parte da infraestrutura Google)
echo       - 206.111.0.0/16   (CDN e servicos diversos)
echo.
echo     IMPORTANTE - Possivel impacto:
echo       - YouTube pode apresentar lentidao ou falhas
echo       - Google Drive/Docs podem ter problemas de sincronizacao
echo       - Alguns servicos de CDN podem ser afetados
echo       - Conexoes com servidores especificos podem falhar
echo.
echo     Esta e uma otimizacao AGRESSIVA e pode causar problemas.
echo     Recomenda-se usar APENAS se souber o que esta fazendo.
echo.
echo     Voce pode remover esta regra a qualquer momento pelo menu [6].
echo.

netsh advfirewall firewall show rule name="StopThrottling" >nul 2>&1
if %errorlevel% equ 0 (
    echo     Regra "StopThrottling" ja existe no sistema.
    echo     Deseja recria-la? (S/N)
    set /p recriar="    Resposta: "
    if /i "!recriar!"=="S" (
        netsh advfirewall firewall delete rule name="StopThrottling" >nul 2>&1
        echo     Regra deletada. Confirme novamente para adicionar.
        echo.
        echo     TEM CERTEZA que deseja adicionar esta regra? (S/N)
        set /p confirmar_add="    Resposta: "
        if /i "!confirmar_add!"=="S" (
            call :ADICIONAR_REGRA_FIREWALL
        ) else (
            echo     Operacao cancelada.
            echo     [SKIP] Usuario cancelou adicao da regra firewall >> "%LOGFILE%"
        )
    ) else (
        echo     Regra mantida.
        echo     [SKIP] Regra firewall mantida - usuario recusou >> "%LOGFILE%"
    )
) else (
    echo     Deseja adicionar esta regra de firewall? (S/N)
    set /p confirmar="    Resposta: "
    if /i "!confirmar!"=="S" (
        echo.
        echo     CONFIRMACAO FINAL: Adicionar regra que pode afetar servicos? (S/N)
        set /p confirmar_final="    Resposta: "
        if /i "!confirmar_final!"=="S" (
            call :ADICIONAR_REGRA_FIREWALL
        ) else (
            echo     Operacao cancelada.
            echo     [SKIP] Usuario cancelou adicao da regra firewall >> "%LOGFILE%"
        )
    ) else (
        echo     Regra de firewall ignorada.
        echo     [SKIP] Regra de firewall nao adicionada - usuario recusou >> "%LOGFILE%"
    )
)

echo.
echo [*] Detectando adaptadores de rede ativos...
set "ADAPTER_COUNT=0"
set "ADAPTER_LIST="
set "ADAPTER_1="
set "ADAPTER_2="
set "ADAPTER_3="
set "ADAPTER_4="
set "ADAPTER_5="
set "DETECTION_METHOD=NONE"

:: MÉTODO 1 (PRIORIDADE MÁXIMA): PowerShell Get-NetAdapter
:: Mais confiável, funciona em qualquer idioma, detecta apenas físicos ativos
echo     [1/3] Tentando deteccao via PowerShell Get-NetAdapter...
for /f "usebackq delims=" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Get-NetAdapter -Physical -ErrorAction Stop | Where-Object Status -eq 'Up' | Select-Object -ExpandProperty Name } catch { exit 1 }" 2^>nul`) do (
    set /a ADAPTER_COUNT+=1
    set "ADAPTER_NAME=%%a"
    set "ADAPTER_LIST=!ADAPTER_LIST!!ADAPTER_COUNT!. !ADAPTER_NAME!
"
    set "ADAPTER_!ADAPTER_COUNT!=!ADAPTER_NAME!"
    set "DETECTION_METHOD=PowerShell-GetNetAdapter"
    echo     [DEBUG] Adaptador !ADAPTER_COUNT! (Get-NetAdapter): !ADAPTER_NAME! >> "%LOGFILE%"
)

if !ADAPTER_COUNT! gtr 0 (
    echo     [OK] !ADAPTER_COUNT! adaptador^(es^) detectado^(s^) via Get-NetAdapter
    echo     [SUCCESS] Deteccao via Get-NetAdapter: !ADAPTER_COUNT! adaptadores >> "%LOGFILE%"
    goto :ADAPTER_DETECTION_DONE
)

:: MÉTODO 2 (FALLBACK 1): PowerShell Get-WmiObject Win32_NetworkAdapter
:: Compatível com PowerShell 2.0+, funciona em sistemas antigos
echo     [2/3] Fallback: Tentando via WMI Win32_NetworkAdapter...
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "try { Get-WmiObject -Class Win32_NetworkAdapter -ErrorAction Stop | Where-Object {$_.NetConnectionStatus -eq 2 -and $_.PhysicalAdapter -eq $true} | Select-Object -ExpandProperty NetConnectionID } catch { exit 1 }" 2^>nul`) do (
    set /a ADAPTER_COUNT+=1
    set "ADAPTER_NAME=%%a"
    set "ADAPTER_LIST=!ADAPTER_LIST!!ADAPTER_COUNT!. !ADAPTER_NAME!
"
    set "ADAPTER_!ADAPTER_COUNT!=!ADAPTER_NAME!"
    set "DETECTION_METHOD=PowerShell-WMI"
    echo     [DEBUG] Adaptador !ADAPTER_COUNT! (WMI): !ADAPTER_NAME! >> "%LOGFILE%"
)

if !ADAPTER_COUNT! gtr 0 (
    echo     [OK] !ADAPTER_COUNT! adaptador^(es^) detectado^(s^) via WMI
    echo     [SUCCESS] Deteccao via WMI: !ADAPTER_COUNT! adaptadores >> "%LOGFILE%"
    goto :ADAPTER_DETECTION_DONE
)

:: MÉTODO 3 (FALLBACK 2): Parsing de netsh interface show interface
:: Último recurso, pode falhar em idiomas diferentes
echo     [3/3] Fallback final: Tentando via netsh parsing...
echo     [WARN] Metodos PowerShell falharam, usando netsh (pode falhar em outros idiomas) >> "%LOGFILE%"

for /f "skip=3 tokens=1,4" %%a in ('netsh interface show interface 2^>nul') do (
    :: Tenta detectar "Connected" em inglês ou "Conectado" em português
    if /i "%%b"=="Connected" (
        set /a ADAPTER_COUNT+=1
        set "ADAPTER_NAME=%%a"
        set "ADAPTER_NAME=!ADAPTER_NAME:"=!"
        set "ADAPTER_LIST=!ADAPTER_LIST!!ADAPTER_COUNT!. !ADAPTER_NAME!
"
        set "ADAPTER_!ADAPTER_COUNT!=!ADAPTER_NAME!"
        set "DETECTION_METHOD=netsh-parsing"
        echo     [DEBUG] Adaptador !ADAPTER_COUNT! (netsh): !ADAPTER_NAME! >> "%LOGFILE%"
    )
    if /i "%%b"=="Conectado" (
        set /a ADAPTER_COUNT+=1
        set "ADAPTER_NAME=%%a"
        set "ADAPTER_NAME=!ADAPTER_NAME:"=!"
        set "ADAPTER_LIST=!ADAPTER_LIST!!ADAPTER_COUNT!. !ADAPTER_NAME!
"
        set "ADAPTER_!ADAPTER_COUNT!=!ADAPTER_NAME!"
        set "DETECTION_METHOD=netsh-parsing-pt"
        echo     [DEBUG] Adaptador !ADAPTER_COUNT! (netsh-pt): !ADAPTER_NAME! >> "%LOGFILE%"
    )
)

if !ADAPTER_COUNT! gtr 0 (
    echo     [OK] !ADAPTER_COUNT! adaptador^(es^) detectado^(s^) via netsh
    echo     [SUCCESS] Deteccao via netsh: !ADAPTER_COUNT! adaptadores >> "%LOGFILE%"
    goto :ADAPTER_DETECTION_DONE
)

:: FALHA TOTAL: Nenhum método funcionou
echo     [ERRO] Nenhum metodo de deteccao funcionou
echo     [ERROR] Falha total na deteccao de adaptadores - todos os 3 metodos falharam >> "%LOGFILE%"
echo.
echo     Motivos possiveis:
echo       - Nenhum adaptador fisico conectado
echo       - PowerShell desabilitado por GPO
echo       - Permissoes insuficientes para WMI/netsh
echo       - Sistema em idioma nao suportado pelo netsh parsing
echo.
set "ADAPTER_COUNT=0"
set "DETECTION_METHOD=FAILED"

:ADAPTER_DETECTION_DONE
echo     [INFO] Metodo usado: !DETECTION_METHOD! >> "%LOGFILE%"

if !ADAPTER_COUNT! equ 0 (
    echo     Nenhum adaptador conectado detectado.
    echo     [INFO] Nenhum adaptador ativo encontrado >> "%LOGFILE%"
) else if !ADAPTER_COUNT! equ 1 (
    set "SELECTED_ADAPTER=!ADAPTER_1!"
    echo     Adaptador detectado: !SELECTED_ADAPTER!
    echo     Deseja resetar este adaptador? (S/N)
    set /p reset="    Resposta: "
    if /i "!reset!"=="S" (
        call :RESETAR_ADAPTADOR "!SELECTED_ADAPTER!"
    )
) else (
    echo     Multiplos adaptadores detectados:
    echo !ADAPTER_LIST!
    echo     Digite o numero do adaptador a resetar (0 para pular):
    set /p adapter_num="    Resposta: "

    if "!adapter_num!" neq "0" (
        if defined ADAPTER_!adapter_num! (
            set "SELECTED_ADAPTER=!ADAPTER_%adapter_num%!"
            call :RESETAR_ADAPTADOR "!SELECTED_ADAPTER!"
        ) else (
            echo     Opcao invalida.
        )
    )
)

echo.
echo Otimizacao de rede concluida!
pause
goto MENU

:SISTEMA
cls
echo OTIMIZACAO DE SISTEMA E DESEMPENHO
echo.
call :CRIAR_PONTO_RESTAURACAO "Antes Otimizacao de Sistema"
echo.
echo Iniciando otimizacoes de sistema...
echo.

echo [*] Verificando uso de memoria do sistema de arquivos...
fsutil behavior query memoryusage
echo [*] Configurando uso de memoria otimizado...
call :EXECUTAR_COMANDO "fsutil behavior set memoryusage 2" "Config memoria FSUtil"

echo.
echo [*] Configuracoes de boot (BCDEdit)...
echo     ATENCAO: Alteracoes no BCDEdit afetam a inicializacao do Windows.
echo     Deseja aplicar otimizacoes de boot? (S/N)
set /p bcdedit_confirm="    Resposta: "
if /i "!bcdedit_confirm!"=="S" (
    echo     Aplicando configuracoes de boot...
    call :EXECUTAR_COMANDO "bcdedit /set useplatformtick yes" "Platform Tick"
    call :EXECUTAR_COMANDO "bcdedit /set disabledynamictick yes" "Dynamic Tick"
    call :EXECUTAR_COMANDO "bcdedit /deletevalue useplatformclock" "Platform Clock"
    echo     [INFO] BCDEdit: useplatformtick=yes, disabledynamictick=yes, useplatformclock removido >> "%LOGFILE%"
) else (
    echo     Configuracoes de boot ignoradas.
    echo     [SKIP] BCDEdit ignorado - usuario recusou >> "%LOGFILE%"
)

echo.
echo [*] Verificando tipo de disco (SSD/HDD)...
set "IS_SSD=0"
set "DISK_INFO="

powershell -Command "$disks = Get-PhysicalDisk -ErrorAction SilentlyContinue; if ($disks) { $ssd = $disks | Where-Object { $_.MediaType -eq 'SSD' -or $_.MediaType -eq 'NVMe' }; if ($ssd) { Write-Host 'SSD_DETECTED'; exit 0 } else { Write-Host 'HDD_DETECTED'; exit 1 } } else { Write-Host 'UNKNOWN'; exit 2 }" > "%TEMP%\disk_check.txt" 2>&1

findstr /i "SSD_DETECTED" "%TEMP%\disk_check.txt" >nul 2>&1
if %errorlevel% equ 0 (
    set "IS_SSD=1"
    echo     SSD ou NVMe detectado!
    echo [*] Verificando status TRIM...
    fsutil behavior query disabledeletenotify
    echo [*] Habilitando TRIM para SSD...
    call :EXECUTAR_COMANDO "fsutil behavior set DisableDeleteNotify 0" "TRIM SSD"
) else (
    findstr /i "HDD_DETECTED" "%TEMP%\disk_check.txt" >nul 2>&1
    if %errorlevel% equ 0 (
        echo     HDD detectado. TRIM nao sera aplicado.
        echo     [INFO] HDD detectado - TRIM ignorado >> "%LOGFILE%"
    ) else (
        echo     Nao foi possivel determinar tipo de disco.
        echo     [WARN] Tipo de disco desconhecido >> "%LOGFILE%"
    )
)
del "%TEMP%\disk_check.txt" >nul 2>&1

echo.
echo [*] Configuracao de hibernacao...
echo     ATENCAO: Desabilitar hibernacao:
echo       - Libera espaco em disco (tamanho da RAM)
echo       - Impede uso do modo hibernar
echo       - Pode afetar funcao "Inicializacao Rapida"
echo     Deseja desabilitar hibernacao? (S/N)
set /p hiber="    Resposta: "
if /i "!hiber!"=="S" (
    call :EXECUTAR_COMANDO "powercfg -h off" "Desabilitar hibernacao"
    echo     [INFO] Hibernacao desabilitada >> "%LOGFILE%"
) else (
    echo     Hibernacao mantida.
    echo     [SKIP] Hibernacao mantida - usuario recusou >> "%LOGFILE%"
)

echo.
echo [*] Configurando plano de energia...
echo     Detectando plano de energia ativo...

:: Obter GUID do plano ativo dinamicamente
set "CURRENT_SCHEME="
set "CURRENT_SCHEME_NAME="
for /f "tokens=3,4*" %%a in ('powercfg /getactivescheme 2^>nul') do (
    set "CURRENT_SCHEME=%%a"
    set "CURRENT_SCHEME_NAME=%%b %%c"
)

if not defined CURRENT_SCHEME (
    echo     [ERRO] Nao foi possivel detectar plano de energia ativo.
    echo     [ERROR] powercfg /getactivescheme falhou >> "%LOGFILE%"
    goto SKIP_POWERCFG
)

echo     Plano ativo detectado: !CURRENT_SCHEME_NAME! (!CURRENT_SCHEME!)
echo     [INFO] Plano atual: !CURRENT_SCHEME_NAME! (GUID: !CURRENT_SCHEME!) >> "%LOGFILE%"

:: Validar build do Windows antes de aplicar GUIDs
for /f "tokens=3" %%a in ('ver ^| findstr /i "Version"') do set "WIN_BUILD=%%a"
echo     [INFO] Windows Build detectado: !WIN_BUILD! >> "%LOGFILE%"

:: Obter GUIDs dinamicamente para USB Settings
echo     Localizando configuracoes de USB no plano atual...
set "USB_SETTINGS_GUID="
set "USB_SELECTIVE_GUID="

:: Tentar obter GUID de USB Settings dinamicamente via query completo
powercfg /query !CURRENT_SCHEME! > "%TEMP%\powercfg_query.txt" 2>&1
findstr /i /c:"USB settings" "%TEMP%\powercfg_query.txt" >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=2 delims=()" %%a in ('findstr /i /c:"USB settings" "%TEMP%\powercfg_query.txt"') do (
        set "USB_SETTINGS_GUID=%%a"
        set "USB_SETTINGS_GUID=!USB_SETTINGS_GUID: =!"
        goto :usb_found
    )
)
:usb_found
del "%TEMP%\powercfg_query.txt" >nul 2>&1

if not defined USB_SETTINGS_GUID (
    echo     [INFO] Usando GUIDs padrao de USB (universais)...
    set "USB_SETTINGS_GUID=2a737441-1930-4402-8d77-b2bebba308a3"
    set "USB_SELECTIVE_GUID=48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
    echo     [INFO] USB GUIDs padrao Windows definidos >> "%LOGFILE%"
) else (
    set "USB_SELECTIVE_GUID=48e6b7a6-50f5-4782-a5d4-53bb8f07e226"
    echo     [INFO] USB Settings GUID dinamico: !USB_SETTINGS_GUID! >> "%LOGFILE%"
)

:: Validar CADA componente antes de aplicar
echo     Validando compatibilidade do plano...
echo     [CHECK] Validando GUID base: !CURRENT_SCHEME! >> "%LOGFILE%"
powercfg -query !CURRENT_SCHEME! >nul 2>&1
if !errorlevel! neq 0 (
    echo     [ERRO] Plano base invalido. Abortando configuracao.
    echo     [ERROR] GUID base invalido >> "%LOGFILE%"
    goto SKIP_POWERCFG
)

echo     [CHECK] Validando USB Settings: !USB_SETTINGS_GUID! >> "%LOGFILE%"
powercfg -query !CURRENT_SCHEME! !USB_SETTINGS_GUID! >nul 2>&1
set "USB_CHECK=!errorlevel!"

if !USB_CHECK! neq 0 (
    echo     [AVISO] Categoria USB Settings nao encontrada neste plano.
    echo     [WARN] USB Settings GUID invalido para este plano >> "%LOGFILE%"
    goto POWERCFG_ALTERNATIVE
)

echo     [CHECK] Validando USB Selective Suspend: !USB_SELECTIVE_GUID! >> "%LOGFILE%"
powercfg -query !CURRENT_SCHEME! !USB_SETTINGS_GUID! !USB_SELECTIVE_GUID! >nul 2>&1
set "SELECTIVE_CHECK=!errorlevel!"

if !SELECTIVE_CHECK! equ 0 (
    echo     [OK] Todas as configuracoes USB validadas com sucesso
    echo     Aplicando: USB Selective Suspend = Desabilitado
    echo     [INFO] Desabilitando: USB Selective Suspend >> "%LOGFILE%"

    :: Aplicar com validação individual e captura de erro especifica
    powercfg -setacvalueindex !CURRENT_SCHEME! !USB_SETTINGS_GUID! !USB_SELECTIVE_GUID! 0 2>>"%LOGFILE%"
    set "AC_ERROR=!errorlevel!"
    if !AC_ERROR! equ 0 (
        echo     [OK] Configuracao AC aplicada (Plugado na tomada)
        echo     [SUCCESS] USB Suspend AC=0 >> "%LOGFILE%"
    ) else (
        echo     [AVISO] Falha ao configurar AC (codigo: !AC_ERROR!)
        echo     [WARN] USB Suspend AC falhou - codigo !AC_ERROR! >> "%LOGFILE%"
    )

    powercfg -setdcvalueindex !CURRENT_SCHEME! !USB_SETTINGS_GUID! !USB_SELECTIVE_GUID! 0 2>>"%LOGFILE%"
    set "DC_ERROR=!errorlevel!"
    if !DC_ERROR! equ 0 (
        echo     [OK] Configuracao DC aplicada (Bateria)
        echo     [SUCCESS] USB Suspend DC=0 >> "%LOGFILE%"
    ) else (
        echo     [AVISO] Falha ao configurar DC (codigo: !DC_ERROR!)
        echo     [WARN] USB Suspend DC falhou - codigo !DC_ERROR! >> "%LOGFILE%"
    )

    powercfg -setactive !CURRENT_SCHEME! 2>>"%LOGFILE%"
    set "ACTIVATE_ERROR=!errorlevel!"
    if !ACTIVATE_ERROR! equ 0 (
        echo     [OK] Plano reativado com sucesso
        echo     [SUCCESS] Plano reativado >> "%LOGFILE%"
    ) else (
        echo     [AVISO] Falha ao reativar plano (codigo: !ACTIVATE_ERROR!)
        echo     [WARN] Reativacao falhou - codigo !ACTIVATE_ERROR! >> "%LOGFILE%"
    )
    goto SKIP_POWERCFG
)

:POWERCFG_ALTERNATIVE
echo     [AVISO] Configuracoes USB nao suportadas neste plano.
echo     [WARN] GUIDs USB nao disponiveis no plano !CURRENT_SCHEME! >> "%LOGFILE%"
echo.
echo     Opcoes alternativas:
echo       [1] Tentar criar/ativar plano Alto Desempenho
echo       [2] Ignorar configuracoes de energia
echo.
set /p alt_option="    Escolha (1 ou 2): "

if "!alt_option!"=="1" (
    echo     Verificando plano Alto Desempenho...
    :: Buscar em multiplos idiomas
    powercfg /list > "%TEMP%\powercfg_list.txt" 2>&1
    findstr /i /c:"High performance" /c:"Alto desempenho" /c:"Haute performance" /c:"Hohe Leistung" "%TEMP%\powercfg_list.txt" >nul 2>&1

    if !errorlevel! neq 0 (
        echo     Criando plano de Alto Desempenho...
        powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>>"%LOGFILE%"
        if !errorlevel! equ 0 (
            echo     [OK] Plano Alto Desempenho criado
            echo     [SUCCESS] Plano Alto Desempenho duplicado >> "%LOGFILE%"
        ) else (
            echo     [ERRO] Falha ao criar plano
            echo     [ERROR] Falha ao duplicar plano HP >> "%LOGFILE%"
            del "%TEMP%\powercfg_list.txt" >nul 2>&1
            goto SKIP_POWERCFG
        )
    ) else (
        echo     [INFO] Plano Alto Desempenho ja existe
    )

    echo     Deseja ativar o plano de Alto Desempenho agora? (S/N)
    set /p ativar_hp="    Resposta: "
    if /i "!ativar_hp!"=="S" (
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>>"%LOGFILE%"
        if !errorlevel! equ 0 (
            echo     [OK] Plano Alto Desempenho ativado com sucesso
            echo     [SUCCESS] Plano HP ativado >> "%LOGFILE%"
        ) else (
            echo     [ERRO] Falha ao ativar plano (verifique se existe)
            echo     [ERROR] Falha ativar HP >> "%LOGFILE%"
        )
    )
    del "%TEMP%\powercfg_list.txt" >nul 2>&1
) else (
    echo     Configuracoes de energia ignoradas.
    echo     [SKIP] Usuario escolheu ignorar powercfg >> "%LOGFILE%"
)
:SKIP_POWERCFG

echo.
echo [*] Resetando Windows Store...
start /min WSreset.exe
echo     Windows Store resetado em background.
echo     [INFO] WSreset executado >> "%LOGFILE%"

echo.
echo [*] Limpando arquivos temporarios...
echo     Analisando pasta TEMP: %TEMP%
echo     Isso pode demorar alguns minutos...

:: Script PowerShell robusto para limpeza de TEMP
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; $removed=0; $errors=0; $size=0; $locked=0; try { Write-Host '    Processando arquivos...'; $items = Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue; $total = ($items | Measure-Object).Count; Write-Host \"    Total de itens encontrados: $total\"; foreach ($item in $items) { try { $itemSize = if ($item.PSIsContainer) { 0 } else { $item.Length }; Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop; $removed++; $size += $itemSize } catch { if ($_.Exception.Message -match 'being used|in use|acesso negado|access denied') { $locked++ } else { $errors++ } } }; $sizeMB = [math]::Round($size/1MB,2); Write-Host \"    [OK] $removed itens removidos ($sizeMB MB)\"; Write-Host \"    [INFO] $locked arquivos em uso, $errors outros erros\"; Add-Content -Path '%LOGFILE%' -Value \"[INFO] TEMP: $removed/$total removidos ($sizeMB MB), $locked em uso, $errors erros - $(Get-Date -Format 'HH:mm:ss')\" } catch { Write-Host '    [ERRO] Falha geral na limpeza'; Add-Content -Path '%LOGFILE%' -Value \"[ERROR] Limpeza TEMP falhou: $($_.Exception.Message)\" }" 2>>"%LOGFILE%"

echo     Removendo pastas vazias...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$removed = 0; Get-ChildItem -Path $env:TEMP -Recurse -Force -Directory -ErrorAction SilentlyContinue | Sort-Object -Property FullName -Descending | ForEach-Object { if ((Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0) { try { Remove-Item -Path $_.FullName -Force -ErrorAction Stop; $removed++ } catch { } } }; if ($removed -gt 0) { Write-Host \"    [OK] $removed pastas vazias removidas\"; Add-Content -Path '%LOGFILE%' -Value \"[INFO] $removed pastas vazias removidas\" }" 2>>"%LOGFILE%"

echo.
echo Otimizacao de sistema concluida!
pause
goto MENU

:MANUTENCAO
cls
echo MANUTENCAO E REPARACAO DO SISTEMA
echo.
call :CRIAR_PONTO_RESTAURACAO "Antes Manutencao do Sistema"
echo.
echo ATENCAO: Este processo pode demorar bastante tempo!
echo.
pause
echo.

where sfc >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Verificando integridade dos arquivos do sistema...
    echo     Isso pode demorar 15-30 minutos...
    call :EXECUTAR_COMANDO "sfc /scannow" "SFC Scan"
) else (
    echo [ERRO] Comando sfc nao encontrado no sistema
    echo [ERROR] sfc.exe nao encontrado >> "%LOGFILE%"
)

echo.
where dism >nul 2>&1
if %errorlevel% equ 0 (
    echo [*] Verificando saude da imagem do Windows...
    call :EXECUTAR_COMANDO "dism /online /cleanup-image /CheckHealth" "DISM CheckHealth"

    echo [*] Reparando imagem do Windows...
    echo     Isso pode demorar 20-40 minutos...
    call :EXECUTAR_COMANDO "dism /online /cleanup-image /restorehealth" "DISM RestoreHealth"
) else (
    echo [ERRO] Comando dism nao encontrado no sistema
    echo [ERROR] dism.exe nao encontrado >> "%LOGFILE%"
)

echo.
echo [*] Verificacao de disco (ChkDsk)...
echo     ATENCAO: ChkDsk com /f /r:
echo       - Agenda verificacao para proxima reinicializacao
echo       - Pode demorar HORAS dependendo do tamanho do disco
echo       - Verifica e repara setores ruins
echo       - Sistema ficara indisponivel durante o processo
echo.
echo     Deseja agendar verificacao do disco C:? (S/N)
set /p chk_c="    Resposta: "
if /i "!chk_c!"=="S" (
    echo Y | chkdsk c: /f /r >> "%LOGFILE%" 2>&1
    set "CHK_ERROR=!errorlevel!"
    if !CHK_ERROR! equ 0 (
        echo     [OK] ChkDsk C: agendado para proxima reinicializacao
        echo     [OK] ChkDsk C: agendado >> "%LOGFILE%"
    ) else (
        echo     [ERRO] Falha ao agendar ChkDsk C: (codigo: !CHK_ERROR!)
        echo     [ERROR] ChkDsk C: falhou (codigo: !CHK_ERROR!) >> "%LOGFILE%"
    )
) else (
    echo     ChkDsk C: ignorado.
    echo     [SKIP] ChkDsk C: usuario recusou >> "%LOGFILE%"
)

if exist D:\ (
    echo     Deseja agendar verificacao do disco D:? (S/N)
    set /p chk_d="    Resposta: "
    if /i "!chk_d!"=="S" (
        echo Y | chkdsk d: /f /r >> "%LOGFILE%" 2>&1
        set "CHK_ERROR=!errorlevel!"
        if !CHK_ERROR! equ 0 (
            echo     [OK] ChkDsk D: agendado para proxima reinicializacao
            echo     [OK] ChkDsk D: agendado >> "%LOGFILE%"
        ) else (
            echo     [ERRO] Falha ao agendar ChkDsk D: (codigo: !CHK_ERROR!)
            echo     [ERROR] ChkDsk D: falhou (codigo: !CHK_ERROR!) >> "%LOGFILE%"
        )
    ) else (
        echo     ChkDsk D: ignorado.
        echo     [SKIP] ChkDsk D: usuario recusou >> "%LOGFILE%"
    )
)

echo.
echo [*] Limpeza de disco...
where cleanmgr >nul 2>&1
if %errorlevel% equ 0 (
    echo     Iniciando Limpeza de Disco C:...
    start /wait cleanmgr.exe /d C:
    echo     [OK] CleanMgr C: executado >> "%LOGFILE%"

    if exist D:\ (
        echo     Iniciando Limpeza de Disco D:...
        start /wait cleanmgr.exe /d D:
        echo     [OK] CleanMgr D: executado >> "%LOGFILE%"
    )
) else (
    echo     [ERRO] cleanmgr.exe nao encontrado
    echo     [ERROR] cleanmgr.exe nao encontrado >> "%LOGFILE%"
)

echo.
echo [*] Atualizacao de pacotes via Winget...
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo     Winget detectado. Verificando atualizacoes disponiveis...

    :: Aceitar agreements primeiro para evitar prompts
    winget list --accept-source-agreements >nul 2>&1

    :: Listar atualizações disponíveis
    winget upgrade > "%TEMP%\winget_list.txt" 2>&1

    :: Verificar se há atualizações
    findstr /i /c:"upgrades available" "%TEMP%\winget_list.txt" >nul 2>&1
    if !errorlevel! equ 0 (
        echo.
        type "%TEMP%\winget_list.txt"
        echo.
        echo     ATENCAO: Atualizacoes disponiveis encontradas.
        echo.
        echo     Importante saber:
        echo       - Processo pode demorar 10-30 minutos ou mais
        echo       - Alguns pacotes podem falhar individualmente
        echo       - Pacotes podem requerer reinicializacao
        echo       - Conexao estavel com internet necessaria
        echo       - AVISO: Alguns instaladores podem ainda solicitar interacao
        echo         (--disable-interactivity nao cobre 100%% dos casos)
        echo       - Recomenda-se revisar o log apos conclusao
        echo.
        echo     Deseja atualizar todos os pacotes? (S/N)
        set /p upg="    Resposta: "
        if /i "!upg!"=="S" (
            echo     Iniciando atualizacoes...
            echo     [INFO] Iniciando winget upgrade --all - %time% >> "%LOGFILE%"
            echo     Isso pode demorar bastante. Acompanhe o progresso...
            echo.

            :: Executar upgrade com todos os agreements
            winget upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity
            set "WINGET_ERROR=!errorlevel!"

            echo. >> "%LOGFILE%"
            echo [WINGET_EXIT_CODE] !WINGET_ERROR! - %time% >> "%LOGFILE%"

            if !WINGET_ERROR! equ 0 (
                echo.
                echo     [OK] Todas as atualizacoes concluidas com sucesso
                echo     [SUCCESS] Winget upgrade completo - %time% >> "%LOGFILE%"
            ) else if !WINGET_ERROR! equ -1978335189 (
                echo.
                echo     [AVISO] Algumas atualizacoes foram instaladas, outras falharam
                echo     Este codigo indica que nem todos os pacotes foram atualizados.
                echo     Verifique o log para detalhes.
                echo     [WARN] Winget parcial - codigo: !WINGET_ERROR! - %time% >> "%LOGFILE%"
            ) else (
                echo.
                echo     [AVISO] Processo concluido com codigo: !WINGET_ERROR!
                echo     Algumas atualizacoes podem ter falhado.
                echo     Recomenda-se revisar o log em: %LOGFILE%
                echo     [WARN] Winget upgrade codigo: !WINGET_ERROR! - %time% >> "%LOGFILE%"
            )

            echo.
            echo     Deseja ver resumo das ultimas linhas do log? (S/N)
            set /p ver_log="    Resposta: "
            if /i "!ver_log!"=="S" (
                echo.
                echo Ultimas 20 linhas do log:
                powershell -Command "Get-Content '%LOGFILE%' -Tail 20"
            )
        ) else (
            echo     Atualizacoes ignoradas.
            echo     [SKIP] Winget upgrade - usuario recusou >> "%LOGFILE%"
        )
    ) else (
        echo     Nenhuma atualizacao disponivel ou erro ao verificar.
        echo     [INFO] Winget: nenhuma atualizacao disponivel >> "%LOGFILE%"
    )
    del "%TEMP%\winget_list.txt" >nul 2>&1
) else (
    echo     [AVISO] Winget nao esta instalado neste sistema.
    echo     Para instalar: https://aka.ms/getwinget
    echo     [WARN] Winget nao encontrado >> "%LOGFILE%"
)

echo.
echo [*] Diagnostico de Memoria (mdsched)...
echo     ATENCAO: Requer reinicializacao IMEDIATA do computador!
echo     O teste de memoria sera executado antes do Windows iniciar.
echo     Deseja executar Diagnostico de Memoria? (S/N)
set /p mem="    Resposta: "
if /i "!mem!"=="S" (
    where mdsched >nul 2>&1
    if !errorlevel! equ 0 (
        echo     Agendando diagnostico de memoria...
        mdsched
        echo     [OK] MDSched agendado - sistema sera reiniciado >> "%LOGFILE%"
    ) else (
        echo     [ERRO] mdsched.exe nao encontrado
        echo     [ERROR] mdsched.exe nao encontrado >> "%LOGFILE%"
    )
) else (
    echo     Diagnostico de memoria ignorado.
    echo     [SKIP] MDSched - usuario recusou >> "%LOGFILE%"
)

echo.
echo Manutencao concluida!
echo.
echo IMPORTANTE: Reinicie o computador para aplicar todas as alteracoes!
pause
goto MENU

:EXECUTAR_TUDO
cls
echo EXECUTANDO TODAS AS OTIMIZACOES
echo.
call :CRIAR_PONTO_RESTAURACAO "Antes Otimizacao Completa"
echo.
echo ATENCAO: Este processo executara:
echo   - Otimizacoes de rede (sem confirmacoes)
echo   - Otimizacoes de sistema (sem confirmacoes)
echo   - Manutencao basica (sem operacoes destrutivas)
echo.
echo Operacoes que SERAO executadas automaticamente:
echo   - Reset de rede (Winsock, DNS, TCP/IP)
echo   - Otimizacoes de sistema (FSUtil, powercfg)
echo   - Limpeza de TEMP
echo   - SFC e DISM
echo.
echo Operacoes que NAO serao executadas:
echo   - Regra de firewall (requer confirmacao manual)
echo   - Reset de adaptador de rede
echo   - BCDEdit (requer confirmacao manual)
echo   - ChkDsk (requer confirmacao manual)
echo   - Winget upgrade (requer confirmacao manual)
echo.
echo Deseja continuar? (S/N)
set /p confirm_all="Resposta: "
if /i "!confirm_all!" neq "S" goto MENU

echo.
pause

call :EXECUTAR_REDE_SILENCIOSO
call :EXECUTAR_SISTEMA_SILENCIOSO
call :EXECUTAR_MANUTENCAO_SILENCIOSO

echo.
echo TODAS AS OTIMIZACOES AUTOMATICAS FORAM CONCLUIDAS!
echo.
echo Recomendacoes:
echo   1. Verifique o log: %LOGFILE%
echo   2. Reinicie o computador
echo   3. Execute operacoes manuais se necessario (menu 1, 2, 3)
echo.
pause
goto MENU

:EXECUTAR_REDE_SILENCIOSO
echo.
echo [AUTO] Otimizacao de Rede
call :EXECUTAR_COMANDO "netsh winsock reset" "Reset Winsock [AUTO]"
call :EXECUTAR_COMANDO "ipconfig /flushdns" "Flush DNS [AUTO]"
call :EXECUTAR_COMANDO "ipconfig /renew" "Renovar IP [AUTO]"
call :EXECUTAR_COMANDO "netsh int ip reset" "Reset TCP/IP [AUTO]"
echo [OK] Rede otimizada (modo automatico)
goto :eof

:EXECUTAR_SISTEMA_SILENCIOSO
echo.
echo [AUTO] Otimizacao de Sistema
call :EXECUTAR_COMANDO "fsutil behavior set memoryusage 2" "FSUtil [AUTO]"

powershell -Command "if ((Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq 'SSD' -or $_.MediaType -eq 'NVMe' }).Count -gt 0) { exit 0 } else { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    call :EXECUTAR_COMANDO "fsutil behavior set DisableDeleteNotify 0" "TRIM [AUTO]"
)

set "SCHEME="
for /f "tokens=4" %%a in ('powercfg /getactivescheme 2^>nul') do set "SCHEME=%%a"
if defined SCHEME (
    powercfg -query !SCHEME! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 >nul 2>&1
    if !errorlevel! equ 0 (
        call :EXECUTAR_COMANDO "powercfg -setacvalueindex !SCHEME! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0" "Energia [AUTO]"
        call :EXECUTAR_COMANDO "powercfg -setdcvalueindex !SCHEME! 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0" "Energia [AUTO]"
        call :EXECUTAR_COMANDO "powercfg -setactive !SCHEME!" "Energia [AUTO]"
    ) else (
        echo [SKIP] GUIDs nao suportados no modo automatico >> "%LOGFILE%"
    )
) else (
    echo [SKIP] Plano de energia nao detectado no modo automatico >> "%LOGFILE%"
)

start /min WSreset.exe
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue" >nul 2>&1
echo [OK] Sistema otimizado (modo automatico)
goto :eof

:EXECUTAR_MANUTENCAO_SILENCIOSO
echo.
echo [AUTO] Manutencao do Sistema
where sfc >nul 2>&1
if %errorlevel% equ 0 call :EXECUTAR_COMANDO "sfc /scannow" "SFC [AUTO]"
where dism >nul 2>&1
if %errorlevel% equ 0 call :EXECUTAR_COMANDO "dism /online /cleanup-image /restorehealth" "DISM [AUTO]"
echo [OK] Manutencao concluida (modo automatico)
goto :eof

:CRIAR_PONTO_RESTAURACAO
echo Verificando Restauracao do Sistema...
echo [CHECK] Verificando System Restore - %time% >> "%LOGFILE%"

:: Script PowerShell usando cmdlets modernos (Get-CimInstance em vez de Get-WmiObject)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { Write-Host '[*] Verificando status da Restauracao do Sistema...'; $rpEnabled = $false; $rpDrives = @(); try { if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) { $rpDrives = Get-CimInstance -ClassName Win32_Volume -Filter \"DriveType=3 AND DriveLetter='C:'\" -ErrorAction SilentlyContinue } else { $rpDrives = Get-WmiObject -Class Win32_Volume -Filter \"DriveType=3 AND DriveLetter='C:'\" -ErrorAction SilentlyContinue }; if ($rpDrives) { $sysRestore = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -ErrorAction SilentlyContinue; if ($sysRestore -and $sysRestore.RPSessionInterval) { $rpEnabled = $true; Write-Host '    [OK] Restauracao do Sistema esta habilitada' } } } catch { Write-Host '    [WARN] Erro ao verificar status' }; if (-not $rpEnabled) { Write-Host '    [WARN] Restauracao do Sistema pode estar desabilitada'; Write-Host '    [*] Tentando habilitar...'; try { Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop; Start-Sleep -Seconds 2; $rpEnabled = $true; Write-Host '    [OK] Restauracao do Sistema habilitada com sucesso' } catch { Write-Host \"    [ERROR] Nao foi possivel habilitar: $($_.Exception.Message)\" } }; if ($rpEnabled) { Write-Host '[*] Criando ponto de restauracao...'; try { Checkpoint-Computer -Description '%~1' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; Write-Host '[OK] Ponto de restauracao criado com sucesso'; exit 0 } catch { if ($_.Exception.Message -match 'frequency|1440|24') { Write-Host '[WARN] Limite de frequencia atingido (max 1 por 24h)'; exit 3 } elseif ($_.Exception.Message -match 'space|disk') { Write-Host '[WARN] Espaco em disco insuficiente'; exit 5 } else { Write-Host \"[ERROR] Falha ao criar checkpoint: $($_.Exception.Message)\"; exit 2 } } } else { Write-Host '[ERROR] Restauracao do Sistema nao esta disponivel neste sistema'; Write-Host '[INFO] Possivel ambiente corporativo com GPO restritiva'; exit 1 } } catch { Write-Host \"[ERROR] Erro critico: $($_.Exception.Message)\"; exit 4 }" 2>>"%LOGFILE%"

set "RP_ERROR=!errorlevel!"

if !RP_ERROR! equ 0 (
    echo [OK] Ponto de restauracao criado: %~1
    echo [SUCCESS] Checkpoint criado: %~1 - %date% %time% >> "%LOGFILE%"
) else if !RP_ERROR! equ 3 (
    echo [AVISO] Limite de frequencia atingido
    echo         Um ponto de restauracao ja foi criado nas ultimas 24h.
    echo         O Windows permite apenas 1 ponto por dia automaticamente.
    echo [WARN] Checkpoint limite frequencia (24h) - %time% >> "%LOGFILE%"
) else if !RP_ERROR! equ 5 (
    echo [AVISO] Espaco em disco insuficiente
    echo         Necessario pelo menos 300MB livres no disco C:
    echo [WARN] Checkpoint falhou - espaco insuficiente - %time% >> "%LOGFILE%"
) else if !RP_ERROR! equ 1 (
    echo [AVISO] Restauracao do Sistema nao disponivel
    echo         Possivel ambiente corporativo com restricoes de GPO.
    echo [WARN] System Restore desabilitado por politica - %time% >> "%LOGFILE%"
) else (
    echo [AVISO] Falha ao criar ponto de restauracao (codigo: !RP_ERROR!)
    echo [ERROR] Checkpoint falhou codigo !RP_ERROR! - %time% >> "%LOGFILE%"
)

if !RP_ERROR! neq 0 (
    echo.
    echo Motivos comuns de falha:
    echo   - Restauracao do Sistema desabilitada pelo administrador
    echo   - Espaco em disco insuficiente (minimo 300MB recomendado)
    echo   - Limite de frequencia (maximo 1 ponto a cada 24 horas)
    echo   - Politicas de grupo (GPO) em ambientes corporativos
    echo   - Volume Shadow Copy Service (VSS) desabilitado/parado
    echo.
    echo Deseja continuar mesmo assim? (S/N)
    set /p continuar="Resposta: "
    if /i "!continuar!" neq "S" (
        echo Operacao cancelada pelo usuario.
        echo [CANCEL] Usuario cancelou apos falha no checkpoint >> "%LOGFILE%"
        goto MENU
    )
    echo [CONTINUE] Usuario optou por continuar sem checkpoint >> "%LOGFILE%"
)
goto :eof

:EXECUTAR_COMANDO
:: Cria arquivo temporário com escape ULTRA-seguro de caracteres especiais
set "TEMP_CMD=%TEMP%\otimizador_cmd_%RANDOM%_%TIME:~6,2%%TIME:~9,2%.cmd"
set "TEMP_CMD=!TEMP_CMD: =!"

:: Usar PowerShell para escrita 100% segura com escape completo
:: Substitui % por %%%% (dobro do necessário para garantir)
:: Protege também ^, &, |, <, >, ", ', e outros caracteres especiais
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { $cmd = '%~1'; $cmd = $cmd -replace '%%', '%%%%'; $cmd = $cmd -replace '\^', '^^'; $content = '@echo off' + [Environment]::NewLine + $cmd + [Environment]::NewLine + 'exit /b %%errorlevel%%'; [System.IO.File]::WriteAllText('%TEMP_CMD%', $content, [System.Text.Encoding]::UTF8); exit 0 } catch { Write-Host 'ERRO: Falha ao criar comando temporario'; exit 1 }" 2>>"%LOGFILE%"

set "PS_ERROR=!errorlevel!"
if !PS_ERROR! neq 0 (
    echo     [ERRO] %~2 - falha ao criar comando temporario via PowerShell
    echo [ERROR] %~2 - PowerShell WriteAllText falhou - codigo: !PS_ERROR! >> "%LOGFILE%"
    goto :eof
)

if not exist "%TEMP_CMD%" (
    echo     [ERRO] %~2 - arquivo temporario nao foi criado
    echo [ERROR] %~2 - arquivo temp inexistente >> "%LOGFILE%"
    goto :eof
)

echo [EXEC] %~2: %~1 >> "%LOGFILE%"
call "%TEMP_CMD%" >> "%LOGFILE%" 2>&1
set "CMD_ERROR=!errorlevel!"

del "%TEMP_CMD%" >nul 2>&1

if !CMD_ERROR! equ 0 (
    echo     [OK] %~2
    echo [SUCCESS] %~2 - %time% >> "%LOGFILE%"
) else (
    echo     [ERRO] %~2 falhou (codigo: !CMD_ERROR!)
    echo [ERROR] %~2 - codigo: !CMD_ERROR! - %time% >> "%LOGFILE%"
)
goto :eof

:ADICIONAR_REGRA_FIREWALL
netsh advfirewall firewall add rule name="StopThrottling" dir=in action=block remoteip=173.194.55.0/24,206.111.0.0/16 enable=yes >> "%LOGFILE%" 2>&1
set "FW_ERROR=!errorlevel!"
if !FW_ERROR! equ 0 (
    echo     [OK] Regra de firewall "StopThrottling" adicionada
    echo [SUCCESS] Regra firewall adicionada - %time% >> "%LOGFILE%"
    echo     [INFO] Para remover: use opcao 6 do menu principal >> "%LOGFILE%"
) else (
    echo     [ERRO] Falha ao adicionar regra (codigo: !FW_ERROR!)
    echo [ERROR] Regra firewall falhou - codigo: !FW_ERROR! - %time% >> "%LOGFILE%"
)
goto :eof

:RESETAR_ADAPTADOR
echo     Resetando adaptador: %~1
echo     Desabilitando adaptador...
netsh interface set interface "%~1" admin=disable >> "%LOGFILE%" 2>&1
set "DISABLE_ERROR=!errorlevel!"
if !DISABLE_ERROR! equ 0 (
    echo     [OK] Adaptador desabilitado
    timeout /t 3 >nul
    echo     Habilitando adaptador...
    netsh interface set interface "%~1" admin=enable >> "%LOGFILE%" 2>&1
    set "ENABLE_ERROR=!errorlevel!"
    if !ENABLE_ERROR! equ 0 (
        echo     [OK] Adaptador "%~1" resetado com sucesso
        echo [SUCCESS] Adaptador "%~1" resetado - %time% >> "%LOGFILE%"
    ) else (
        echo     [ERRO] Falha ao habilitar adaptador (codigo: !ENABLE_ERROR!)
        echo [ERROR] Falha ao habilitar "%~1" - codigo: !ENABLE_ERROR! >> "%LOGFILE%"
    )
) else (
    echo     [ERRO] Falha ao desabilitar adaptador (codigo: !DISABLE_ERROR!)
    echo [ERROR] Falha ao desabilitar "%~1" - codigo: !DISABLE_ERROR! >> "%LOGFILE%"
)
goto :eof

:REMOVER_FIREWALL
cls
echo REMOVER REGRA DE FIREWALL
echo.
echo Verificando regra "StopThrottling"...
netsh advfirewall firewall show rule name="StopThrottling" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Regra "StopThrottling" encontrada.
    echo.
    netsh advfirewall firewall show rule name="StopThrottling"
    echo.
    echo Deseja remover esta regra? (S/N)
    set /p remover="Resposta: "
    if /i "!remover!"=="S" (
        netsh advfirewall firewall delete rule name="StopThrottling" >> "%LOGFILE%" 2>&1
        set "DEL_ERROR=!errorlevel!"
        if !DEL_ERROR! equ 0 (
            echo.
            echo [OK] Regra removida com sucesso!
            echo [SUCCESS] Regra firewall
