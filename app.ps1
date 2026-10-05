<#
.SYNOPSIS
    System Hub & Tweaker - WPF UI на чистом PowerShell.
.DESCRIPTION
    Запуск из сети:   irm https://raw.githubusercontent.com/TipOk1125/my-tweaker/refs/heads/main/app.ps1 | iex
    Запуск локально:  iex (Get-Content .\app.ps1 -Raw -Encoding UTF8)
    НЕ используйте powershell -File: файл в UTF-8 без BOM, а PowerShell 5.1
    читает такие файлы как ANSI, и кириллица ломает разбор скрипта.
    BOM ставить нельзя: он ломает запуск через irm ... | iex.
.NOTES
    Возможности: схемы питания (в т.ч. максимальная без дублей), тёмная/светлая
    тема, точный замер скорости, IP с резервными сервисами, скачивание
    установщиков в "Загрузки" с прогрессом и отменой, установка в 1 клик.
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
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { }

# =====================================================================
# 2. XAML - интерфейс в стиле iOS (светлая/тёмная тема через Tag + обход)
#    Внимание: внутри here-string нельзя использовать символы $ и `
#    Цвета в стилях - значения по умолчанию; Apply-Theme перекрывает их
#    локальными значениями по тегам элементов (кисти WPF замораживает).
# =====================================================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="System Hub &amp; Tweaker" Height="760" Width="1010"
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

        <!-- Неявный стиль: все обычные кнопки - pill -->
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

        <!-- Кнопка успеха (зелёная) -->
        <Style x:Key="SuccessBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#30D158"/>
            <Setter Property="BorderBrush" Value="#30D158"/>
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

        <!-- Сегментированная кнопка: полупрозрачный hover виден в обеих темах -->
        <ControlTemplate x:Key="SegTemplate" TargetType="Button">
            <Border x:Name="Sbd" CornerRadius="15" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter TargetName="Sbd" Property="Background" Value="#4D808080"/>
                </Trigger>
                <Trigger Property="IsPressed" Value="True">
                    <Setter TargetName="Sbd" Property="Background" Value="#66808080"/>
                </Trigger>
            </ControlTemplate.Triggers>
        </ControlTemplate>

        <Style x:Key="SegBtn" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="2,0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template" Value="{StaticResource SegTemplate}"/>
        </Style>

        <!-- Кнопки окна (свернуть / тема / закрыть) -->
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

        <!-- Выпадающий список схем питания -->
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="#2C2C2E"/>
            <Setter Property="Foreground" Value="#F2F2F7"/>
            <Setter Property="BorderBrush" Value="#3A3A3C"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,7"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style x:Key="ComboItemStyle" TargetType="ComboBoxItem">
            <Setter Property="Foreground" Value="#111114"/>
            <Setter Property="Background" Value="#FFFFFF"/>
            <Setter Property="Padding" Value="8,6"/>
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="#DDDDE3"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#C9D9F0"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Полоса прокрутки: средний серый виден в обеих темах -->
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
                                                <Border CornerRadius="4" Background="#7D7D82" Margin="1,1"/>
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
        <Border Grid.Row="0" Tag="titlebg" Background="#111114" BorderBrush="#2C2C2E" BorderThickness="0,0,0,1">
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
                            <TextBlock Tag="txt" Text="System Hub" FontSize="14" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                            <TextBlock Tag="sub" Text="TWEAKER FOR WINDOWS" FontSize="9" Foreground="#8E8E93"/>
                        </StackPanel>
                    </Grid>
                </Border>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button x:Name="BtnTheme" Style="{StaticResource TitleBtn}" Content="&#9789;" Margin="8,0,0,0" Tag="btn"
                            ToolTip="Сменить тему (тёмная / светлая)"/>
                    <Button x:Name="BtnMin" Style="{StaticResource TitleBtn}" Content="-" Margin="8,0,0,0" Tag="btn"/>
                    <Button x:Name="BtnClose" Style="{StaticResource TitleBtn}" Background="#FF453A"
                            Foreground="#FFFFFF" Content="x" Margin="8,0,0,0"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- ================= ЗАГОЛОВОК + СЕГМЕНТЫ ================= -->
        <Border Grid.Row="1" Tag="bg" Background="#0B0B0F">
            <Grid Margin="22,18,22,6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel VerticalAlignment="Center">
                    <TextBlock Name="LblBigTitle" Tag="txt" Text="Мониторинг и сеть" FontSize="26" FontWeight="Bold" Foreground="#FFFFFF"/>
                    <TextBlock Name="LblBigSub" Tag="sub" Text="Состояние ПК, питание, интернет и софт" FontSize="13" Foreground="#8E8E93" Margin="0,4,0,0"/>
                </StackPanel>

                <Border Grid.Column="1" Tag="segbox" Background="#1C1C1E" BorderBrush="#2C2C2E" BorderThickness="1"
                        CornerRadius="17" Padding="3" VerticalAlignment="Center" Height="38" Width="340">
                    <Grid>
                        <Border Name="SegIndicator" Tag="segind" Width="166" CornerRadius="14" Background="#636366"
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
                                    Content="Мониторинг" Foreground="#FFFFFF" FontWeight="SemiBold" Padding="2,4"/>
                            <Button Name="TabBtnApps" Grid.Column="1" Style="{StaticResource SegBtn}"
                                    Content="Каталог ПО" Foreground="#8E8E93" Padding="2,4"/>
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
                <Border Tag="card" Style="{StaticResource Card}">
                    <StackPanel>
                        <Grid Margin="0,0,0,6">
                            <TextBlock Tag="sub" Text="ПИТАНИЕ" Style="{StaticResource SectionHeader}" VerticalAlignment="Center" Margin="0"/>
                            <Button Name="BtnPowerRefresh" Content="&#10227; Обновить" HorizontalAlignment="Right"
                                    Padding="12,5" FontSize="12" Tag="btn"/>
                        </Grid>
                        <TextBlock Name="LblPowerPlan" Text="Текущий план: определение..." FontSize="16" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                        <Grid Margin="0,10,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <ComboBox Name="CmbPowerPlans" Tag="combo" VerticalAlignment="Center" ItemContainerStyle="{StaticResource ComboItemStyle}"/>
                            <Button Name="BtnPowerApply" Grid.Column="1" Style="{StaticResource AccentBtn}" Content="Применить"
                                    Margin="10,0,0,0" VerticalAlignment="Center"/>
                            <Button Name="BtnEnableUltimate" Grid.Column="2" Style="{StaticResource AccentBtn}"
                                    Content="Макс. производительность" Margin="10,0,0,0" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock Tag="sub" Text="Схема создаётся автоматически, если её нет. Переключение применяется сразу в Windows."
                                   FontSize="11" Foreground="#8E8E93" Margin="0,8,0,0" TextWrapping="Wrap"/>
                    </StackPanel>
                </Border>

                <!-- Железо -->
                <Border Tag="card" Style="{StaticResource Card}">
                    <StackPanel>
                        <Grid Margin="0,0,0,6">
                            <TextBlock Tag="sub" Text="ЖЕЛЕЗО" Style="{StaticResource SectionHeader}" VerticalAlignment="Center" Margin="0"/>
                            <Button Name="BtnScanHardware" Content="Обновить" HorizontalAlignment="Right" Padding="14,6" FontSize="12" Tag="btn"/>
                        </Grid>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Margin="0,0,14,0">
                                <TextBlock Name="TxtCpu" Tag="muted" Text="CPU: сканирование..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtGpu" Tag="muted" Text="GPU: сканирование..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtBoard" Tag="muted" Text="Материнская плата: ..." Style="{StaticResource InfoText}"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock Name="TxtRam" Tag="muted" Text="ОЗУ: сканирование..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtVirt" Tag="muted" Text="Виртуализация: ..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtSecureBoot" Tag="muted" Text="Secure Boot: ..." Style="{StaticResource InfoText}"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>

                <!-- Сеть и скорость -->
                <Border Tag="card" Style="{StaticResource Card}">
                    <StackPanel>
                        <TextBlock Tag="sub" Text="СЕТЬ" Style="{StaticResource SectionHeader}"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel>
                                <TextBlock Name="TxtIp" Tag="muted" Text="IP: определение..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtLocation" Tag="muted" Text="Локация: определение..." Style="{StaticResource InfoText}"/>
                                <TextBlock Name="TxtIsp" Tag="muted" Text="Провайдер: определение..." Style="{StaticResource InfoText}"/>
                            </StackPanel>
                            <Button Name="BtnCheckIp" Grid.Column="1" Style="{StaticResource AccentBtn}"
                                    Content="Определить IP" VerticalAlignment="Top"/>
                        </Grid>

                        <Separator Tag="sep"/>

                        <TextBlock Tag="sub" Text="СКОРОСТЬ ИНТЕРНЕТА" Style="{StaticResource SectionHeader}"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel VerticalAlignment="Center" Margin="0,0,16,0">
                                <TextBlock Name="TxtSpeed" Tag="txt" Text="Ожидание замера" FontSize="15" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                                <ProgressBar Name="PbSpeed" Tag="progress" Margin="0,8,0,0" Value="0"/>
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
                <TextBlock Tag="sub" Text="БЫСТРАЯ УСТАНОВКА" Style="{StaticResource SectionHeader}" Margin="0,0,0,10"/>
                <TextBlock Tag="sub" Text="Скачивание установщиков в папку Загрузки с прогрессом и отменой, затем установка в один клик."
                           FontSize="11" Foreground="#8E8E93" Margin="0,-4,0,12" TextWrapping="Wrap"/>
                <UniformGrid Name="AppsGrid" Columns="2"/>
            </StackPanel>
        </ScrollViewer>

        <!-- ================= СТАТУС-БАР ================= -->
        <Border Grid.Row="3" Tag="titlebg" Background="#111114" BorderBrush="#2C2C2E" BorderThickness="0,1,0,0" Padding="22,0">
            <Grid VerticalAlignment="Center">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <Ellipse Width="8" Height="8" Fill="#30D158" VerticalAlignment="Center"/>
                <TextBlock Name="TxtStatusBar" Grid.Column="1" Tag="sub" Text="Система готова к работе"
                           FontSize="12" Foreground="#8E8E93" VerticalAlignment="Center" Margin="10,0,0,0"/>
                <Button Name="BtnRefreshAll" Grid.Column="2" Content="&#10227; Обновить всё" Padding="12,4" FontSize="11"
                        Tag="btn" Margin="12,0,0,0" VerticalAlignment="Center"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# =====================================================================
