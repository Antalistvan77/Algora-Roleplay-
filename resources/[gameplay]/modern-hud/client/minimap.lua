-- ==============================
-- MODERN MINIMAP RENDSZER
-- ==============================

local minimapVisible = true
local minimapData = {}
local playerBlips = {}
local customWaypoint = nil

-- ==============================
-- MINIMAP BEÁLLÍTÁSOK
-- ==============================
local minimapConfig = {
    -- Pozíció és méret
    x = screenWidth - 220,
    y = screenHeight - 170,
    width = 200,
    height = 150,
    
    -- Radar beállítások
    centerX = screenWidth - 120,
    centerY = screenHeight - 95,
    radius = 75,
    
    -- Színek
    colors = {
        background = {0, 0, 0, 180},
        border = {255, 255, 255, 200},
        player = {0, 255, 0, 255},
        vehicle = {255, 255, 0, 255},
        waypoint = {255, 0, 0, 255},
        friendlyPlayer = {0, 0, 255, 255},
        police = {0, 0, 255, 255},
        medic = {255, 255, 255, 255},
        mechanic = {255, 165, 0, 255}
    },
    
    -- Zoom szintek
    zoomLevels = {0.5, 1.0, 1.5, 2.0, 3.0},
    currentZoom = 2,
    
    -- Frissítési gyakoriság
    updateRate = 100
}

-- ==============================
-- MINIMAP INICIALIZÁLÁS
-- ==============================
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Eredeti radar elrejtése
    setPlayerHudComponentVisible("radar", false)
    
    -- Timer indítása
    setTimer(updateMinimap, minimapConfig.updateRate, 0)
    
    outputChatBox("Modern Minimap betöltve! F11 - zoom, F12 - be/ki", 0, 255, 0)
end)

-- ==============================
-- MINIMAP FRISSÍTÉS
-- ==============================
function updateMinimap()
    if not minimapVisible then return end
    
    local player = getLocalPlayer()
    if not player then return end
    
    -- Játékos pozíció és rotáció
    local px, py, pz = getElementPosition(player)
    local _, _, rotation = getElementRotation(player)
    
    minimapData = {
        playerX = px,
        playerY = py,
        playerZ = pz,
        playerRotation = rotation,
        inVehicle = isPedInVehicle(player)
    }
    
    -- Közeli játékosok frissítése
    updateNearbyPlayers()
end

-- ==============================
-- KÖZELI JÁTÉKOSOK FRISSÍTÉSE
-- ==============================
function updateNearbyPlayers()
    playerBlips = {}
    local player = getLocalPlayer()
    local px, py = getElementPosition(player)
    
    for _, otherPlayer in ipairs(getElementsByType("player")) do
        if otherPlayer ~= player then
            local ox, oy = getElementPosition(otherPlayer)
            local distance = getDistanceBetweenPoints2D(px, py, ox, oy)
            
            -- Csak 500 méteren belüli játékosokat mutatjuk
            if distance <= 500 then
                local job = getElementData(otherPlayer, "job") or "civilian"
                local blipColor = getPlayerBlipColor(job)
                
                table.insert(playerBlips, {
                    x = ox,
                    y = oy,
                    name = getPlayerName(otherPlayer),
                    job = job,
                    color = blipColor,
                    inVehicle = isPedInVehicle(otherPlayer)
                })
            end
        end
    end
end

-- ==============================
-- JÁTÉKOS BLIP SZÍN MEGHATÁROZÁSA
-- ==============================
function getPlayerBlipColor(job)
    local colors = minimapConfig.colors
    
    if job == "police" then
        return colors.police
    elseif job == "medic" then
        return colors.medic
    elseif job == "mechanic" then
        return colors.mechanic
    else
        return colors.friendlyPlayer
    end
end

-- ==============================
-- MINIMAP RAJZOLÁSA
-- ==============================
function drawMinimap()
    local config = minimapConfig
    local data = minimapData
    
    -- Háttér
    dxDrawRectangle(config.x - 5, config.y - 5, config.width + 10, config.height + 10, 
        tocolor(unpack(config.colors.background)), false)
    dxDrawRectangle(config.x - 3, config.y - 3, config.width + 6, config.height + 6, 
        tocolor(unpack(config.colors.border)), false)
    
    -- Kör alakú radar terület (maszkolás nélkül, egyszerű kör)
    local centerX, centerY = config.centerX, config.centerY
    local radius = config.radius
    
    -- Játékos pozíció (mindig középen)
    drawPlayerBlip()
    
    -- Közeli játékosok
    drawNearbyPlayers()
    
    -- Waypoint
    if customWaypoint then
        drawWaypoint()
    end
    
    -- Zoom kijelzés
    drawZoomLevel()
    
    -- Iránytű
    drawCompass()
end

-- ==============================
-- JÁTÉKOS BLIP RAJZOLÁSA
-- ==============================
function drawPlayerBlip()
    local config = minimapConfig
    local data = minimapData
    
    local centerX, centerY = config.centerX, config.centerY
    local blipSize = 6
    local color = data.inVehicle and config.colors.vehicle or config.colors.player
    
    -- Játékos blip (háromszög a forgás irányába)
    local rotation = math.rad(data.playerRotation)
    local points = {}
    
    -- Háromszög pontjai
    for i = 0, 2 do
        local angle = rotation + (i * 2 * math.pi / 3)
        local x = centerX + math.sin(angle) * blipSize
        local y = centerY - math.cos(angle) * blipSize
        table.insert(points, {x, y})
    end
    
    -- Háromszög rajzolása (vonalakkal)
    for i = 1, 3 do
        local nextI = i == 3 and 1 or i + 1
        dxDrawLine(points[i][1], points[i][2], points[nextI][1], points[nextI][2], 
            tocolor(unpack(color)), 2, false)
    end
