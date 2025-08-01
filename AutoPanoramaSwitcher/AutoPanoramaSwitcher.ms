struct AutoPanoramaSwitcherStruct (
    stopped = false,
    completed = false,
    checkMode = false,
    
    -- Окно выбора опций
    optionsRollout = rollout optionsRollout "Auto Panorama Switcher" (
        local owner = if owner != undefined then owner
        local cams = if cams != undefined then cams
        group "Настройка опций" (
            multilistbox cameraList "Выбери камеры:" items: (for cam in cams collect cam.name)
            label pathLabel "Укажи папку для сохранения:" align: #left
            edittext pathFolder width: 240 height: 20 across: 2 labelOnTop: true
            button pathButton "..." align: #right
            button runButton "Запустить скрипт" across: 2 align: #left
            button hintButton "Правила именования" images: #(((getDir #ui_ln) + "IconsDark\bip_mflgraph_i.bmp"), undefined, 40, 9, 9, 10, 10, false, true) border: false align: #right
        )
        on pathButton pressed do (
            local folderDialog = dotNetObject "System.Windows.Forms.FolderBrowserDialog"
            folderDialog.Description = "Укажи папку для сохранения:"
            local dialogResult = folderDialog.showDialog()
            if (dialogResult.ToString() == "OK") then (
                pathFolder.text = folderDialog.selectedPath
            )
        )
        on runButton pressed do (
            local selectedCams = for s in (cameraList.selection as Array) collect cams[s]
            if selectedCams.count == 0 then (
                messageBox "Не выбраны камеры!" title: "Ошибка"
                return false
            )
            if pathFolder.text == "" then (
                owner.checkMode = queryBox "Не выбрана папка для сохранения! Скрипт отработает в режиме проверки!" title: "Подтверди действие"
                if not owner.checkMode then return false
            ) else (
                owner.checkMode = false
            )
            if not owner.checkMode and not doesFileExist pathFolder.text then (
                messageBox "Указанной папки не существует!" title: "Ошибка"
                return false
            )
            -- Запускаем основную логику
            owner.run selectedCams pathFolder.text
        )
        on hintButton pressed do (
            -- Показываем окно правил именования
            createDialog owner.rulesRollout width: 675 height: 856 parent: optionsRollout.hwnd
        )
        on optionsRollout close do (
            if not owner.logsRollout.isDisplayed then owner.completed = true
        )
    ),

    -- Окно правил именования
    rulesRollout = rollout rulesRollout "Правила именования" (
        group "Камеры" (
            dotNetControl camTextBox "System.Windows.Forms.RichTextBox" width: 645 height: 166
        )
        group "Карты" (
            dotNetControl mapTextBox "System.Windows.Forms.RichTextBox" width: 645 height: 140
        )
        group "Материалы окон" (
            dotNetControl matTextBox "System.Windows.Forms.RichTextBox" width: 645 height: 140
        )
        group "Солнца" (
            dotNetControl sunTextBox "System.Windows.Forms.RichTextBox" width: 645 height: 179
        )
        group "Рендер элементы" (
            dotNetControl addTextBox "System.Windows.Forms.RichTextBox" width: 645 height: 70
        )
        local textBox
        fn addLine message style: "Regular" bullet: false newline: true = (
            textBox.SelectionColor = (dotNetClass "System.Drawing.Color").White
            if bullet then textBox.AppendText "  •  "
            textBox.SelectionFont = dotNetObject "System.Drawing.Font" textBox.Font (getProperty (dotNetClass "System.Drawing.FontStyle") style)
            textBox.AppendText (message + (if newline then "\n" else ""))
        )
        on rulesRollout open do (
            for textBox in #("camTextBox", "mapTextBox", "matTextBox", "sunTextBox", "addTextBox") do (
                textBox = getProperty rulesRollout textBox
                textBox.BackColor = (dotNetClass "System.Drawing.Color").FromArgb(-12303292)
                textBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").None
                textBox.ReadOnly = true
            )
            textBox = rulesRollout.camTextBox
            addLine "Название камеры должно формироваться следующим образом: " newline: false
            addLine "*_(лат. буквы)(число)_h(число)_s(число)_(D|N)" style: "Bold" newline: false
            addLine ", где:"
            addLine "*" style: "Bold" bullet: true newline: false
            addLine " - произвольная часть названия, необязательный параметр"
            addLine "(лат. буквы)(число)" style: "Bold" bullet: true newline: false
            addLine " - название панорамы, обязательный параметр"
            addLine "h(число)" style: "Bold" bullet: true newline: false
            addLine " - высота съемки, обязательный параметр"
            addLine "s(число)" style: "Bold" bullet: true newline: false
            addLine " - номер солнца, обязательный параметр"
            addLine "(D|N)" style: "Bold" bullet: true newline: false
            addLine " - время суток, обязательный параметр"
            addLine "\nПримеры правильных названий:"
            addLine "p01_h025_s001" bullet: true
            addLine "Cam_a02_h050_s002" bullet: true
            addLine "Camera_b03_h100_s003_D" bullet: true
            addLine "Камера_pan04_h200_s004_N" bullet: true newline: false
            textBox = rulesRollout.mapTextBox
            addLine "Название карты должно формироваться следующим образом: " newline: false
            addLine "*_(лат. буквы)(число)_h(число)_(D|N)" style: "Bold" newline: false
            addLine ", где:"
            addLine "*" style: "Bold" bullet: true newline: false
            addLine " - произвольная часть названия, необязательный параметр"
            addLine "(лат. буквы)(число)" style: "Bold" bullet: true newline: false
            addLine " - название панорамы, обязательный параметр"
            addLine "h(число)" style: "Bold" bullet: true newline: false
            addLine " - высота съемки, обязательный параметр"
            addLine "(D|N)" style: "Bold" bullet: true newline: false
            addLine " - время суток, обязательный параметр"
            addLine "\nПримеры правильных названий:"
            addLine "p01_h025" bullet: true
            addLine "Map_a02_h050_D" bullet: true
            addLine "Карта_b03_h100_N" bullet: true newline: false
            textBox = rulesRollout.matTextBox
            addLine "Название материала окон должно формироваться следующим образом: " newline: false
            addLine "*_(D|N)" style: "Bold" newline: false
            addLine ", где:"
            addLine "*" style: "Bold" bullet: true newline: false
            addLine " - произвольная часть названия, обязательный параметр"
            addLine "(D|N)" style: "Bold" bullet: true newline: false
            addLine " - время суток, обязательный параметр"
            addLine "\nПри этом в сцене обязательно должен быть слой, название которого совпадает с произвольной частью названия материала окон (название материала окон без части " newline: false
            addLine "_(D|N)" style: "Bold" newline: false
            addLine ")."
            addLine "\nПримеры правильных названий:"
            addLine "Материалы окон: appartemnts_D и appartments_N; Слой: appartments" bullet: true
            addLine "Материалы окон: offices_D и offices_N; Слой: offices" bullet: true newline: false
            textBox= rulesRollout.sunTextBox
            addLine "Название солнца должно формироваться следующим образом: " newline: false
            addLine "*(число)" style: "Bold" newline: false
            addLine ", где:"
            addLine "*" style: "Bold" bullet: true newline: false
            addLine " - произвольная часть названия, необязательный параметр"
            addLine "(число)" style: "Bold" bullet: true newline: false
            addLine " - произвольный номер солнца, обязательный параметр"
            addLine "\nТо есть солнца можно именовать как угодно, подойдут даже названия по умолчанию. Главное, чтобы в конце названиия было число. Это число указывается в названии камеры для связи."
            addLine "\nЕсли есть необходимость в фейковых солнцах, такие солнца нужно замоморозить (галочка Frozen)."
            addLine "\nПримеры правильных названий:"
            addLine "Corona Sun001" bullet: true
            addLine "Sun_002" bullet: true
            addLine "Солнце_003" bullet: true newline: false
            textBox= rulesRollout.addTextBox
            addLine "По схеме " newline: false
            addLine "*_(D|N)" style: "Bold" newline: false
            addLine " также могут быть названы Render Elemets в настройках рендера. Для элементов, названных по этой схеме, будут автоматически выключаться галочки во вкладке LightMix во время рендера. Для дневных рендеров будут выключаться элементы " newline: false
            addLine "*_N" style: "Bold" newline: false
            addLine ", для ночных - " newline: false
            addLine "*_D" style: "Bold"
            addLine "\nRender Elemets, не помеченные по этой схеме, будут всегда автоматически включаться во время рендера." newline: false
        )
    ),

    -- Окно логов
    logsRollout = rollout logsRollout "Процесс работы скрипта" (
        local owner = if owner != undefined then owner
        button stopButton "Остановить скрипт" width: 120 pos: [15, 10]
        progressBar progress color: (color 0 200 0) width: 695 pos: [150, 14]
        dotNetControl textBox "System.Windows.Forms.RichTextBox" width: 860 height: 360 pos: [0, 40]
        on stopButton pressed do (
            owner.stopped = true
            stopButton.enabled = false
            owner.addLogLine "Скрипт остановлен пользователем и завершит работу после окончания рендера" type: "warn"
        )
        on logsRollout open do (
            textBox.ReadOnly = true
        )
        on logsRollout oktoclose do (
            if not owner.completed then messageBox "Закрытие окна запрещено, пока скрипт не завершит работу" title: "Ошибка"
            return owner.completed
        )
    ),

    -- Добавляем строку в textBox логов
    fn addLogLine message type: "info" prefix: undefined postfix: "\n" = (
        if prefix == undefined then (
            local time = getLocalTime()
            time = formattedPrint time[4] format: "02d" + "." + formattedPrint time[2] format: "02d" + " " + formattedPrint time[5] format: "02d" + ":" + formattedPrint time[6] format: "02d"
            prefix = "[" + time + "] " + (toUpper type) + ": "
        )
        if type == "warn" then (
            logsRollout.textBox.SelectionColor = (dotNetClass "System.Drawing.Color").Orange
        ) else if type == "error" then (
            logsRollout.textBox.SelectionColor = (dotNetClass "System.Drawing.Color").Red
        ) else if type == "success" then (
            logsRollout.textBox.SelectionColor = (dotNetClass "System.Drawing.Color").Green
        ) else (
            logsRollout.textBox.SelectionColor = (dotNetClass "System.Drawing.Color").Blue
        )
        logsRollout.textBox.SelectionFont = dotNetObject "System.Drawing.Font" editorFont editorFontSize
        logsRollout.textBox.AppendText (prefix + message + postfix)
        logsRollout.textBox.ScrollToCaret()
    ),

    -- Окно подтверждения рендера
    timerRollout = rollout timerRollout "" (
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
    ),

    -- Показываем окно логов
    fn createLogsDialog = (
        logsRollout.owner = this
        logsRollout.stopButton.enabled = true
        logsRollout.progress.value = 0
        createDialog logsRollout width: 860 height: 400
        logsRollout.textBox.Clear()
    ),

    -- Показываем окно подтверждения рендера
    fn createTimerDialog = (
        createDialog timerRollout width: 50 height: 0 modal: true parent: logsRollout.hwnd
        if not timerRollout.confirmed and not timerRollout.countdown == 0 then (
            addLogLine "Рендер отменен пользователем" type: "warn"
            if (queryBox ("Рендер отменен. Остановить скрипт?") title: "Остановить скрипт?" parent: logsRollout.hwnd) then (
                stopped = true
                logsRollout.stopButton.enabled = false
                addLogLine "Скрипт остановлен пользователем" type: "warn"
            )
        )
        return timerRollout.confirmed or timerRollout.countdown == 0
    ),

    -- Устанавливаем выбранную камеру
    fn changeCam cam = (
        if not checkMode then viewport.setCamera cam
        addLogLine ((if checkMode then "Проверка камеры" else "Установлена камера") + ": " + cam.name)
    ),
    
    -- Определяем параметры по названию камеры
    fn defineCameraParams cam = (
        local pattern = "([A-Z]+\d+)_H(\d+)_S(\d+)_([DN])$"
        local match = (dotNetClass "System.Text.RegularExpressions.Regex").Match cam.name pattern (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase
        if not match.Success then (
            addLogLine "По названию камеры не определены параметры" type: "error"
            addLogLine "Убедись, что тебе не требуется перестановка Environment Map и солнца или проверь название камеры" type: "error"
            return undefined
        )
        local params = #()
        for i = 1 to 4 do (
            params[i] = match.Groups.item[i].value
        )
        if params[4] == "" then params[4] = "D"
        addLogLine ("По названию камеры определены параметры: Панорама - " + params[1] + "; Высота - " + params[2] + "; Солнце - " + params[3] + "; День/ночь - " + params[4])
        return params
    ),

    -- Устанавливаем карту
    fn changeMap params maps = (
        local pattern = params[1] + "_H" + params[2] + "_" + params[4] + "$"
        local foundMaps = #()
        for map in maps do (
            local selected = 0
            for textmap in map.texmaps do (
                if not textmap == undefined and (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch textmap.name pattern (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase then (
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
            addLogLine "По заданным параметрам карта не найдена" type: "error"
            if not checkMode then addLogLine "Карта не установлена" type: "error"
        ) else if foundMaps.count > 1 then (
            addLogLine "По заданным параметрам найдено несколько карт: " type: "error" postfix: ""
            for i = 1 to foundMaps.count do (
                addLogLine (foundMaps[i][1].name + " (" + foundMaps[i][2] + ")") type: "error" prefix: "" postfix: (if i < foundMaps.count then ", " else "\n")
            )
            if not checkMode then addLogLine "Карта не установлена" type: "error"
        ) else (
            if not checkMode then environmentmap = foundMaps[1][1]
            addLogLine ((if checkMode then "Найдена" else "В Environment Map установлена") + " карта: " + foundMaps[1][1].name + " (" + foundMaps[1][2] + ")")
        )
    ),

    -- Устанавливаем материалы окон
    fn changeMaterials params materials = (
        for material in materials do (
            local layerName = (dotNetClass "System.Text.RegularExpressions.Regex").Replace material.name ("_" + params[4] + "$") "" (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase
            local layer = LayerManager.getLayerFromName layerName
            if layer == undefined then (
                addLogLine ("Для материала окон " + material.name + " не найден слой " + layerName) type: "error"
                if not checkMode then addLogLine "Материал окон не установлен" type: "error"
            ) else (
                if not checkMode then (
                    layer.isHidden = false
                    layer.nodes &nodes
                    for obj in nodes do (
                        obj.material = material
                    )
                    addLogLine ("Материал окон " + material.name + " установлен в слой " + layer.name)
                ) else (
                    addLogLine ("Для материала окон " + material.name + " найден слой " + layer.name)
                )
            )
        )
    ),

    -- Получаем карты и материалы окон
    fn getMapsAndMaterials params = (
        local pattern = "_" + params[4] + "$"
        local maps = #()
        local materials = #()
        if sme.GetNumViews() == 0 and not sme.IsOpen() then (
            sme.Open()
            sme.Close()
        )
        for i = 1 to sme.GetNumViews() do (
            local view = sme.GetView i
            for j = 1 to view.GetNumNodes() do (
                local node = view.GetNode j
                local ref = node.reference
                if ClassOf ref == CoronaSelect then append maps ref
                if ClassOf ref == Multimaterial and (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch ref.name pattern (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase then append materials ref
            )
        )
        if maps.count == 0 then (
            addLogLine "Карты CoronaSelect не найдены, перестановка карты не требуется" type: "warn"
        ) else (
            -- Устанавливаем карту
            changeMap params maps
        )
        if materials.count == 0 then (
            addLogLine "Материалы окон не найдены, перестановка материалов окон не требуется" type: "warn"
        ) else (
            -- Устанавливаем материалы окон
            changeMaterials params materials
        )
    ),

    -- Устанавливаем солнца
    fn changeSun params suns = (
        local pattern = params[3] + "$"
        local foundSuns = #()
        for sun in suns do (
            if (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch sun.name pattern then (
                append foundSuns sun
            )
        )
        if foundSuns.count == 0 then (
            addLogLine "По заданным параметрам солнце не найдено" type: "error"
            if not checkMode then addLogLine "Солнце не установлено" type: "error"
        ) else if foundSuns.count > 1 then (
            addLogLine "По заданным параметрам найдено несколько солнц: " type: "error" postfix: ""
            for i = 1 to foundSuns.count do (
                addLogLine foundSuns[i].name type: "error" prefix: "" postfix: (if i < foundSuns.count then ", " else "\n")
            )
            if not checkMode then addLogLine "Солнце не установлено" type: "error"
        ) else (
            local extraSuns = #()
            for sun in suns do (
                if sun.isFrozen then (
                    append extraSuns sun
                )
                if not checkMode then sun.isHidden = (sun != foundSuns[1] and not sun.isFrozen)
            )
            addLogLine ((if checkMode then "Найдено" else "Установлено") + " солнце: " + foundSuns[1].name)
            if not extraSuns.count == 0 then (
                addLogLine ((if checkMode then "Найдены" else "Установлены") + " фейковые солнца: ") postfix: ""
                local extraSunNames = ""
                for i = 1 to extraSuns.count do (
                    addLogLine extraSuns[1].name prefix: "" postfix: (if i < extraSuns.count then ", " else "\n")
                )
            )
        )
    ),

    -- Получаем солнца
    fn getSuns params = (
        local suns = for obj in objects where classOf obj == CoronaSun collect obj
        if suns.count == 0 then (
            addLogLine "Солнца не найдены, перестановка солнца не требуется" type: "warn"
        ) else if suns.count == 1 then (
            addLogLine "Найдено одно солнце, перестановка солнца не требуется" type: "warn"
        ) else (
            -- Устанавливаем солнца
            changeSun params suns
        )
    ),

    -- Рендерим
    fn render params path = (
        addLogLine "Рендер запущен"
        renderSceneDialog.open()
        tif.setType(#color)
        tif.setCompression(#none)
        tif.setAlpha(#false)
        tif.setDPI(300)
        rendSaveFile = true
        local outputFilename = params[1] + "_" + params[2] + "_" + params[4] + ".tif"
        rendOutputFilename = path + "\\" + outputFilename
        -- Отключаем лишние Render Elements
        local manager = maxOps.GetCurRenderElementMgr()
        for i = 0 to (manager.NumRenderElements() - 1) do (
            local element = manager.GetRenderElement i
            if (classOf element == CShading_LightSelect) then (
                local enabled = element.addEnvironment
                if not enabled then (
                    local nodes = element.includedNodes
                    for node in nodes do (
                        if not node.isHidden then (
                            enabled = true
                            exit
                        )
                    )
                )
                element.enabled = enabled
            )
        )
        -- Настраиваем галочки во вкладке LightMix
        local pattern1 = "_[DN]$"
        local pattern2 = "_" + params[4] + "$"
        local lightMixNames = renderers.current.colormap_lightmix_elementNames
        local lightMixEnabled = #()
        for name in lightMixNames do (
            local enabled = true
            if (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch name pattern1 (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase then (
                if not (dotNetClass "System.Text.RegularExpressions.Regex").IsMatch name pattern2 (dotNetClass "System.Text.RegularExpressions.RegexOptions").IgnoreCase then (
                    enabled = false
                )
            )
            append lightMixEnabled enabled
        )
        renderers.current.colorMap_lightmixEnabledLayers = lightMixEnabled
        renderSceneDialog.update()
        max quick render
        rendSaveFile = false
        rendOutputFilename = ""
        renderSceneDialog.update()
        renderSceneDialog.close()
        addLogLine ("Рендер завершен: " + outputFilename) type: "success"
    ),

    -- Обрабатываем камеры в цикле
    fn loop cams path = (
        for i = 1 to cams.count do (
            if stopped then (
                logsRollout.progress.value = 100
                return false
            )
            addLogLine (i as String + "/" + cams.count as String + " -----------------------------------------------") prefix: ""

            -- Устанавливаем выбранную камеру
            changeCam cams[i]
            
            -- Определяем параметры по названию камеры
            local params = defineCameraParams cams[i]
            if params == undefined then return false

            -- Получаем и устанавливаем карты и материалы для окон
            getMapsAndMaterials params

            -- Получаем и устанавливаем солнца 
            getSuns params

            -- Рендерим
            if not checkMode and createTimerDialog() then render params path

            logsRollout.progress.value = 100.0 / cams.count * i
        )
    ),

    -- Запускаем основную логику
    fn run cams path = (
        stopped = false
        completed = false

        -- Показываем окно логов
        createLogsDialog()
        addLogLine "Скрипт начал работу"
        addLogLine ("Выбрано камер: " + cams.count as String + "; " + (if checkMode then "Плагин работает в режиме проверки" else "Папка для сохранения: " + path)) type: (if checkMode then "warn" else "info")

        -- Обрабатываем камеры в цикле
        loop cams path
        
        if not checkMode then shellLaunch "explorer.exe" path
        addLogLine "--------------------------------------------------" prefix: ""
        addLogLine "Скрипт завершил работу"
        logsRollout.stopButton.enabled = false
        completed = true
    ),

    fn openGui = (
        -- Получаем камеры
        local cams = for obj in objects where superClassOf obj == Camera collect obj
        if cams.count == 0 then (
            messageBox "В сцене нет камер!" title: "Ошибка"
            completed = true
        ) else (
            qsort cams (fn compare cam1 cam2 = if cam1.name < cam2.name then -1 else 1)
            -- Показываем окно выбора опций
            optionsRollout.owner = this
            optionsRollout.cams = cams
            createDialog optionsRollout width: 300 height: 264
        )
    )
)

if AutoPanoramaSwitcher == undefined or AutoPanoramaSwitcher.completed then (
    AutoPanoramaSwitcher = AutoPanoramaSwitcherStruct()
    AutoPanoramaSwitcher.openGui()
) else (
    messageBox "Скрипт уже запущен!" title: "Ошибка"
)
