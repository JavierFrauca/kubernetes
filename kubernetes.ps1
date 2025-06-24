# Script Interactivo para Configurar Cluster Kubernetes Local
# Creado para Windows 11 con Docker Desktop
# Version: 2.0 - Interactiva y Mejorada

# Funcion para mostrar banner ASCII
function Show-KubernetesBanner {
    Clear-Host
    Write-Host ""
    Write-Host " ___   _  __   __  _______  _______  ______    __    _  _______  _______  _______  _______ " -ForegroundColor Cyan
    Write-Host "|   | | ||  | |  ||  _    ||       ||    _ |  |  |  | ||       ||       ||       ||       |" -ForegroundColor Cyan
    Write-Host "|   |_| ||  | |  || |_|   ||    ___||   | ||  |   |_| ||    ___||_     _||    ___||  _____|" -ForegroundColor Cyan
    Write-Host "|      _||  |_|  ||       ||   |___ |   |_||_ |       ||   |___   |   |  |   |___ | |_____ " -ForegroundColor Blue
    Write-Host "|     |_ |       ||  _   | |    ___||    __  ||  _    ||    ___|  |   |  |    ___||_____  |" -ForegroundColor Blue
    Write-Host "|    _  ||       || |_|   ||   |___ |   |  | || | |   ||   |___   |   |  |   |___  _____| |" -ForegroundColor DarkBlue
    Write-Host "|___| |_||_______||_______||_______||___|  |_||_|  |__||_______|  |___|  |_______||_______|" -ForegroundColor DarkBlue
    Write-Host ""
    Write-Host "        CONFIGURADOR INTERACTIVO DE CLUSTER" -ForegroundColor Yellow
    Write-Host "        VERSION 2.0 - EDICION INTERACTIVA" -ForegroundColor Gray
    Write-Host "        ====================================" -ForegroundColor DarkGray
    Write-Host ""
}

# Funcion para mostrar spinner de carga
function Show-LoadingSpinner {
    param([string]$Message)
    
    $spinner = @("|", "/", "-", "\\")
    $counter = 0
    
    for ($i = 0; $i -lt 20; $i++) {
        $spinChar = $spinner[$counter % $spinner.Length]
        Write-Host "`r$spinChar $Message" -NoNewline -ForegroundColor Yellow
        Start-Sleep -Milliseconds 100
        $counter++
    }
    Write-Host "`r[OK] $Message - Completado" -ForegroundColor Green
}

# Funcion para verificar permisos de administrador
function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Funcion para verificar puertos
function Test-PortAvailability {
    param([int]$Port)
    
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        return $true
    }
    catch {
        return $false
    }
}

