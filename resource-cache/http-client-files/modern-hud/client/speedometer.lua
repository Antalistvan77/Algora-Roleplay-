-- ==============================
-- PRÉMIUM AUTÓS SEBESSÉGMÉRŐ
-- ==============================

local speedometerVisible = false
local currentVehicle = nil
local speedometerData = {}

-- ==============================
-- AUTÓS SEBESSÉGMÉRŐ DESIGN
-- ==============================
local speedometerConfig = {
    -- Pozíció és méret (jobb alsó sarok)
    x = screenWidth - 250,
    y = screenHeight - 250,
    width = 230,
    height = 230,
    
    -- Körös sebességmérő középpont
    centerX = screenWidth - 135,
    centerY = screenHeight - 135,
    radius = 100,
    
    -- Új autós színpaletta - R:70 G:137 B:12
    colors = {
        background = {10, 15, 5, 240},        -- Sötét zöld háttér
        dial = {25, 35, 10, 255},            -- Sötét zöld dial
        primary = {70, 137, 12, 255},         -- Új zöld szín
        secondary = {50, 100, 8, 200},        -- Sötétebb zöld
        accent = {90, 170, 20, 255},          -- Világosabb zöld
        needle = {220, 50, 50, 255},          -- Piros tű
        text = {255, 255, 255, 255},          -- Fehér szöveg
        numbers = {200, 200, 200, 255},       -- Szürke számok
        glow = {70, 137, 12, 150},           -- Glow hatás
        shadow = {0, 0, 0, 200},             -- Árnyék
        glass = {35, 60, 10, 100},           -- Üveg zöld
        fuel = {255, 165, 0, 255},           -- Narancs üzemanyag
        warning = {255, 100, 0, 255}         -- Figyelmeztetés
    },
    
    -- Beállítások
    maxSpeed = 280,
    animations = {
        breathe = 0,
        pulse = 0,
        needleSmooth = 0
    },
    
    -- Ikonok
    icons = {
        fuel = "⛽",
        engine = "🔧",
        speed = "🏁",
        condition = "⚙️"
    }
}

-- ==============================
-- LEKEREKÍTETT KÖR RAJZOLÓ
-- ==============================
function drawCircle(x, y, radius, color, segments, thickness)
    segments = segments or 32
    thickness = thickness or 2
    
    for i = 0, segments - 1 do
        local angle1 = (i / segments) * 2 * math.pi
        local angle2 = ((i + 1) / segments) * 2 * math.pi
        
        local x1 = x + math.cos(angle1) * radius
        local y1 = y + math.sin(angle1) * radius
        local x2 = x + math.cos(angle2) * radius
        local y2 = y + math.sin(angle2) * radius
        
        dxDrawLine(x1, y1, x2, y2, color, thickness, false)
    end
end

-- ==============================
-- LEKEREKÍTETT TÉGLALAP (speedometer)
-- ==============================
function drawRoundedRect(x, y, width, height, radius, color)
    -- Fő téglalap
    dxDrawRectangle(x + radius, y, width - radius * 2, height, color, false)
    dxDrawRectangle(x, y + radius, width, height - radius * 2, color, false)
    
    -- Sarkok
    local segments = 6
    for corner = 1, 4 do
        local cornerX, cornerY, startAngle
        if corner == 1 then -- Bal felső
            cornerX, cornerY, startAngle = x + radius, y + radius, math.pi
        elseif corner == 2 then -- Jobb felső  
            cornerX, cornerY, startAngle = x + width - radius, y + radius, 3 * math.pi / 2
        elseif corner == 3 then -- Jobb alsó
            cornerX, cornerY, startAngle = x + width - radius, y + height - radius, 0
        else -- Bal alsó
            cornerX, cornerY, startAngle = x + radius, y + height - radius, math.pi / 2
        end
        
        for i = 0, segments do
            local angle1 = startAngle + (i / segments) * (math.pi / 2)
            local angle2 = startAngle + ((i + 1) / segments) * (math.pi / 2)
            
            local x1 = cornerX + math.cos(angle1) * radius
            local y1 = cornerY + math.sin(angle1) * radius
            local x2 = cornerX + math.cos(angle2) * radius
            local y2 = cornerY + math.sin(angle2) * radius
            
            dxDrawLine(x1, y1, x2, y2, color, 2, false)
        end
    end
