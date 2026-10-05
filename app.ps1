# 1. ПРОВЕРКА ПРАВ АДМИНИСТРАТОРА
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/TipOk1125/my-tweaker/refs/heads/main/app.ps1 | iex`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# 2. XAML-РАЗМЕТКА ИНТЕРФЕЙСА
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Optimizer &amp; Control Hub" Height="720" Width="980"
        WindowStartupLocation="CenterScreen" Background="#0F111A" Foreground="#E2E8F0"
        FontFamily="Segoe UI" ResizeMode="CanMinimize">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#1E2235"/>
            <Setter Property="Foreground" Value="#F8FAFC"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#2E344E"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" CornerRadius="8" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#2D334D"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="#6366F1"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#4338CA"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="#161926"/>
            <Setter Property="CornerRadius" Value="14"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#23283C"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="35"/>
        </Grid.RowDefinitions>

        <!-- Шапка -->
        <Border Grid.Row="0" Background="#131622" BorderBrush="#1F2438" BorderThickness="0,0,0,1">
            <Grid Margin="20,0">
                <TextBlock Text="SYSTEM HUB // TWEAKER" VerticalAlignment="Center" FontSize="18" FontWeight="Bold" Foreground="#818CF8"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
                    <Button Name="TabBtnSystem" Content="Мониторинг и Сеть" Margin="0,0,10,0"/>
                    <Button Name="TabBtnApps" Content="Каталог ПО" Margin="0,0,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Вкладка 1: Информация, Сеть, Питание -->
        <ScrollViewer Name="TabSystem" Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="20,15,20,10">
            <StackPanel>
                <!-- Блок Питания -->
                <Border Style="{StaticResource Card}">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel VerticalAlignment="Center">
                            <TextBlock Text="Энергопотребление и режим работы" FontSize="14" FontWeight="Bold" Foreground="#F1F5F9"/>
                            <TextBlock Name="LblPowerPlan" Text="Текущий план: Определение..." Margin="0,4,0,0" Foreground="#94A3B8"/>
                        </StackPanel>
                        <Button Name="BtnEnableUltimate" Grid.Column="1" Content="Включить Макс. Производительность" Background="#4F46E5" BorderBrush="#6366F1"/>
                    </Grid>
                </Border>

                <!-- Блок ПК железа -->
                <Border Style="{StaticResource Card}">
                    <StackPanel>
                        <Grid Margin="0,0,0,10">
                            <TextBlock Text="Характеристики компьютера" FontSize="14" FontWeight="Bold" Foreground="#F1F5F9"/>
                            <Button Name="BtnScanHardware" Content="Обновить данные" HorizontalAlignment="Right" Padding="8,3"/>
                        </Grid>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0">
                                <TextBlock Name="TxtCpu" Text="CPU: Сканирование..." Margin="0,3" Foreground="#CBD5E1"/>
                                <TextBlock Name="TxtGpu" Text="GPU: Сканирование..." Margin="0,3" Foreground="#CBD5E1"/>
                                <TextBlock Name="TxtBoard" Text="Материнская плата: ..." Margin="0,3" Foreground="#CBD5E1"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock Name="TxtRam" Text="ОЗУ: Сканирование..." Margin="0,3" Foreground="#CBD5E1"/>
                                <TextBlock Name="TxtVirt" Text="Виртуализация: ..." Margin="0,3" Foreground="#CBD5E1"/>
                                <TextBlock Name="TxtSecureBoot" Text="Secure Boot: ..." Margin="0,3" Foreground="#CBD5E1"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Блок Сети -->
                <Border Style="{StaticResource Card}">
                    <StackPanel>
                        <TextBlock Text="Сетевые данные и Скорость" FontSize="14" FontWeight="Bold" Margin="0,0,0,10" Foreground="#F1F5F9"/>
                        <Grid Margin="0,0,0,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0">
                                <TextBlock Name="TxtIp" Text="IP: Не проверено" Margin="0,2" Foreground="#CBD5E1"/>
                                <TextBlock Name="TxtLocation" Text="Локация: Не проверено" Margin="0,2" Foreground="#CBD5E1"/>
                                <TextBlock Name="TxtIsp" Text="Провайдер: Не проверено" Margin="0,2" Foreground="#CBD5E1"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1" HorizontalAlignment="Right">
                                <Button Name="BtnCheckIp" Content="Узнать IP и Геолокацию" Margin="0,0,0,5"/>
                            </StackPanel>
                        </Grid>

                        <Separator Background="#23283C" Margin="0,5,0,10"/>

                        <!-- Спидтест -->
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel VerticalAlignment="Center">
                                <TextBlock Name="TxtSpeed" Text="Скорость интернета: Ожидание замера" FontSize="13" Foreground="#38BDF8"/>
                                <ProgressBar Name="PbSpeed" Height="6" Margin="0,6,15,0" Background="#1E2235" Foreground="#38BDF8" BorderThickness="0"/>
                            </StackPanel>
                            <Button Name="BtnStartSpeed" Grid.Column="1" Content="Замерить скорость" Margin="0,0,8,0"/>
                            <Button Name="BtnStopSpeed" Grid.Column="2" Content="Остановить" IsEnabled="False"/>
                        </Grid>
                    </StackPanel>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <!-- Вкладка 2: Программы -->
        <ScrollViewer Name="TabApps" Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="20,15,20,10" Visibility="Collapsed">
            <StackPanel>
                <TextBlock Text="Быстрая установка программ" FontSize="15" FontWeight="Bold" Margin="0,0,0,15" Foreground="#F1F5F9"/>

                <UniformGrid Columns="2">
                    <Border Style="{StaticResource Card}" Margin="5">
                        <DockPanel>
                            <Button Name="BtnInstallVSCode" Content="Установить" DockPanel.Dock="Right" VerticalAlignment="Center"/>
                            <StackPanel>
                                <TextBlock Text="Visual Studio Code" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock Text="Редактор кода" FontSize="11" Foreground="#94A3B8"/>
                            </StackPanel>
                        </DockPanel>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="5">
                        <DockPanel>
                            <Button Name="BtnInstallSteam" Content="Установить" DockPanel.Dock="Right" VerticalAlignment="Center"/>
                            <StackPanel>
                                <TextBlock Text="Steam" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock Text="Игровая площадка" FontSize="11" Foreground="#94A3B8"/>
                            </StackPanel>
                        </DockPanel>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="5">
                        <DockPanel>
                            <Button Name="BtnInstallDiscord" Content="Установить" DockPanel.Dock="Right" VerticalAlignment="Center"/>
                            <StackPanel>
                                <TextBlock Text="Discord" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock Text="Голосовой чат" FontSize="11" Foreground="#94A3B8"/>
                            </StackPanel>
                        </DockPanel>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="5">
                        <DockPanel>
                            <Button Name="BtnInstallTelegram" Content="Установить" DockPanel.Dock="Right" VerticalAlignment="Center"/>
                            <StackPanel>
                                <TextBlock Text="Telegram Desktop" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock Text="Мессенджер" FontSize="11" Foreground="#94A3B8"/>
                            </StackPanel>
                        </DockPanel>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="5">
                        <DockPanel>
                            <Button Name="BtnInstallRiot" Content="Установить" DockPanel.Dock="Right" VerticalAlignment="Center"/>
                            <StackPanel>
                                <TextBlock Text="Riot Games Client" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock Text="Игровой клиент Riot" FontSize="11" Foreground="#94A3B8"/>
                            </StackPanel>
                        </DockPanel>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="5">
                        <DockPanel>
                            <Button Name="BtnInstallQBit" Content="Скачать и Запустить" DockPanel.Dock="Right" VerticalAlignment="Center"/>
                            <StackPanel>
                                <TextBlock Text="qBittorrent" FontWeight="Bold" Foreground="#F8FAFC"/>
                                <TextBlock Text="SourceForge релиз" FontSize="11" Foreground="#94A3B8"/>
                            </StackPanel>
                        </DockPanel>
                    </Border>
                </UniformGrid>
            </StackPanel>
        </ScrollViewer>

        <!-- Статус-бар -->
        <Border Grid.Row="2" Background="#0C0E15" BorderBrush="#1F2438" BorderThickness="0,1,0,0" Padding="20,0">
            <Grid VerticalAlignment="Center">
                <TextBlock Name="TxtStatusBar" Text="Система готова к работе" FontSize="12" Foreground="#64748B"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# 3. ИНИЦИАЛИЗАЦИЯ WPF
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Поиск контролов
$controls = @(
    "TabBtnSystem", "TabBtnApps", "TabSystem", "TabApps",
    "LblPowerPlan", "BtnEnableUltimate", "BtnScanHardware",
    "TxtCpu", "TxtGpu", "TxtBoard", "TxtRam", "TxtVirt", "TxtSecureBoot",
    "TxtIp", "TxtLocation", "TxtIsp", "BtnCheckIp",
    "TxtSpeed", "PbSpeed", "BtnStartSpeed", "BtnStopSpeed",
    "BtnInstallVSCode", "BtnInstallSteam", "BtnInstallDiscord",
    "BtnInstallTelegram", "BtnInstallRiot", "BtnInstallQBit", "TxtStatusBar"
)
foreach ($c in $controls) { 
    Set-Variable -Name $c -Value $window.FindName($c) 
}

# Глобальные переменные для спидтеста
$script:SpeedTestCancelled = $false
$script:WebClient = $null

# Вкладки
$TabBtnSystem.Add_Click({
    $TabSystem.Visibility = "Visible"
    $TabApps.Visibility = "Collapsed"
})
$TabBtnApps.Add_Click({
    $TabSystem.Visibility = "Collapsed"
    $TabApps.Visibility = "Visible"
})

# План питания
function Update-PowerPlanDisplay {
    $planOutput = powercfg /getactivescheme
    if ($planOutput -match '\((.+?)\)') {
        $activePlan = $matches[1]
        $LblPowerPlan.Text = "Текущий план: $activePlan"
        if ($activePlan -like "*Ultimate*" -or $activePlan -like "*Максимальная*") {
            $LblPowerPlan.Foreground = [System.Windows.Media.Brushes]::LightGreen
        }
    }
}
Update-PowerPlanDisplay

$BtnEnableUltimate.Add_Click({
    $TxtStatusBar.Text = "Попытка активации схемы Ultimate Performance..."
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
    
    $plans = powercfg /list
    $targetGuid = $null
    foreach ($line in ($plans -split "`n")) {
        if ($line -match "GUID:\s+([a-f0-9\-]+).*(Ultimate Performance|Максимальная производительность)") {
            $targetGuid =$matches[1]
            break
        }
    }

    if ($targetGuid) {
        powercfg /setactive $targetGuid
        Update-PowerPlanDisplay
        $TxtStatusBar.Text = "Максимальная производительность успешно включена!"
    } else {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Update-PowerPlanDisplay
        $TxtStatusBar.Text = "Включена Высокая производительность (Ultimate ограничена ОС)."
    }
})

