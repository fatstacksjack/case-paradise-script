-- Case Paradise Script (Premium Native UI) v3.14 (ROBUST)
-- Author: Antigravity
-- Status: V3.14 (Safe UI + InvokeServer Corrected)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LogBuffer = {}

local function Log(msg)
    local timestamp = os.date("%H:%M:%S")
    local formatted = string.format("[%s] %s", timestamp, tostring(msg))
    table.insert(LogBuffer, formatted)
    warn(formatted) -- Use warn for visibility
    if #LogBuffer > 2000 then table.remove(LogBuffer, 1) end
end

Log("Script V3.14 Initializing...")

-- [CONFIG]
local Config = {
    AutoOpen = false,
    AutoSell = false, 
    AutoLevelCrates = false, -- Rewards
    SelectedCase = "Starter Case" 
}

-- [THEME]
local Theme = {
    Background = Color3.fromRGB(20, 20, 25),
    Sidebar = Color3.fromRGB(30, 30, 35),
    Accent = Color3.fromRGB(255, 140, 0), -- Orange
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(100, 255, 100),
    Error = Color3.fromRGB(255, 100, 100),
    ToggleOff = Color3.fromRGB(50, 50, 55),
    ToggleOn = Color3.fromRGB(0, 200, 100),
    Search = Color3.fromRGB(40, 40, 45)
}

-- [REMOTES]
local Remotes = { Open = nil, Sell = nil, Rewards = nil }

local function ScanRemotes()
    Log("Scanning Remotes...")
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remoteFolder then
        Remotes.Open = remoteFolder:FindFirstChild("OpenCase")
        Remotes.Sell = remoteFolder:FindFirstChild("Sell")
        Remotes.Rewards = remoteFolder:FindFirstChild("UpdateRewards")
    else
        -- Fallback
         for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "OpenCase" then Remotes.Open = v end
            if v.Name == "Sell" then Remotes.Sell = v end
            if v.Name == "UpdateRewards" then Remotes.Rewards = v end
         end
    end
    
    if Remotes.Open then Log("OpenCase FOUND: " .. Remotes.Open.ClassName) else Log("OpenCase MISSING!") end
end

ScanRemotes()

