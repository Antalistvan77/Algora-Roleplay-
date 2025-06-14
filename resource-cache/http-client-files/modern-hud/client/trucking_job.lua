-- ==============================
-- KAMIONOS MUNKA RENDSZER
-- ==============================

local screenWidth, screenHeight = guiGetScreenSize()
local truckingJob = {
    active = false,
    selectedTruck = nil,
    currentTruck = nil,
    stage = "idle", -- idle, selected, loading, delivering
    loadingProgress = 0,
    jobData = {},
    npcDialogue = ""
}

-- ==============================
-- KOORDINÁTÁK
-- ==============================
local jobLocations = {
    npc = {x = 150.86165, y = -287.66144, z = 1.57812}, -- NPC munkafelvételhez
    spawn = {x = 68.74153, y = -236.01837, z = 1.57237}, -- Kamion spawn
    loading = {x = 64.61997, y = -279.76141, z = 1.57812}, -- Felrakodás
    delivery = {x = 312.23898, y = -241.56963, z = 1.57812} -- Szállítás
}

-- ==============================
-- KAMION TÍPUSOK
-- ==============================
local truckTypes = {
    {
        name = "Tejszállító Kamion",
        model = 456, -- Flatbed
        capacity = 1000,
        payment = 5000,
        fuel_usage = 15,
        icon = "🥛",
        description = "Nagy tejszállító kamion\nKapacitás: 1000L\nFizetés: €5,000"
    },
    {
        name = "Gyors Tejkiszállító", 
        model = 456,
        capacity = 500,
        payment = 3000,
        fuel_usage = 10,
        icon = "🚛",
        description = "Gyors kis tejkiszállító\nKapacitás: 500L\nFizetés: €3,000"
    },
    {
        name = "Mega Tejszállító",
        model = 456,
        capacity = 2000,
        payment = 8000,
        fuel_usage = 25,
        icon = "🏭",
        description = "Óriás tejszállító kamion\nKapacitás: 2000L\nFizetés: €8,000"
    }
}

-- ==============================
-- NPC BESZÉLGETÉSEK
-- ==============================
local npcDialogues = {
    idle = {
        "Szia! Szeretnél tejszállítási munkát vállalni?",
        "Van szabad kamion, ha érdekel a munka!",
        "Jó fizetés vár a tejszállításért!",
        "Kell egy megbízható sofőr tejszállításra!"
    },
    working = {
        "Látom van aktív munkád! Hajrá!",
        "A kamion várja, hogy elvidd a tejet!",
        "Siess, a tej nem vár!",
        "Biztos vagyok benne, hogy jól fogod csinálni!"
    },
    completed = {
        "Szuper munka volt! Vállalsz újat?",
        "Kiváló szállítás! Újra mehet?",
        "Profi vagy! Kell még egy kör?",
        "Tökéletes volt! Folytatjuk?"
    }
}

-- ==============================
-- GUI DESIGN KONFIGURÁCIÓ
-- ==============================
local guiConfig = {
    panel = {
        x = screenWidth/2 - 200,
        y = screenHeight/2 - 150,
        width = 400,
        height = 300
    },
    colors = {
        background = {10, 15, 10, 240},
        panel = {25, 35, 25, 220},
        accent = {10, 126, 18, 255},
        text = {255, 255, 255, 255},
        button = {15, 100, 15, 255},
        buttonHover = {20, 150, 20, 255},
        glow = {10, 126, 18, 100}
    }
}

-- ==============================
-- GLOBÁLIS VÁLTOZÓK
-- ==============================
local truckingNPC = nil
local currentDialogue = ""
local dialogueTimer = 0

