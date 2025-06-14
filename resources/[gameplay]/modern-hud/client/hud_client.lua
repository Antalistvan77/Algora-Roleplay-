-- ==============================
-- MODERN SLEEK HUD RENDSZER
-- ==============================

local screenWidth, screenHeight = guiGetScreenSize()
local isHudVisible = true
local hudElements = {}
local animationProgress = {}

-- Stamina rendszer
local playerStamina = 100
local maxStamina = 100

-- ==============================
-- MODERN DESIGN BEÁLLÍTÁSOK
-- ==============================
local hudConfig = {
    -- Általános beállítások
    fadeTime = 300,
    updateRate = 50,
    glowIntensity = 1.0,
    pulseSpeed = 0.003,
    
    -- HUD pozíció (JOBB FELSŐ SAROK)
    mainHud = {
        x = screenWidth - 350,
        y = 30,
        width = 320,
        height = 150
    },
    
    -- Money panel (JOBB FELSŐ SAROK A HUD ALATT)
    moneyPanel = {
        x = screenWidth - 250,
        y = 190,
        width = 220,
        height = 40
    },
    
    -- Modern zöld színpaletta
    colors = {
        background = {10, 10, 10, 255},       -- Fekete háttér (nem átlátszó)
        panel = {20, 20, 20, 255},            -- Sötét panel háttér
        border = {10, 126, 18, 255},          -- Zöld border
        text = {255, 255, 255, 255},          -- Fehér szöveg
        textSecondary = {180, 180, 180, 255}, -- Halvány szöveg
        accent = {10, 126, 18, 255},          -- Zöld accent
        health = {255, 60, 60, 255},          -- Piros élet
        stamina = {255, 200, 0, 255},         -- Sárga stamina
        armor = {100, 150, 255, 255},         -- Kék páncél
        money = {10, 126, 18, 255},           -- Zöld pénz
        glow = {10, 126, 18, 100}             -- Zöld glow
    },
    
    -- Animációs beállítások
    animation = {
        pulse = 0,
        glow = 0,
        time = 0
    }
}

-- ==============================
-- HUD INICIALIZÁLÁS
-- ==============================
addEventHandler("onClientResourceStart", resourceRoot, function()
    -- Eredeti HUD elrejtése
    setPlayerHudComponentVisible("health", false)
    setPlayerHudComponentVisible("armour", false)
    setPlayerHudComponentVisible("money", false)
    setPlayerHudComponentVisible("weapon", false)
    setPlayerHudComponentVisible("clock", false)
    setPlayerHudComponentVisible("radar", false)
    setPlayerHudComponentVisible("area_name", false)
    setPlayerHudComponentVisible("vehicle_name", false)
    
    -- Animációs timerek
    setTimer(updateAnimations, 16, 0) -- 60 FPS animáció
    setTimer(updateStamina, 100, 0) -- Stamina frissítés
    
    outputChatBox("🎮 Modern HUD aktiválva!", 10, 126, 18)
end)

-- ==============================
-- ANIMÁCIÓK FRISSÍTÉSE  
-- ==============================
function updateAnimations()
    local time = getTickCount()
    hudConfig.animation.pulse = math.sin(time * 0.003) * 0.3 + 0.7
    hudConfig.animation.glow = math.sin(time * 0.002) * 0.5 + 0.5
    hudConfig.animation.time = time
end

-- ==============================
-- STAMINA RENDSZER FRISSÍTÉSE
-- ==============================
function updateStamina()
    local player = getLocalPlayer()
    if not player then return end
    
    -- Stamina csökkenés futás/úszás közben
    if isPedRunning(player) or isPedInWater(player) then
        playerStamina = math.max(0, playerStamina - 1.5)
    else
        -- Stamina regenerálódás
        playerStamina = math.min(maxStamina, playerStamina + 0.8)
    end
end

-- ==============================
-- MODERN PANEL RAJZOLÁS
-- ==============================
function drawModernPanel(x, y, width, height, alpha)
    local colors = hudConfig.colors
    alpha = alpha or 1
    
    -- Fő háttér
    dxDrawRectangle(x, y, width, height, 
        tocolor(colors.background[1], colors.background[2], colors.background[3], colors.background[4] * alpha))
    
    -- Felső border
    dxDrawRectangle(x, y, width, 2, 
        tocolor(colors.accent[1], colors.accent[2], colors.accent[3], colors.accent[4] * alpha))
    
    -- Subtle inner glow
    dxDrawRectangle(x + 1, y + 2, width - 2, 1, 
        tocolor(colors.glow[1], colors.glow[2], colors.glow[3], colors.glow[4] * alpha))
