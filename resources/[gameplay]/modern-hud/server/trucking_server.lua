-- ==============================
-- KAMIONOS MUNKA SZERVER OLDAL
-- ==============================

local truckingPlayers = {}

-- ==============================
-- FIZETÉSI RENDSZER
-- ==============================
addEvent("giveTruckingPayment", true)
addEventHandler("giveTruckingPayment", root, function(amount)
    local player = source
    if not player or not isElement(player) then return end
    
    -- Fizetés ellenőrzése
    if type(amount) ~= "number" or amount <= 0 or amount > 10000 then
        outputChatBox("❌ Hibás fizetési összeg!", player, 255, 100, 100)
        return
    end
    
    -- Pénz hozzáadása
    givePlayerMoney(player, amount)
    
    -- Statisztika frissítése
    local playerName = getPlayerName(player)
    local completedJobs = getElementData(player, "completed_trucking_jobs") or 0
    setElementData(player, "completed_trucking_jobs", completedJobs + 1)
    
    -- Broadcast üzenet
    outputChatBox("💰 " .. playerName .. " befejezett egy tejszállítást! (€" .. formatNumber(amount) .. ")", root, 10, 126, 18)
    
    -- Log
    outputDebugString("[TRUCKING] " .. playerName .. " completed trucking job, payment: $" .. amount)
end)

-- ==============================
-- JÁTÉKOS STATISZTIKÁK
-- ==============================
addEventHandler("onPlayerJoin", root, function()
    -- Kezdő statisztikák beállítása
    if not getElementData(source, "completed_trucking_jobs") then
        setElementData(source, "completed_trucking_jobs", 0)
    end
    if not getElementData(source, "total_trucking_earnings") then
        setElementData(source, "total_trucking_earnings", 0)
    end
end)

-- ==============================
-- KAMION SPAWN ENGEDÉLYEK
-- ==============================
addEvent("requestTruckSpawn", true)
addEventHandler("requestTruckSpawn", root, function(truckModel, x, y, z)
    local player = source
    if not player or not isElement(player) then return end
    
    -- Ellenőrzések
    if type(truckModel) ~= "number" or truckModel <= 0 then return end
    if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then return end
    
    -- Kamion létrehozása
    local truck = createVehicle(truckModel, x, y, z, 0, 0, 90)
    if truck then
        setElementData(truck, "owner", player)
        setElementData(truck, "trucking_vehicle", true)
        setVehicleFuelTankCapacity(truck, 100)
        
        -- Vissza küldés kliensnek
        triggerClientEvent(player, "onTruckSpawned", player, truck)
        
        outputDebugString("[TRUCKING] Truck spawned for " .. getPlayerName(player))
    end
end)

-- ==============================
-- KAMION TÖRLÉS
-- ==============================
addEvent("destroyTruckingVehicle", true)
addEventHandler("destroyTruckingVehicle", root, function(vehicle)
    if vehicle and isElement(vehicle) and getElementData(vehicle, "trucking_vehicle") then
        destroyElement(vehicle)
        outputDebugString("[TRUCKING] Trucking vehicle destroyed")
    end
end)

-- ==============================
-- MUNKÁS RANGOK RENDSZER
-- ==============================
local truckingRanks = {
    {name = "Kezdő Sofőr", jobs = 0, bonus = 0},
    {name = "Tapasztalt Sofőr", jobs = 5, bonus = 500},
    {name = "Profi Sofőr", jobs = 15, bonus = 1000},
    {name = "Kamionos Mester", jobs = 30, bonus = 1500},
    {name = "Szállítási Legenda", jobs = 50, bonus = 2000}
}

function getTruckingRank(player)
    local completedJobs = getElementData(player, "completed_trucking_jobs") or 0
    local currentRank = truckingRanks[1]
    
    for _, rank in ipairs(truckingRanks) do
        if completedJobs >= rank.jobs then
            currentRank = rank
        end
    end
    
    return currentRank
end

-- ==============================
-- RANG ELLENŐRZÉS MUNKA UTÁN
-- ==============================
addEvent("checkTruckingRankUp", true)
addEventHandler("checkTruckingRankUp", root, function()
    local player = source
    if not player or not isElement(player) then return end
    
    local completedJobs = getElementData(player, "completed_trucking_jobs") or 0
    local currentRank = getTruckingRank(player)
    
    -- Rang változás ellenőrzése
    for _, rank in ipairs(truckingRanks) do
        if completedJobs == rank.jobs and rank.jobs > 0 then
            -- Rang előléptetés!
            givePlayerMoney(player, rank.bonus)
            outputChatBox("🎉 RANG ELŐLÉPTETÉS! 🎉", player, 255, 215, 0)
            outputChatBox("Új rang: " .. rank.name, player, 10, 126, 18)
            outputChatBox("Bónusz fizetés: €" .. formatNumber(rank.bonus), player, 10, 126, 18)
            
            -- Broadcast
            outputChatBox("🌟 " .. getPlayerName(player) .. " elérte a(z) " .. rank.name .. " rangot!", root, 255, 215, 0)
            break
        end
    end
end)

