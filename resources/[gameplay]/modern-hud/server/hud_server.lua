-- ==============================
-- MODERN HUD SZERVER OLDALI RENDSZER
-- ==============================

local playerData = {}
local vehicleData = {}

-- ==============================
-- JÁTÉKOS CSATLAKOZÁS/KILÉPÉS
-- ==============================
addEventHandler("onPlayerJoin", root, function()
    -- Játékos adatok inicializálása
    playerData[source] = {
        money = 5000, -- Kezdő pénz
        job = "civilian",
        level = 1,
        experience = 0,
        playtime = 0,
        lastUpdate = getTickCount()
    }
    
    -- Kezdő pénz beállítása
    setPlayerMoney(source, playerData[source].money)
    
    -- Element data beállítása
    setElementData(source, "job", "civilian")
    setElementData(source, "level", 1)
    setElementData(source, "experience", 0)
    
    outputChatBox("Modern Roleplay szerverre csatlakoztál!", source, 0, 255, 0)
    outputChatBox("HUD parancsok: /hud, /engine, /waypoint", source, 255, 255, 0)
end)

addEventHandler("onPlayerQuit", root, function()
    -- Játékos adatok mentése (később adatbázisba)
    if playerData[source] then
        savePlayerData(source)
        playerData[source] = nil
    end
end)

-- ==============================
-- JÁRMŰ RENDSZER
-- ==============================
addEventHandler("onVehicleEnter", root, function(player, seat)
    if seat == 0 then -- Csak sofőr
        -- Jármű adatok inicializálása ha nincs
        if not getElementData(source, "fuel") then
            setElementData(source, "fuel", math.random(20, 100))
        end
        
        if not getElementData(source, "owner") then
            setElementData(source, "owner", "Állami")
        end
        
        -- Jármű információk küldése a kliensnek
        triggerClientEvent(player, "onVehicleDataUpdate", source, {
            fuel = getElementData(source, "fuel"),
            owner = getElementData(source, "owner"),
            locked = isVehicleLocked(source)
        })
    end
end)

-- ==============================
-- MUNKA RENDSZER
-- ==============================
function setPlayerJob(player, jobName)
    if not playerData[player] then return false end
    
    local validJobs = {
        "civilian", "police", "medic", "mechanic", 
        "taxi", "trucker", "dealer", "admin"
    }
    
    local isValidJob = false
    for _, job in ipairs(validJobs) do
        if job == jobName then
            isValidJob = true
            break
        end
    end
    
    if not isValidJob then
        outputChatBox("Érvénytelen munka! Elérhető munkák: " .. table.concat(validJobs, ", "), player, 255, 0, 0)
        return false
    end
    
    playerData[player].job = jobName
    setElementData(player, "job", jobName)
    
    outputChatBox("Munkád megváltozott: " .. jobName, player, 0, 255, 0)
    
    -- Munka specifikus beállítások
    setupJobSpecificData(player, jobName)
    
    return true
end

-- ==============================
-- MUNKA SPECIFIKUS BEÁLLÍTÁSOK
-- ==============================
function setupJobSpecificData(player, job)
    if job == "police" then
        -- Rendőr felszerelés
        giveWeapon(player, 3, 1, true) -- Gumibot
        giveWeapon(player, 41, 500, false) -- Spray
        outputChatBox("Rendőr felszerelést kaptál!", player, 0, 0, 255)
        
    elseif job == "medic" then
        -- Mentős felszerelés
        outputChatBox("Mentős felszerelést kaptál!", player, 255, 255, 255)
        
    elseif job == "mechanic" then
        -- Szerelő felszerelés
        giveWeapon(player, 9, 1, true) -- Láncfűrész
        outputChatBox("Szerelő felszerelést kaptál!", player, 255, 165, 0)
    end
end

-- ==============================
-- PÉNZ RENDSZER
-- ==============================
function addPlayerMoney(player, amount, reason)
    if not playerData[player] then return false end
    
    local currentMoney = getPlayerMoney(player)
    local newMoney = currentMoney + amount
    
    setPlayerMoney(player, newMoney)
    playerData[player].money = newMoney
    
    local action = amount > 0 and "kaptál" or "elvesztetél"
    local color = amount > 0 and {0, 255, 0} or {255, 0, 0}
    
    outputChatBox("$" .. math.abs(amount) .. " " .. action .. " (" .. (reason or "Ismeretlen ok") .. ")", 
        player, color[1], color[2], color[3])
    
    return true
end

function removePlayerMoney(player, amount, reason)
    return addPlayerMoney(player, -amount, reason)
end

-- ==============================
-- TAPASZTALAT RENDSZER
-- ==============================
function addPlayerExperience(player, amount, reason)
    if not playerData[player] then return false end
    
    playerData[player].experience = playerData[player].experience + amount
    setElementData(player, "experience", playerData[player].experience)
    
    -- Szint növelés ellenőrzése
    local requiredExp = playerData[player].level * 1000
    if playerData[player].experience >= requiredExp then
        levelUpPlayer(player)
    end
    
    outputChatBox("+" .. amount .. " tapasztalat (" .. (reason or "Ismeretlen") .. ")", 
        player, 255, 255, 0)
    
    return true
end