-- [CRATES]
local KnownCrates = {"Starter Case", "Common Case", "Rare Case"} -- Pre-fill some defaults
task.spawn(function()
    pcall(function()
        local mod = require(ReplicatedStorage.Modules.Cases)
        if mod then
            for k,v in pairs(mod) do
                if type(k) == "string" then table.insert(KnownCrates, k) end
                if type(v) == "table" and v.Name then table.insert(KnownCrates, v.Name) end
            end
        end
    end)
    -- clean duplicates
    local hash = {}
    local res = {}
    for _,v in ipairs(KnownCrates) do
       if (not hash[v]) then
           res[#res+1] = v
           hash[v] = true
       end
    end
    table.sort(res)
    KnownCrates = res
    Log("Loaded " .. #KnownCrates .. " Cases.")
end)


-- [UI CONSTRUCTION - SAFE WRAPPER]
task.spawn(function()
    local success, err = pcall(function()
        local PlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui:FindFirstChild("CaseParadiseV314") then PlayerGui.CaseParadiseV314:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "CaseParadiseV314"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 450, 0, 350) 
        MainFrame.Position = UDim2.new(0.5, -225, 0.5, -175)
        MainFrame.BackgroundColor3 = Theme.Background
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Draggable = true -- Simple drag
        MainFrame.Parent = ScreenGui
        
        -- Title
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 40)
        Title.BackgroundColor3 = Theme.Sidebar
        Title.Text = "  Case Paradise V3.14 (Robust)"
        Title.TextColor3 = Theme.Accent
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 16
        Title.Parent = MainFrame
        
        -- Close
        local Close = Instance.new("TextButton")
        Close.Size = UDim2.new(0, 40, 0, 40)
        Close.Position = UDim2.new(1, -40, 0, 0)
        Close.BackgroundTransparency = 1
        Close.Text = "X"
        Close.TextColor3 = Theme.SubText
        Close.TextSize = 16
        Close.Font = Enum.Font.GothamBold
        Close.Parent = MainFrame
        Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
        
        -- Content Container
        local Container = Instance.new("ScrollingFrame")
        Container.Size = UDim2.new(1, -20, 1, -50)
        Container.Position = UDim2.new(0, 10, 0, 45)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.Parent = MainFrame
        
        local UIList = Instance.new("UIListLayout")
        UIList.Padding = UDim.new(0, 5)
        UIList.Parent = Container
        
        -- Helper: Button
        local function CreateButton(text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 35)
            Btn.BackgroundColor3 = Theme.Sidebar
            Btn.Text = text
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.GothamSemibold
            Btn.TextSize = 14
            Btn.Parent = Container
            
            Btn.MouseButton1Click:Connect(callback)
            return Btn
        end
        
        -- Helper: Toggle
        local function CreateToggle(text, callback)
            local Btn = CreateButton(text .. ": OFF", function() end)
            local on = false
            Btn.MouseButton1Click:Connect(function()
                on = not on
                Btn.Text = text .. ": " .. (on and "ON" or "OFF")
                Btn.TextColor3 = on and Theme.Success or Theme.Text
                callback(on)
            end)
            return Btn
        end

        -- Toggles
        CreateToggle("Auto Open Case", function(v) Config.AutoOpen = v end)
        CreateToggle("Auto Sell Items", function(v) Config.AutoSell = v end)
        CreateToggle("Auto Rewards", function(v) Config.AutoLevelCrates = v end)
        
        -- Status
        local StatusLabel = Instance.new("TextLabel")
        StatusLabel.Size = UDim2.new(1, 0, 0, 60)
        StatusLabel.BackgroundTransparency = 1
        StatusLabel.Text = "Status: OK"
        StatusLabel.TextColor3 = Theme.SubText
        StatusLabel.TextWrapped = true
        StatusLabel.Font = Enum.Font.Code
        StatusLabel.TextSize = 12
        StatusLabel.Parent = Container
        
        -- Update Loop for GUI
        task.spawn(function()
            while MainFrame.Parent do
                StatusLabel.Text = string.format(
                    "Selected: %s\nOpen Remote: %s\nSell Remote: %s",
                    Config.SelectedCase,
                    (Remotes.Open and "FOUND" or "MISSING"),
                    (Remotes.Sell and "FOUND" or "MISSING")
                )
                task.wait(1)
            end
        end)
        
        -- Case Selection (Simple List)
        local SelectBtn = CreateButton("Select Case (Click to Cycle)", function()
            -- Simple cycle for robustness
            local currentIdx = 1
            for i,v in ipairs(KnownCrates) do if v == Config.SelectedCase then currentIdx = i break end end
            currentIdx = currentIdx + 1
            if currentIdx > #KnownCrates then currentIdx = 1 end
            Config.SelectedCase = KnownCrates[currentIdx]
            Log("Selected: " .. Config.SelectedCase)
        end)

    end)
    
    if not success then
        Log("CRITICAL UI ERROR: " .. tostring(err))
    end
end)


-- [MAIN LOOPS]
task.spawn(function()
    while true do
        if Config.AutoOpen and Remotes.Open then
            pcall(function()
                if Remotes.Open:IsA("RemoteFunction") then
                    Remotes.Open:InvokeServer(Config.SelectedCase)
                else
                    Remotes.Open:FireServer(Config.SelectedCase)
                end
            end)
        end
        
        if Config.AutoSell and Remotes.Sell then
             pcall(function()
                if Remotes.Sell:IsA("RemoteFunction") then
                    Remotes.Sell:InvokeServer()
                else
                    Remotes.Sell:FireServer()
                end
            end)
        end
        task.wait(1.5) 
    end
end)

task.spawn(function()
    while true do
        if Config.AutoLevelCrates and Remotes.Rewards then
            pcall(function()
                 if Remotes.Rewards:IsA("RemoteFunction") then
                    Remotes.Rewards:InvokeServer()
                    for i=1, 9 do Remotes.Rewards:InvokeServer("Gift"..i) end
                else
                    Remotes.Rewards:FireServer()
                    for i=1, 9 do Remotes.Rewards:FireServer("Gift"..i) end
                end
            end)
        end
        task.wait(5)
    end
end)

Log("V3.14 (Robust) Fully Loaded!")