# Funcion para mostrar verificaciones del sistema
function Show-SystemChecks {
    Write-Host "VERIFICACIONES DEL SISTEMA" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Verificar permisos de administrador
    Write-Host "Verificando permisos de administrador..." -NoNewline
    if (Test-AdminRights) {
        Write-Host " [OK] CORRECTO" -ForegroundColor Green
    } else {
        Write-Host " [ERROR] FALLO" -ForegroundColor Red
        Write-Host ""
        Write-Host "PERMISOS INSUFICIENTES" -ForegroundColor Red
        Write-Host "Este script requiere permisos de administrador para:" -ForegroundColor Yellow
        Write-Host "- Instalar software mediante Chocolatey" -ForegroundColor White
        Write-Host "- Modificar configuraciones de red" -ForegroundColor White
        Write-Host "- Crear clusters de Kubernetes" -ForegroundColor White
        Write-Host ""
        Write-Host "SOLUCION:" -ForegroundColor Cyan
        Write-Host "1. Cierra esta ventana de PowerShell" -ForegroundColor White
        Write-Host "2. Abre PowerShell como Administrador" -ForegroundColor White
        Write-Host "3. Ejecuta el script nuevamente" -ForegroundColor White
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 1
    }
    
    # Verificar Docker
    Write-Host "Verificando Docker Desktop..." -NoNewline
    $dockerTest = docker version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK] CORRECTO" -ForegroundColor Green
    } else {
        Write-Host " [ERROR] FALLO" -ForegroundColor Red
        Write-Host ""
        Write-Host "DOCKER NO DISPONIBLE" -ForegroundColor Red
        Write-Host "Docker Desktop no esta funcionando correctamente." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "SOLUCION:" -ForegroundColor Cyan
        Write-Host "1. Asegurate de que Docker Desktop este instalado" -ForegroundColor White
        Write-Host "2. Inicia Docker Desktop y espera a que se complete" -ForegroundColor White
        Write-Host "3. Ejecuta el script nuevamente" -ForegroundColor White
        Write-Host ""
        Read-Host "Presiona Enter para salir"
        exit 1
    }
    
    # Verificar puerto 6443
    Write-Host "Verificando puerto 6443..." -NoNewline
    if (Test-PortAvailability -Port 6443) {
        Write-Host " [OK] DISPONIBLE" -ForegroundColor Green
    } else {
        Write-Host " [AVISO] EN USO" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "PUERTO 6443 OCUPADO" -ForegroundColor Yellow
        Write-Host "Este puerto es utilizado por el API Server de Kubernetes." -ForegroundColor Gray
        
        # Verificar si es Docker Desktop K8s
        $currentContext = kubectl config current-context 2>$null
        if ($currentContext -eq "docker-desktop" -or $currentContext -eq "docker-for-desktop") {
            Write-Host "Detectado: Kubernetes de Docker Desktop activo" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "RECOMENDACION:" -ForegroundColor Cyan
            Write-Host "Desactiva Kubernetes en Docker Desktop para evitar conflictos:" -ForegroundColor White
            Write-Host "Settings > Kubernetes > Desmarcar Enable Kubernetes" -ForegroundColor Gray
            Write-Host ""
            $choice = Read-Host "Continuar de todos modos? (s/n)"
            if ($choice -ne "s" -and $choice -ne "S") {
                exit 1
            }
        }
    }
    
    # Verificar conectividad a internet
    Write-Host "Verificando conectividad a internet..." -NoNewline
    try {
        $response = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -WarningAction SilentlyContinue
        if ($response.TcpTestSucceeded) {
            Write-Host " [OK] CORRECTO" -ForegroundColor Green
        } else {
            Write-Host " [ERROR] FALLO" -ForegroundColor Red
        }
    } catch {
        Write-Host " [ERROR] FALLO" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Verificaciones completadas" -ForegroundColor Green
    Write-Host ""
    Read-Host "Presiona Enter para continuar"
}

# Funcion para el menu principal
function Show-MainMenu {
    Clear-Host
    Show-KubernetesBanner
    
    Write-Host "MENU PRINCIPAL" -ForegroundColor Cyan
    Write-Host "===============" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "1. Verificar Sistema" -ForegroundColor White
    Write-Host "2. Configurar Cluster" -ForegroundColor White
    Write-Host "3. Ver Clusters Existentes" -ForegroundColor White
    Write-Host "4. Eliminar Cluster" -ForegroundColor White
    Write-Host "5. Comandos Comunes" -ForegroundColor White
    Write-Host "6. Salir" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor DarkGray
    Write-Host ""
}

