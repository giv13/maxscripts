if not apsComplete == undefined and not apsComplete then throw("Скрипт уже запущен!")

-- Путь для сохранения рендеров, активность скрипта, завершенность скрипта
global apsActive = true
global apsComplete = false

-- Окно с логами
rollout logs "Процесс работы скрипта" (
    group "" (
        dotNetControl textBox "System.Windows.Forms.RichTextBox" width: 500 height: 200
        button stopButton "Остановить скрипт" align: #left
    )
    on stopButton pressed do (
        apsActive = false
        stopButton.enabled = false
        addMessage "Скрипт завершит работу после окончания рендера"
    )
    on logs oktoclose do (
        if not apsComplete then messageBox "Закрытие окна запрещено, пока скрипт не завершит работу" title: "Ошибка"
        return apsComplete
    )
)

-- Получаем камеры
fn getCameras = (
    local cams = for obj in objects where superClassOf obj == Camera collect obj
    if cams.count == 0 then (
        messageBox "В сцене нет камер!" title: "Ошибка"
		return undefined
    )
    qsort cams (fn compare cam1 cam2 = if cam1.name < cam2.name then -1 else 1)
    return cams
)

-- Создаем окно с выбором опций
fn createOptionsDialog cams = (
    rollout optionsRollout "autoPanoramaSwitcher" (
        group "Настройка опций" (
            multilistbox cameraList "Выбери камеры:" items: (for cam in cams collect cam.name)
            label pathLabel "Укажи папку для сохранения:" align: #left
            edittext pathFolder width: 240 height: 20 across: 2 labelOnTop: true readonly: true
            button pathButton "..." align: #right
            button runButton "Запустить скрипт" across: 2 align: #left
            button hintButton "Правила именования" images: #(((getDir #ui_ln) + "IconsDark\bip_mflgraph_i.bmp"), undefined, 40, 9, 9, 10, 10, false, true) border: false align: #right
        )
		local selectedCams = #()
        on pathButton pressed do (
            local folderDialog = dotNetObject "System.Windows.Forms.FolderBrowserDialog"
            folderDialog.Description = "Укажи папку для сохранения:"
            local dialogResult = folderDialog.showDialog()
            if (dialogResult.ToString() == "OK") then (
                pathFolder.text = folderDialog.selectedPath
            )
        )
        on runButton pressed do (
            local sel = cameraList.selection as Array
            if sel.count == 0 then (
                messageBox "Не выбраны камеры!" title: "Ошибка"
                return false
            )
            if pathFolder.text == "" then (
                messageBox "Не выбрана папка для сохранения!" title: "Ошибка"
                return false
            )
            if not doesFileExist pathFolder.text then (
                messageBox "Указанной папки не существует!" title: "Ошибка"
                return false
            )
            local cams = optionsRollout.cams
            for s in sel do append selectedCams cams[s]
            destroyDialog optionsRollout
        )
        on hintButton pressed do (
            for control in optionsRollout.controls do control.enabled = false
            showRules optionsRollout
        )
    )
    createDialog optionsRollout width: 300 height: 264 modal: true
	return #(optionsRollout.selectedCams, optionsRollout.pathFolder.text)
)

