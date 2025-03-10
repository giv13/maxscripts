-- .NET класс для работы с регулярными выражениями
dotNet.loadAssembly "System.Text.RegularExpressions"
regex = dotNetClass "System.Text.RegularExpressions.Regex"

-- Глобальное окно с логами
rollout logs "Процесс работы скрипта" (
    dotNetControl control "System.Windows.Forms.RichTextBox" width: 270 height: 200
)

-- Получаем список камер
fn getCameras = (
    local cams = for obj in objects where superClassOf obj == Camera collect obj
    if cams.count == 0 then (
        messageBox "В сцене нет камер!"
		return undefined
    )
    qsort cams (fn compare cam1 cam2 = if cam1.name < cam2.name then -1 else 1)
    return cams
)

-- Создаем окно с выбором камеры
fn createCameraDialog cams = (
    rollout cameraRollout "Выберите камеру" (
        dropdownlist cameraList "Камеры:" items: (for cam in cams collect cam.name)
        button selectButton "Выбрать"
		local cam = undefined
        on selectButton pressed do (
            cam = cameraRollout.cams[cameraList.selection]
            destroyDialog cameraRollout
        )
    )
    createDialog cameraRollout width: 300 height: 90 modal: true
	if cameraRollout.cam == undefined then (
        messageBox "Камера не выбрана!"
    )
	return cameraRollout.cam
)

-- Создаем окно с логами
fn createLogsDialog = (
    createDialog logs width: 300 height: 220
	logs.control.BulletIndent = 10
	logs.control.ReadOnly = true
)

-- Добавляем сообщения в лог
fn addMessage message color: "blue" bullet: false = (
	logs.control.SelectionColor = getProperty (dotNetClass "System.Drawing.Color") color
	logs.control.SelectionBullet = bullet
    logs.control.AppendText (message + "\n")
)

-- Устанавливаем выбранную камеру
fn changeCamera cam = (
    viewport.setCamera cam
	addMessage "Установлена камера:" color: "green"
	addMessage cam.name color: "green" bullet: true
)

-- Определяем параметры по названию камеры
fn defineCameraParams cam = (
	local pattern = "^\D*(\d+)\D+(\d+)\D*?(N?)$"
    local match = regex.Match (toUpper cam.name) pattern
	if not match.Success then (
		addMessage "По названию камеры не определены параметры" color: "red"
		return undefined
	)
	return match
)

-- Формируем паттерн для дальнейших поисков
fn formPattern match = (
	local camAngle = match.Groups.item[1].value
	local camHeight = match.Groups.item[2].value
	local camDayOrNight = match.Groups.item[3].value
	if camDayOrNight == "" then camDayOrNight = "D"
	addMessage ("По названию камеры определены параметры:")
	addMessage ("Ракурс: " + camAngle) bullet: true
	addMessage ("Высота: " + camHeight) bullet: true
	addMessage ("День/ночь: " + camDayOrNight) bullet: true
	return "^\D*" + camAngle + "\D+" + camHeight + "\D*" + camDayOrNight + "$"
)

-- Устанавливаем карту
fn changeMap pattern = (
    local foundMaps = #()
    for i = 1 to sme.GetNumViews() do (
        local view = sme.GetView i
        for j = 1 to view.GetNumNodes() do (
            local node = view.GetNode j
            local map = node.reference
            if ClassOf map == CoronaSelect then (
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
        )
    )
    if foundMaps.count == 0 then (
        addMessage "По заданным параметрам не найдена карта" color: "red"
        return undefined
    )
    if foundMaps.count > 1 then (
        addMessage "По заданным параметрам найдено несколько карт:" color: "red"
        for map in foundMaps do (
            addMessage (map[1].name + " (" + map[2] + ")") color: "red" bullet: true
        )
        return undefined
    )
    environmentmap = foundMaps[1][1]
    addMessage "В Environment Map установлена карта:" color: "green"
    addMessage (foundMaps[1][1].name + " (" + foundMaps[1][2] + ")") color: "green" bullet: true
    return foundMaps[1][1]
)

-- Основная логика
fn main = (
	-- Получаем список камер
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
	local match = defineCameraParams cam
    if match == undefined then return false

	-- Формируем паттерн для дальнейших поисков
	local pattern = formPattern match

    -- Устанавливаем карту
    changeMap pattern

    return true
)

-- Запускаем скрипт
fn run = (
    local result = main()
    ForceCompleteRedraw()
	if not result == undefined then addMessage "Скрипт закончил работу"
)

run()