# Funcion para configurar cluster
function Start-ClusterConfiguration {
    Clear-Host
    Show-KubernetesBanner
    
    Write-Host "CONFIGURACION DEL CLUSTER" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Nombre del cluster
    do {
        $clusterName = Read-Host "Nombre del cluster (dev-cluster)"
        if ([string]::IsNullOrWhiteSpace($clusterName)) {
            $clusterName = "dev-cluster"
        }
        if ($clusterName -match "[^a-zA-Z0-9-]") {
            Write-Host "Solo se permiten letras, numeros y guiones" -ForegroundColor Red
        }
    } while ($clusterName -match "[^a-zA-Z0-9-]")
    
    # Numero de workers
    do {
        $workersInput = Read-Host "Numero de nodos worker (2)"
        if ([string]::IsNullOrWhiteSpace($workersInput)) {
            $workerNodes = 2
        } else {
            $workerNodes = [int]$workersInput
        }
        if ($workerNodes -lt 1 -or $workerNodes -gt 10) {
            Write-Host "Debe ser entre 1 y 10 workers" -ForegroundColor Red
        }
    } while ($workerNodes -lt 1 -or $workerNodes -gt 10)
    
    # Puertos personalizados
    $defaultHttpPort = 8080
    $defaultHttpsPort = 8443
    $httpPort = Read-Host "Puerto HTTP para exponer el cluster (por defecto $defaultHttpPort)"
    if ([string]::IsNullOrWhiteSpace($httpPort)) { $httpPort = $defaultHttpPort }
    $httpsPort = Read-Host "Puerto HTTPS para exponer el cluster (por defecto $defaultHttpsPort)"
    if ([string]::IsNullOrWhiteSpace($httpsPort)) { $httpsPort = $defaultHttpsPort }
    
    # Exposicion a red local
    Write-Host ""
    Write-Host "Exponer cluster a la red local?" -ForegroundColor Yellow
    Write-Host "   Esto permitira acceso desde otros dispositivos en tu red" -ForegroundColor Gray
    $exposeNetwork = (Read-Host "   (s/n) [n]") -eq "s"
    
    # Aplicacion de ejemplo
    Write-Host ""
    Write-Host "Instalar aplicacion de ejemplo?" -ForegroundColor Yellow
    Write-Host "   Se desplegara una app Hello Kubernetes de prueba" -ForegroundColor Gray
    $installDemo = (Read-Host "   (s/n) [s]") -ne "n"
    
    Write-Host ""
    Write-Host "RESUMEN DE CONFIGURACION" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor DarkGray
    Write-Host "- Nombre: $clusterName" -ForegroundColor White
    Write-Host "- Workers: $workerNodes" -ForegroundColor White
    Write-Host "- Puerto HTTP: $httpPort" -ForegroundColor White
    Write-Host "- Puerto HTTPS: $httpsPort" -ForegroundColor White
    if ($exposeNetwork) {
        Write-Host "- Red local: Si" -ForegroundColor White
    } else {
        Write-Host "- Red local: No" -ForegroundColor White
    }
    if ($installDemo) {
        Write-Host "- App demo: Si" -ForegroundColor White
    } else {
        Write-Host "- App demo: No" -ForegroundColor White
    }
    Write-Host ""
    
    $confirm = Read-Host "Proceder con la instalacion? (s/n)"
    if ($confirm -eq "s" -or $confirm -eq "S") {
        Install-KubernetesCluster -ClusterName $clusterName -WorkerNodes $workerNodes -ExposeNetwork $exposeNetwork -InstallDemo $installDemo -HttpPort $httpPort -HttpsPort $httpsPort
    }
}

# Funcion principal de instalacion
function Install-KubernetesCluster {
    param(
        [string]$ClusterName,
        [int]$WorkerNodes,
        [bool]$ExposeNetwork,
        [bool]$InstallDemo,
        [int]$HttpPort,
        [int]$HttpsPort
    )
    
    Clear-Host
    Show-KubernetesBanner
    
    Write-Host "INSTALANDO CLUSTER KUBERNETES" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor DarkGray
    Write-Host ""
    
    # Instalar dependencias
    Install-Dependencies
    
    # Crear configuracion del cluster
    Create-ClusterConfig -ClusterName $ClusterName -WorkerNodes $WorkerNodes -ExposeNetwork $ExposeNetwork -HttpPort $HttpPort -HttpsPort $HttpsPort
    
    # Crear el cluster
    Write-Host "Creando cluster $ClusterName..." -ForegroundColor Yellow
    Show-LoadingSpinner "Creando cluster Kubernetes"
    
    kind create cluster --config "kind-config.yaml" --wait 300s
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Error creando el cluster" -ForegroundColor Red
        Remove-Item "kind-config.yaml" -ErrorAction SilentlyContinue
        Read-Host "Presiona Enter para continuar"
        return
    }
    
    Write-Host "[OK] Cluster creado exitosamente" -ForegroundColor Green
    
    # Configurar componentes adicionales
    Install-ClusterComponents -ClusterName $ClusterName
    
    # Instalar aplicacion demo si se solicita
    if ($InstallDemo) {
        Install-DemoApplication
    }
    
    # Mostrar resumen final
    Show-CompletionSummary -ClusterName $ClusterName -WorkerNodes $WorkerNodes -InstallDemo $InstallDemo
    
    # Limpiar archivos temporales
    Remove-Item "kind-config.yaml" -ErrorAction SilentlyContinue
    Remove-Item "metallb-config.yaml" -ErrorAction SilentlyContinue
    Remove-Item "demo-app.yaml" -ErrorAction SilentlyContinue
}