# 3. ИНИЦИАЛИЗАЦИЯ WPF + СОСТОЯНИЕ
# =====================================================================
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$controls = @(
    "TitleBar", "BtnMin", "BtnClose", "BtnTheme",
    "TabBtnSystem", "TabBtnApps", "SegIndicator",
    "LblBigTitle", "LblBigSub",
    "TabSystem", "TabApps",
    "LblPowerPlan", "CmbPowerPlans", "BtnPowerApply", "BtnPowerRefresh", "BtnEnableUltimate",
    "BtnScanHardware", "TxtCpu", "TxtGpu", "TxtBoard", "TxtRam", "TxtVirt", "TxtSecureBoot",
    "TxtIp", "TxtLocation", "TxtIsp", "BtnCheckIp",
    "TxtSpeed", "PbSpeed", "BtnStartSpeed", "BtnStopSpeed",
    "AppsGrid", "TxtStatusBar", "BtnRefreshAll"
)
foreach ($c in $controls) {
    Set-Variable -Name $c -Value $window.FindName($c)
}

# ---- Состояние ----
$script:SpeedTestCancelled = $false
$script:SpeedTesting = $false
$script:CurrentDownloadKey = $null
$script:ActiveDownloadApp = $null
$script:AppCancel = @{}
$script:AppUi = @{}
$script:ActivePlanGuid = $null
$script:PowerLabelSuccess = $false
$script:ActiveTab = 'System'
$script:IsDark = $true
$script:GuidRe = '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})'
$script:UltimateTemplate = 'e9a42b02-d5df-448d-aa00-03f14749eb61'

# Палитры тем (выставляются обходом дерева по Tag)
$script:ThemeDark = @{
    Bg = '#0B0B0F'; Title = '#111114'; Card = '#1C1C1E'; Edge = '#2C2C2E'; Field = '#2C2C2E'
    Text = '#FFFFFF'; Muted = '#E5E5EA'; Sub = '#8E8E93'; SegBg = '#1C1C1E'; Indicator = '#636366'
    Accent = '#0A84FF'; Success = '#30D158'; Danger = '#FF453A'
}
$script:ThemeLight = @{
    Bg = '#F2F2F7'; Title = '#FFFFFF'; Card = '#FFFFFF'; Edge = '#E1E1E6'; Field = '#E9E9EE'
    Text = '#111114'; Muted = '#3A3A3F'; Sub = '#6E6E73'; SegBg = '#E9E9EE'; Indicator = '#FFFFFF'
    Accent = '#0A84FF'; Success = '#248A3D'; Danger = '#FF3B30'
}
$script:ThemeColors = $script:ThemeDark

# Папка загрузок (учитывает перемещение через OneDrive/редиректы)
$script:DownloadsFolder = $null
try {
    $sh = New-Object -ComObject Shell.Application
    $dl = $sh.NameSpace('shell:Downloads').Self.Path
    if ($dl) { $script:DownloadsFolder = $dl }
} catch { }
if (-not $script:DownloadsFolder -or -not (Test-Path -LiteralPath $script:DownloadsFolder)) {
    $script:DownloadsFolder = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
}

# =====================================================================
# 4. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =====================================================================

