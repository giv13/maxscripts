-- Глобальное окно с логами
rollout logs "Процесс работы скрипта" (
    dotNetControl control "System.Windows.Forms.RichTextBox" width: 270 height: 200
)

-- Получаем список камер
fn getCameras = (
    local cams = for obj in objects where superClassOf obj == Camera collect obj
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
	addMessage ("Установлена камера: " + cam.name) color: "green"
)

-- Определяем параметры по названию камеры
fn defineCameraParams cam = (
	dotNet.loadAssembly "System.Text.RegularExpressions"
	local regex = dotNetClass "System.Text.RegularExpressions.Regex"
	local pattern = "^\D*(\d+)\D+(\d+)\D*?(N?)$"
	return regex.Match (toUpper cam.name) pattern
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

-- Основная логика
fn main = (
	-- Получаем список камер
    local cams = getCameras()
    if cameras.count == 0 then (
        messageBox "В сцене нет камер!"
		return false
    )
	
	-- Создаем окно с выбором камеры
	local cam = createCameraDialog cams
	if cam == undefined then (
        messageBox "Камера не выбрана!"
		return false
    )
	
	-- Создаем окно с логами
    createLogsDialog()
	
	-- Устанавливаем выбранную камеру
    changeCamera cam
	
	-- Определяем параметры по названию камеры
	local match = defineCameraParams cam
	if not match.Success then (
		addMessage "По названию камеры не определены параметры" color: "red"
		return false
	)

	-- Формируем паттерн для дальнейших поисков
	local pattern = formPattern match
)

-- Запускаем скрипт
fn run = (
    main()
    ForceCompleteRedraw()
	addMessage "Скрипт закончил работу"
)

run()
