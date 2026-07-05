-- Fisch Hub | Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

local flags = { AutoFish = false, FishESP = false, AutoSell = false }
local espCache = {}

local function getHRP()
    local ch = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return ch:FindFirstChild("HumanoidRootPart")
end

-- try to resolve fishing remotes (Fisch uses net folder)
local function findRemote(names)
    local net = ReplicatedStorage:FindFirstChild("packages")
        or ReplicatedStorage:FindFirstChild("Packages")
        or ReplicatedStorage
    for _, n in ipairs(names) do
        local r = net:FindFirstChild(n, true)
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            return r
        end
    end
    return nil
end

local Window = Rayfield:CreateWindow({
    Name = "Fisch Hub",
    LoadingTitle = "Fisch Hub",
    LoadingSubtitle = "Enjoy!",
    ConfigurationSaving = { Enabled = true, FolderName = "FischHub", FileName = "FischHub" },
})

-- ===== FISHING TAB =====
local FishTab = Window:CreateTab("Fishing", 4483362458)

FishTab:CreateToggle({
    Name = "Auto Fish",
    CurrentValue = false,
    Callback = function(v) flags.AutoFish = v end,
})

FishTab:CreateToggle({
    Name = "Auto Sell All",
    CurrentValue = false,
    Callback = function(v) flags.AutoSell = v end,
})

FishTab:CreateButton({
    Name = "Equip Best Rod (last in backpack)",
    Callback = function()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        if bp and char then
            local best
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find("rod") then best = t end
            end
            if best then
                best.Parent = char
                Rayfield:Notify({Title="Fisch", Content="Equipped "..best.Name, Duration=3})
            else
                Rayfield:Notify({Title="Fisch", Content="No rod found", Duration=3})
            end
        end
    end,
})

-- ===== ESP TAB =====
local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateToggle({
    Name = "Fish ESP",
    CurrentValue = false,
    Callback = function(v)
        flags.FishESP = v
        if not v then
            for k, hl in pairs(espCache) do
                if hl and hl.Parent then hl:Destroy() end
                espCache[k] = nil
            end
        end
    end,
})

-- ===== TELEPORT TAB =====
local TPTab = Window:CreateTab("Teleport", 4483362458)
local spots = {
    ["Moosewood (Spawn)"] = Vector3.new(280, 135, 230),
    ["Roslit Bay"]        = Vector3.new(-1550, 135, 660),
    ["Terrapin Island"]   = Vector3.new(-360, 135, -1425),
    ["Snowcap Island"]    = Vector3.new(2600, 135, 3900),
    ["Forsaken Shores"]   = Vector3.new(-3400, 135, 1000),
    ["Vertigo (deep)"]    = Vector3.new(-140, 40, 3000),
}
TPTab:CreateDropdown({
    Name = "Fishing Spots",
    Options = (function() local t={} for k in pairs(spots) do table.insert(t,k) end table.sort(t) return t end)(),
    CurrentOption = {"Moosewood (Spawn)"},
    Callback = function(opt)
        local name = type(opt)=="table" and opt[1] or opt
        local pos = spots[name]
        local hrp = getHRP()
        if pos and hrp then
            hrp.CFrame = CFrame.new(pos)
            Rayfield:Notify({Title="Teleport", Content="-> "..name, Duration=3})
        end
    end,
})

-- anti afk
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ===== LOOPS =====
task.spawn(function()
    local castRemote = findRemote({"ChargeFishingRod", "RequestFishingMinigameStarted", "castRod"})
    local reelRemote = findRemote({"FishingCompleted", "RequestReelStarted", "reelFinished"})
    while true do
        task.wait(1.2)
        if flags.AutoFish then
            pcall(function()
                if castRemote then
                    if castRemote:IsA("RemoteFunction") then castRemote:InvokeServer(math.random(90,100)/100)
                    else castRemote:FireServer(workspace:GetServerTimeNow()) end
                end
                task.wait(0.6)
                if reelRemote then
                    if reelRemote:IsA("RemoteFunction") then reelRemote:InvokeServer()
                    else reelRemote:FireServer(true) end
                end
            end)
        end
    end
end)

task.spawn(function()
    local sellRemote = findRemote({"Sell", "SellAll", "sellFish"})
    while true do
        task.wait(30)
        if flags.AutoSell and sellRemote then
            pcall(function()
                if sellRemote:IsA("RemoteFunction") then sellRemote:InvokeServer()
                else sellRemote:FireServer() end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.6)
        if flags.FishESP then
            local fishFolder = Workspace:FindFirstChild("Fishes") or Workspace:FindFirstChild("Fish")
            local container = fishFolder or Workspace
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("fish") and not espCache[obj] then
                    local hl = Instance.new("Highlight")
                    hl.FillColor = Color3.fromRGB(0, 170, 255)
                    hl.Adornee = obj
                    hl.Parent = obj
                    espCache[obj] = hl
                end
            end
            for obj, hl in pairs(espCache) do
                if not obj.Parent then
                    if hl and hl.Parent then hl:Destroy() end
                    espCache[obj] = nil
                end
            end
        end
    end
end)

Rayfield:Notify({Title="Fisch Hub", Content="Loaded! Remotes auto-detected.", Duration=4})