-- Показываем правила именования
fn showRules optionsRollout = (
    rollout rulesRollout "Правила именования" (
        group "Камеры" (
            dotNetControl camTextBox "System.Windows.Forms.RichTextBox" width: 580 height: 166
        )
        group "Карты" (
            dotNetControl mapTextBox "System.Windows.Forms.RichTextBox" width: 580 height: 140
        )
        group "Солнца" (
            dotNetControl sunTextBox "System.Windows.Forms.RichTextBox" width: 580 height: 179
        )
        on rulesRollout open do (
            local textBox
            for textBox in #("camTextBox", "mapTextBox", "sunTextBox") do (
                textBox = getProperty rulesRollout textBox
                textBox.BackColor = (dotNetClass "System.Drawing.Color").FromArgb(-12303292)
                textBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
                textBox.ReadOnly = true
            )
            textBox = rulesRollout.camTextBox
            addMessage "Название камеры должно формироваться следующим образом: " textBox: textBox newline: false
            addMessage "*_p(число)_h(число)_s(число)_(D|N)" textBox: textBox style: "Bold" newline: false
            addMessage ", где:" textBox: textBox
            addMessage "*" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольная часть названия, необязательный параметр" textBox: textBox
            addMessage "p(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - номер панорамы, обязательный параметр" textBox: textBox
            addMessage "h(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - высота съемки, обязательный параметр" textBox: textBox
            addMessage "s(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - номер солнца, обязательный параметр" textBox: textBox
            addMessage "(D|N)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - время суток, необязательный параметр, по умолчанию: D" textBox: textBox
            addMessage "\nПримеры правильных названий:" textBox: textBox
            addMessage "p01_h025_s001" textBox: textBox bullet: true
            addMessage "Cam_p02_h050_s002" textBox: textBox bullet: true
            addMessage "Camera_p03_h100_s003_D" textBox: textBox bullet: true
            addMessage "Камера_p04_h200_s004_N" textBox: textBox bullet: true newline: false
            textBox = rulesRollout.mapTextBox
            addMessage "Название карты должно формироваться следующим образом: " textBox: textBox newline: false
            addMessage "*_p(число)_h(число)_(D|N)" textBox: textBox style: "Bold" newline: false
            addMessage ", где:" textBox: textBox
            addMessage "*" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольная часть названий, необязательный параметр" textBox: textBox
            addMessage "p(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - номер панорамы, обязательный параметр" textBox: textBox
            addMessage "h(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - высота съемки, обязательный параметр" textBox: textBox
            addMessage "(D|N)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - время суток, необязательный параметр, по умолчанию: D" textBox: textBox
            addMessage "\nПримеры правильных названий:" textBox: textBox
            addMessage "p01_h025" textBox: textBox bullet: true
            addMessage "Map_p02_h050_D" textBox: textBox bullet: true
            addMessage "Карта_p03_h100_N" textBox: textBox bullet: true newline: false
            textBox = rulesRollout.sunTextBox
            addMessage "Название солнца должно формироваться следующим образом: " textBox: textBox newline: false
            addMessage "*(число)" textBox: textBox style: "Bold" newline: false
            addMessage ", где:" textBox: textBox
            addMessage "*" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольная часть названия, необязательный параметр" textBox: textBox
            addMessage "(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольный номер солнца, обязательный параметр" textBox: textBox
            addMessage "\nТо есть солнца можно именовать как угодно, подойдут даже названия по умолчанию. Главное, чтобы в конце названиия было число. Это число указывается в названии камеры для связи." textBox: textBox
            addMessage "\nЕсли есть необходимость в фейковых солнцах, такие солнца нужно замоморозить (галочка Frozen)." textBox: textBox
            addMessage "\nПримеры правильных названий:" textBox: textBox
            addMessage "Corona Sun001" textBox: textBox bullet: true
            addMessage "Sun_002" textBox: textBox bullet: true
            addMessage "Солнце_003" textBox: textBox bullet: true newline: false
        )
    )
    createDialog rulesRollout width: 610 height: 586 modal: true parent: optionsRollout.hwnd
    for control in optionsRollout.controls do control.enabled = true
)

-- Создаем окно с логами
fn createLogsDialog = (
    createDialog logs width: 530 height: 300
    logs.textBox.BackColor = (dotNetClass "System.Drawing.Color").FromArgb(-12303292)
    logs.textBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
	logs.textBox.ReadOnly = true
)

-- Добавляем сообщения в лог
fn addMessage message textBox: logs.textBox color: "White" style: "Regular" bullet: false newline: true = (
	textBox.SelectionColor = getProperty (dotNetClass "System.Drawing.Color") color
    if bullet then textBox.AppendText "  •  "
    textBox.SelectionFont = dotNetObject "System.Drawing.Font" textBox.Font (getProperty (dotNetClass "System.Drawing.FontStyle") style)
    textBox.AppendText (message + (if newline then "\n" else ""))
)