end

-- ==============================
-- ANIMÁCIÓK FRISSÍTÉSE
-- ==============================
function updateSpeedometerAnimations()
    local time = getTickCount()
    speedometerConfig.animations.breathe = math.sin(time * 0.002) * 0.3 + 0.7
    speedometerConfig.animations.pulse = math.sin(time * 0.004) * 0.4 + 0.6
end

-- ==============================
-- PRÉMIUM AUTÓS SEBESSÉGMÉRŐ KERET
-- ==============================
function drawAutomotiveFrame(x, y, width, height)
    local colors = speedometerConfig.colors
    local centerX, centerY = speedometerConfig.centerX, speedometerConfig.centerY
    local radius = speedometerConfig.radius
    
    -- Külső árnyék (mély)
    drawCircle(centerX + 3, centerY + 3, radius + 20, tocolor(0, 0, 0, 120), 64, 6)
    drawCircle(centerX + 2, centerY + 2, radius + 15, tocolor(0, 0, 0, 80), 48, 4)
    
    -- Fő háttér kör
    drawCircle(centerX, centerY, radius + 15, tocolor(unpack(colors.background)), 64, 20)
    
    -- Belső dial háttér
    drawCircle(centerX, centerY, radius + 5, tocolor(unpack(colors.dial)), 48, 15)
    
    -- Üveg hatás (zöld)
    drawCircle(centerX, centerY, radius + 10, tocolor(unpack(colors.glass)), 32, 3)
    
    -- Külső neonfény keret (új zöld)
    local glow = speedometerConfig.animations.pulse
    local glowAlpha = math.floor(colors.primary[4] * glow)
    drawCircle(centerX, centerY, radius + 12, tocolor(colors.primary[1], colors.primary[2], colors.primary[3], glowAlpha), 64, 2)
    
    -- Belső accent kör
    drawCircle(centerX, centerY, radius - 75, tocolor(unpack(colors.secondary)), 32, 1)
end