end

-- ==============================
-- MODERN STATUS BAR
-- ==============================
function drawModernBar(x, y, width, height, value, maxValue, color, icon, label, showPercentage)
    local percentage = math.max(0, math.min(1, value / maxValue))
    local colors = hudConfig.colors
    
    -- Bar háttér
    dxDrawRectangle(x, y, width, height, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 150))
    
    -- Aktív bar rész
    local barWidth = width * percentage
    if barWidth > 0 then
        dxDrawRectangle(x, y, barWidth, height, tocolor(unpack(color)))
        
        -- Glow effect
        local glowAlpha = math.floor(color[4] * hudConfig.animation.glow * 0.3)
        dxDrawRectangle(x, y - 1, barWidth, height + 2, 
            tocolor(color[1], color[2], color[3], glowAlpha))
    end
    
    -- Bar border
    dxDrawRectangle(x, y, width, 1, tocolor(colors.border[1], colors.border[2], colors.border[3], 100))
    dxDrawRectangle(x, y + height - 1, width, 1, tocolor(colors.border[1], colors.border[2], colors.border[3], 100))
    dxDrawRectangle(x, y, 1, height, tocolor(colors.border[1], colors.border[2], colors.border[3], 100))
    dxDrawRectangle(x + width - 1, y, 1, height, tocolor(colors.border[1], colors.border[2], colors.border[3], 100))
    
    -- Label
    if label then
        local labelText = icon .. " " .. label
        dxDrawText(labelText, x, y - 18, x + width, y, 
            tocolor(unpack(colors.text)), 0.8, "default-bold", "left", "center")
    end
    
    -- Value/Percentage
    if showPercentage then
        local valueText = math.floor(percentage * 100) .. "%"
        dxDrawText(valueText, x, y - 18, x + width, y, 
            tocolor(unpack(colors.textSecondary)), 0.8, "default", "right", "center")
    else
        local valueText = math.floor(value) .. "/" .. math.floor(maxValue)
        dxDrawText(valueText, x, y - 18, x + width, y, 
            tocolor(unpack(colors.textSecondary)), 0.8, "default", "right", "center")
    end
end

-- ==============================
-- CIRCULAR INDICATOR (MINT A MÁSODIK KÉPEN)
-- ==============================
function drawCircularIndicator(x, y, radius, value, maxValue, color, icon, label)
    local percentage = math.max(0, math.min(1, value / maxValue))
    local colors = hudConfig.colors
    local segments = 32
    local angle = percentage * 360
    
    -- Háttér kör
    for i = 0, segments do
        local a1 = (i / segments) * 360
        local a2 = ((i + 1) / segments) * 360
        
        local x1 = x + math.cos(math.rad(a1 - 90)) * (radius - 3)
        local y1 = y + math.sin(math.rad(a1 - 90)) * (radius - 3)
        local x2 = x + math.cos(math.rad(a2 - 90)) * (radius - 3)
        local y2 = y + math.sin(math.rad(a2 - 90)) * (radius - 3)
        
        dxDrawLine(x1, y1, x2, y2, tocolor(colors.panel[1], colors.panel[2], colors.panel[3], 150), 4)
    end
    
    -- Aktív kör rész
    for i = 0, math.floor(segments * percentage) do
        local a1 = (i / segments) * 360
        local a2 = ((i + 1) / segments) * 360
        
        if a1 <= angle then
            local x1 = x + math.cos(math.rad(a1 - 90)) * (radius - 3)
            local y1 = y + math.sin(math.rad(a1 - 90)) * (radius - 3)
            local x2 = x + math.cos(math.rad(a2 - 90)) * (radius - 3)
            local y2 = y + math.sin(math.rad(a2 - 90)) * (radius - 3)
            
            dxDrawLine(x1, y1, x2, y2, tocolor(unpack(color)), 5)
        end
    end
    
    -- Központi ikon
    dxDrawText(icon, x - 10, y - 10, x + 10, y + 10, 
        tocolor(unpack(colors.text)), 1.5, "default", "center", "center")
    
    -- Érték szöveg
    local valueText = math.floor(value)
    dxDrawText(valueText, x - 20, y + 15, x + 20, y + 35, 
        tocolor(unpack(colors.text)), 0.9, "default-bold", "center", "center")
    
    -- Label
    if label then
        dxDrawText(label, x - 30, y + 30, x + 30, y + 45, 
            tocolor(unpack(colors.textSecondary)), 0.7, "default", "center", "center")
    end