# Сбор характеристик ПК
$BtnScanHardware.Add_Click({$TxtStatusBar.Text = "Сбор информации о системе..."
    
    $cpu = Get-CimInstance Win32_Processor \vert{} Select-Object -First 1$TxtCpu.Text = "CPU: $($cpu.Name)"

    $gpus = (Get-CimInstance Win32_VideoController \vert{} ForEach-Object {$_.Name }) -join " / "
    $TxtGpu.Text = "GPU: $gpus"

    $bb = Get-CimInstance Win32_BaseBoard$TxtBoard.Text = "Плата: $($bb.Manufacturer) $($bb.Product)"

    $ramSticks = Get-CimInstance Win32_PhysicalMemory
    $totalRamGb = [math]::Round(($ramSticks | Measure-Object -Property Capacity -Sum).Sum / 1GB, 1)
    $maxSpeed = ($ramSticks | Measure-Object -Property Speed -Maximum).Maximum
    $TxtRam.Text = "ОЗУ: $totalRamGb GB (Частота: $maxSpeed MHz)"

    $virt =$cpu.VirtualizationFirmwareEnabled
    $TxtVirt.Text = "Виртуализация: $(if ($virt) { 'Включена (OK)' } else { 'Отключена' })"

    try {
        $sb = Confirm-SecureBootUEFI$TxtSecureBoot.Text = "Secure Boot: $(if ($sb) { 'Включен (OK)' } else { 'Выключен' })"
    } catch {
        $TxtSecureBoot.Text = "Secure Boot: Legacy / Не поддерживается"
    }

    $TxtStatusBar.Text = "Характеристики ПК успешно обновлены."
})