-- ==============================
-- PRÉMIUM AUTÓS SEBESSÉGMÉRŐ SZÁMLAP
-- ==============================
function drawAutomotiveSpeedometer(speed)
    local config = speedometerConfig
    local colors = config.colors
    local centerX, centerY = config.centerX, config.centerY
    local radius = config.radius
    
    -- Fő keret
    drawAutomotiveFrame(config.x, config.y, config.width, config.height)
    
    -- Sebesség skála (0-280 km/h, 270 fokos ív)
    local startAngle = 135 -- balról indítva
    local totalAngle = 270 -- 270 fokos ív
    local majorTicks = 14  -- 0, 20, 40, 60... 280
    
    for i = 0, majorTicks do
        local speedValue = i * 20
        local angle = startAngle + (i / majorTicks) * totalAngle
        local radians = math.rad(angle)
        
        -- Nagy vonások (20-as értékek)
        local innerRadius = radius - 5
        local outerRadius = radius + 8
        
        local x1 = centerX + math.cos(radians) * innerRadius
        local y1 = centerY + math.sin(radians) * innerRadius
        local x2 = centerX + math.cos(radians) * outerRadius
        local y2 = centerY + math.sin(radians) * outerRadius
        
        -- Főbb vonások zöld vagy piros
        local tickColor = speedValue <= 200 and colors.primary or colors.needle
        dxDrawLine(x1, y1, x2, y2, tocolor(unpack(tickColor)), 3, false)
        
        -- Számok
        if speedValue % 40 == 0 then  -- csak minden második szám
            local textRadius = radius + 25
            local textX = centerX + math.cos(radians) * textRadius
            local textY = centerY + math.sin(radians) * textRadius
            
            dxDrawText(tostring(speedValue), textX - 15, textY - 8, textX + 15, textY + 8, 
                tocolor(unpack(colors.numbers)), 1.0, "default-bold", "center", "center")
        end
        
        -- Kis vonások (10-es értékek között)
        if i < majorTicks then
            local smallAngle = startAngle + ((i + 0.5) / majorTicks) * totalAngle
            local smallRadians = math.rad(smallAngle)
            
            local sx1 = centerX + math.cos(smallRadians) * (innerRadius + 5)
            local sy1 = centerY + math.sin(smallRadians) * (innerRadius + 5)
            local sx2 = centerX + math.cos(smallRadians) * outerRadius
            local sy2 = centerY + math.sin(smallRadians) * outerRadius
            
            dxDrawLine(sx1, sy1, sx2, sy2, tocolor(unpack(colors.secondary)), 1, false)
        end
    end
    
    -- Központi digitális kijelző (lekerekített)
    local speedText = tostring(math.floor(speed))
    local digitalW, digitalH = 85, 35
    local digitalX = centerX - digitalW/2
    local digitalY = centerY + 10
    
    drawRoundedRect(digitalX, digitalY, digitalW, digitalH, 6, tocolor(0, 0, 0, 200))
    drawRoundedRect(digitalX + 1, digitalY + 1, digitalW - 2, digitalH - 2, 5, tocolor(unpack(colors.dial)))
    drawRoundedRect(digitalX, digitalY, digitalW, digitalH, 6, tocolor(unpack(colors.primary)))
    
    -- Sebesség szám
    dxDrawText(speedText, digitalX, digitalY + 3, digitalX + digitalW, digitalY + digitalH - 10, 
        tocolor(unpack(colors.primary)), 1.5, "default-bold", "center", "center")
    
    -- KM/H felirat
    dxDrawText("KM/H", digitalX, digitalY + digitalH - 12, digitalX + digitalW, digitalY + digitalH, 
        tocolor(unpack(colors.text)), 0.7, "default", "center", "center")
    
    -- Sebességmérő tű
    drawAutomotiveNeedle(speed, centerX, centerY, radius - 10)
    
    -- Központi csavar (zöld árnyalatokkal)
    drawCircle(centerX, centerY, 8, tocolor(unpack(colors.dial)), 16, 10)
    drawCircle(centerX, centerY, 5, tocolor(unpack(colors.accent)), 12, 6)
    drawCircle(centerX, centerY, 2, tocolor(unpack(colors.text)), 8, 2)
end

-- ==============================
-- PRÉMIUM PIROS TŰ RAJZOLÁS
-- ==============================
function drawAutomotiveNeedle(speed, centerX, centerY, needleLength)
    local config = speedometerConfig
    local colors = config.colors
    
    -- Tű szög kiszámítása (0-280 km/h -> 135° to 405°, de 270° ív)
    local startAngle = 135
    local totalAngle = 270
    local percentage = math.min(speed / config.maxSpeed, 1.0)
    local angle = startAngle + (percentage * totalAngle)
    local radians = math.rad(angle)
    
    -- Tű végpontjai
    local needleX = centerX + math.cos(radians) * needleLength
    local needleY = centerY + math.sin(radians) * needleLength
    
    -- Tű háttér (vastagabb árnyék)
    dxDrawLine(centerX + 1, centerY + 1, needleX + 1, needleY + 1, tocolor(0, 0, 0, 150), 6, false)
    
    -- Fő tű (piros)
    dxDrawLine(centerX, centerY, needleX, needleY, tocolor(unpack(colors.needle)), 4, false)
    
    -- Tű fénye
    dxDrawLine(centerX, centerY, needleX, needleY, tocolor(255, 255, 255, 100), 2, false)
    
    -- Tű vége
    drawCircle(needleX, needleY, 3, tocolor(unpack(colors.needle)), 8, 4)