# Funcion para instalar dependencias
function Install-Dependencies {
    Write-Host "Verificando dependencias..." -ForegroundColor Yellow
    
    # Verificar Chocolatey
    Write-Host "Verificando Chocolatey..." -NoNewline
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $chocoCmd) {
        Write-Host " [NO ENCONTRADO]" -ForegroundColor Red
        Write-Host "Instalando Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))
        Update-Path
        Write-Host "[OK] Chocolatey instalado" -ForegroundColor Green
    } else {
        Write-Host " [OK] DISPONIBLE" -ForegroundColor Green
    }
    
    # Verificar kubectl
    Write-Host "Verificando kubectl..." -NoNewline
    $kubectlCmd = Get-Command kubectl -ErrorAction SilentlyContinue
    if (-not $kubectlCmd) {
        Write-Host " [NO ENCONTRADO]" -ForegroundColor Red
        Write-Host "Instalando kubectl..." -ForegroundColor Yellow
        choco install kubernetes-cli -y
        Update-Path
        Write-Host "[OK] kubectl instalado" -ForegroundColor Green
    } else {
        Write-Host " [OK] DISPONIBLE" -ForegroundColor Green
    }
    
    # Verificar Kind
    Write-Host "Verificando Kind..." -NoNewline
    $kindCmd = Get-Command kind -ErrorAction SilentlyContinue
    if (-not $kindCmd) {
        Write-Host " [NO ENCONTRADO]" -ForegroundColor Red
        Write-Host "Instalando Kind..." -ForegroundColor Yellow
        choco install kind -y
        Update-Path
        Write-Host "[OK] Kind instalado" -ForegroundColor Green
    } else {
        Write-Host " [OK] DISPONIBLE" -ForegroundColor Green
    }
    
    # Verificar Helm
    Write-Host "Verificando Helm..." -NoNewline
    $helmCmd = Get-Command helm -ErrorAction SilentlyContinue
    if (-not $helmCmd) {
        Write-Host " [NO ENCONTRADO]" -ForegroundColor Red
        Write-Host "Instalando Helm..." -ForegroundColor Yellow
        choco install kubernetes-helm -y
        Update-Path
        Write-Host "[OK] Helm instalado" -ForegroundColor Green
    } else {
        Write-Host " [OK] DISPONIBLE" -ForegroundColor Green
    }
}

# Funcion para actualizar PATH
function Update-Path {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)
    $env:Path = $machinePath + ";" + $userPath
}

# Funcion para crear configuracion del cluster
function Create-ClusterConfig {
    param(
        [string]$ClusterName,
        [int]$WorkerNodes,
        [bool]$ExposeNetwork,
        [int]$HttpPort,
        [int]$HttpsPort
    )
    
    Write-Host "Creando configuracion del cluster..." -ForegroundColor Yellow
    
    $apiServerAddress = if ($ExposeNetwork) { "0.0.0.0" } else { "127.0.0.1" }
    
    $config = @"
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: $ClusterName
networking:
  apiServerAddress: "$apiServerAddress"
  apiServerPort: 6443
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: $HttpPort
    protocol: TCP
  - containerPort: 443
    hostPort: $HttpsPort
    protocol: TCP
"@
    
    for ($i = 1; $i -le $WorkerNodes; $i++) {
        $config += "`n- role: worker"
    }
    
    $config | Out-File -FilePath "kind-config.yaml" -Encoding UTF8
    Write-Host "[OK] Configuracion creada" -ForegroundColor Green
}