function Convert-Brush {
    param([string]$Hex)
    return (New-Object System.Windows.Media.SolidColorBrush -ArgumentList ([System.Windows.Media.ColorConverter]::ConvertFromString($Hex)))
}

# Логические дети элемента (панели, декораторы, контент-контролы)
function Get-UiChildren {
    param($el)
    $result = @()
    if ($el -is [System.Windows.Controls.Panel]) {
        foreach ($ch in $el.Children) { $result += $ch }
    } elseif ($el -is [System.Windows.Controls.Decorator]) {
        if ($el.Child) { $result += $el.Child }
    } elseif ($el -is [System.Windows.Controls.ContentControl]) {
        if ($el.Content -is [System.Windows.UIElement]) { $result += $el.Content }
    } elseif ($el -is [System.Windows.Controls.ItemsControl]) {
        foreach ($it in $el.Items) { if ($it -is [System.Windows.UIElement]) { $result += $it } }
    }
    return $result
}

# Обход дерева: выставляем цвета по тегам (детерминированно, без ресурсов)
function Apply-Theme {
    $c = $script:ThemeColors

    try { $window.Background = Convert-Brush $c.Bg } catch { }
    try { $window.Foreground = Convert-Brush $c.Text } catch { }

    $stack = New-Object System.Collections.Stack
    $stack.Push($window)
    $guard = 0
    while ($stack.Count -gt 0 -and $guard -lt 8000) {
        $guard++
        $el = $stack.Pop()
        $tag = $null
        try { $tag = $el.Tag } catch { }
        if ($tag -is [string] -and $tag.Length -gt 0) {
            try {
                switch ($tag) {
                    'bg'       { $el.Background = Convert-Brush $c.Bg }
                    'titlebg'  { $el.Background = Convert-Brush $c.Title; $el.BorderBrush = Convert-Brush $c.Edge }
                    'card'     { $el.Background = Convert-Brush $c.Card; $el.BorderBrush = Convert-Brush $c.Edge }
                    'txt'      { $el.Foreground = Convert-Brush $c.Text }
                    'sub'      { $el.Foreground = Convert-Brush $c.Sub }
                    'muted'    { $el.Foreground = Convert-Brush $c.Muted }
                    'btn'      { $el.Background = Convert-Brush $c.Field; $el.Foreground = Convert-Brush $c.Text; $el.BorderBrush = Convert-Brush $c.Edge }
                    'segbox'   { $el.Background = Convert-Brush $c.SegBg; $el.BorderBrush = Convert-Brush $c.Edge }
                    'segind'   { $el.Background = Convert-Brush $c.Indicator }
                    'sep'      { $el.Background = Convert-Brush $c.Edge }
                    'progress' { $el.Background = Convert-Brush $c.Edge; $el.Foreground = Convert-Brush $c.Accent }
                    'combo'    { $el.Background = Convert-Brush $c.Field; $el.Foreground = Convert-Brush $c.Text; $el.BorderBrush = Convert-Brush $c.Edge }
                }
            } catch { }
        }
        foreach ($ch in (Get-UiChildren $el)) { $stack.Push($ch) }
    }

    Update-TabButtons
    Update-PowerLabelColor
}

function Update-TabButtons {
    $c = $script:ThemeColors
    if ($script:ActiveTab -eq 'Apps') {
        $TabBtnApps.Foreground = Convert-Brush $c.Text
        $TabBtnApps.FontWeight = 'SemiBold'
        $TabBtnSystem.Foreground = Convert-Brush $c.Sub
        $TabBtnSystem.FontWeight = 'Normal'
    } else {
        $TabBtnSystem.Foreground = Convert-Brush $c.Text
        $TabBtnSystem.FontWeight = 'SemiBold'
        $TabBtnApps.Foreground = Convert-Brush $c.Sub
        $TabBtnApps.FontWeight = 'Normal'
    }
}

function Update-PowerLabelColor {
    $c = $script:ThemeColors
    if ($script:PowerLabelSuccess) {
        $LblPowerPlan.Foreground = Convert-Brush $c.Success
    } else {
        $LblPowerPlan.Foreground = Convert-Brush $c.Text
    }
}

function Set-Theme {
    param([bool]$Dark)
    $script:IsDark = $Dark
    if ($Dark) {
        $script:ThemeColors = $script:ThemeDark
        $BtnTheme.Content = [string][char]0x263E
    } else {
        $script:ThemeColors = $script:ThemeLight
        $BtnTheme.Content = [string][char]0x2600
    }
    Apply-Theme
    try {
        if (-not (Test-Path 'HKCU:\Software\SystemHubTweaker')) { New-Item -Path 'HKCU:\Software\SystemHubTweaker' -Force | Out-Null }
        $val = 'dark'
        if (-not $Dark) { $val = 'light' }
        Set-ItemProperty -Path 'HKCU:\Software\SystemHubTweaker' -Name 'Theme' -Value $val
    } catch { }
}