end

-- ==============================
-- PRÉMIUM JÁRMŰ INFO PANEL
-- ==============================
function drawVehicleInfoPanel(data)
    local config = speedometerConfig
    local colors = config.colors
    local icons = config.icons
    local panelX = config.x + 10
    local panelY = config.y + 10
    local panelW = 95
    local panelH = 75
    
    -- Info panel háttér (lekerekített)
    drawRoundedRect(panelX, panelY, panelW, panelH, 6, tocolor(unpack(colors.background)))
    drawRoundedRect(panelX + 1, panelY + 1, panelW - 2, panelH - 2, 5, tocolor(unpack(colors.dial)))
    
    -- Keret (lekerekített)
    drawRoundedRect(panelX, panelY, panelW, panelH, 6, tocolor(unpack(colors.primary)))
    
    -- Jármű név ikonnal
    local vehicleName = string.upper(data.vehicleName or "UNKNOWN")
    if string.len(vehicleName) > 7 then
        vehicleName = string.sub(vehicleName, 1, 7)
    end
    local vehicleText = icons.speed .. " " .. vehicleName
    dxDrawText(vehicleText, panelX + 3, panelY + 5, panelX + panelW - 3, panelY + 18, 
        tocolor(unpack(colors.text)), 0.65, "default-bold", "center", "center")
    
    -- Motor státusz LED ikonnal
    local engineColor = data.engine and colors.primary or colors.needle
    local engineStatus = data.engine and "ON" or "OFF"
    local engineText = icons.engine .. " " .. engineStatus
    dxDrawText(engineText, panelX + 3, panelY + 20, panelX + panelW - 3, panelY + 32, 
        tocolor(unpack(engineColor)), 0.6, "default-bold", "center", "center")
    
    -- Fuel gauge (lekerekített kis bar)
    local fuelY = panelY + 38
    local fuelW = panelW - 10
    local fuelH = 10
    local fuelX = panelX + 5
    
    drawAutomotiveFuelGauge(fuelX, fuelY, fuelW, fuelH, data.fuel)
    
    -- Condition ikonnal
    local healthPercent = math.floor((data.health / 1000) * 100)
    local healthColor = healthPercent > 75 and colors.primary or 
                       healthPercent > 40 and colors.accent or colors.needle
    local condText = icons.condition .. " " .. healthPercent .. "%"
    dxDrawText(condText, panelX + 3, panelY + 55, panelX + panelW - 3, panelY + 68, 
        tocolor(unpack(healthColor)), 0.55, "default", "center", "center")
end

-- ==============================
-- PRÉMIUM LEKEREKÍTETT ÜZEMANYAG
-- ==============================
function drawAutomotiveFuelGauge(x, y, width, height, fuel)
    local colors = speedometerConfig.colors
    local icons = speedometerConfig.icons
    local percentage = fuel / 100
    
    -- Háttér (lekerekített)
    drawRoundedRect(x, y, width, height, 4, tocolor(0, 0, 0, 200))
    drawRoundedRect(x + 1, y + 1, width - 2, height - 2, 3, tocolor(unpack(colors.dial)))
    
    -- Fuel bar (lekerekített)
    local fuelWidth = (width - 4) * percentage
    local fuelColor = fuel > 25 and colors.fuel or colors.needle
    
    if fuelWidth > 6 then
        drawRoundedRect(x + 2, y + 2, fuelWidth, height - 4, 2, tocolor(unpack(fuelColor)))
        
        -- Highlight
        drawRoundedRect(x + 2, y + 2, fuelWidth, 1, 2, tocolor(255, 255, 255, 150))
    end
    
    -- Border (lekerekített)
    drawRoundedRect(x, y, width, height, 4, tocolor(unpack(colors.secondary)))
    
    -- Fuel text ikonnal
    local fuelText = icons.fuel .. " " .. math.floor(fuel) .. "%"
    dxDrawText(fuelText, x, y - 12, x + width, y - 2, 
        tocolor(unpack(colors.text)), 0.5, "default", "center", "center")