-- ==============================
-- NPC ÉS MARKEREK LÉTREHOZÁSA
-- ==============================
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- NPC munkafelvételhez
    truckingNPC = createPed(61, jobLocations.npc.x, jobLocations.npc.y, jobLocations.npc.z)
    setPedRotation(truckingNPC, 180)
    setElementFrozen(truckingNPC, true)
    setElementData(truckingNPC, "trucking_npc", true)
    setElementData(truckingNPC, "clickable", true)
    
    -- CSAK MUNKÁHOZ SZÜKSÉGES MARKEREK (nem zavaró)
    createMarker(jobLocations.loading.x, jobLocations.loading.y, jobLocations.loading.z - 1, "cylinder", 4.0, 255, 165, 0, 120)
    createMarker(jobLocations.delivery.x, jobLocations.delivery.y, jobLocations.delivery.z - 1, "cylinder", 4.0, 255, 50, 50, 120)
    
    -- Blip az NPC-hez
    createBlipAttachedToElement(truckingNPC, 56) -- Munkahely ikon
    
    -- NPC beszélgetés timer
    setTimer(updateNPCDialogue, 5000, 0) -- 5 másodpercenként új beszéd
    
    outputChatBox("🚛 Kamionos munka rendszer betöltve!", 10, 126, 18)
    outputChatBox("💡 Menj az NPC-hez és kattints rá a munkához!", 255, 255, 0)
end)

