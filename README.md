OTIMIZADOR WINDOWS

Script para manutenção e otimização do sistema Windows.

AVISO: Execute por sua conta e risco. Este script faz alterações profundas no sistema. É altamente recomendado criar um backup manual ou testar em uma máquina virtual antes de usar.

RECURSOS PRINCIPAIS:

Elevação automática: O script pedirá privilégios de Administrador e abrirá uma nova janela. A janela original será fechada.

Ponto de Restauração: Tenta criar um ponto de restauração antes de operações críticas.

Log: Todas as ações são registradas em "otimizador_log.txt" na mesma pasta do script.

COMO USAR:

Clique com o botão direito no arquivo .bat e selecione "Executar como administrador".

Escolha uma opção no menu.

OPÇÕES DO MENU:

[1] OTIMIZAÇÃO DE REDE

Limpa o cache DNS, reseta o Winsock e a pilha TCP/IP.

Opcional: Adiciona uma regra de firewall agressiva que pode afetar serviços do Google/YouTube.

[2] OTIMIZAÇÃO DE SISTEMA

Aplica otimizações de memória (FSUtil).

Aplica otimizações de boot (BCDEdit - opcional).

Habilita TRIM (se SSD detectado).

Desabilita a hibernação (opcional).

Otimiza o plano de energia (suspensão seletiva USB).

Limpa arquivos temporários (%TEMP%).

[3] MANUTENÇÃO E REPARAÇÃO

Executa SFC /scannow (Verificador de arquivos do sistema).

Executa DISM /RestoreHealth (Reparo da imagem do Windows).

Agenda ChkDsk (Verificação de disco - opcional).

Abre a Limpeza de Disco (cleanmgr).

Atualiza pacotes via Winget (opcional).

[4] EXECUTAR TODAS AS OTIMIZAÇÕES

Executa uma versão automática e "silenciosa" das opções 1, 2 e 3, pulando etapas que exigem confirmação manual (como BCDEdit, ChkDsk e a regra de firewall).

[5] VER LOG DE EXECUÇÃO

Abre o arquivo "otimizador_log.txt".

[6] REMOVER REGRA DE FIREWALL

Remove a regra "StopThrottling" criada pela opção [1].

[7] SAIR

Fecha o script.

REQUISITOS:

Windows 7 ou superior.

PowerShell 2.0 ou superior.

Privilégios de Administrador.

Conexão com a internet (apenas para Winget).
