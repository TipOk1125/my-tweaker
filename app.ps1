<#
.SYNOPSIS
    System Hub & Tweaker - WPF UI на чистом PowerShell.
.DESCRIPTION
    Запуск из сети:   irm https://raw.githubusercontent.com/TipOk1125/my-tweaker/refs/heads/main/app.ps1 | iex
    Запуск локально:  iex (Get-Content .\app.ps1 -Raw -Encoding UTF8)
    НЕ используйте powershell -File: файл в UTF-8 без BOM, а PowerShell 5.1
    читает такие файлы как ANSI, и кириллица ломает разбор скрипта.
    BOM ставить нельзя: он ломает запуск через irm ... | iex.
#>

# =====================================================================
# 1. ПРАВА АДМИНИСТРАТОРА (работает и при iex, и при локальном запуске)
# =====================================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    if ($PSCommandPath) {
        # Скрипт запущен из файла - перезапускаем его с явным чтением UTF-8
        $argList = '-NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText(''' + $PSCommandPath + ''', [Text.Encoding]::UTF8))"'
    } else {
        # Скрипт запущен через irm | iex - перезапускаем ту же ссылку
        $argList = '-NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/TipOk1125/my-tweaker/refs/heads/main/app.ps1 | iex"'
    }
    Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    return
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

# =====================================================================
# 2. XAML — интерфейс в стиле iOS (тёмная тема, скругления, сегменты)
#    Внимание: внутри here-string нельзя использовать символы $ и `
# =====================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Hub &amp; Tweaker" Height="740" Width="1010"
        WindowStartupLocation="CenterScreen"
        Background="#0B0B0F" Foreground="#F2F2F7"
        FontFamily="Segoe UI" FontSize="13"
        ResizeMode="CanMinimize" UseLayoutRounding="True" SnapsToDevicePixels="True">

    <WindowChrome.WindowChrome>
        <WindowChrome CaptionHeight="0" CornerRadius="18" GlassFrameThickness="-1" ResizeBorderThickness="6" UseAeroCaptionButtons="False"/>
    </WindowChrome.WindowChrome>

    <Window.Resources>

        <!-- ========== Шаблон кнопки (pill) с анимациями ========== -->
        <ControlTemplate x:Key="PillTemplate" TargetType="Button">
            <Border x:Name="Bd" CornerRadius="18"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    Padding="{TemplateBinding Padding}"
                    RenderTransformOrigin="0.5,0.5">
                <Border.RenderTransform>
                    <ScaleTransform ScaleX="1" ScaleY="1"/>
                </Border.RenderTransform>
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" RecognizesAccessKey="True"/>
            </Border>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Trigger.EnterActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="Opacity" To="0.85" Duration="0:0:0.12"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.EnterActions>
                    <Trigger.ExitActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="Opacity" To="1" Duration="0:0:0.18"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.ExitActions>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Trigger.EnterActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="0.96" Duration="0:0:0.08"/>
                                <DoubleAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="0.96" Duration="0:0:0.08"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.EnterActions>
                    <Trigger.ExitActions>
                        <BeginStoryboard>
                            <Storyboard>
                                <DoubleAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)" To="1" Duration="0:0:0.12"/>
                                <DoubleAnimation Storyboard.TargetName="Bd" Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)" To="1" Duration="0:0:0.12"/>
                            </Storyboard>
                        </BeginStoryboard>
                    </Trigger.ExitActions>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter TargetName="Bd" Property="Opacity" Value="0.45"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <!-- Неявный стиль: все обычные кнопки — тёмный pill -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2C2C2E"/>
            <Setter Property="Foreground" Value="#F2F2F7"/>
            <Setter Property="BorderBrush" Value="#3A3A3C"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="SnapsToDevicePixels" Value="True"/>
            <Setter Property="Template" Value="{StaticResource PillTemplate}"/>
        </Style>

        <!-- Акцентная (синяя) кнопка -->
        <Style x:Key="AccentBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#0A84FF"/>
            <Setter Property="BorderBrush" Value="#0A84FF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
        </Style>

        <!-- Опасная (красная) кнопка -->
        <Style x:Key="DangerBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#FF453A"/>
            <Setter Property="BorderBrush" Value="#FF453A"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
        </Style>

        <!-- Шаблон кнопки сегментированного контрола (без анимаций, дёшево) -->
        <ControlTemplate x:Key="SegTemplate" TargetType="Button">
            <Border x:Name="Sbd" CornerRadius="15" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Sbd" Property="Background" Value="#48484A"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter TargetName="Sbd" Property="Background" Value="#5A5A5E"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style x:Key="SegBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template" Value="{StaticResource SegTemplate}"/>
        </Style>

        <!-- Кнопки окна (свернуть / закрыть) -->
        <Style x:Key="TitleBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Width" Value="34"/>
            <Setter Property="Height" Value="34"/>
            <Setter Property="Padding" Value="0"/>
            <Setter Property="Background" Value="#2C2C2E"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>

        <!-- Карточка -->
        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="#1C1C1E"/>
            <Setter Property="CornerRadius" Value="20"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#2C2C2E"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="0,0,0,14"/>
        </Style>

        <!-- Заголовок секции -->
        <Style x:Key="SectionHeader" TargetType="TextBlock">
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#8E8E93"/>
            <Setter Property="Margin" Value="0,0,0,8"/>
        </Style>

        <!-- Текст внутри карточек -->
        <Style x:Key="InfoText" TargetType="TextBlock">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="#E5E5EA"/>
            <Setter Property="Margin" Value="0,3"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
        </Style>

        <!-- Тонкая тёмная полоса прокрутки -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent">
                            <Track x:Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False"/>
                                </Track.DecreaseRepeatButton>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False"/>
                                </Track.IncreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border CornerRadius="4" Background="#48484A" Margin="1,1"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="PART_Track" Property="Opacity" Value="0.3"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Разделитель -->
        <Style TargetType="Separator">
            <Setter Property="Background" Value="#2C2C2E"/>
            <Setter Property="Height" Value="1"/>
            <Setter Property="Margin" Value="0,12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Separator">
                        <Border Background="{TemplateBinding Background}" Height="{TemplateBinding Height}"/>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Полоса прогресса -->
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="8"/>
            <Setter Property="Background" Value="#2C2C2E"/>
            <Setter Property="Foreground" Value="#0A84FF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Grid>
                            <Border x:Name="PART_Track" Background="{TemplateBinding Background}" CornerRadius="4"/>
                            <Border x:Name="PART_Indicator" HorizontalAlignment="Left" Background="{TemplateBinding Foreground}" CornerRadius="4"/>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="54"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="34"/>
        </Grid.RowDefinitions>

        <!-- ================= ШАПКА ОКНА ================= -->
        <Border Grid.Row="0" Background="#111114" BorderBrush="#2C2C2E" BorderThickness="0,0,0,1">
            <Grid Margin="18,0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <Border x:Name="TitleBar" Background="Transparent" Cursor="Hand">
                    <Grid VerticalAlignment="Center">
                        <Border Width="28" Height="28" CornerRadius="9" Background="#0A84FF">
                            <TextBlock Text="S" FontSize="15" FontWeight="Bold" Foreground="#FFFFFF"
                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <StackPanel Margin="10,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="System Hub" FontSize="14" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                            <TextBlock Text="TWEAKER FOR WINDOWS" FontSize="9" Foreground="#8E8E93"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnMin" Style="{StaticResource TitleBtn}" Content="-" Margin="8,0,0,0"/>
                    <Button x:Name="BtnClose" Style="{StaticResource TitleBtn}" Background="#FF453A"
                            Foreground="#FFFFFF" Content="x" Margin="8,0,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- ================= ЗАГОЛОВОК + СЕГМЕНТЫ ================= -->
        <Border Grid.Row="1" Background="#0B0B0F">
            <Grid Margin="22,18,22,6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel VerticalAlignment="Center">
                    <TextBlock Name="LblBigTitle" Text="Мониторинг и сеть" FontSize="26" FontWeight="Bold" Foreground="#FFFFFF"/>
                    <TextBlock Name="LblBigSub" Text="Состояние ПК, питание, интернет и софт" FontSize="13" Foreground="#8E8E93" Margin="0,4,0,0"/>
                </StackPanel>

                <Border Grid.Column="1" Background="#1C1C1E" BorderBrush="#2C2C2E" BorderThickness="1"
                        CornerRadius="17" Padding="3" VerticalAlignment="Center" Height="38" Width="340">
                    <Grid>
                        <Border Name="SegIndicator" Width="166" CornerRadius="14" Background="#3A3A3C"
                                HorizontalAlignment="Left" VerticalAlignment="Stretch">
                            <Border.RenderTransform>
                                <TranslateTransform X="0"/>
                            </Border.RenderTransform>
                        </Border>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Button Name="TabBtnSystem" Grid.Column="0" Style="{StaticResource SegBtn}"
                                    Content="Мониторинг" Foreground="#FFFFFF" FontWeight="SemiBold"/>
                            <Button Name="TabBtnApps" Grid.Column="1" Style="{StaticResource SegBtn}"
                                    Content="Каталог ПО" Foreground="#8E8E93"/>
                        </Grid>
                    </Grid>
                </Border>
            </Grid>
        </Border>

        <!-- ================= КОНТЕНТ: ВКЛАДКА 1 ================= -->
        <ScrollViewer Name="TabSystem" Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="22,10,22,8">
            <ScrollViewer.RenderTransform>
                <TranslateTransform Y="0"/>
            </ScrollViewer.RenderTransform>
            <StackPanel>

                <!-- Питание -->
                <Border Style="{StaticResource Card}">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel VerticalAlignment="Center">
                            <TextBlock Text="ПИТАНИЕ" Style="{StaticResource SectionHeader}"/>
                            <TextBlock Name="LblPowerPlan" Text="Текущий план: определение..." FontSize="16" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                            <TextBlock Text="Схема максимальной производительности" FontSize="12" Foreground="#8E8E93" Margin="0,4,0,0"/>
                        </StackPanel>
                        <Button Name="BtnEnableUltimate" Grid.Column="1" Style="{StaticResource AccentBtn}"
                                Content="Макс. производительность" VerticalAlignment="Center" Margin="16,0,0,0"/>
                    </Grid>
                </Border>

                <!-- Железо -->
                <Border Style="{StaticResource Card}">
                    <StackPanel>
                        <Grid Margin="0,0,0,6">
                            <TextBlock Text="ЖЕЛЕЗО" Style="{StaticResource SectionHeader}" VerticalAlignment="Center" Margin="0"/>
                            <Button Name="BtnScanHardware" Content="Обновить" HorizontalAlignment="Right" Padding="14,6" FontSize="12"/>
                        </Grid>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,14,0">
                                <TextBlock Name="TxtCpu" Text="CPU: сканирование..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtGpu" Text="GPU: сканирование..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtBoard" Text="Материнская плата: ..." Style="{StaticResource InfoText}"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock Name="TxtRam" Text="ОЗУ: сканирование..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtVirt" Text="Виртуализация: ..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtSecureBoot" Text="Secure Boot: ..." Style="{StaticResource InfoText}"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Сеть и скорость -->
                <Border Style="{StaticResource Card}">
                    <StackPanel>
                        <TextBlock Text="СЕТЬ" Style="{StaticResource SectionHeader}"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock Name="TxtIp" Text="IP: не проверено" Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtLocation" Text="Локация: не проверено" Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtIsp" Text="Провайдер: не проверено" Style="{StaticResource InfoText}"/>
                            </StackPanel>
                            <Button Name="BtnCheckIp" Grid.Column="1" Style="{StaticResource AccentBtn}"
                                    Content="Определить IP" VerticalAlignment="Top"/>
                        </Grid>

                        <Separator/>

                        <TextBlock Text="СКОРОСТЬ ИНТЕРНЕТА" Style="{StaticResource SectionHeader}"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel VerticalAlignment="Center" Margin="0,0,16,0">
                                <TextBlock Name="TxtSpeed" Text="Ожидание замера" FontSize="15" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <ProgressBar Name="PbSpeed" Margin="0,8,0,0" Value="0"/>
                            </StackPanel>
                            <Button Name="BtnStartSpeed" Grid.Column="1" Style="{StaticResource AccentBtn}"
                                    Content="Замерить" Margin="0,0,10,0"/>
                            <Button Name="BtnStopSpeed" Grid.Column="2" Style="{StaticResource DangerBtn}"
                                    Content="Стоп" IsEnabled="False"/>
                        </Grid>
                    </StackPanel>
                </Border>

            </StackPanel>
        </ScrollViewer>

        <!-- ================= КОНТЕНТ: ВКЛАДКА 2 ================= -->
        <ScrollViewer Name="TabApps" Grid.Row="2" VerticalScrollBarVisibility="Auto" Margin="22,10,22,8" Visibility="Collapsed">
            <ScrollViewer.RenderTransform>
                <TranslateTransform Y="0"/>
            </ScrollViewer.RenderTransform>
            <StackPanel>
                <TextBlock Text="БЫСТРАЯ УСТАНОВКА" Style="{StaticResource SectionHeader}" Margin="0,0,0,10"/>

                <UniformGrid Columns="2">

                    <Border Style="{StaticResource Card}" Margin="0,0,13,14" Padding="16">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Border Width="42" Height="42" CornerRadius="12" Background="#0078D4" VerticalAlignment="Center">
                                <TextBlock Text="V" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="13,0,10,0">
                                <TextBlock Text="Visual Studio Code" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <TextBlock Text="Редактор кода" FontSize="12" Foreground="#8E8E93" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button Name="BtnInstallVSCode" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Установить" Padding="14,8" FontSize="12" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="0,0,0,14" Padding="16">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Border Width="42" Height="42" CornerRadius="12" Background="#66C0F4" VerticalAlignment="Center">
                                <TextBlock Text="S" FontSize="18" FontWeight="Bold" Foreground="#0B0B0F" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="13,0,10,0">
                                <TextBlock Text="Steam" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <TextBlock Text="Игровая площадка" FontSize="12" Foreground="#8E8E93" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button Name="BtnInstallSteam" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Установить" Padding="14,8" FontSize="12" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="0,0,13,14" Padding="16">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Border Width="42" Height="42" CornerRadius="12" Background="#5865F2" VerticalAlignment="Center">
                                <TextBlock Text="D" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="13,0,10,0">
                                <TextBlock Text="Discord" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <TextBlock Text="Голосовой чат" FontSize="12" Foreground="#8E8E93" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button Name="BtnInstallDiscord" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Установить" Padding="14,8" FontSize="12" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="0,0,0,14" Padding="16">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Border Width="42" Height="42" CornerRadius="12" Background="#2AABEE" VerticalAlignment="Center">
                                <TextBlock Text="T" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="13,0,10,0">
                                <TextBlock Text="Telegram" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <TextBlock Text="Мессенджер" FontSize="12" Foreground="#8E8E93" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button Name="BtnInstallTelegram" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Установить" Padding="14,8" FontSize="12" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="0,0,13,14" Padding="16">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Border Width="42" Height="42" CornerRadius="12" Background="#FF4655" VerticalAlignment="Center">
                                <TextBlock Text="R" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="13,0,10,0">
                                <TextBlock Text="Riot Games" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <TextBlock Text="Valorant, LoL" FontSize="12" Foreground="#8E8E93" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button Name="BtnInstallRiot" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Установить" Padding="14,8" FontSize="12" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>

                    <Border Style="{StaticResource Card}" Margin="0,0,0,14" Padding="16">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <Border Width="42" Height="42" CornerRadius="12" Background="#34C759" VerticalAlignment="Center">
                                <TextBlock Text="Q" FontSize="18" FontWeight="Bold" Foreground="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="13,0,10,0">
                                <TextBlock Text="qBittorrent" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <TextBlock Text="Торрент-клиент" FontSize="12" Foreground="#8E8E93" Margin="0,2,0,0"/>
                            </StackPanel>
                            <Button Name="BtnInstallQBit" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Скачать" Padding="14,8" FontSize="12" VerticalAlignment="Center"/>
                        </Grid>
                    </Border>

                </UniformGrid>
            </StackPanel>
        </ScrollViewer>

        <!-- ================= СТАТУС-БАР ================= -->
        <Border Grid.Row="3" Background="#111114" BorderBrush="#2C2C2E" BorderThickness="0,1,0,0" Padding="22,0">
            <Grid VerticalAlignment="Center">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Ellipse Width="8" Height="8" Fill="#30D158" VerticalAlignment="Center"/>
                <TextBlock Name="TxtStatusBar" Grid.Column="1" Text="Система готова к работе"
                           FontSize="12" Foreground="#8E8E93" VerticalAlignment="Center" Margin="10,0,0,0"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# =====================================================================
# 3. ИНИЦИАЛИЗАЦИЯ WPF
# =====================================================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$controls = @(
    "TitleBar", "BtnMin", "BtnClose",
    "TabBtnSystem", "TabBtnApps", "SegIndicator",
    "LblBigTitle", "LblBigSub",
    "TabSystem", "TabApps",
    "LblPowerPlan", "BtnEnableUltimate",
    "BtnScanHardware", "TxtCpu", "TxtGpu", "TxtBoard", "TxtRam", "TxtVirt", "TxtSecureBoot",
    "TxtIp", "TxtLocation", "TxtIsp", "BtnCheckIp",
    "TxtSpeed", "PbSpeed", "BtnStartSpeed", "BtnStopSpeed",
    "BtnInstallVSCode", "BtnInstallSteam", "BtnInstallDiscord",
    "BtnInstallTelegram", "BtnInstallRiot", "BtnInstallQBit",
    "TxtStatusBar"
)
foreach ($c in $controls) {
    Set-Variable -Name $c -Value $window.FindName($c)
}

# Состояние спидтеста
$script:SpeedTestCancelled = $false
$script:WebClient = $null
$script:IdleBrush = New-Object System.Windows.Media.SolidColorBrush -ArgumentList ([System.Windows.Media.Color]::FromRgb(0x8E, 0x8E, 0x93))

# =====================================================================
# 4. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =====================================================================

function Switch-Tab {
    param([ValidateSet('System', 'Apps')][string]$Target)

    $isSystem = ($Target -eq 'System')

    if ($isSystem) {
        $shift = 0
        $TabSystem.Visibility = [System.Windows.Visibility]::Visible
        $TabApps.Visibility = [System.Windows.Visibility]::Collapsed
        $shown = $TabSystem
        $TabBtnSystem.Foreground = [System.Windows.Media.Brushes]::White
        $TabBtnSystem.FontWeight = [System.Windows.FontWeights]::SemiBold
        $TabBtnApps.Foreground = $script:IdleBrush
        $TabBtnApps.FontWeight = [System.Windows.FontWeights]::Normal
        $LblBigTitle.Text = "Мониторинг и сеть"
        $LblBigSub.Text = "Состояние ПК, питание, интернет и софт"
    } else {
        $shift = 166
        $TabSystem.Visibility = [System.Windows.Visibility]::Collapsed
        $TabApps.Visibility = [System.Windows.Visibility]::Visible
        $shown = $TabApps
        $TabBtnApps.Foreground = [System.Windows.Media.Brushes]::White
        $TabBtnApps.FontWeight = [System.Windows.FontWeights]::SemiBold
        $TabBtnSystem.Foreground = $script:IdleBrush
        $TabBtnSystem.FontWeight = [System.Windows.FontWeights]::Normal
        $LblBigTitle.Text = "Каталог ПО"
        $LblBigSub.Text = "Установка популярных программ в один клик"
    }

    # Слайдер сегментированного контрола (лёгкая анимация)
    $slide = New-Object System.Windows.Media.Animation.DoubleAnimation
    $slide.To = $shift
    $slide.Duration = New-Object System.Windows.Duration -ArgumentList 250
    $ease = New-Object System.Windows.Media.Animation.CubicEase
    $ease.EasingMode = 'EaseOut'
    $slide.EasingFunction = $ease
    $segTransform = $SegIndicator.RenderTransform
    $segTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::XProperty, $slide)

    # Появление контента: прозрачность + сдвиг на 10px вверх
    $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
    $fadeIn.From = 0.0
    $fadeIn.To = 1.0
    $fadeIn.Duration = New-Object System.Windows.Duration -ArgumentList 220

    $slideUp = New-Object System.Windows.Media.Animation.DoubleAnimation
    $slideUp.From = 10.0
    $slideUp.To = 0.0
    $slideUp.Duration = New-Object System.Windows.Duration -ArgumentList 220

    $shown.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)
    $shown.RenderTransform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $slideUp)
}

function Update-PowerPlanDisplay {
    try {
        $planOutput = powercfg /getactivescheme 2>$null
        if ($planOutput -match '\((.+?)\)') {
            $activePlan = $matches[1]
            $LblPowerPlan.Text = "Текущий план: $activePlan"
            if ($activePlan -like "*Ultimate*" -or $activePlan -like "*Максимальная*") {
                $LblPowerPlan.Foreground = [System.Windows.Media.Brushes]::LightGreen
            } else {
                $LblPowerPlan.Foreground = [System.Windows.Media.Brushes]::LightGray
            }
        }
    } catch { }
}

function Update-HardwareInfo {
    try {
        $TxtStatusBar.Text = "Сбор данных о комплектующих..."
        $window.Dispatcher.Invoke([Action]{ }, [System.Windows.Threading.DispatcherPriority]::Background)

        # Процессор
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        if ($cpu) {
            $TxtCpu.Text = "CPU: " + $cpu.Name.Trim()
            if ($cpu.VirtualizationFirmwareEnabled) {
                $TxtVirt.Text = "Виртуализация: включена (OK)"
            } else {
                $TxtVirt.Text = "Виртуализация: отключена в BIOS"
            }
        } else {
            $TxtCpu.Text = "CPU: не найден"
        }

        # Видеокарта
        $gpus = (Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join " / "
        if (-not $gpus) { $gpus = "не найдена" }
        $TxtGpu.Text = "GPU: $gpus"

        # Материнская плата
        $bb = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
        if ($bb) {
            $TxtBoard.Text = "Плата: $($bb.Manufacturer) $($bb.Product)"
        } else {
            $TxtBoard.Text = "Плата: не найдена"
        }

        # ОЗУ
        $ramSticks = @(Get-CimInstance Win32_PhysicalMemory)
        if ($ramSticks.Count -gt 0) {
            $totalRamGb = [math]::Round(($ramSticks | Measure-Object -Property Capacity -Sum).Sum / 1GB, 1)
            $maxSpeed = ($ramSticks | Measure-Object -Property Speed -Maximum).Maximum
            $TxtRam.Text = "ОЗУ: $totalRamGb GB ($maxSpeed MHz)"
        } else {
            $TxtRam.Text = "ОЗУ: данные недоступны"
        }

        # Secure Boot
        try {
            $sb = Confirm-SecureBootUEFI
            if ($sb) {
                $TxtSecureBoot.Text = "Secure Boot: включён (OK)"
            } else {
                $TxtSecureBoot.Text = "Secure Boot: выключен"
            }
        } catch {
            $TxtSecureBoot.Text = "Secure Boot: Legacy / не поддерживается"
        }

        $TxtStatusBar.Text = "Характеристики ПК обновлены"
    } catch {
        $TxtStatusBar.Text = "Ошибка чтения данных о железе"
    }
}

# =====================================================================
# 5. ОБРАБОТЧИКИ СОБЫТИЙ
# =====================================================================

# Кнопки окна
$BtnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
$BtnClose.Add_Click({ $window.Close() })

# Перетаскивание окна за шапку
$TitleBar.Add_MouseLeftButtonDown({
    param($sender, $e)
    try { $window.DragMove() } catch { }
})

# Переключение вкладок
$TabBtnSystem.Add_Click({ Switch-Tab -Target 'System' })
$TabBtnApps.Add_Click({ Switch-Tab -Target 'Apps' })

# Обновление плана питания
Update-PowerPlanDisplay

$BtnEnableUltimate.Add_Click({
    $TxtStatusBar.Text = "Попытка разблокировки схемы питания..."

    # Разблокировка схемы Ultimate Performance
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null

    # Поиск GUID нужной схемы
    $plans = powercfg /list
    $targetGuid = $null
    foreach ($line in ($plans -split "`n")) {
        if (($line -match "Ultimate Performance") -or ($line -match "Максимальная производительность")) {
            if ($line -match "GUID:\s+([a-f0-9\-]+)") {
                $targetGuid = $matches[1]
                break
            }
        }
    }

    if ($targetGuid) {
        powercfg /setactive $targetGuid
        Update-PowerPlanDisplay
        $TxtStatusBar.Text = "Максимальная производительность активирована"
    } else {
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Update-PowerPlanDisplay
        $TxtStatusBar.Text = "Включена высокая производительность (Ultimate заблокирован ОС)"
    }
})

# Сканирование железа
$BtnScanHardware.Add_Click({ Update-HardwareInfo })

# Проверка IP
$BtnCheckIp.Add_Click({
    $TxtStatusBar.Text = "Запрос информации о соединении..."
    try {
        $ipInfo = Invoke-RestMethod -Uri "https://ipapi.co/json/" -TimeoutSec 8
        $TxtIp.Text = "IP: $($ipInfo.ip)"
        $TxtLocation.Text = "Локация: $($ipInfo.country_name), $($ipInfo.city)"
        $TxtIsp.Text = "Провайдер: $($ipInfo.org)"
        $TxtStatusBar.Text = "Сетевая информация обновлена"
    } catch {
        $TxtStatusBar.Text = "Не удалось связаться с сервером проверки IP"
    }
})

# Замер скорости
$BtnStartSpeed.Add_Click({
    $script:SpeedTestCancelled = $false
    $BtnStartSpeed.IsEnabled = $false
    $BtnStopSpeed.IsEnabled = $true
    $PbSpeed.Value = 0
    $TxtSpeed.Text = "Загрузка тестового блока..."
    $TxtStatusBar.Text = "Идёт замер скорости..."

    $testUrl = "https://speed.cloudflare.com/__down?bytes=25000000"
    $testBytes = 25000000
    $tempFile = Join-Path $env:TEMP "speedtest_tmp.dat"
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }

    $script:WebClient = New-Object System.Net.WebClient
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $task = $script:WebClient.DownloadFileTaskAsync($testUrl, $tempFile)

        while (-not $task.IsCompleted) {
            if ($script:SpeedTestCancelled) { break }

            $done = 0
            try {
                $fi = Get-Item $tempFile -ErrorAction SilentlyContinue
                if ($fi) { $done = $fi.Length }
            } catch { }
            if ($done -gt 0) {
                $PbSpeed.Value = [math]::Min(99, [math]::Round(($done / $testBytes) * 100))
            }

            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 60
        }

        $stopwatch.Stop()

        if ($script:SpeedTestCancelled) {
            $TxtSpeed.Text = "Замер отменён"
            $TxtStatusBar.Text = "Тест скорости остановлен"
        } elseif ($task.IsFaulted -or -not (Test-Path $tempFile)) {
            $PbSpeed.Value = 0
            $TxtSpeed.Text = "Ошибка замера"
            $TxtStatusBar.Text = "Сбой при тесте скорости"
        } else {
            $PbSpeed.Value = 100
            $fileSizeBits = (Get-Item $tempFile).Length * 8
            $seconds = $stopwatch.Elapsed.TotalSeconds
            if ($seconds -le 0) { $seconds = 0.001 }
            $mbps = [math]::Round(($fileSizeBits / $seconds) / 1Mb, 2)
            $TxtSpeed.Text = "Скорость загрузки: $mbps Mbps"
            $TxtStatusBar.Text = "Тест завершён: $mbps Mbps"
        }
    } catch {
        $PbSpeed.Value = 0
        $TxtSpeed.Text = "Ошибка замера"
        $TxtStatusBar.Text = "Сбой при тесте скорости"
    } finally {
        $stopwatch.Stop()
        try { if ($script:WebClient) { $script:WebClient.CancelAsync() } } catch { }
        try { if ($script:WebClient) { $script:WebClient.Dispose() } } catch { }
        $script:WebClient = $null
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
        $BtnStartSpeed.IsEnabled = $true
        $BtnStopSpeed.IsEnabled = $false
    }
})

$BtnStopSpeed.Add_Click({
    $script:SpeedTestCancelled = $true
    try { if ($script:WebClient) { $script:WebClient.CancelAsync() } } catch { }
})

# Установка ПО через winget
function Install-AppWinget {
    param([string]$Id, [string]$Name)
    $TxtStatusBar.Text = "Установка $Name через winget..."
    $pargs = '-NoProfile -ExecutionPolicy Bypass -Command "winget install --id {0} -e --silent --accept-package-agreements --accept-source-agreements; Write-Host; Write-Host Готово. Нажмите Enter для закрытия; Read-Host"' -f $Id
    Start-Process powershell.exe -ArgumentList $pargs
}

$BtnInstallVSCode.Add_Click({ Install-AppWinget -Id "Microsoft.VisualStudioCode" -Name "VS Code" })
$BtnInstallSteam.Add_Click({ Install-AppWinget -Id "Valve.Steam" -Name "Steam" })
$BtnInstallDiscord.Add_Click({ Install-AppWinget -Id "Discord.Discord" -Name "Discord" })
$BtnInstallTelegram.Add_Click({ Install-AppWinget -Id "Telegram.TelegramDesktop" -Name "Telegram" })
$BtnInstallRiot.Add_Click({ Install-AppWinget -Id "RiotGames.RiotClient" -Name "Riot Client" })

# Загрузка qBittorrent с SourceForge
$BtnInstallQBit.Add_Click({
    $TxtStatusBar.Text = "Загрузка qBittorrent с SourceForge..."
    $BtnInstallQBit.IsEnabled = $false
    $url = "https://sourceforge.net/projects/qbittorrent/files/latest/download"
    $outFile = Join-Path $env:TEMP "qbittorrent_setup.exe"
    try {
        Invoke-WebRequest -Uri $url -OutFile $outFile -UserAgent "Mozilla/5.0" -MaximumRedirection 10 -UseBasicParsing
        $TxtStatusBar.Text = "Запуск установщика qBittorrent..."
        Start-Process -FilePath $outFile
    } catch {
        $TxtStatusBar.Text = "Ошибка загрузки qBittorrent. Проверьте сеть"
    } finally {
        $BtnInstallQBit.IsEnabled = $true
    }
})

# =====================================================================
# 6. ЗАПУСК
# =====================================================================
$window.Opacity = 0

$window.Add_ContentRendered({
    # Мягкое появление окна
    $winFade = New-Object System.Windows.Media.Animation.DoubleAnimation
    $winFade.From = 0.0
    $winFade.To = 1.0
    $winFade.Duration = New-Object System.Windows.Duration -ArgumentList 350
    $window.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $winFade)

    Update-HardwareInfo
})

$window.ShowDialog() | Out-Null