-- ==============================
-- KAMION STATISZTIKÁK PARANCS
-- ==============================
addCommandHandler("truckstats", function(player)
    local completedJobs = getElementData(player, "completed_trucking_jobs") or 0
    local totalEarnings = getElementData(player, "total_trucking_earnings") or 0
    local currentRank = getTruckingRank(player)
    
    outputChatBox("📊 KAMIONOS STATISZTIKÁK:", player, 10, 126, 18)
    outputChatBox("🚛 Befejezett munkák: " .. completedJobs, player, 255, 255, 255)
    outputChatBox("💰 Összes kereset: €" .. formatNumber(totalEarnings), player, 255, 255, 255)
    outputChatBox("🏆 Jelenlegi rang: " .. currentRank.name, player, 255, 255, 255)
    
    -- Következő rang
    local nextRank = nil
    for _, rank in ipairs(truckingRanks) do
        if completedJobs < rank.jobs then
            nextRank = rank
            break
        end
    end
    
    if nextRank then
        local jobsNeeded = nextRank.jobs - completedJobs
        outputChatBox("🎯 Következő rang: " .. nextRank.name .. " (" .. jobsNeeded .. " munka)", player, 10, 126, 18)
    else
        outputChatBox("👑 Elérted a legmagasabb rangot!", player, 255, 215, 0)
    end
end)

-- ==============================
-- TOP KAMIONOSOK PARANCS
-- ==============================
addCommandHandler("trucktop", function(player)
    local players = getElementsByType("player")
    local truckingData = {}
    
    -- Adatok gyűjtése
    for _, p in ipairs(players) do
        local jobs = getElementData(p, "completed_trucking_jobs") or 0
        if jobs > 0 then
            table.insert(truckingData, {
                name = getPlayerName(p),
                jobs = jobs,
                rank = getTruckingRank(p).name
            })
        end
    end
    
    -- Rendezés munkák szerint
    table.sort(truckingData, function(a, b) return a.jobs > b.jobs end)
    
    outputChatBox("🏆 TOP KAMIONOSOK:", player, 10, 126, 18)
    
    for i = 1, math.min(5, #truckingData) do
        local data = truckingData[i]
        local medal = i == 1 and "🥇" or i == 2 and "🥈" or i == 3 and "🥉" or "🏅"
        outputChatBox(medal .. " " .. data.name .. " - " .. data.jobs .. " munka (" .. data.rank .. ")", 
            player, 255, 255, 255)
    end
    
    if #truckingData == 0 then
        outputChatBox("Még senki nem végzett kamionos munkát!", player, 255, 100, 100)
    end
end)

-- ==============================
-- ADMIN PARANCSOK
-- ==============================
addCommandHandler("settruckjobs", function(player, cmd, targetName, amount)
    if not hasObjectPermissionTo(player, "general.adminpanel") then
        outputChatBox("❌ Nincs jogosultságod ehhez!", player, 255, 100, 100)
        return
    end
    
    if not targetName or not amount then
        outputChatBox("Használat: /settruckjobs [játékos] [mennyiség]", player, 255, 255, 255)
        return
    end
    
    local target = getPlayerFromName(targetName)
    amount = tonumber(amount)
    
    if not target then
        outputChatBox("❌ Játékos nem található!", player, 255, 100, 100)
        return
    end
    
    if not amount or amount < 0 then
        outputChatBox("❌ Hibás mennyiség!", player, 255, 100, 100)
        return
    end
    
    setElementData(target, "completed_trucking_jobs", amount)
    outputChatBox("✅ " .. getPlayerName(target) .. " kamionos munkáinak száma: " .. amount, player, 10, 126, 18)
    outputChatBox("📊 Admin beállította a kamionos munkáid számát: " .. amount, target, 10, 126, 18)
end)

-- ==============================
-- SZERVER INDULÁS
-- ==============================
addEventHandler("onResourceStart", resourceRoot, function()
    outputDebugString("[TRUCKING] Kamionos munka szerver oldal betöltve!")
    
    -- Összes játékoshoz alapértelmezett adatok
    for _, player in ipairs(getElementsByType("player")) do
        if not getElementData(player, "completed_trucking_jobs") then
            setElementData(player, "completed_trucking_jobs", 0)
        end
        if not getElementData(player, "total_trucking_earnings") then
            setElementData(player, "total_trucking_earnings", 0)
        end
    end
end)

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
-- JÁTÉKOS KILÉPÉS CLEANUP
-- ==============================
addEventHandler("onPlayerQuit", root, function()
    -- Tisztítás ha volt aktív munka
    truckingPlayers[source] = nil
    
    -- Játékos kamionjai törlése
    for _, vehicle in ipairs(getElementsByType("vehicle")) do
        if getElementData(vehicle, "owner") == source and getElementData(vehicle, "trucking_vehicle") then
            destroyElement(vehicle)
        end
    end
end) 