-- Устанавливаем выбранную камеру
fn changeCamera cam = (
    viewport.setCamera cam
    addMessage "Установлена камера: " color: "LimeGreen" newline: false
    addMessage cam.name color: "LimeGreen" style: "Bold"
)

-- Определяем параметры по названию камеры
fn defineCameraParams cam = (
    local pattern = "P(\d+)_H(\d+)_S(\d+)(?:_([DN]))?$"
    local match = (dotNetClass "System.Text.RegularExpressions.Regex").Match (toUpper cam.name) pattern
	if not match.Success then (
		addMessage "По названию камеры не определены параметры. Убедись, что тебе не требуется перестановка Environment Map и солнца или проверь название камеры!" color: "Tomato"
		return undefined
	)
    local params = #()
    for i = 1 to 4 do (
        params[i] = match.Groups.item[i].value
    )
    if params[4] == "" then params[4] = "D"
    addMessage ("По названию камеры определены параметры:")
	addMessage "Панорама: " bullet: true newline: false
	addMessage params[1] style: "Bold"
	addMessage "Высота: " bullet: true newline: false
	addMessage params[2] style: "Bold"
	addMessage "Солнце: " bullet: true newline: false
	addMessage params[3] style: "Bold"
	addMessage "День/ночь: " bullet: true newline: false
	addMessage params[4] style: "Bold"
	return params
)

-- Получаем карты
fn getMaps = (
    local maps = #()
    if sme.GetNumViews() == 0 and not sme.IsOpen() then (
        sme.Open()
        sme.Close()
    )
    for i = 1 to sme.GetNumViews() do (
        local view = sme.GetView i
        for j = 1 to view.GetNumNodes() do (
            local node = view.GetNode j
            local map = node.reference
            if ClassOf map == CoronaSelect then append maps map
        )
    )
    if maps.count == 0 then (
        addMessage ("Карты CoronaSelect не найдены, перестановка карты не требуется")
		return undefined
    )
    return maps
)

-- Устанавливаем карту
fn changeMap params maps = (
    local pattern = "P" + params[1] + "_H" + params[2] + (if params[4] == "D" then "(?:_" + params[4] + ")?" else "_" + params[4]) + "$"
    local foundMaps = #()
    for map in maps do (
        local selected = 0
        for textmap in map.texmaps where not textmap == undefined do (
            if (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch (toUpper textmap.name) pattern then (
                map.selected = selected
                append foundMaps #(
                    map,
                    textmap.name
                )
            )
            selected += 1
        )
    )
    if foundMaps.count == 0 then (
        addMessage "По заданным параметрам карта не найдена" color: "Tomato"
        addMessage "Карта не установлена" color: "Tomato" style: "Bold"
        return undefined
    )
    if foundMaps.count > 1 then (
        addMessage "По заданным параметрам найдено несколько карт:" color: "Tomato"
        for map in foundMaps do (
            addMessage (map[1].name + " (" + map[2] + ")") color: "Tomato" bullet: true
        )
        addMessage "Карта не установлена" color: "Tomato" style: "Bold"
        return undefined
    )
    environmentmap = foundMaps[1][1]
    addMessage "В Environment Map установлена карта: " color: "LimeGreen" newline: false
    addMessage (foundMaps[1][1].name + " (" + foundMaps[1][2] + ")") color: "LimeGreen" style: "Bold"
    return foundMaps[1][1]
)

-- Получаем солнца
fn getSuns = (
    local suns = for obj in objects where classOf obj == CoronaSun collect obj
    if suns.count == 0 then (
        addMessage "Солнца не найдены, перестановка солнца не требуется"
		return undefined
    )
    if suns.count == 1 then (
        addMessage ("Найдено одно солнце, перестановка солнца не требуется")
        return undefined
    )
    return suns
)