function Switch-Tab {
    param([ValidateSet('System', 'Apps')][string]$Target)

    $script:ActiveTab = $Target
    $isSystem = ($Target -eq 'System')

    if ($isSystem) {
        $shift = 0
        $TabSystem.Visibility = [System.Windows.Visibility]::Visible
        $TabApps.Visibility = [System.Windows.Visibility]::Collapsed
        $shown = $TabSystem
        $LblBigTitle.Text = "Мониторинг и сеть"
        $LblBigSub.Text = "Состояние ПК, питание, интернет и софт"
    } else {
        $shift = 166
        $TabSystem.Visibility = [System.Windows.Visibility]::Collapsed
        $TabApps.Visibility = [System.Windows.Visibility]::Visible
        $shown = $TabApps
        $LblBigTitle.Text = "Каталог ПО"
        $LblBigSub.Text = "Скачивание и установка программ в один клик"
    }
    Update-TabButtons

    # Лёгкая анимация слайдера сегментов
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

# ---- Схемы питания ----

function Get-PowerPlans {
    $plans = @()
    $out = @()
    try { $out = @(powercfg /list 2>$null) } catch { return $plans }
    foreach ($line in $out) {
        if ($line -match $script:GuidRe) {
            $guid = $Matches[1]
            $name = $null
            if ($line -match '\((.+?)\)\s*\*?\s*$') { $name = $Matches[1].Trim() }
            $active = [bool]($line -match '\)\s*\*\s*$')
            if (-not $name) { $name = $guid }
            $plans += [PSCustomObject]@{ Guid = $guid; Name = $name; Active = $active }
        }
    }
    return $plans
}

function Update-PowerPlanDisplay {
    $plans = @(Get-PowerPlans)
    if ($plans.Count -eq 0) { return }
    $active = $plans | Where-Object { $_.Active } | Select-Object -First 1
    if (-not $active) { $active = $plans[0] }
    $script:ActivePlanGuid = $active.Guid
    $LblPowerPlan.Text = "Текущий план: " + $active.Name
    $script:PowerLabelSuccess = [bool]($active.Name -match '(?i)максимальн|ultimate')
    Update-PowerLabelColor

    $items = @()
    foreach ($p in $plans) {
        $display = $p.Name
        if ($p.Active) { $display = $p.Name + "  (активная)" }
        $items += [PSCustomObject]@{ Guid = $p.Guid; Display = $display }
    }
    $CmbPowerPlans.ItemsSource = $items
    $CmbPowerPlans.DisplayMemberPath = 'Display'
    $idx = 0
    for ($i = 0; $i -lt $plans.Count; $i++) { if ($plans[$i].Active) { $idx = $i; break } }
    $CmbPowerPlans.SelectedIndex = $idx
}

function Sync-PowerPlanQuiet {
    try {
        $plans = @(Get-PowerPlans)
        if ($plans.Count -eq 0) { return }
        $active = $plans | Where-Object { $_.Active } | Select-Object -First 1
        if ($active -and $active.Guid -ne $script:ActivePlanGuid) {
            Update-PowerPlanDisplay
            $TxtStatusBar.Text = "Схема питания изменена извне: " + $active.Name
        }
    } catch { }
}

# ---- Железо ----

function Update-HardwareInfo {
    try {
        $TxtStatusBar.Text = "Сбор данных о комплектующих..."
        $window.Dispatcher.Invoke([Action]{ }, [System.Windows.Threading.DispatcherPriority]::Background)

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

        $gpus = (Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name }) -join " / "
        if (-not $gpus) { $gpus = "не найдена" }
        $TxtGpu.Text = "GPU: " + $gpus

        $bb = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
        if ($bb) {
            $TxtBoard.Text = "Плата: " + $bb.Manufacturer + " " + $bb.Product
        } else {
            $TxtBoard.Text = "Плата: не найдена"
        }

        $ramSticks = @(Get-CimInstance Win32_PhysicalMemory)
        if ($ramSticks.Count -gt 0) {
            $totalRamGb = [math]::Round(($ramSticks | Measure-Object -Property Capacity -Sum).Sum / 1GB, 1)
            $maxSpeed = ($ramSticks | Measure-Object -Property Speed -Maximum).Maximum
            $TxtRam.Text = "ОЗУ: " + $totalRamGb + " GB (" + $maxSpeed + " MHz)"
        } else {
            $TxtRam.Text = "ОЗУ: данные недоступны"
        }

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

# ---- IP с резервными сервисами (работает и в РФ) ----

function Get-PublicIp {
    $TxtStatusBar.Text = "Определение IP-адреса..."
    $ip = $null
    $loc = $null
    $isp = $null

    # 1. ipwho.is - сразу и страна, и город, и провайдер
    try {
        $g = Invoke-RestMethod -Uri 'https://ipwho.is/' -TimeoutSec 5
        if ($g.ip) {
            $ip = $g.ip
            $parts = @()
            if ($g.country) { $parts += [string]$g.country }
            if ($g.city) { $parts += [string]$g.city }
            if ($parts.Count -gt 0) { $loc = $parts -join ', ' }
            if ($g.connection -and $g.connection.isp) { $isp = [string]$g.connection.isp }
        }
    } catch { }

    # 2. ipapi.co
    if (-not $ip) {
        try {
            $g = Invoke-RestMethod -Uri 'https://ipapi.co/json/' -TimeoutSec 5
            if ($g.ip) {
                $ip = $g.ip
                $parts = @()
                if ($g.country_name) { $parts += [string]$g.country_name }
                if ($g.city) { $parts += [string]$g.city }
                if ($parts.Count -gt 0) { $loc = $parts -join ', ' }
                if ($g.org) { $isp = [string]$g.org }
            }
        } catch { }
    }

    # 3. Только IP (если геолокация недоступна)
    if (-not $ip) {
        try {
            $g = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json' -TimeoutSec 4
            if ($g.ip) { $ip = $g.ip }
        } catch { }
    }

    # 4. Просто текстовый IP
    if (-not $ip) {
        try {
            $t = ([string](Invoke-RestMethod -Uri 'https://icanhazip.com' -TimeoutSec 4)).Trim()
            if ($t -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ip = $t }
        } catch { }
    }

    # 5. DNS через OpenDNS - работает даже когда HTTP-сервисы недоступны
    if (-not $ip) {
        try {
            $d = Resolve-DnsName -Name 'myip.opendns.com' -Type TXT -Server 'resolver1.opendns.com' -QuickTimeout -ErrorAction Stop
            foreach ($rec in @($d)) {
                if ($rec.Strings) {
                    foreach ($s in @($rec.Strings)) {
                        if ([string]$s -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') { $ip = $Matches[0]; break }
                    }
                }
                if ($ip) { break }
            }
        } catch { }
    }

    # Страховка: в поле IP должен попадать только настоящий адрес
    if ($ip -and ($ip -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')) { $ip = $null }

    # Локальный IP машины в сети
    $local = $null
    try {
        $local = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.AddressState -eq 'Preferred' -and $_.IPAddress -ne '127.0.0.1' -and $_.IPAddress -notlike '169.254*' } |
            Select-Object -ExpandProperty IPAddress -First 1
    } catch { }

    if ($ip) {
        $line = "IP: " + $ip
        if ($local) { $line = $line + "   (локальный: " + $local + ")" }
        $TxtIp.Text = $line
        if ($loc) { $TxtLocation.Text = "Локация: " + $loc } else { $TxtLocation.Text = "Локация: недоступна" }
        if ($isp) { $TxtIsp.Text = "Провайдер: " + $isp } else { $TxtIsp.Text = "Провайдер: недоступен" }
        $TxtStatusBar.Text = "Сетевая информация обновлена"
    } else {
        $TxtIp.Text = "IP: не удалось определить"
        $TxtLocation.Text = "Локация: -"
        $TxtIsp.Text = "Провайдер: -"
        $TxtStatusBar.Text = "Не удалось определить IP (проверьте интернет или VPN)"
    }
}

# ---- Передача: прогресс, отмена, точный тайминг ----

function Invoke-FileTransfer {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$UserAgent,
        [scriptblock]$OnProgress,
        [scriptblock]$OnCancel
    )
    $result = @{ Bytes = [int64]0; Total = [int64]-1; Seconds = 0.0; Cancelled = $false; Error = $null }
    $resp = $null
    $fs = $null
    $src = $null
    try {
        $req = [System.Net.WebRequest]::Create($Url)
        $req.Method = 'GET'
        $req.Timeout = 30000
        $req.ReadWriteTimeout = 60000
        $req.AllowAutoRedirect = $true
        if ($UserAgent) { $req.UserAgent = $UserAgent }
        $resp = $req.GetResponse()
        $result.Total = [int64]$resp.ContentLength
        $src = $resp.GetResponseStream()
        if ($OutFile) { $fs = [System.IO.File]::Create($OutFile) }
        $buffer = New-Object byte[] 65536
        $sw = $null
        $done = [int64]0
        $lastUi = 0
        while ($true) {
            if ($OnCancel -and $OnCancel.Invoke()) { $result.Cancelled = $true; break }
            $n = $src.Read($buffer, 0, $buffer.Length)
            if ($n -le 0) { break }
            # Таймер стартует с первого полученного байта - handshake не занижает результат
            if ($null -eq $sw) { $sw = [System.Diagnostics.Stopwatch]::StartNew() }
            if ($fs) { $fs.Write($buffer, 0, $n) }
            $done += $n
            $now = [Environment]::TickCount
            if ($OnProgress -and (($now - $lastUi) -ge 120)) {
                $lastUi = $now
                $sec = 0.0
                if ($sw) { $sec = $sw.Elapsed.TotalSeconds }
                $OnProgress.Invoke($done, $result.Total, $sec)
            }
        }
        if ($sw) { $sw.Stop(); $result.Seconds = $sw.Elapsed.TotalSeconds }
        $result.Bytes = $done
        # Финальный колбэк: иначе полоса может остаться неполной после последнего куска
        if ($OnProgress -and (-not $result.Cancelled)) {
            $secFinal = 0.0
            if ($sw) { $secFinal = $sw.Elapsed.TotalSeconds }
            $OnProgress.Invoke($done, $result.Total, $secFinal)
        }
    } catch {
        $result.Error = $_.Exception.Message
    } finally {
        if ($fs) { try { $fs.Flush(); $fs.Dispose() } catch { } }
        if ($src) { try { $src.Close() } catch { } }
        if ($resp) { try { $resp.Close() } catch { } }
    }
    return $result
}

function Format-Mb {
    param([double]$Bytes)
    return ('{0:N1} MB' -f ($Bytes / 1MB))
}

# ---- Каталог ПО ----

$script:Apps = @(
    [PSCustomObject]@{ Key = 'vscode'; Name = 'Visual Studio Code'; Desc = 'Редактор кода'; Icon = 'V'; IconBg = '#0078D4'; IconFg = '#FFFFFF'
        Kind = 'url'; Url = 'https://update.code.visualstudio.com/latest/win32-x64-user/stable'; File = 'VSCodeUserSetup.exe'; Repo = $null; Asset = $null },
    [PSCustomObject]@{ Key = 'steam'; Name = 'Steam'; Desc = 'Игровая площадка'; Icon = 'S'; IconBg = '#66C0F4'; IconFg = '#0B0B0F'
        Kind = 'url'; Url = 'https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe'; File = 'SteamSetup.exe'; Repo = $null; Asset = $null },
    [PSCustomObject]@{ Key = 'discord'; Name = 'Discord'; Desc = 'Голосовой чат'; Icon = 'D'; IconBg = '#5865F2'; IconFg = '#FFFFFF'
        Kind = 'url'; Url = 'https://discord.com/api/download?platform=win&installer=exe'; File = 'DiscordSetup.exe'; Repo = $null; Asset = $null },
    [PSCustomObject]@{ Key = 'telegram'; Name = 'Telegram'; Desc = 'Мессенджер'; Icon = 'T'; IconBg = '#2AABEE'; IconFg = '#FFFFFF'
        Kind = 'url'; Url = 'https://telegram.org/dl/desktop/win64'; File = 'TelegramSetup.exe'; Repo = $null; Asset = $null },
    [PSCustomObject]@{ Key = 'riot'; Name = 'Riot Games'; Desc = 'VALORANT, LoL'; Icon = 'R'; IconBg = '#FF4655'; IconFg = '#FFFFFF'
        Kind = 'url'; Url = 'https://lol.secure.dyn.riotcdn.net/channels/public/x/installer/current/live.na.exe'; File = 'RiotClientSetup.exe'; Repo = $null; Asset = $null },
    [PSCustomObject]@{ Key = 'qbit'; Name = 'qBittorrent'; Desc = 'Торрент-клиент'; Icon = 'Q'; IconBg = '#34C759'; IconFg = '#FFFFFF'
        Kind = 'github'; Url = $null; File = $null; Repo = 'qbittorrent/qBittorrent'; Asset = '*x64_setup.exe' }
)

function New-AppCard {
    param($App, [int]$Index)

    $card = New-Object System.Windows.Controls.Border
    $card.Tag = 'card'
    $card.CornerRadius = 20
    $card.BorderThickness = 1
    $card.Padding = New-Object System.Windows.Thickness -ArgumentList 16,14,16,14
    if ($Index % 2 -eq 0) { $card.Margin = New-Object System.Windows.Thickness -ArgumentList 0,0,13,14 }
    else { $card.Margin = New-Object System.Windows.Thickness -ArgumentList 0,0,0,14 }

    $grid = New-Object System.Windows.Controls.Grid
    $col0 = New-Object System.Windows.Controls.ColumnDefinition
    $col0.Width = [System.Windows.GridLength]::Auto
    $col1 = New-Object System.Windows.Controls.ColumnDefinition
    $col1.Width = [System.Windows.GridLength]::Auto
    $col2 = New-Object System.Windows.Controls.ColumnDefinition
    $col2.Width = New-Object System.Windows.GridLength -ArgumentList 1, ([System.Windows.GridUnitType]::Star)
    $col3 = New-Object System.Windows.Controls.ColumnDefinition
    $col3.Width = [System.Windows.GridLength]::Auto
    [void]$grid.ColumnDefinitions.Add($col0)
    [void]$grid.ColumnDefinitions.Add($col1)
    [void]$grid.ColumnDefinitions.Add($col2)
    [void]$grid.ColumnDefinitions.Add($col3)

    # Иконка (брендовый цвет - одинаков в обеих темах)
    $icon = New-Object System.Windows.Controls.Border
    $icon.Width = 42
    $icon.Height = 42
    $icon.CornerRadius = 12
    $icon.VerticalAlignment = 'Center'
    $icon.Background = New-Object System.Windows.Media.SolidColorBrush -ArgumentList ([System.Windows.Media.ColorConverter]::ConvertFromString($App.IconBg))
    $letter = New-Object System.Windows.Controls.TextBlock
    $letter.Text = $App.Icon
    $letter.FontSize = 18
    $letter.FontWeight = 'Bold'
    $letter.HorizontalAlignment = 'Center'
    $letter.VerticalAlignment = 'Center'
    $letter.Foreground = New-Object System.Windows.Media.SolidColorBrush -ArgumentList ([System.Windows.Media.ColorConverter]::ConvertFromString($App.IconFg))
    $icon.Child = $letter
    [System.Windows.Controls.Grid]::SetColumn($icon, 0)
    [void]$grid.Children.Add($icon)

    # Тексты + блок прогресса
    $stack = New-Object System.Windows.Controls.StackPanel
    $stack.Margin = New-Object System.Windows.Thickness -ArgumentList 13,0,10,0
    $stack.VerticalAlignment = 'Center'

    $t1 = New-Object System.Windows.Controls.TextBlock
    $t1.Tag = 'txt'
    $t1.Text = $App.Name
    $t1.FontWeight = 'SemiBold'
    $t1.Foreground = Convert-Brush $script:ThemeColors.Text

    $t2 = New-Object System.Windows.Controls.TextBlock
    $t2.Tag = 'sub'
    $t2.Text = $App.Desc
    $t2.FontSize = 12
    $t2.Margin = New-Object System.Windows.Thickness -ArgumentList 0,2,0,0
    $t2.Foreground = Convert-Brush $script:ThemeColors.Sub

    [void]$stack.Children.Add($t1)
    [void]$stack.Children.Add($t2)

    $prog = New-Object System.Windows.Controls.StackPanel
    $prog.Margin = New-Object System.Windows.Thickness -ArgumentList 0,10,0,0
    $prog.Visibility = 'Collapsed'

    $txtPct = New-Object System.Windows.Controls.TextBlock
    $txtPct.Tag = 'muted'
    $txtPct.FontSize = 12
    $txtPct.FontWeight = 'SemiBold'
    $txtPct.Text = '0%'
    $txtPct.Foreground = Convert-Brush $script:ThemeColors.Muted

    $bar = New-Object System.Windows.Controls.ProgressBar
    $bar.Tag = 'progress'
    $bar.Height = 8
    $bar.Margin = New-Object System.Windows.Thickness -ArgumentList 0,5,0,0
    $bar.Value = 0
    $bar.Background = Convert-Brush $script:ThemeColors.Edge
    $bar.Foreground = Convert-Brush $script:ThemeColors.Accent

    $txtSize = New-Object System.Windows.Controls.TextBlock
    $txtSize.Tag = 'sub'
    $txtSize.FontSize = 11
    $txtSize.Margin = New-Object System.Windows.Thickness -ArgumentList 0,5,0,0
    $txtSize.Foreground = Convert-Brush $script:ThemeColors.Sub

    $btnCancel = New-Object System.Windows.Controls.Button
    $btnCancel.Content = 'Отмена'
    $btnCancel.Style = $window.Resources['DangerBtn']
    $btnCancel.Padding = '10,3'
    $btnCancel.FontSize = 11
    $btnCancel.Margin = New-Object System.Windows.Thickness -ArgumentList 0,7,0,0
    $btnCancel.HorizontalAlignment = 'Left'

    [void]$prog.Children.Add($txtPct)
    [void]$prog.Children.Add($bar)
    [void]$prog.Children.Add($txtSize)
    [void]$prog.Children.Add($btnCancel)
    [void]$stack.Children.Add($prog)
    [System.Windows.Controls.Grid]::SetColumn($stack, 2)
    [void]$grid.Children.Add($stack)

    # Кнопка действия: Скачать -> (прогресс) -> Установить
    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = 'Скачать'
    $btn.Padding = '14,8'
    $btn.FontSize = 12
    $btn.VerticalAlignment = 'Center'
    $btn.Style = $window.Resources['AccentBtn']
    [System.Windows.Controls.Grid]::SetColumn($btn, 3)
    [void]$grid.Children.Add($btn)

    $card.Child = $grid

    $script:AppUi[$App.Key] = @{
        Btn = $btn; Pct = $txtPct; Bar = $bar; Size = $txtSize; Cancel = $btnCancel
        State = 'idle'; File = $null
    }

    $btn.Add_Click({
        $u = $script:AppUi[$App.Key]
        if ($u.State -eq 'ready') {
            Start-AppInstall -App $App
        } elseif ($u.State -eq 'idle') {
            Start-AppDownload -App $App
        }
    }.GetNewClosure())

    $btnCancel.Add_Click({
        $script:AppCancel[$App.Key] = $true
        $script:AppUi[$App.Key].Cancel.IsEnabled = $false
    }.GetNewClosure())

    return $card
}

function Set-AppState {
    param([string]$Key, [string]$State)
    $u = $script:AppUi[$Key]
    if (-not $u) { return }
    $u.State = $State
    if ($State -eq 'busy') {
        $u.Btn.Visibility = 'Collapsed'
        $u.Pct.Visibility = 'Visible'
        $u.Bar.Visibility = 'Visible'
        $u.Size.Visibility = 'Visible'
        $u.Cancel.Visibility = 'Visible'
        $u.Cancel.IsEnabled = $true
        $u.Pct.Text = '0%'
        $u.Bar.Value = 0
        $u.Size.Text = ''
    } elseif ($State -eq 'ready') {
        $u.Btn.Visibility = 'Visible'
        $u.Btn.Content = 'Установить'
        $u.Btn.Style = $window.Resources['SuccessBtn']
        $u.Pct.Visibility = 'Collapsed'
        $u.Bar.Visibility = 'Collapsed'
        $u.Size.Visibility = 'Collapsed'
        $u.Cancel.Visibility = 'Collapsed'
    } else {
        $u.Btn.Visibility = 'Visible'
        $u.Btn.Content = 'Скачать'
        $u.Btn.Style = $window.Resources['AccentBtn']
        $u.Pct.Visibility = 'Collapsed'
        $u.Bar.Visibility = 'Collapsed'
        $u.Size.Visibility = 'Collapsed'
        $u.Cancel.Visibility = 'Collapsed'
        $u.Cancel.IsEnabled = $true
    }
}

function Resolve-AppUrl {
    param($App)
    if ($App.Kind -eq 'github') {
        $rel = Invoke-RestMethod -Uri ('https://api.github.com/repos/' + $App.Repo + '/releases/latest') -TimeoutSec 10 -Headers @{ 'User-Agent' = 'SystemHubTweaker' }
        $asset = $rel.assets | Where-Object { $_.name -like $App.Asset } | Select-Object -First 1
        if (-not $asset) { return $null }
        $script:AppUi[$App.Key].File = Join-Path $script:DownloadsFolder $asset.name
        return $asset.browser_download_url
    }
    return $App.Url
}

function Start-AppDownload {
    param($App)
    if ($script:CurrentDownloadKey) { $TxtStatusBar.Text = "Дождитесь окончания текущей загрузки"; return }
    if ($script:SpeedTesting) { $TxtStatusBar.Text = "Сначала остановите замер скорости"; return }

    $u = $script:AppUi[$App.Key]
    $script:CurrentDownloadKey = $App.Key
    $script:ActiveDownloadApp = $App
    $script:AppCancel[$App.Key] = $false
    foreach ($entry in $script:AppUi.Values) { $entry.Btn.IsEnabled = $false }
    Set-AppState -Key $App.Key -State 'busy'
    $TxtStatusBar.Text = "Подготовка загрузки: " + $App.Name

    $cancelled = $false
    $ok = $false
    $path = $null
    try {
        $url = Resolve-AppUrl -App $App
        if (-not $url) {
            $TxtStatusBar.Text = "Не удалось получить ссылку: " + $App.Name
        } else {
            if ($App.Kind -eq 'github') { $path = $u.File } else { $path = Join-Path $script:DownloadsFolder $App.File }
            if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }

            $progress = {
                param($bytes, $total, $sec)
                $entry = $script:AppUi[$script:ActiveDownloadApp.Key]
                $nm = $script:ActiveDownloadApp.Name
                $mb = [math]::Round($bytes / 1MB, 1)
                $speed = 0.0
                if ($sec -gt 0.1) { $speed = [math]::Round(($bytes / 1MB) / $sec, 1) }
                if ($total -gt 0) {
                    $pct = [math]::Min(100, [math]::Floor($bytes * 100 / $total))
                    $all = [math]::Round($total / 1MB, 1)
                    $left = [math]::Round(($total - $bytes) / 1MB, 1)
                    $entry.Pct.Text = "{0}%  {1} MB/s" -f $pct, $speed
                    $entry.Size.Text = "{0} из {1} MB  (осталось {2} MB)" -f $mb, $all, $left
                    $entry.Bar.Value = [math]::Min(100, ($bytes * 100.0 / $total))
                } else {
                    $entry.Pct.Text = "{0} MB/s" -f $speed
                    $entry.Size.Text = "{0} MB" -f $mb
                }
                $TxtStatusBar.Text = "Загрузка " + $nm + ": " + $entry.Pct.Text
                [System.Windows.Forms.Application]::DoEvents()
            }
            $cancel = { $script:AppCancel[$script:ActiveDownloadApp.Key] }

            $res = Invoke-FileTransfer -Url $url -OutFile $path -UserAgent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' -OnProgress $progress -OnCancel $cancel

            if ($res.Cancelled) {
                $cancelled = $true
            } elseif ($res.Error) {
                $TxtStatusBar.Text = "Ошибка загрузки " + $App.Name + ": " + $res.Error
            } elseif ($res.Bytes -le 0) {
                $TxtStatusBar.Text = "Ошибка загрузки " + $App.Name + ": пустой ответ сервера"
            } else {
                $u.File = $path
                $ok = $true
            }
        }
    } catch {
        $TxtStatusBar.Text = "Ошибка загрузки " + $App.Name
    } finally {
        $script:CurrentDownloadKey = $null
        $script:ActiveDownloadApp = $null
        foreach ($entry in $script:AppUi.Values) { $entry.Btn.IsEnabled = $true }
    }

    if ($cancelled) {
        if ($path -and (Test-Path -LiteralPath $path)) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
        Set-AppState -Key $App.Key -State 'idle'
        $TxtStatusBar.Text = "Загрузка " + $App.Name + " отменена"
    } elseif ($ok) {
        Set-AppState -Key $App.Key -State 'ready'
        $TxtStatusBar.Text = "Скачано: " + $App.Name + " (папка Загрузки). Нажмите Установить"
    } else {
        if ($path -and (Test-Path -LiteralPath $path)) { Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue }
        Set-AppState -Key $App.Key -State 'idle'
    }
}

function Start-AppInstall {
    param($App)
    $u = $script:AppUi[$App.Key]
    $path = $u.File
    if (-not $path -or -not (Test-Path -LiteralPath $path)) {
        $found = $null
        if ($App.Kind -eq 'github' -and $App.Asset) {
            $hit = Get-ChildItem -Path $script:DownloadsFolder -File -Filter $App.Asset -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($hit) { $found = $hit.FullName }
        } elseif ($App.File) {
            $cand = Join-Path $script:DownloadsFolder $App.File
            if (Test-Path -LiteralPath $cand) { $found = $cand }
        }
        if (-not $found) {
            $TxtStatusBar.Text = "Файл не найден - скачайте " + $App.Name + " заново"
            Set-AppState -Key $App.Key -State 'idle'
            return
        }
        $u.File = $found
        $path = $found
    }
    try {
        if ($path -like '*.msi') {
            Start-Process -FilePath 'msiexec.exe' -ArgumentList ('/i "' + $path + '"')
        } else {
            Start-Process -FilePath $path
        }
        $TxtStatusBar.Text = "Запущен установщик: " + $App.Name
    } catch {
        $TxtStatusBar.Text = "Не удалось запустить установщик " + $App.Name
    }
}

# =====================================================================
# 5. СБОРКА КАРТОЧЕК + НАЧАЛЬНАЯ ИНИЦИАЛИЗАЦИЯ
# =====================================================================

for ($i = 0; $i -lt $script:Apps.Count; $i++) {
    [void]$AppsGrid.Children.Add((New-AppCard -App $script:Apps[$i] -Index $i))
}

# Уже скачанные установщики - сразу кнопка "Установить"
foreach ($app in $script:Apps) {
    $u = $script:AppUi[$app.Key]
    $found = $null
    if ($app.Kind -eq 'github' -and $app.Asset) {
        $hit = Get-ChildItem -Path $script:DownloadsFolder -File -Filter $app.Asset -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($hit) { $found = $hit.FullName }
    } elseif ($app.File) {
        $cand = Join-Path $script:DownloadsFolder $app.File
        if (Test-Path -LiteralPath $cand) { $found = $cand }
    }
    if ($found) {
        $u.File = $found
        Set-AppState -Key $app.Key -State 'ready'
    }
}

# Тема: читаем сохранённый выбор, по умолчанию тёмная
$themeChoice = $null
try { $themeChoice = (Get-ItemProperty -Path 'HKCU:\Software\SystemHubTweaker' -Name Theme -ErrorAction SilentlyContinue).Theme } catch { }
if ($themeChoice -eq 'light') { Set-Theme -Dark $false } else { Set-Theme -Dark $true }

Update-PowerPlanDisplay

# =====================================================================
# 6. ОБРАБОТЧИКИ СОБЫТИЙ
# =====================================================================

# Кнопки окна
$BtnMin.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
$BtnClose.Add_Click({ $window.Close() })
$BtnTheme.Add_Click({ Set-Theme -Dark (-not $script:IsDark) })

# Перетаскивание окна за шапку
$TitleBar.Add_MouseLeftButtonDown({
    param($sender, $e)
    try { $window.DragMove() } catch { }
})

# Переключение вкладок
$TabBtnSystem.Add_Click({ Switch-Tab -Target 'System' })
$TabBtnApps.Add_Click({ Switch-Tab -Target 'Apps' })

# ---- Питание ----

$BtnEnableUltimate.Add_Click({
    $TxtStatusBar.Text = "Проверка схем питания..."
    $plans = @(Get-PowerPlans)
    $matchesMax = @($plans | Where-Object { $_.Name -match '(?i)максимальн|ultimate' })
    $activeMax = @($matchesMax | Where-Object { $_.Active }) | Select-Object -First 1

    if ($activeMax) {
        Update-PowerPlanDisplay
        $TxtStatusBar.Text = "Максимальная производительность уже активна - ничего не менялось"
        return
    }

    $max = $null
    if ($matchesMax.Count -gt 0) {
        $max = $matchesMax[0]
    } else {
        # Схемы нет - создаём скрытый шаблон Ultimate Performance
        $out = @()
        try { $out = @(powercfg /duplicatescheme $script:UltimateTemplate 2>&1) } catch { }
        $g = $null
        foreach ($line in $out) {
            if ($line -match $script:GuidRe) { $g = $Matches[1] }
        }
        if (-not $g) {
            $TxtStatusBar.Text = "Не удалось создать схему максимальной производительности"
            return
        }
        $max = [PSCustomObject]@{ Guid = $g; Name = "Максимальная производительность"; Active = $false }
        $TxtStatusBar.Text = "Схема максимальной производительности создана..."
    }

    try { powercfg /setactive $max.Guid 2>&1 | Out-Null } catch { }
    Update-PowerPlanDisplay
    if ($script:ActivePlanGuid -eq $max.Guid) {
        $TxtStatusBar.Text = "Активирована схема: " + $max.Name
    } else {
        $TxtStatusBar.Text = "Не удалось активировать схему питания"
    }
})

$BtnPowerApply.Add_Click({
    $sel = $CmbPowerPlans.SelectedItem
    if (-not $sel) { $TxtStatusBar.Text = "Выберите схему питания из списка"; return }
    $TxtStatusBar.Text = "Переключение схемы питания..."
    try { powercfg /setactive $sel.Guid 2>&1 | Out-Null } catch { }
    Update-PowerPlanDisplay
    if ($script:ActivePlanGuid -eq $sel.Guid) {
        $TxtStatusBar.Text = "Схема питания переключена и применена в Windows"
    } else {
        $TxtStatusBar.Text = "Не удалось переключить схему питания"
    }
})

$BtnPowerRefresh.Add_Click({
    Update-PowerPlanDisplay
    $TxtStatusBar.Text = "Список схем питания обновлён"
})

# ---- Железо ----
$BtnScanHardware.Add_Click({ Update-HardwareInfo })

# ---- Сеть ----
$BtnCheckIp.Add_Click({ Get-PublicIp })

$BtnRefreshAll.Add_Click({
    Update-PowerPlanDisplay
    Update-HardwareInfo
    Get-PublicIp
    $TxtStatusBar.Text = "Все данные обновлены"
})

# ---- Замер скорости ----
$BtnStartSpeed.Add_Click({
    if ($script:CurrentDownloadKey) { $TxtStatusBar.Text = "Сначала дождитесь загрузки файлов"; return }
    if ($script:SpeedTesting) { return }
    $script:SpeedTestCancelled = $false
    $script:SpeedTesting = $true
    $BtnStartSpeed.IsEnabled = $false
    $BtnStopSpeed.IsEnabled = $true
    $PbSpeed.Value = 0
    $TxtSpeed.Text = "Разогрев соединения..."
    $TxtStatusBar.Text = "Идёт замер скорости..."
    try {
        # Разогрев: DNS/handshake не входят в замер
        $warm = Invoke-FileTransfer -Url 'https://speed.cloudflare.com/__down?bytes=5000000' `
            -OnProgress { param($b, $t, $s) [System.Windows.Forms.Application]::DoEvents() } `
            -OnCancel { $script:SpeedTestCancelled }

        if ($warm.Cancelled) {
            $TxtSpeed.Text = "Замер отменён"
            $TxtStatusBar.Text = "Тест скорости остановлен"
        } else {
            # Два источника: разные узлы отдают разную скорость, берём лучший результат
            $sources = @(
                [PSCustomObject]@{ Label = 'OVH'; Url = 'https://proof.ovh.net/files/100Mb.dat' },
                [PSCustomObject]@{ Label = 'Cloudflare'; Url = 'https://speed.cloudflare.com/__down?bytes=50000000' }
            )
            $best = 0.0
            $good = 0
            foreach ($src in $sources) {
                if ($script:SpeedTestCancelled) { break }
                $script:SpeedSrcLabel = "Замер (" + $src.Label + ")"
                $TxtSpeed.Text = $script:SpeedSrcLabel + ": подключение..."
                $PbSpeed.Value = 0
                $progress = {
                    param($bytes, $total, $sec)
                    $live = 0.0
                    if ($sec -gt 0.2) { $live = [math]::Round(($bytes * 8 / 1000000) / $sec, 1) }
                    if ($total -gt 0) { $PbSpeed.Value = [math]::Min(100, ($bytes * 100.0 / $total)) }
                    $TxtSpeed.Text = $script:SpeedSrcLabel + ": " + $live + " Мбит/с"
                    [System.Windows.Forms.Application]::DoEvents()
                }
                $res = Invoke-FileTransfer -Url $src.Url -OnProgress $progress -OnCancel { $script:SpeedTestCancelled }
                if ((-not $res.Cancelled) -and (-not $res.Error) -and ($res.Bytes -gt 0)) {
                    $secs = $res.Seconds
                    if ($secs -le 0) { $secs = 0.001 }
                    $mbps = [math]::Round(($res.Bytes * 8 / 1000000) / $secs, 1)
                    $good = $good + 1
                    if ($mbps -gt $best) { $best = $mbps }
                }
            }

            if ($script:SpeedTestCancelled) {
                $TxtSpeed.Text = "Замер отменён"
                $TxtStatusBar.Text = "Тест скорости остановлен"
            } elseif ($best -le 0) {
                $PbSpeed.Value = 0
                $TxtSpeed.Text = "Ошибка замера"
                $TxtStatusBar.Text = "Сбой при тесте скорости (источники недоступны)"
            } else {
                $PbSpeed.Value = 100
                $TxtSpeed.Text = "Скорость загрузки: " + $best + " Мбит/с"
                $TxtStatusBar.Text = "Тест завершён, источников: " + $good + " (лучший результат)"
            }
        }
    } catch {
        $PbSpeed.Value = 0
        $TxtSpeed.Text = "Ошибка замера"
        $TxtStatusBar.Text = "Сбой при тесте скорости"
    } finally {
        $script:SpeedTesting = $false
        $BtnStartSpeed.IsEnabled = $true
        $BtnStopSpeed.IsEnabled = $false
    }
})

$BtnStopSpeed.Add_Click({ $script:SpeedTestCancelled = $true })

# =====================================================================
# 7. ТАЙМЕРЫ + ЗАПУСК
# =====================================================================

# Периодическая сверка активной схемы (например, сменили в Windows)
$powerTimer = New-Object System.Windows.Threading.DispatcherTimer
$powerTimer.Interval = [TimeSpan]::FromSeconds(15)
$powerTimer.Add_Tick({ Sync-PowerPlanQuiet })
$powerTimer.Start()

# Автоопределение IP через 1.5 секунды после старта
$ipTimer = New-Object System.Windows.Threading.DispatcherTimer
$ipTimer.Interval = [TimeSpan]::FromMilliseconds(1500)
$ipTimer.Add_Tick({ $ipTimer.Stop(); Get-PublicIp })
$ipTimer.Start()

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