# Проверка IP
$BtnCheckIp.Add_Click({$TxtStatusBar.Text = "Определение IP и геолокации..."
    try {
        $ipInfo = Invoke-RestMethod -Uri "https://ipapi.co/json/" -TimeoutSec 5
        $TxtIp.Text = "IP: $($ipInfo.ip)"
        $TxtLocation.Text = "Локация: $($ipInfo.country_name), $($ipInfo.city)"
        $TxtIsp.Text = "Провайдер: $($ipInfo.org)"
        $TxtStatusBar.Text = "Данные сети успешно получены."
    } catch {
        $TxtStatusBar.Text = "Ошибка соединения с сервисом IP."
    }
})

# Замер скорости
$BtnStartSpeed.Add_Click({$script:SpeedTestCancelled = $false$BtnStartSpeed.IsEnabled = $false$BtnStopSpeed.IsEnabled = $true$PbSpeed.IsIndeterminate = $true$TxtSpeed.Text = "Загрузка тестового блока..."
    $TxtStatusBar.Text = "Тестирование скорости..."

    $testUrl = "https://speed.cloudflare.com/__down?bytes=50000000"
    $tempFile = "$env:TEMP\speedtest_tmp.dat"

    $script:WebClient = New-Object System.Net.WebClient
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $task =$script:WebClient.DownloadFileTaskAsync($testUrl,$tempFile)
        while (-not $task.IsCompleted) {
            if ($script:SpeedTestCancelled) { 
                break 
            }
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
            Start-Sleep -Milliseconds 100
        }

        $stopwatch.Stop()
        $PbSpeed.IsIndeterminate =$false

        if ($script:SpeedTestCancelled) {$TxtSpeed.Text = "Замер скорости отменен."
            $TxtStatusBar.Text = "Тест скорости остановлен."
        } else {
            $fileSizeBits = (Get-Item$tempFile).Length * 8
            $seconds =$stopwatch.Elapsed.TotalSeconds
            $mbps = [math]::Round(($fileSizeBits / $seconds) / 1Mb, 2)
            $TxtSpeed.Text = "Скорость загрузки: $mbps Mbps"
            $TxtStatusBar.Text = "Тест скорости завершен."
        }
    } catch {
        $PbSpeed.IsIndeterminate = $false$TxtSpeed.Text = "Ошибка замера или отмена."
    } finally {
        if (Test-Path $tempFile) { 
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue 
        }
        $BtnStartSpeed.IsEnabled =$true
        $BtnStopSpeed.IsEnabled =$false
        if ($script:WebClient) {$script:WebClient.Dispose() 
        }
    }
})