function levelUpPlayer(player)
    if not playerData[player] then return false end
    
    playerData[player].level = playerData[player].level + 1
    playerData[player].experience = 0
    
    setElementData(player, "level", playerData[player].level)
    setElementData(player, "experience", 0)
    
    -- Szint jutalom
    local reward = playerData[player].level * 500
    addPlayerMoney(player, reward, "Szint jutalom")
    
    outputChatBox("Szintet léptél! Új szint: " .. playerData[player].level, player, 0, 255, 0)
    
    return true
end

-- ==============================
-- JÁRMŰ ÜZEMANYAG RENDSZER
-- ==============================
function refuelVehicle(vehicle, amount)
    if not isElement(vehicle) or getElementType(vehicle) ~= "vehicle" then
        return false
    end
    
    local currentFuel = getElementData(vehicle, "fuel") or 0
    local maxFuel = 100
    local newFuel = math.min(maxFuel, currentFuel + amount)
    
    setElementData(vehicle, "fuel", newFuel)
    
    return newFuel
end

-- ==============================
-- ADATOK MENTÉSE
-- ==============================
function savePlayerData(player)
    if not playerData[player] then return end
    
    -- Itt történne az adatbázisba mentés
    -- Jelenleg csak log-olunk
    local data = playerData[player]
    outputServerLog("Játékos adatok mentve: " .. getPlayerName(player) .. 
        " | Pénz: $" .. data.money .. 
        " | Szint: " .. data.level .. 
        " | Munka: " .. data.job)
end

-- Időszakos mentés
setTimer(function()
    for player, data in pairs(playerData) do
        if isElement(player) then
            savePlayerData(player)
        end
    end
end, 300000, 0) -- 5 percenként

-- ==============================
-- PARANCSOK
-- ==============================
addCommandHandler("setjob", function(player, cmd, targetName, jobName)
    if not hasObjectPermissionTo(player, "command.setjob") then
        outputChatBox("Nincs jogosultságod ehhez a parancshoz!", player, 255, 0, 0)
        return
    end
    
    if not targetName or not jobName then
        outputChatBox("Használat: /setjob [játékos] [munka]", player, 255, 255, 0)
        return
    end
    
    local target = getPlayerFromName(targetName)
    if not target then
        outputChatBox("Játékos nem található!", player, 255, 0, 0)
        return
    end
    
    if setPlayerJob(target, jobName) then
        outputChatBox("Sikeresen beállítottad " .. getPlayerName(target) .. " munkáját: " .. jobName, 
            player, 0, 255, 0)
    end
end)

addCommandHandler("givemoney", function(player, cmd, targetName, amount)
    if not hasObjectPermissionTo(player, "command.givemoney") then
        outputChatBox("Nincs jogosultságod ehhez a parancshoz!", player, 255, 0, 0)
        return
    end
    
    if not targetName or not amount then
        outputChatBox("Használat: /givemoney [játékos] [összeg]", player, 255, 255, 0)
        return
    end
    
    local target = getPlayerFromName(targetName)
    local moneyAmount = tonumber(amount)
    
    if not target then
        outputChatBox("Játékos nem található!", player, 255, 0, 0)
        return
    end
    
    if not moneyAmount then
        outputChatBox("Érvénytelen összeg!", player, 255, 0, 0)
        return
    end
    
    if addPlayerMoney(target, moneyAmount, "Admin által adva") then
        outputChatBox("Sikeresen adtál $" .. moneyAmount .. "-t " .. getPlayerName(target) .. " játékosnak", 
            player, 0, 255, 0)
    end
end)

addCommandHandler("refuel", function(player, cmd)
    local vehicle = getPedOccupiedVehicle(player)
    if not vehicle then
        outputChatBox("Nem vagy járműben!", player, 255, 0, 0)
        return
    end
    
    local cost = 500
    if getPlayerMoney(player) < cost then
        outputChatBox("Nincs elég pénzed a tankoláshoz! ($" .. cost .. ")", player, 255, 0, 0)
        return
    end
    
    local newFuel = refuelVehicle(vehicle, 100)
    removePlayerMoney(player, cost, "Tankolás")
    
    outputChatBox("Sikeresen feltankoltál! Üzemanyag: " .. math.floor(newFuel) .. "%", player, 0, 255, 0)
end)

addCommandHandler("stats", function(player, cmd, targetName)
    local target = targetName and getPlayerFromName(targetName) or player
    
    if not target then
        outputChatBox("Játékos nem található!", player, 255, 0, 0)
        return
    end
    
    if not playerData[target] then
        outputChatBox("Nincs adat erről a játékosról!", player, 255, 0, 0)
        return
    end
    
    local data = playerData[target]
    local name = getPlayerName(target)
    
    outputChatBox("=== " .. name .. " statisztikái ===", player, 255, 255, 0)
    outputChatBox("Pénz: $" .. data.money, player, 255, 255, 255)
    outputChatBox("Szint: " .. data.level, player, 255, 255, 255)
    outputChatBox("Tapasztalat: " .. data.experience, player, 255, 255, 255)
    outputChatBox("Munka: " .. data.job, player, 255, 255, 255)
end)

-- ==============================
-- JÁTÉK KEZDÉSE
-- ==============================
outputServerLog("Modern Roleplay HUD szerver oldali rendszer betöltve!")
outputChatBox("Modern Roleplay szerver elindítva!", root, 0, 255, 0) 