end

-- ==============================
-- FŐ HUD RAJZOLÁSA
-- ==============================
function drawMainHUD()
    if not isHudVisible then return end
    
    local player = getLocalPlayer()
    if not player then return end
    
    local config = hudConfig.mainHud
    local colors = hudConfig.colors
    
    -- Játékos adatok
    local health = getElementHealth(player)
    local armor = getPedArmor(player)
    local money = getPlayerMoney(player)
    
    -- Fő panel
    drawModernPanel(config.x, config.y, config.width, config.height)
    
    -- Circular indicators (mint a második képen)
    local startX = config.x + 50
    local startY = config.y + 60
    local spacing = 80
    
    -- Health indicator
    drawCircularIndicator(startX, startY, 25, health, 100, colors.health, "♥", "HP")
    
    -- Stamina indicator
    drawCircularIndicator(startX + spacing, startY, 25, playerStamina, maxStamina, colors.stamina, "⚡", "STA")
    
    -- Armor indicator (csak ha van)
    if armor > 0 then
        drawCircularIndicator(startX + spacing * 2, startY, 25, armor, 100, colors.armor, "🛡", "ARM")
    end
    
    -- Money display (a HUD alatt)
    local moneyX = hudConfig.moneyPanel.x
    local moneyY = hudConfig.moneyPanel.y
    local moneyW = hudConfig.moneyPanel.width
    local moneyH = hudConfig.moneyPanel.height
    
    -- Money panel
    drawModernPanel(moneyX, moneyY, moneyW, moneyH)
    
    -- Money icon és text
    dxDrawText("💰", moneyX + 10, moneyY + 5, moneyX + 30, moneyY + 35, 
        tocolor(unpack(colors.money)), 1.5, "default", "center", "center")
    
    -- Money érték EURO-val
    local moneyText = "" .. formatNumber(money)
    dxDrawText(moneyText, moneyX + 35, moneyY + 25, moneyX + moneyW - 10, moneyY + 25, 
        tocolor(unpack(colors.text)), 0.9, "pricedown", "left", "center")
    
    -- "EURO" felirat
    dxDrawText("EURO", moneyX + 35, moneyY + 20, moneyX + moneyW - 10, moneyY + 35, 
        tocolor(unpack(colors.money)), 0.7, "default", "left", "center")
    
    -- Status panel header
    dxDrawText("PLAYER STATUS", config.x + 10, config.y + 8, config.x + config.width - 10, config.y + 25, 
        tocolor(unpack(colors.accent)), 0.9, "default-bold", "left", "center")
    
    -- Minimap-like circular design elements
    local decorSize = 6
    local decorX = config.x + config.width - 20
    local decorY = config.y + 10
    
    for i = 0, 2 do
        local alpha = math.floor(255 * hudConfig.animation.pulse)
        dxDrawRectangle(decorX, decorY + (i * 8), decorSize, decorSize, 
            tocolor(colors.accent[1], colors.accent[2], colors.accent[3], alpha))
    end
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
-- HUD VEZÉRLÉS
-- ==============================
function toggleHUD()
    isHudVisible = not isHudVisible
    local status = isHudVisible and "🟢 BEKAPCSOLVA" or "🔴 KIKAPCSOLVA"
    outputChatBox("HUD Status: " .. status, 10, 126, 18)
end

-- ==============================
-- PARANCSOK
-- ==============================
addCommandHandler("hud", toggleHUD)
addCommandHandler("togglehud", toggleHUD)

-- ==============================
-- RENDERELÉS
-- ==============================
addEventHandler("onClientRender", root, function()
    drawMainHUD()
end)

-- ==============================
-- CLEANUP
-- ==============================
addEventHandler("onClientResourceStop", resourceRoot, function()
    -- Eredeti HUD visszaállítása
    setPlayerHudComponentVisible("health", true)
    setPlayerHudComponentVisible("armour", true)
    setPlayerHudComponentVisible("money", true)
    setPlayerHudComponentVisible("weapon", true)
    setPlayerHudComponentVisible("clock", true)
    setPlayerHudComponentVisible("radar", true)
    setPlayerHudComponentVisible("area_name", true)
    setPlayerHudComponentVisible("vehicle_name", true)
end)