$BtnStopSpeed.Add_Click({
    $script:SpeedTestCancelled =$true
    if ($script:WebClient) {$script:WebClient.CancelAsync()
    }
})

# Установка ПО
function Install-AppWinget ($id,$name) {
    $TxtStatusBar.Text = "Запуск установки $name..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -Command `"winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements; Write-Host 'Завершено!'; Start-Sleep -Seconds 2`""
}

$BtnInstallVSCode.Add_Click({ Install-AppWinget "Microsoft.VisualStudioCode" "VS Code" })
$BtnInstallSteam.Add_Click({ Install-AppWinget "Valve.Steam" "Steam" })
$BtnInstallDiscord.Add_Click({ Install-AppWinget "Discord.Discord" "Discord" })
$BtnInstallTelegram.Add_Click({ Install-AppWinget "Telegram.TelegramDesktop" "Telegram" })
$BtnInstallRiot.Add_Click({ Install-AppWinget "RiotGames.RiotClient" "Riot Client" })

$BtnInstallQBit.Add_Click({$TxtStatusBar.Text = "Скачивание qBittorrent..."
    $url = "https://sourceforge.net/projects/qbittorrent/files/latest/download"
    $outFile = "$env:TEMP\qbittorrent_setup.exe"
    try {
        Invoke-WebRequest -Uri $url -OutFile$outFile -UserAgent "Mozilla/5.0"
        $TxtStatusBar.Text = "Запуск инсталлятора qBittorrent..."
        Start-Process -FilePath $outFile
    } catch {
        $TxtStatusBar.Text = "Не удалось загрузить qBittorrent."
    }
})

# Первоначальный опрос железа при показе окна
$window.Add_ContentRendered({
    $BtnScanHardware.RaiseEvent((New-Object System.Windows.RoutedEventArgs($Button.ClickEvent)))
})

# Отображение окна
$window.ShowDialog() | Out-Null