end

-- ==============================
-- JÁRMŰBE BESZÁLLÁS/KISZÁLLÁS
-- ==============================
addEventHandler("onClientVehicleEnter", root, function(player, seat)
    if player == localPlayer and seat == 0 then
        currentVehicle = source
        speedometerVisible = true
        
        -- Animáció timer
        setTimer(updateSpeedometerAnimations, 16, 0) -- 60 FPS
        
        outputChatBox("🚗 Premium sebességmérő aktiválva!", 70, 137, 12)
    end
end)

addEventHandler("onClientVehicleExit", root, function(player, seat)
    if player == localPlayer then
        speedometerVisible = false
        currentVehicle = nil
    end
end)

-- ==============================
-- JÁRMŰ ADATOK FRISSÍTÉSE
-- ==============================
function updateVehicleData()
    if not currentVehicle then return end
    
    local vx, vy, vz = getElementVelocity(currentVehicle)
    local speed = math.floor((vx^2 + vy^2 + vz^2)^0.5 * 180) -- km/h konvertálás
    
    speedometerData = {
        speed = speed,
        fuel = getElementData(currentVehicle, "fuel") or 100,
        engine = getVehicleEngineState(currentVehicle),
        vehicleName = getVehicleName(currentVehicle),
        health = getElementHealth(currentVehicle),
        locked = isVehicleLocked(currentVehicle)
    }
end

-- ==============================
-- FŐ SPEEDOMETER RAJZOLÁS
-- ==============================
function drawAutomotiveSpeedometer()
    if not speedometerVisible or not currentVehicle then return end
    
    updateVehicleData()
    updateSpeedometerAnimations()
    
    local config = speedometerConfig
    local data = speedometerData
    
    -- Prémium autós sebességmérő
    drawAutomotiveSpeedometer(data.speed)
    
    -- Jármű info panel
    drawVehicleInfoPanel(data)
    
    -- Soft breathing glow az egész gauge-ra (zöld)
    local breatheAlpha = config.animations.breathe * 20
    drawCircle(config.centerX, config.centerY, config.radius + 15, 
        tocolor(config.colors.glow[1], config.colors.glow[2], config.colors.glow[3], breatheAlpha), 64, 1)
end

-- ==============================
-- PARANCSOK
-- ==============================
addCommandHandler("engine", function()
    if currentVehicle then
        local currentState = getVehicleEngineState(currentVehicle)
        setVehicleEngineState(currentVehicle, not currentState)
        
        local stateText = currentState and "🔴 OFF" or "🟢 ON"
        outputChatBox("Engine: " .. stateText, 70, 137, 12)
    else
        outputChatBox("❌ Not in vehicle!", 255, 100, 100)
    end
end)

-- ==============================
-- ÜZEMANYAG RENDSZER
-- ==============================
setTimer(function()
    if currentVehicle and getVehicleEngineState(currentVehicle) then
        local currentFuel = getElementData(currentVehicle, "fuel") or 100
        local vx, vy, vz = getElementVelocity(currentVehicle)
        local speed = (vx^2 + vy^2 + vz^2)^0.5 * 180
        
        -- Üzemanyag fogyasztás
        local consumption = 0.008 + (speed / 15000)
        local newFuel = math.max(0, currentFuel - consumption)
        
        setElementData(currentVehicle, "fuel", newFuel)
        
        -- Motor leállítása ha nincs üzemanyag
        if newFuel <= 0 then
            setVehicleEngineState(currentVehicle, false)
            outputChatBox("⛽ No Fuel!", 255, 100, 100)
        elseif newFuel <= 15 then
            outputChatBox("⚠️ Low Fuel!", 255, 200, 0)
        end
    end
end, 1000, 0)

-- ==============================
-- RENDERELÉS
-- ==============================
addEventHandler("onClientRender", root, function()
    drawAutomotiveSpeedometer()
end) 