# Funcion para instalar componentes del cluster
function Install-ClusterComponents {
    param([string]$ClusterName)
    
    Write-Host "Instalando componentes del cluster..." -ForegroundColor Yellow
    
    # NGINX Ingress Controller
    Write-Host "Instalando NGINX Ingress Controller..." -ForegroundColor Cyan
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
    
    # MetalLB
    Write-Host "Instalando MetalLB..." -ForegroundColor Cyan
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
    kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=300s
    
    # Configurar MetalLB
    $metallbConfig = @"
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - 172.19.255.200-172.19.255.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
"@
    
    $metallbConfig | Out-File -FilePath "metallb-config.yaml" -Encoding UTF8
    kubectl apply -f "metallb-config.yaml"
    
    Write-Host "[OK] Componentes instalados correctamente" -ForegroundColor Green
}

# Funcion para instalar aplicacion demo
function Install-DemoApplication {
    Write-Host "Desplegando aplicacion de ejemplo..." -ForegroundColor Yellow
    
    kubectl create namespace demo --dry-run=client -o yaml | kubectl apply -f -
    
    $demoApp = @"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-kubernetes
  namespace: demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello-kubernetes
  template:
    metadata:
      labels:
        app: hello-kubernetes
    spec:
      containers:
      - name: hello-kubernetes
        image: paulbouwer/hello-kubernetes:1.10
        ports:
        - containerPort: 8080
        env:
        - name: MESSAGE
          value: "Hola desde tu cluster Kubernetes local!"
---
apiVersion: v1
kind: Service
metadata:
  name: hello-kubernetes-service
  namespace: demo
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: hello-kubernetes
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-kubernetes-ingress
  namespace: demo
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: hello.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-kubernetes-service
            port:
              number: 80
"@
    
    $demoApp | Out-File -FilePath "demo-app.yaml" -Encoding UTF8
    kubectl apply -f "demo-app.yaml"
    
    Write-Host "[OK] Aplicacion demo desplegada" -ForegroundColor Green
}

# Funcion para mostrar resumen final
function Show-CompletionSummary {
    param(
        [string]$ClusterName,
        [int]$WorkerNodes,
        [bool]$InstallDemo
    )
    
    Clear-Host
    Show-KubernetesBanner
    
    Write-Host "CLUSTER CONFIGURADO EXITOSAMENTE!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor DarkGray
    Write-Host ""
    
    Write-Host "INFORMACION DEL CLUSTER:" -ForegroundColor Cyan
    Write-Host "- Nombre: $ClusterName" -ForegroundColor White
    Write-Host "- Nodos: 1 control-plane + $WorkerNodes workers" -ForegroundColor White
    Write-Host "- Ingress Controller: NGINX [OK]" -ForegroundColor White
    Write-Host "- LoadBalancer: MetalLB [OK]" -ForegroundColor White
    if ($InstallDemo) {
        Write-Host "- Aplicacion Demo: Desplegada [OK]" -ForegroundColor White
    }
    Write-Host ""
    
    Show-QuickReference
    
    Write-Host "CLUSTER LISTO PARA USAR!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Presiona Enter para volver al menu principal"
}

# Funcion para mostrar comandos rapidos
function Show-QuickReference {
    Write-Host "COMANDOS RAPIDOS Y UTILES" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor DarkGray
    Write-Host "kubectl get nodes                           # Ver nodos"
    Write-Host "kubectl get pods -A                         # Ver todos los pods"
    Write-Host "kubectl get svc -n demo                     # Ver servicios demo"
    Write-Host "kubectl logs -n demo deployment/hello-kubernetes  # Ver logs"
    Write-Host "kubectl describe pod <nombre>               # Detalles de un pod"
    Write-Host "kubectl exec -it <pod> -- bash              # Acceder a un pod"
    Write-Host "kubectl delete pod <nombre>                 # Eliminar un pod"
    Write-Host "kubectl apply -f <archivo.yaml>             # Aplicar manifiesto"
    Write-Host "kind get clusters                           # Listar clusters Kind"
    Write-Host "kind delete cluster --name <nombre>          # Eliminar cluster Kind"
    Write-Host "kind export kubeconfig --name <nombre>       # Exportar kubeconfig"
    Write-Host "docker ps                                   # Ver contenedores Docker"
    Write-Host "docker stop <id>                            # Parar contenedor Docker"
    Write-Host ""
}