-- ==============================
-- NPC BESZÉLGETÉS FRISSÍTÉS
-- ==============================
function updateNPCDialogue()
    local playerX, playerY, playerZ = getElementPosition(localPlayer)
    local npcDist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, jobLocations.npc.x, jobLocations.npc.y, jobLocations.npc.z)
    
    if npcDist < 15 then -- Ha közelben van a játékos
        local dialogues
        
        if truckingJob.stage == "idle" then
            dialogues = npcDialogues.idle
        elseif truckingJob.stage == "selected" or truckingJob.stage == "loading" or truckingJob.stage == "delivering" then
            dialogues = npcDialogues.working
        else
            dialogues = npcDialogues.idle
        end
        
        currentDialogue = dialogues[math.random(1, #dialogues)]
        dialogueTimer = getTickCount()
    end
end

-- ==============================
-- NPC KATTINTÁS KEZELÉS
-- ==============================
addEventHandler("onClientElementClicked", root, function(button, state, player)
    if button == "left" and state == "down" and player == localPlayer then
        if source == truckingNPC then
            local playerX, playerY, playerZ = getElementPosition(localPlayer)
            local npcDist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, jobLocations.npc.x, jobLocations.npc.y, jobLocations.npc.z)
            
            if npcDist < 5 then
                if truckingJob.stage == "idle" then
                    showTruckSelectionPanel()
                    outputChatBox("👨‍💼 NPC: Válassz egy kamion típust a munkához!", 10, 126, 18)
                else
                    outputChatBox("👨‍💼 NPC: " .. currentDialogue, 10, 126, 18)
                end
            else
                outputChatBox("❌ Menj közelebb az NPC-hez!", 255, 100, 100)
            end
        end
    end
end)

-- ==============================
-- LEKEREKÍTETT TÉGLALAP RAJZOLÁS
-- ==============================
function drawRoundedRectangle(x, y, width, height, radius, color)
    radius = math.min(radius, width/2, height/2)
    
    -- Fő téglalap
    dxDrawRectangle(x + radius, y, width - radius * 2, height, color, false)
    dxDrawRectangle(x, y + radius, width, height - radius * 2, color, false)
    
    -- Sarkok
    local segments = 8
    local corners = {
        {x + radius, y + radius, math.pi, math.pi * 1.5},
        {x + width - radius, y + radius, math.pi * 1.5, math.pi * 2},
        {x + width - radius, y + height - radius, 0, math.pi * 0.5},
        {x + radius, y + height - radius, math.pi * 0.5, math.pi}
    }
    
    for _, corner in ipairs(corners) do
        local cx, cy, startAngle, endAngle = corner[1], corner[2], corner[3], corner[4]
        for i = 0, segments do
            local angle1 = startAngle + (i / segments) * (endAngle - startAngle)
            local angle2 = startAngle + ((i + 1) / segments) * (endAngle - startAngle)
            
            local x1 = cx + math.cos(angle1) * radius
            local y1 = cy + math.sin(angle1) * radius
            local x2 = cx + math.cos(angle2) * radius
            local y2 = cy + math.sin(angle2) * radius
            
            dxDrawLine(x1, y1, x2, y2, color, 2, false)
        end
    end
end

-- ==============================
-- KAMION KIVÁLASZTÓ PANEL
-- ==============================
function drawTruckSelectionPanel()
    local panel = guiConfig.panel
    local colors = guiConfig.colors
    
    -- Fő panel háttér
    drawRoundedRectangle(panel.x, panel.y, panel.width, panel.height, 15, tocolor(unpack(colors.background)))
    
    -- Panel keret (világosabb)
    drawRoundedRectangle(panel.x - 2, panel.y - 2, panel.width + 4, panel.height + 4, 17, tocolor(unpack(colors.accent)))
    
    -- Header
    drawRoundedRectangle(panel.x + 5, panel.y + 5, panel.width - 10, 40, 10, tocolor(unpack(colors.panel)))
    dxDrawText("🚛 TEJSZÁLLÍTÓ KAMIONOK", panel.x, panel.y + 5, panel.x + panel.width, panel.y + 45, 
        tocolor(unpack(colors.text)), 1.0, "default-bold", "center", "center")
    
    -- Kamion lista
    local startY = panel.y + 60
    local itemHeight = 60
    
    for i, truck in ipairs(truckTypes) do
        local itemY = startY + (i - 1) * (itemHeight + 10)
        local isHovered = isMouseInPosition(panel.x + 10, itemY, panel.width - 20, itemHeight)
        
        -- Item háttér
        local bgColor = isHovered and colors.buttonHover or colors.button
        drawRoundedRectangle(panel.x + 10, itemY, panel.width - 20, itemHeight, 8, tocolor(unpack(bgColor)))
        
        -- Item keret hover esetén
        if isHovered then
            drawRoundedRectangle(panel.x + 8, itemY - 2, panel.width - 16, itemHeight + 4, 10, tocolor(unpack(colors.accent)))
        end
        
        -- Ikon
        dxDrawText(truck.icon, panel.x + 25, itemY + 5, panel.x + 65, itemY + 35, 
            tocolor(unpack(colors.text)), 2.0, "default", "center", "center")
        
        -- Kamion neve
        dxDrawText(truck.name, panel.x + 70, itemY + 5, panel.x + panel.width - 20, itemY + 25, 
            tocolor(unpack(colors.text)), 0.9, "default-bold", "left", "center")
        
        -- Leírás
        dxDrawText(truck.description, panel.x + 70, itemY + 25, panel.x + panel.width - 20, itemY + 55, 
            tocolor(unpack(colors.text)), 0.7, "default", "left", "top")
        
        -- Kattintás kezelés
        if isHovered and getKeyState("mouse1") and not wasMousePressed then
            truckingJob.selectedTruck = i
            truckingJob.jobData = truck
            spawnTruck(truck)
            hideTruckSelectionPanel()
            wasMousePressed = true
        end
    end
    
    -- Bezárás gomb
    local closeY = panel.y + panel.height - 45
    local isCloseHovered = isMouseInPosition(panel.x + panel.width - 45, closeY, 35, 35)
    local closeColor = isCloseHovered and colors.buttonHover or colors.button
    
    drawRoundedRectangle(panel.x + panel.width - 45, closeY, 35, 35, 5, tocolor(unpack(closeColor)))
    dxDrawText("✖", panel.x + panel.width - 45, closeY, panel.x + panel.width - 10, closeY + 35, 
        tocolor(unpack(colors.text)), 1.0, "default-bold", "center", "center")
    
    if isCloseHovered and getKeyState("mouse1") and not wasMousePressed then
        hideTruckSelectionPanel()
        wasMousePressed = true
    end
end

-- ==============================
-- KAMION SPAWN RENDSZER (JAVÍTOTT)
-- ==============================
function spawnTruck(truckData)
    local spawn = jobLocations.spawn
    
    -- Régi kamion törlése ha van
    if truckingJob.currentTruck and isElement(truckingJob.currentTruck) then
        destroyElement(truckingJob.currentTruck)
    end
    
    -- Új kamion létrehozása
    truckingJob.currentTruck = createVehicle(truckData.model, spawn.x, spawn.y, spawn.z, 0, 0, 90)
    setElementData(truckingJob.currentTruck, "truck_job", true)
    setElementData(truckingJob.currentTruck, "capacity", truckData.capacity)
    setElementData(truckingJob.currentTruck, "fuel", 100)
    
    -- Kamion tulajdonságok beállítása (javítás a beszálláshoz)
    setVehicleDamageProof(truckingJob.currentTruck, false)
    setVehicleLocked(truckingJob.currentTruck, false) -- Biztosítjuk hogy nem zárva van
    setElementFrozen(truckingJob.currentTruck, false) -- Nem befagyasztva
    
    -- Blip a kamionhoz
    local blip = createBlipAttachedToElement(truckingJob.currentTruck, 51)
    setBlipColor(blip, 255)
    setElementData(blip, "truck_blip", true)
    
    truckingJob.stage = "selected"
    
    outputChatBox("🚛 " .. truckData.name .. " lehívva!", 10, 126, 18)
    outputChatBox("📍 Menj a kamionhoz és szállj be! (sárga blip)", 255, 255, 0)
    outputChatBox("📦 Aztán menj a felrakodó helyre! (narancssárga marker)", 255, 165, 0)
    
    -- NPC reakció
    currentDialogue = "Szuper! A kamion készen áll. Menj és szállj be!"
    updateNPCDialogue()
end

-- ==============================
-- FELRAKODÁSI RENDSZER
-- ==============================
function startLoading()
    if truckingJob.stage ~= "selected" then return end
    
    truckingJob.stage = "loading"
    truckingJob.loadingProgress = 0
    
    outputChatBox("📦 Tejek felrakodása megkezdődött...", 10, 126, 18)
    outputChatBox("⏰ Várd meg míg befejeződik a felrakodás!", 255, 255, 0)
    
    -- Loading timer
    setTimer(function()
        if truckingJob.stage == "loading" then
            truckingJob.loadingProgress = truckingJob.loadingProgress + 2
            
            if truckingJob.loadingProgress >= 100 then
                finishLoading()
            end
        end
    end, 100, 50) -- 5 másodperc alatt
end

function finishLoading()
    truckingJob.stage = "delivering"
    truckingJob.loadingProgress = 100
    
    outputChatBox("✅ Felrakodás kész! Szállítsd el a tejeket a célállomásra!", 10, 126, 18)
    outputChatBox("🏪 Kövesd a piros blipet a térképen!", 255, 50, 50)
    
    -- Blip a célállomáshoz
    local deliveryBlip = createBlip(jobLocations.delivery.x, jobLocations.delivery.y, jobLocations.delivery.z, 19)
    setBlipColor(deliveryBlip, 255)
    setElementData(deliveryBlip, "delivery_blip", true)
    
    -- NPC reakció
    currentDialogue = "Kiváló! Most szállítsd el a tejeket a célállomásra!"
end

-- ==============================
-- FELRAKODÁSI PROGRESS BAR
-- ==============================
function drawLoadingProgress()
    if truckingJob.stage ~= "loading" then return end
    
    local colors = guiConfig.colors
    local barX = screenWidth/2 - 150
    local barY = screenHeight - 100
    local barWidth = 300
    local barHeight = 20
    
    -- Háttér panel
    drawRoundedRectangle(barX - 20, barY - 40, barWidth + 40, 80, 10, tocolor(unpack(colors.background)))
    
    -- Progress bar háttér
    drawRoundedRectangle(barX, barY, barWidth, barHeight, 8, tocolor(50, 50, 50, 200))
    
    -- Progress bar töltés
    local fillWidth = (barWidth * truckingJob.loadingProgress) / 100
    if fillWidth > 0 then
        drawRoundedRectangle(barX, barY, fillWidth, barHeight, 8, tocolor(unpack(colors.accent)))
    end
    
    -- Progress szöveg
    dxDrawText("📦 Tejek felrakodása: " .. math.floor(truckingJob.loadingProgress) .. "%", 
        barX, barY - 25, barX + barWidth, barY - 5, 
        tocolor(unpack(colors.text)), 0.9, "default-bold", "center", "center")
    
    -- Stamina ikon
    dxDrawText("🥛", barX - 40, barY - 10, barX - 10, barY + 30, 
        tocolor(unpack(colors.text)), 2.0, "default", "center", "center")
end

-- ==============================
-- SZÁLLÍTÁS BEFEJEZÉSE
-- ==============================
function completeDelivery()
    if truckingJob.stage ~= "delivering" then return end
    
    local payment = truckingJob.jobData.payment
    triggerServerEvent("giveTruckingPayment", localPlayer, payment)
    triggerServerEvent("checkTruckingRankUp", localPlayer)
    
    -- Kamion eltüntetése
    if isElement(truckingJob.currentTruck) then
        destroyElement(truckingJob.currentTruck)
    end
    
    -- Blipek eltávolítása
    for _, element in ipairs(getElementsByType("blip")) do
        if getElementData(element, "delivery_blip") or getElementData(element, "truck_blip") then
            destroyElement(element)
        end
    end
    
    -- Reset
    truckingJob.active = false
    truckingJob.selectedTruck = nil
    truckingJob.currentTruck = nil
    truckingJob.stage = "idle"
    truckingJob.loadingProgress = 0
    
    outputChatBox("💰 Szállítás befejezve! Fizetés: €" .. formatNumber(payment), 10, 126, 18)
    outputChatBox("🎉 Remek munka! Újra dolgozhatsz az NPC-nél!", 255, 215, 0)
    
    -- NPC reakció
    currentDialogue = "Fantasztikus munka! Szeretnél újat vállalni?"
end

-- ==============================
-- MARKER ESEMÉNYEK (JAVÍTOTT)
-- ==============================
addEventHandler("onClientMarkerHit", root, function(player, matchingDimension)
    if player ~= localPlayer then return end
    
    local x, y, z = getElementPosition(source)
    
    -- Felrakodó marker
    if getDistanceBetweenPoints3D(x, y, z, jobLocations.loading.x, jobLocations.loading.y, jobLocations.loading.z) < 5 then
        if truckingJob.stage == "selected" and isPedInVehicle(localPlayer) then
            local vehicle = getPedOccupiedVehicle(localPlayer)
            if vehicle == truckingJob.currentTruck then
                startLoading()
            else
                outputChatBox("❌ A saját kamionoddal kell idejönnöd!", 255, 100, 100)
            end
        elseif truckingJob.stage == "selected" then
            outputChatBox("💡 Szállj be a kamionba először!", 255, 255, 0)
        end
    end
    
    -- Szállítási marker
    if getDistanceBetweenPoints3D(x, y, z, jobLocations.delivery.x, jobLocations.delivery.y, jobLocations.delivery.z) < 5 then
        if truckingJob.stage == "delivering" and isPedInVehicle(localPlayer) then
            local vehicle = getPedOccupiedVehicle(localPlayer)
            if vehicle == truckingJob.currentTruck then
                completeDelivery()
            else
                outputChatBox("❌ A saját kamionoddal kell idejönnöd!", 255, 100, 100)
            end
        elseif truckingJob.stage == "delivering" then
            outputChatBox("💡 A kamionnal kell idejönnöd!", 255, 255, 0)
        end
    end
end)

-- ==============================
-- GUI VEZÉRLÉS
-- ==============================
local showPanel = false
local wasMousePressed = false

function showTruckSelectionPanel()
    showPanel = true
    truckingJob.active = true
    showCursor(true)
end

function hideTruckSelectionPanel()
    showPanel = false
    showCursor(false)
end

function isMouseInPosition(x, y, width, height)
    if not isCursorShowing() then return false end
    local cx, cy = getCursorPosition()
    cx, cy = cx * screenWidth, cy * screenHeight
    return cx >= x and cx <= x + width and cy >= y and cy <= y + height
end

-- ==============================
-- SEGÉD FUNKCIÓK
-- ==============================
function formatNumber(num)
    local formatted = tostring(num)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- ==============================
-- RENDERELÉS
-- ==============================
addEventHandler("onClientRender", root, function()
    if showPanel then
        drawTruckSelectionPanel()
    end
    
    drawLoadingProgress()
    
    -- Mouse pressed state reset
    if not getKeyState("mouse1") then
        wasMousePressed = false
    end
end)

-- ==============================
-- 3D SZÖVEGEK ÉS KOMMUNIKÁCIÓ
-- ==============================
addEventHandler("onClientRender", root, function()
    local playerX, playerY, playerZ = getElementPosition(localPlayer)
    
    -- NPC kommunikáció és interakció
    local npcDist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, jobLocations.npc.x, jobLocations.npc.y, jobLocations.npc.z)
    if npcDist < 15 then
        -- NPC neve és alapinfó
        dxDrawText3D("👨‍💼 TEJSZÁLLÍTÓ FŐNÖK\n💼 Kattints rám a munkához!", 
            jobLocations.npc.x, jobLocations.npc.y, jobLocations.npc.z + 1.2, 15, tocolor(10, 126, 18, 255))
        
        -- Folyamatos beszélgetés
        if currentDialogue ~= "" and npcDist < 8 then
            dxDrawText3D("💬 \"" .. currentDialogue .. "\"", 
                jobLocations.npc.x, jobLocations.npc.y, jobLocations.npc.z + 2.0, 12, tocolor(255, 255, 255, 255))
        end
    end
    
    -- Felrakodó hely szöveg
    if truckingJob.stage == "selected" then
        local loadDist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, jobLocations.loading.x, jobLocations.loading.y, jobLocations.loading.z)
        if loadDist < 15 then
            dxDrawText3D("📦 FELRAKODÓ RAKTÁR\n🥛 Hajts ide a kamionnal", 
                jobLocations.loading.x, jobLocations.loading.y, jobLocations.loading.z + 1.5, 20, tocolor(255, 165, 0, 255))
        end
    end
    
    -- Szállítási hely szöveg
    if truckingJob.stage == "delivering" then
        local deliveryDist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, jobLocations.delivery.x, jobLocations.delivery.y, jobLocations.delivery.z)
        if deliveryDist < 15 then
            dxDrawText3D("🏪 CÉLÁLLOMÁS\n💰 Szállítsd le a tejeket", 
                jobLocations.delivery.x, jobLocations.delivery.y, jobLocations.delivery.z + 1.5, 20, tocolor(255, 50, 50, 255))
        end
    end
    
    -- Kamion helyzet mutatása
    if truckingJob.currentTruck and isElement(truckingJob.currentTruck) and truckingJob.stage == "selected" then
        local truckX, truckY, truckZ = getElementPosition(truckingJob.currentTruck)
        local truckDist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, truckX, truckY, truckZ)
        if truckDist < 15 then
            dxDrawText3D("🚛 KAMIONOD\n🔑 Szállj be!", 
                truckX, truckY, truckZ + 1.5, 15, tocolor(255, 255, 0, 255))
        end
    end
end)

-- ==============================
-- 3D SZÖVEG RAJZOLÓ FÜGGVÉNY
-- ==============================
function dxDrawText3D(text, x, y, z, distance, color)
    local playerX, playerY, playerZ = getElementPosition(localPlayer)
    local dist = getDistanceBetweenPoints3D(playerX, playerY, playerZ, x, y, z)
    
    if dist < distance then
        local screenX, screenY = getScreenFromWorldPosition(x, y, z + 0.5)
        if screenX and screenY then
            local scale = 1 - (dist / distance)
            dxDrawText(text, screenX, screenY, screenX, screenY, color, scale, "default-bold", "center", "center", false, false, true)
        end
    end
end 