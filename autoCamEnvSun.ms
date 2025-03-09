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
fn createLogDialog = (
    rollout logRollout "Процесс работы скрипта" (
		dotNetControl log "System.Windows.Forms.RichTextBox" width: 270 height: 200
	)
    createDialog logRollout width: 300 height: 220
	logRollout.log.BulletIndent = 10
	logRollout.log.ReadOnly = true
    return logRollout
)

-- Добавляем сообщения в лог
fn addLogMessage logRollout message color: "blue" bullet: false = (
	logRollout.log.SelectionColor = getProperty (dotNetClass "System.Drawing.Color") color
	logRollout.log.SelectionBullet = bullet
    logRollout.log.AppendText (message + "\n")
)

-- Устанавливаем выбранную камеру
fn changeCamera cam logRollout = (
    viewport.setCamera cam
	addLogMessage logRollout ("Установлена камера: " + cam.name) color: "green"
)

-- Определяем параметры по названию камеры
fn defineCameraParams cam = (
	dotNet.loadAssembly "System.Text.RegularExpressions"
	local regex = dotNetClass "System.Text.RegularExpressions.Regex"
	local pattern = "^\D*(\d+)\D+(\d+)\D*?(N?)$"
	return regex.Match (toUpper cam.name) pattern
)

-- Формируем паттерн для дальнейших поисков
fn formPattern match logRollout = (
	local camAngle = match.Groups.item[1].value
	local camHeight = match.Groups.item[2].value
	local camDayOrNight = match.Groups.item[3].value
	if camDayOrNight == "" then camDayOrNight = "D"
	addLogMessage logRollout ("По названию камеры определены параметры:")
	addLogMessage logRollout ("Ракурс: " + camAngle) bullet: true
	addLogMessage logRollout ("Высота: " + camHeight) bullet: true
	addLogMessage logRollout ("День/ночь: " + camDayOrNight) bullet: true
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
    local logRollout = createLogDialog()
	
	-- Устанавливаем выбранную камеру
    changeCamera cam logRollout

	
	-- Определяем параметры по названию камеры
	local match = defineCameraParams cam
	if not match.Success then (
		addLogMessage logRollout "По названию камеры не определены параметры" color: "red"
		addLogMessage logRollout "Скрипт закончил работу"
		return false
	)

	-- Формируем паттерн для дальнейших поисков
	local pattern = formPattern match logRollout

	ForceCompleteRedraw()
	addLogMessage logRollout "Скрипт закончил работу"
)

-- Запускаем скрипт
main()