# Funcion para mostrar comandos comunes
function Show-CommonCommands {
    Clear-Host
    Show-KubernetesBanner
    Write-Host "COMANDOS COMUNES DE KUBERNETES, KIND Y DOCKER" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "KUBECTL (Kubernetes):" -ForegroundColor Yellow
    Write-Host "kubectl get nodes                # Ver nodos del cluster"
    Write-Host "kubectl get pods -A              # Ver todos los pods en todos los namespaces"
    Write-Host "kubectl get svc -A               # Ver todos los servicios"
    Write-Host "kubectl get deployments -A       # Ver todos los deployments"
    Write-Host "kubectl describe pod <nombre>    # Detalles de un pod"
    Write-Host "kubectl logs <pod>               # Ver logs de un pod"
    Write-Host "kubectl apply -f <archivo.yaml>  # Aplicar un manifiesto"
    Write-Host "kubectl delete -f <archivo.yaml> # Eliminar recursos de un manifiesto"
    Write-Host "kubectl exec -it <pod> -- bash   # Acceder a un pod con bash"
    Write-Host "kubectl config get-contexts      # Ver contextos disponibles"
    Write-Host "kubectl config use-context <ctx> # Cambiar de contexto"
    Write-Host "kubectl delete pod <nombre>      # Eliminar un pod"
    Write-Host "kubectl port-forward svc/<svc> 8080:80 # Redirigir puerto local a un servicio"
    Write-Host ""
    Write-Host "KIND (Kubernetes in Docker):" -ForegroundColor Yellow
    Write-Host "kind create cluster --name <nombre>         # Crear un cluster nuevo"
    Write-Host "kind get clusters                          # Listar clusters existentes"
    Write-Host "kind delete cluster --name <nombre>         # Eliminar un cluster"
    Write-Host "kind export kubeconfig --name <nombre>      # Exportar kubeconfig de un cluster"
    Write-Host "kind load docker-image <img> --name <nombre># Cargar imagen local al cluster"
    Write-Host ""
    Write-Host "DOCKER:" -ForegroundColor Yellow
    Write-Host "docker ps                # Ver contenedores en ejecucion"
    Write-Host "docker images            # Ver imagenes locales"
    Write-Host "docker stop <id>         # Parar un contenedor"
    Write-Host "docker rm <id>           # Eliminar un contenedor"
    Write-Host "docker rmi <img>         # Eliminar una imagen"
    Write-Host "docker logs <id>         # Ver logs de un contenedor"
    Write-Host "docker exec -it <id> sh  # Acceder a un contenedor"
    Write-Host ""
    Write-Host "Presiona Enter para volver al menu principal"
    Read-Host
}

