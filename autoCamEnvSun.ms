-- .NET класс для работы с регулярными выражениями
dotNet.loadAssembly "System.Text.RegularExpressions"
regex = dotNetClass "System.Text.RegularExpressions.Regex"

-- Глобальное окно с логами
rollout logs "Процесс работы скрипта" (
    group "" (
        dotNetControl textBox "System.Windows.Forms.RichTextBox" width: 500 height: 200
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

-- Создаем окно с выбором камеры
fn createCameraDialog cams = (
    rollout cameraRollout "Выберите камеру" (
        group "Камеры" (
            dropdownlist cameraList items: (for cam in cams collect cam.name)
            button selectButton "Выбрать" width: 100 across: 2 align: #left
            button hintButton "Правила именования" images: #(((getDir #ui_ln) + "IconsDark\bip_mflgraph_i.bmp"), undefined, 40, 9, 9, 10, 10, false, true) border: false align: #right
        )
		local cam = undefined
        on selectButton pressed do (
            cam = cameraRollout.cams[cameraList.selection]
            destroyDialog cameraRollout
        )
        on hintButton pressed do (
            cameraList.enabled = false
            selectButton.enabled = false
            hintButton.enabled = false
            showRules cameraRollout
        )
    )
    createDialog cameraRollout width: 300 height: 90 modal: true
	if cameraRollout.cam == undefined then (
        messageBox "Камера не выбрана!" title: "Ошибка"
    )
	return cameraRollout.cam
)

-- Показываем правила именования
fn showRules cameraRollout = (
    rollout rulesRollout "Правила именования" (
        group "Камеры" (
            dotNetControl camTextBox "System.Windows.Forms.RichTextBox" width: 620 height: 166
        )
        group "Карты" (
            dotNetControl mapTextBox "System.Windows.Forms.RichTextBox" width: 620 height: 140
        )
        group "Солнца" (
            dotNetControl sunTextBox "System.Windows.Forms.RichTextBox" width: 620 height: 153
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
            addMessage "Наименование камеры должно формироваться следующим образом: " textBox: textBox newline: false
            addMessage "*_p(число)_h(число)_s(число)_(D|N)" textBox: textBox style: "Bold" newline: false
            addMessage ", где:" textBox: textBox
            addMessage "*" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольная часть наименования, необязательный параметр" textBox: textBox
            addMessage "p(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - номер панорамы, обязательный параметр" textBox: textBox
            addMessage "h(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - высота съемки, обязательный параметр" textBox: textBox
            addMessage "s(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - номер солнца, обязательный параметр" textBox: textBox
            addMessage "(D|N)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - время суток, необязательный параметр, по умолчанию: D" textBox: textBox
            addMessage "\nПримеры правильных наименований:" textBox: textBox
            addMessage "p01_h025_s001" textBox: textBox bullet: true
            addMessage "Cam_p02_h050_s002" textBox: textBox bullet: true
            addMessage "Camera_p03_h100_s003_D" textBox: textBox bullet: true
            addMessage "Камера_p04_h200_s004_N" textBox: textBox bullet: true newline: false
            textBox = rulesRollout.mapTextBox
            addMessage "Наименование карт должно формироваться следующим образом: " textBox: textBox newline: false
            addMessage "*_p(число)_h(число)_(D|N)" textBox: textBox style: "Bold" newline: false
            addMessage ", где:" textBox: textBox
            addMessage "*" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольная часть наименования, необязательный параметр" textBox: textBox
            addMessage "p(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - номер панорамы, обязательный параметр" textBox: textBox
            addMessage "h(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - высота съемки, обязательный параметр" textBox: textBox
            addMessage "(D|N)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - время суток, необязательный параметр, по умолчанию: D" textBox: textBox
            addMessage "\nПримеры правильных наименований:" textBox: textBox
            addMessage "p01_h025" textBox: textBox bullet: true
            addMessage "Map_p02_h050_D" textBox: textBox bullet: true
            addMessage "Карта_p03_h100_N" textBox: textBox bullet: true newline: false
            textBox = rulesRollout.sunTextBox
            addMessage "Наименование солнц должно формироваться следующим образом: " textBox: textBox newline: false
            addMessage "*(число)" textBox: textBox style: "Bold" newline: false
            addMessage ", где:" textBox: textBox
            addMessage "*" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольная часть наименования, необязательный параметр" textBox: textBox
            addMessage "(число)" textBox: textBox style: "Bold" bullet: true newline: false
            addMessage " - произвольный номер солнца, обязательный параметр" textBox: textBox
            addMessage "\nТо есть солнца можно именовать как угодно, подойдут даже наименования по умолчанию. Главное, чтобы в названии было число, которое указывается в наименовании камеры для связи." textBox: textBox
            addMessage "\nПримеры правильных наименований:" textBox: textBox
            addMessage "Corona Sun001" textBox: textBox bullet: true
            addMessage "Sun_002" textBox: textBox bullet: true
            addMessage "Солнце_003" textBox: textBox bullet: true newline: false
        )
    )
    createDialog rulesRollout width: 650 height: 560 modal: true parent: cameraRollout.hwnd
    cameraRollout.cameraList.enabled = true
    cameraRollout.selectButton.enabled = true
    cameraRollout.hintButton.enabled = true
)

-- Создаем окно с логами
fn createLogsDialog = (
    createDialog logs width: 530 height: 220
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
    local match = regex.Match (toUpper cam.name) pattern
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
	addMessage ("Панорама: " + params[1]) bullet: true
	addMessage ("Высота: " + params[2]) bullet: true
	addMessage ("Солнце: " + params[3]) bullet: true
	addMessage ("День/ночь: " + params[4]) bullet: true
	return params
)

-- Получаем карты
fn getMaps = (
    local maps = #()
    if sme.GetNumViews() == 0 and not sme.IsOpen() then sme.Open()
    for i = 1 to sme.GetNumViews() do (
        local view = sme.GetView i
        for j = 1 to view.GetNumNodes() do (
            local node = view.GetNode j
            local map = node.reference
            if ClassOf map == CoronaSelect then append maps map
        )
    )
    if maps.count == 0 then (
        addMessage ("Не найдены карты CoronaSelect, перестановка Environment Map не требуется")
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
            if regex.IsMatch (toUpper textmap.name) pattern then (
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
        addMessage "По заданным параметрам не найдена карта" color: "Tomato"
        return undefined
    )
    if foundMaps.count > 1 then (
        addMessage "По заданным параметрам найдено несколько карт:" color: "Tomato"
        for map in foundMaps do (
            addMessage (map[1].name + " (" + map[2] + ")") color: "Tomato" bullet: true
        )
        return undefined
    )
    environmentmap = foundMaps[1][1]
    addMessage "В Environment Map установлена карта: " color: "LimeGreen" newline: false
    addMessage (foundMaps[1][1].name + " (" + foundMaps[1][2] + ")") color: "LimeGreen" style: "Bold"
    return foundMaps[1][1]
)

-- Основная логика
fn main = (
	-- Получаем камеры
    local cams = getCameras()
    if cams == undefined then return undefined
	
	-- Создаем окно с выбором камеры
	local cam = createCameraDialog cams
    if cam == undefined then return undefined
	
	-- Создаем окно с логами
    createLogsDialog()
	
	-- Устанавливаем выбранную камеру
    changeCamera cam
	
	-- Определяем параметры по названию камеры
	local params = defineCameraParams cam
    if params == undefined then return false

    -- Получаем карты
    local maps = getMaps()

    -- Устанавливаем карту
    if not maps == undefined then changeMap params maps

    return true
)

-- Запускаем скрипт
fn run = (
    local result = main()
    ForceCompleteRedraw()
	if not result == undefined then addMessage "Скрипт закончил работу"
)

run()