end

-- ==============================
-- KÖZELI JÁTÉKOSOK RAJZOLÁSA
-- ==============================
function drawNearbyPlayers()
    local config = minimapConfig
    local data = minimapData
    local zoom = config.zoomLevels[config.currentZoom]
    
    for _, blip in ipairs(playerBlips) do
        -- Relatív pozíció kiszámítása
        local relativeX = (blip.x - data.playerX) * zoom
        local relativeY = (blip.y - data.playerY) * zoom
        
        -- Képernyő pozíció
        local screenX = config.centerX + relativeX
        local screenY = config.centerY - relativeY -- Y tengely megfordítása
        
        -- Ha a radar területen belül van
        local distance = getDistanceBetweenPoints2D(config.centerX, config.centerY, screenX, screenY)
        if distance <= config.radius then
            local blipSize = blip.inVehicle and 4 or 3
            
            -- Blip rajzolása
            dxDrawRectangle(screenX - blipSize/2, screenY - blipSize/2, blipSize, blipSize, 
                tocolor(unpack(blip.color)), false)
        end
    end
end

-- ==============================
-- WAYPOINT RAJZOLÁSA
-- ==============================
function drawWaypoint()
    if not customWaypoint then return end
    
    local config = minimapConfig
    local data = minimapData
    local zoom = config.zoomLevels[config.currentZoom]
    
    -- Relatív pozíció
    local relativeX = (customWaypoint.x - data.playerX) * zoom
    local relativeY = (customWaypoint.y - data.playerY) * zoom
    
    -- Képernyő pozíció
    local screenX = config.centerX + relativeX
    local screenY = config.centerY - relativeY
    
    -- Waypoint rajzolása (X alakban)
    local size = 8
    dxDrawLine(screenX - size, screenY - size, screenX + size, screenY + size, 
        tocolor(unpack(config.colors.waypoint)), 3, false)
    dxDrawLine(screenX - size, screenY + size, screenX + size, screenY - size, 
        tocolor(unpack(config.colors.waypoint)), 3, false)
end

-- ==============================
-- ZOOM SZINT KIJELZÉSE
-- ==============================
function drawZoomLevel()
    local config = minimapConfig
    local zoomText = "ZOOM: " .. tostring(config.zoomLevels[config.currentZoom]) .. "x"
    
    dxDrawText(zoomText, 
        config.x, config.y - 20, config.x + config.width, config.y, 
        tocolor(255, 255, 255, 200), 
        0.8, "default", "center", "center")
end

-- ==============================
-- IRÁNYTŰ RAJZOLÁSA
-- ==============================
function drawCompass()
    local config = minimapConfig
    local data = minimapData
    
    -- Iránytű pozíció (minimap tetején)
    local compassY = config.y + 10
    local compassX = config.centerX
    
    -- Forgás alapján az irányok
    local rotation = math.rad(data.playerRotation)
    local directions = {"É", "ÉK", "K", "DK", "D", "DNY", "NY", "ÉNY"}
    
    -- Fő irány meghatározása
    local directionIndex = math.floor((data.playerRotation + 22.5) / 45) % 8 + 1
    local currentDirection = directions[directionIndex]
    
    dxDrawText(currentDirection, 
        compassX - 20, compassY, compassX + 20, compassY + 15, 
        tocolor(255, 255, 255, 255), 
        1, "default-bold", "center", "center")
end

-- ==============================
-- VEZÉRLÉS
-- ==============================
function toggleMinimap()
    minimapVisible = not minimapVisible
    outputChatBox("Minimap " .. (minimapVisible and "bekapcsolva" or "kikapcsolva"), 255, 255, 0)
end

function zoomMinimap()
    minimapConfig.currentZoom = minimapConfig.currentZoom % #minimapConfig.zoomLevels + 1
    outputChatBox("Minimap zoom: " .. tostring(minimapConfig.zoomLevels[minimapConfig.currentZoom]) .. "x", 255, 255, 0)
end

-- ==============================
-- WAYPOINT BEÁLLÍTÁSA
-- ==============================
function setCustomWaypoint(x, y)
    customWaypoint = {x = x, y = y}
    outputChatBox("Waypoint beállítva!", 0, 255, 0)
end

function removeCustomWaypoint()
    customWaypoint = nil
    outputChatBox("Waypoint eltávolítva!", 255, 255, 0)
end

-- ==============================
-- GOMBKEZELÉS
-- ==============================
addEventHandler("onClientKey", root, function(key, press)
    if not press then return end
    
    if key == "F11" then
        zoomMinimap()
    elseif key == "F12" then
        toggleMinimap()
    end
end)

-- ==============================
-- PARANCSOK
-- ==============================
addCommandHandler("minimap", toggleMinimap)
addCommandHandler("waypoint", function(cmd, x, y)
    if x and y then
        local wx, wy = tonumber(x), tonumber(y)
        if wx and wy then
            setCustomWaypoint(wx, wy)
        else
            outputChatBox("Használat: /waypoint [x] [y]", 255, 0, 0)
        end
    else
        removeCustomWaypoint()
    end
end)

-- ==============================
-- RENDERELÉS
-- ==============================
addEventHandler("onClientRender", root, function()
    if minimapVisible then
        drawMinimap()
    end
end)

-- ==============================
-- CLEANUP
-- ==============================
addEventHandler("onClientResourceStop", resourceRoot, function()
    setPlayerHudComponentVisible("radar", true)
end) 