# Funcion para mostrar clusters existentes
function Show-ExistingClusters {
    while ($true) {
        Clear-Host
        Show-KubernetesBanner
        Write-Host "CLUSTERS EXISTENTES" -ForegroundColor Cyan
        Write-Host "===================" -ForegroundColor DarkGray
        Write-Host ""
        $clustersRaw = kind get clusters 2>$null
        if ($clustersRaw) {
            $clusters = $clustersRaw -split "\r?\n" | Where-Object { $_.Trim() -ne "" }
            if ($clusters.Count -eq 0) {
                Write-Host "[AVISO] No hay clusters disponibles" -ForegroundColor Yellow
                Write-Host ""
                Show-QuickReference
                Read-Host "Presiona Enter para continuar"
                break
            }
            Write-Host "Nombres de clusters disponibles:" -ForegroundColor White
            foreach ($c in $clusters) {
                Write-Host "- $c" -ForegroundColor White
            }
            Write-Host ""
            $sel = Read-Host "Escribe el nombre de un cluster para ver detalles, o pulsa Enter para volver al menu principal"
            if ([string]::IsNullOrWhiteSpace($sel)) { break }
            elseif ($clusters -contains $sel) {
                kubectl config use-context "kind-$sel" | Out-Null
                Show-ClusterDetails -ClusterName $sel
            } else {
                Write-Host "[ERROR] Cluster no encontrado. Escribe el nombre exactamente como aparece en la lista." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        } else {
            Write-Host "[AVISO] No hay clusters disponibles" -ForegroundColor Yellow
            Write-Host ""
            Show-QuickReference
            Read-Host "Presiona Enter para continuar"
            break
        }
    }
}

# Funcion para eliminar cluster
function Remove-KubernetesCluster {
    while ($true) {
        Clear-Host
        Show-KubernetesBanner
        Write-Host "ELIMINAR CLUSTER" -ForegroundColor Red
        Write-Host "================" -ForegroundColor DarkGray
        Write-Host ""
        $clustersRaw = kind get clusters 2>$null
        if ($clustersRaw) {
            $clusters = $clustersRaw -split "\r?\n" | Where-Object { $_.Trim() -ne "" }
            if ($clusters.Count -eq 0) {
                Write-Host "[AVISO] No hay clusters disponibles para eliminar" -ForegroundColor Yellow
                Write-Host ""
                Read-Host "Presiona Enter para continuar"
                break
            }
            Write-Host "Nombres de clusters disponibles:" -ForegroundColor White
            foreach ($c in $clusters) {
                Write-Host "- $c" -ForegroundColor White
            }
            Write-Host ""
            $sel = Read-Host "Escribe el nombre de un cluster para eliminarlo, o pulsa Enter para volver al menu principal"
            if ([string]::IsNullOrWhiteSpace($sel)) { break }
            elseif ($clusters -contains $sel) {
                $confirm = Read-Host "Estas seguro de eliminar $sel? (s/n)"
                if ($confirm -eq "s" -or $confirm -eq "S") {
                    Write-Host "Eliminando cluster $sel..." -ForegroundColor Yellow
                    kind delete cluster --name $sel
                    Write-Host "[OK] Cluster eliminado exitosamente" -ForegroundColor Green
                    Start-Sleep -Seconds 2
                }
            } else {
                Write-Host "[ERROR] Cluster no encontrado. Escribe el nombre exactamente como aparece en la lista." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        } else {
            Write-Host "[AVISO] No hay clusters disponibles para eliminar" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Presiona Enter para continuar"
            break
        }
    }
}

# Funcion para mostrar detalles de un cluster
function Show-ClusterDetails {
    param(
        [string]$ClusterName
    )
    Clear-Host
    Show-KubernetesBanner
    Write-Host "DETALLE DEL CLUSTER: $ClusterName" -ForegroundColor Cyan
    Write-Host "===============================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "NODOS:" -ForegroundColor Yellow
    kubectl get nodes
    Write-Host ""
    Write-Host "DEPLOYMENTS (con replicas e imagen):" -ForegroundColor Yellow
    kubectl get deployments -A -o wide
    Write-Host ""
    Write-Host "PODS (con imagen):" -ForegroundColor Yellow
    kubectl get pods -A -o wide
    Write-Host ""
    Write-Host "SERVICIOS:" -ForegroundColor Yellow
    kubectl get svc -A -o wide
    Write-Host ""
    Write-Host "IMAGENES USADAS EN LOS PODS:" -ForegroundColor Yellow
    $pods = kubectl get pods -A -o json | ConvertFrom-Json
    $images = $pods.items | ForEach-Object { $_.spec.containers | ForEach-Object { $_.image } } | Sort-Object -Unique
    foreach ($img in $images) { Write-Host $img }
    Write-Host ""
    Write-Host "Presiona Enter para volver"
    Read-Host
}

# Funcion principal
function Main {
    # Verificar que estamos en Windows
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "[ERROR] Este script requiere PowerShell 5.0 o superior" -ForegroundColor Red
        exit 1
    }
    
    while ($true) {
        Show-MainMenu
        $choice = Read-Host "Selecciona una opcion (1-6)"
        
        switch ($choice) {
            "1" { Show-SystemChecks }
            "2" { Start-ClusterConfiguration }
            "3" { Show-ExistingClusters }
            "4" { Remove-KubernetesCluster }
            "5" { Show-CommonCommands }
            "6" {
                Write-Host ""
                Write-Host "Gracias por usar el configurador de Kubernetes!" -ForegroundColor Green
                Write-Host "Que tengas un excelente dia desarrollando!" -ForegroundColor Yellow
                exit 0
            }
            default {
                Write-Host "[ERROR] Opcion no valida. Por favor selecciona 1-6." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# Ejecutar script principal
Main