-- Устанавливаем солнце
fn changeSun params suns = (
    local pattern = params[3] + "$"
    local foundSuns = #()
    for sun in suns do (
        if (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch sun.name pattern then (
            append foundSuns sun
        )
    )
    if foundSuns.count == 0 then (
        addMessage "По заданным параметрам солнце не найдено" color: "Tomato"
        addMessage "Солнце не установлено" color: "Tomato" style: "Bold"
        return undefined
    )
    if foundSuns.count > 1 then (
        addMessage "По заданным параметрам найдено несколько солнц:" color: "Tomato"
        for sun in foundSuns do (
            addMessage sun.name color: "Tomato" bullet: true
        )
        addMessage "Солнце не установлено" color: "Tomato" style: "Bold"
        return undefined
    )
    local extraSuns = #()
    for sun in suns do (
        if sun.isFrozen then (
            append extraSuns sun
        )
        sun.isHidden = (sun != foundSuns[1] and not sun.isFrozen)
    )
    addMessage "Установлено солнце: " color: "LimeGreen" newline: false
    addMessage foundSuns[1].name color: "LimeGreen" style: "Bold"
    if not extraSuns.count == 0 then (
        addMessage "Установлены фейковые солнца: " color: "LimeGreen" newline: false
        local extraSunNames = ""
        for i = 1 to extraSuns.count do (
            addMessage extraSuns[1].name color: "LimeGreen" style: "Bold" newline: false
            addMessage (if i < extraSuns.count then ", " else "\n") color: "LimeGreen" newline: false
        )
    )
    return foundSuns[1]
)

-- Показываем окно подтверждения рендера
fn createTimerDialog = (
    rollout timerRollout "" (
        local countdown = 20
        local confirmed = true
        timer autoYes interval: 1000
        on timerRollout open do (
            confirmed = queryBox ("Окно закроется с подтверждением через " + countdown as String + " секунд") title: "Запустить рендер?" parent: timerRollout.hwnd
            destroyDialog timerRollout
        )
        on autoYes tick do (
            if autoYes.ticks == countdown then (
                countdown = 0
                destroyDialog timerRollout
            )
        )
    )
    createDialog timerRollout width: 50 height: 0 modal: true parent: logs.hwnd
    if not timerRollout.confirmed and not timerRollout.countdown == 0 then addMessage "Рендер отменен пользователем"
    return timerRollout.confirmed or timerRollout.countdown == 0
)

-- Рендерим
fn runRender params path = (
    addMessage "Запуск рендера"
    renderSceneDialog.open()
    tif.setType(#color)
    tif.setCompression(#none)
    tif.setAlpha(#false)
    tif.setDPI(300)
    rendSaveFile = true
    local outputFilename = params[1] + "_" + params[2] + "_" + params[4] + ".tif"
    rendOutputFilename = path + "\\" + outputFilename
    renderSceneDialog.update()
    max quick render
    rendSaveFile = false
    rendOutputFilename = ""
    renderSceneDialog.update()
    renderSceneDialog.close()
    addMessage "Рендер завершен: " color: "LimeGreen" newline: false
    addMessage outputFilename color: "LimeGreen" style: "Bold"
)

-- Основная логика
fn main = (
	-- Получаем камеры
    local cams = getCameras()
    if cams == undefined then return undefined
	
	-- Создаем окно с выбором опций
	local options = createOptionsDialog cams
    if options[1].count == 0 then return undefined

	
	-- Создаем окно с логами
    createLogsDialog()
	
    for cam in options[1] do (
        if not apsActive then return false

        -- Устанавливаем выбранную камеру
        changeCamera cam
        
        -- Определяем параметры по названию камеры
        local params = defineCameraParams cam
        if params == undefined then return false

        -- Получаем карты
        local maps = getMaps()

        -- Устанавливаем карту
        if not maps == undefined then changeMap params maps

        -- Получаем солнца 
        local suns = getSuns()

        -- Устанавливаем солнце
        if not suns == undefined then changeSun params suns

        -- Рендерим
        if createTimerDialog() then runRender params options[2]
    )

    return true
)

-- Запускаем скрипт
fn run = (
    local result = main()
	if not result == undefined then (
        addMessage "Скрипт завершил работу"
        logs.stopButton.enabled = false
    )
    apsComplete = true
)

run()
