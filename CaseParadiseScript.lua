-- Case Paradise Script (Premium Native UI) v3.11 GOD DUMP
-- Author: Antigravity
-- Status: GOD MODE DUMP (Full System Scan to File)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [LOGGING SYSTEM]
local LogBuffer = {}
local function Log(msg)
    local timestamp = os.date("%H:%M:%S")
    local formatted = string.format("[%s] %s", timestamp, tostring(msg))
    table.insert(LogBuffer, formatted)
    print(formatted)
    if #LogBuffer > 2000 then table.remove(LogBuffer, 1) end
end

Log("Script V3.11 GOD DUMP Initializing...")

-- [CONFIG]
local Config = {
    AutoOpen = false,
    AutoSell = false,
    AutoQuests = false,
    AutoLevelCrates = false, 
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
    Search = Color3.fromRGB(40, 40, 45),
    GodMode = Color3.fromRGB(255, 50, 50) -- RED for God Mode
}

-- [REMOTES & DATA]
local Remotes = { Open = nil, Sell = nil, Rewards = nil, Generic = {} }
local KnownCrates = {} 
local FilteredCrates = {} 
local LoadedCases = {} 
local ItemSearchInput = nil
local ItemResultsFrame = nil
local CrateScrollFrame = nil
local SearchInput = nil
local StatusLabels = {} 

local function UpdateStatus(name, found)
    if StatusLabels[name] then
        StatusLabels[name].Text = name .. ": " .. (found and "FOUND" or "MISSING")
        StatusLabels[name].TextColor3 = found and Theme.Success or Theme.Error
    end
end

local function ScanRemotes()
    Log("Scanning for Remotes...")
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remoteFolder then
        Remotes.Open = remoteFolder:FindFirstChild("OpenCase")
        Remotes.Sell = remoteFolder:FindFirstChild("Sell")
        Remotes.Rewards = remoteFolder:FindFirstChild("UpdateRewards")
        
        for _, v in pairs(remoteFolder:GetChildren()) do
            if v.Name:lower():find("claim") or v.Name:lower():find("quest") then
                table.insert(Remotes.Generic, v)
            end
        end
    else
        Log("WARN: 'Remotes' folder NOT found in ReplicatedStorage!")
        -- Fallback scan
        for _, child in pairs(ReplicatedStorage:GetDescendants()) do
             if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                if (name:find("open") or name:find("case")) and not Remotes.Open then 
                    Remotes.Open = child 
                    Log("Found Open Remote via Scan: " .. child:GetFullName())
                end
                if name:find("sell") and not Remotes.Sell then 
                    Remotes.Sell = child 
                    Log("Found Sell Remote via Scan: " .. child:GetFullName())
                end
            end
        end
    end
    
    UpdateStatus("OpenCase", Remotes.Open ~= nil)
    UpdateStatus("Sell", Remotes.Sell ~= nil)
    UpdateStatus("Rewards", Remotes.Rewards ~= nil)
end

-- [UPDATE CRATE LIST UI]
local function UpdateCrateList()
    if not CrateScrollFrame then return end
    for _, v in pairs(CrateScrollFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    local listToUse = (SearchInput and SearchInput.Text ~= "") and FilteredCrates or KnownCrates
    
    for _, crate in ipairs(listToUse) do
        local Btn = Instance.new("TextButton")
        Btn.Text = crate
        Btn.Size = UDim2.new(1, 0, 0, 35)
        Btn.BackgroundColor3 = Theme.Sidebar
        Btn.TextColor3 = Theme.Text
        Btn.Font = Enum.Font.GothamMedium
        Btn.TextSize = 13
        Btn.Parent = CrateScrollFrame
        local CCorner = Instance.new("UICorner"); CCorner.Parent = Btn
        
        Btn.MouseButton1Click:Connect(function()
            Config.SelectedCase = crate
            Log("Selected Case: " .. crate)
        end)
    end
    CrateScrollFrame.CanvasSize = UDim2.new(0,0,0, #listToUse * 40)
end

-- [MODULE SCRAPER & DATA LOADER]
local function ScrapeCrates()
    Log("Scraping Crates...")
    local foundCrates = {}
    local Success, Module = pcall(function()
        local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
        if modulesFolder then
            local casesModule = modulesFolder:FindFirstChild("Cases")
            if casesModule and casesModule:IsA("ModuleScript") then return require(casesModule) end
        end
        return nil
    end)
    
    if Success and Module and type(Module) == "table" then
        Log("'Cases' Module Loaded Successfully.")
        LoadedCases = Module 
        for k, v in pairs(Module) do
            if type(k) == "string" then table.insert(foundCrates, k)
            elseif type(v) == "table" and v.Name then table.insert(foundCrates, v.Name)
            elseif type(v) == "string" then table.insert(foundCrates, v) end
            
            if type(v) == "table" and v.Name then
                LoadedCases[v.Name] = v
            end
        end
    else
        Log("WARN: Failed to load 'Cases' Module or it's empty.")
    end

    local unique = {}
    KnownCrates = {}
    if #foundCrates == 0 then foundCrates = {"Starter Case", "Common Case", "Rare Case"} end
    
    for _, name in ipairs(foundCrates) do
        if type(name) == "string" and #name > 2 and #name < 30 and not unique[name] then
            unique[name] = true
            table.insert(KnownCrates, name)
        end
    end
    table.sort(KnownCrates)
    UpdateCrateList()
end

local function FilterList(text)
    FilteredCrates = {}
    local lowerText = text:lower()
    for _, crate in ipairs(KnownCrates) do
        if crate:lower():find(lowerText) then table.insert(FilteredCrates, crate) end
    end
    UpdateCrateList()
end

-- [ITEM FINDER / ODDS CALCULATOR]
local function FindItem(itemName)
    if not itemName or itemName == "" then return end
    itemName = itemName:lower()
    local results = {}
    for caseName, data in pairs(LoadedCases) do
        if type(data) == "table" and data.Drops then
            for _, drop in pairs(data.Drops) do
                if drop.Item and drop.Item:lower():find(itemName) then
                    table.insert(results, {
                        Case = data.Name or caseName,
                        Item = drop.Item,
                        Odds = drop.Odds,
                        Price = data.Price or 0
                    })
                end
            end
        end
    end
    table.sort(results, function(a,b) return (a.Odds or 0) > (b.Odds or 0) end)
    
    if not ItemResultsFrame then return end
    for _, v in pairs(ItemResultsFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    for i, res in ipairs(results) do
        if i > 20 then break end 
        local Btn = Instance.new("TextButton")
        local oddsPercent = (res.Odds * 100)
        Btn.Text = string.format("%s\nCase: %s | Odds: %.4f%% | Cost: %s", res.Item, res.Case, oddsPercent, res.Price)
        Btn.Size = UDim2.new(1, 0, 0, 50)
        Btn.BackgroundColor3 = Theme.Sidebar
        Btn.TextColor3 = Theme.Success
        Btn.Font = Enum.Font.GothamMedium
        Btn.TextSize = 12
        Btn.Parent = ItemResultsFrame
        local CCorner = Instance.new("UICorner"); CCorner.Parent = Btn
        
        Btn.MouseButton1Click:Connect(function()
            Config.SelectedCase = res.Case
             StarterGui:SetCore("SendNotification", {Title="Case Selected", Text="Switched to " .. res.Case, Duration=3})
        end)
    end
    ItemResultsFrame.CanvasSize = UDim2.new(0,0,0, #results * 55)
end

-- [FILE EXPORT FUNCTIONS]
local function SaveStringToFile(fileName, content)
    Log("Attempting to save file: " .. fileName)
    local s, err = pcall(function()
        if writefile then
            writefile(fileName, content)
            return true
        end
        return false
    end)
    
    if s then
        Log("File Saved Successfully: " .. fileName)
        StarterGui:SetCore("SendNotification", {Title="FILE SAVED!", Text="Check Workspace Folder: "..fileName, Duration=5})
    else
        Log("ERROR: File Save Failed: " .. tostring(err))
        StarterGui:SetCore("SendNotification", {Title="Save Failed", Text="Your executor might not support writefile.", Duration=5})
    end
end

-- [GOD MODE DUMP]
local function GodModeDump()
    Log("STARTING GOD MODE DUMP...")
    local buffer = {}
    table.insert(buffer, "--- CASE PARADISE GOD DUMP V3.11 ---")
    table.insert(buffer, "Date: " .. os.date("%c"))
    
    -- Helper: Serialize Table
    local function serializeTable(t, indent)
        for k,v in pairs(t) do
            local keyStr = tostring(k)
            local valStr = tostring(v)
            if type(v) == "table" then
                table.insert(buffer, indent .. "[" .. keyStr .. "] (Table):")
                if indent:len() < 20 then -- Prevent infinite recursion
                     serializeTable(v, indent .. "  ")
                else
                     table.insert(buffer, indent .. "  (Max Depth Reached)")
                end
            else
                table.insert(buffer, indent .. "[" .. keyStr .. "] = " .. valStr)
            end
        end
    end

    -- 1. Dump ReplicatedStorage (Structure)
    table.insert(buffer, "\n=== REPLICATED STORAGE STRUCTURE ===")
    local function scan(obj, indent)
        pcall(function()
            table.insert(buffer, indent .. obj.Name .. " [" .. obj.ClassName .. "]")
            for _, child in pairs(obj:GetChildren()) do
                scan(child, indent .. "  ")
            end
        end)
    end
    scan(ReplicatedStorage, "")
    
    -- 2. Dump Modules Content
    table.insert(buffer, "\n=== MODULES CONTENT ===")
    local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
    if modulesFolder then
        for _, mod in pairs(modulesFolder:GetDescendants()) do
            if mod:IsA("ModuleScript") then
                table.insert(buffer, "\n-- Module: " .. mod.Name .. " (" .. mod:GetFullName() .. ") --")
                local s, data = pcall(function() return require(mod) end)
                if s and type(data) == "table" then
                    serializeTable(data, "  ")
                elseif s then
                    table.insert(buffer, "  Returned: " .. tostring(data))
                else
                    table.insert(buffer, "  Require Failed: " .. tostring(data))
                end
            end
        end
    end
    
    -- 3. Dump Workspace (Interactables)
    table.insert(buffer, "\n=== WORKSPACE INTERACTABLES ===")
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") or v:IsA("ClickDetector") or v:IsA("TouchTransmitter") then
            table.insert(buffer, "Interactable: " .. v.Name .. " | Parent: " .. v.Parent:GetFullName() .. " | Class: " .. v.ClassName)
        end
    end
    
    -- 4. Dump PlayerGui
    table.insert(buffer, "\n=== PLAYER GUI ===")
    scan(PlayerGui, "")

    -- 5. Dump Log Buffer
    table.insert(buffer, "\n=== DEBUG LOGS ===")
    for _, line in ipairs(LogBuffer) do
        table.insert(buffer, line)
    end

    table.insert(buffer, "--- END GOD DUMP ---")
    
    local content = table.concat(buffer, "\n")
    SaveStringToFile("CaseParadise_GOD_DUMP.txt", content)
    Log("GOD DUMP COMPLETE!")
end

-- [UI BUILDER]
if PlayerGui:FindFirstChild("CaseParadisePremium") then PlayerGui.CaseParadisePremium:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CaseParadisePremium"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 500) 
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -250)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 45)
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "Case Paradise | V3.11 GOD DUMP"
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.GodMode -- Red to indicate power
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 45, 1, 0)
CloseBtn.Position = UDim2.new(1, -45, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, -45)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -120, 1, -45)
Content.Position = UDim2.new(0, 120, 0, 45)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Tabs Container
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 45)
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = name
    TabBtn.TextColor3 = Theme.SubText
    TabBtn.Font = Enum.Font.GothamSemibold
    TabBtn.TextSize = 14
    TabBtn.Parent = Sidebar
    
    local TabFrame = Instance.new("ScrollingFrame")
    TabFrame.Size = UDim2.new(1, -20, 1, -20)
    TabFrame.Position = UDim2.new(0, 10, 0, 10)
    TabFrame.BackgroundTransparency = 1
    TabFrame.ScrollBarThickness = 4
    TabFrame.Visible = false
    TabFrame.Parent = Content
    
    local UIList = Instance.new("UIListLayout")
    UIList.Padding = UDim.new(0, 8)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Parent = TabFrame
    
    local function UpdateLayout() TabFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 10) end
    UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateLayout)
    
    Tabs[name] = {Btn = TabBtn, Frame = TabFrame}
    
    TabBtn.MouseButton1Click:Connect(function()
        if CurrentTab then
            CurrentTab.Frame.Visible = false
            CurrentTab.Btn.TextColor3 = Theme.SubText
        end
        CurrentTab = Tabs[name]
        CurrentTab.Frame.Visible = true
        CurrentTab.Btn.TextColor3 = Theme.Accent
    end)
end

-- UI Helpers
local function CreateSection(tabName, title)
    local Label = Instance.new("TextLabel")
    Label.Text = title:upper()
    Label.Size = UDim2.new(1, 0, 0, 25)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Theme.SubText
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Tabs[tabName].Frame
end

local function CreateToggle(tabName, text, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 40)
    Container.BackgroundColor3 = Theme.Sidebar
    Container.BorderSizePixel = 0
    Container.Parent = Tabs[tabName].Frame
    local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 6); Corner.Parent = Container
    
    local Label = Instance.new("TextLabel")
    Label.Text = text
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Theme.Text
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Container
    
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Text = ""
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -50, 0.5, -10)
    ToggleBtn.BackgroundColor3 = Theme.ToggleOff
    ToggleBtn.Parent = Container
    local ToggleCorner = Instance.new("UICorner"); ToggleCorner.CornerRadius = UDim.new(1, 0); ToggleCorner.Parent = ToggleBtn
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, 1, 0.5, -9)
    Circle.BackgroundColor3 = Theme.Text
    Circle.Parent = ToggleBtn
    local CircleCorner = Instance.new("UICorner"); CircleCorner.CornerRadius = UDim.new(1, 0); CircleCorner.Parent = Circle
    
    local on = false
    ToggleBtn.MouseButton1Click:Connect(function()
        on = not on
        pcall(function()
            if on then
                TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOn}):Play()
                TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -9)}):Play()
            else
                TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ToggleOff}):Play()
                TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 1, 0.5, -9)}):Play()
            end
            callback(on)
        end)
    end)
end

-- [BUILD TABS]
CreateTab("Main")
CreateTab("Finder")
CreateTab("Crates")
CreateTab("Debug")

-- Main Tab
CreateSection("Main", "Automation settings")
CreateToggle("Main", "Auto Open Case", function(v) Config.AutoOpen = v end)
CreateToggle("Main", "Auto Sell Items", function(v) Config.AutoSell = v end)
CreateToggle("Main", "Auto Rewards/Gifts", function(v) Config.AutoLevelCrates = v end)

-- Debug Status Indicators
local function CreateStatusLabel(name)
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = name .. ": CHECKING..."
    Lbl.Size = UDim2.new(1, 0, 0, 20)
    Lbl.BackgroundTransparency = 1
    Lbl.TextColor3 = Theme.SubText
    Lbl.Font = Enum.Font.GothamMedium
    Lbl.TextSize = 12
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Tabs.Main.Frame
    StatusLabels[name] = Lbl
end
CreateSection("Main", "Remote Status (Debug)")
CreateStatusLabel("OpenCase")
CreateStatusLabel("Sell")
CreateStatusLabel("Rewards")

-- Finder Tab
CreateSection("Finder", "Item Finder")
ItemSearchInput = Instance.new("TextBox")
ItemSearchInput.PlaceholderText = "Type item name (e.g. Ruby)"
ItemSearchInput.Text = ""
ItemSearchInput.Size = UDim2.new(1, 0, 0, 35)
ItemSearchInput.BackgroundColor3 = Theme.Search
ItemSearchInput.TextColor3 = Theme.Text
ItemSearchInput.PlaceholderColor3 = Theme.SubText
ItemSearchInput.Font = Enum.Font.Gotham
ItemSearchInput.Parent = Tabs.Finder.Frame
local ISC = Instance.new("UICorner"); ISC.Parent = ItemSearchInput

ItemSearchInput:GetPropertyChangedSignal("Text"):Connect(function() FindItem(ItemSearchInput.Text) end)

ItemResultsFrame = Instance.new("ScrollingFrame")
ItemResultsFrame.Size = UDim2.new(1, 0, 0, 200)
ItemResultsFrame.BackgroundTransparency = 1
ItemResultsFrame.Parent = Tabs.Finder.Frame
local IRLayout = Instance.new("UIListLayout"); IRLayout.Padding = UDim.new(0,5); IRLayout.Parent = ItemResultsFrame

-- Crates Tab
CreateSection("Crates", "Case Selection")
local SelectedLbl = Instance.new("TextLabel")
SelectedLbl.Text = "Selected: "..Config.SelectedCase
SelectedLbl.Size = UDim2.new(1, 0, 0, 30)
SelectedLbl.BackgroundColor3 = Theme.Accent
SelectedLbl.TextColor3 = Theme.Text
SelectedLbl.Font = Enum.Font.GothamBold
SelectedLbl.TextSize = 14
SelectedLbl.Parent = Tabs.Crates.Frame
local SelCorner = Instance.new("UICorner"); SelCorner.Parent = SelectedLbl

SearchInput = Instance.new("TextBox")
SearchInput.PlaceholderText = "Search Case Name..."
SearchInput.Text = ""
SearchInput.Size = UDim2.new(1, 0, 0, 35)
SearchInput.BackgroundColor3 = Theme.Search
SearchInput.TextColor3 = Theme.Text
SearchInput.PlaceholderColor3 = Theme.SubText
SearchInput.Font = Enum.Font.Gotham
SearchInput.Parent = Tabs.Crates.Frame
local SearchCorner = Instance.new("UICorner"); SearchCorner.Parent = SearchInput

SearchInput:GetPropertyChangedSignal("Text"):Connect(function() FilterList(SearchInput.Text) end)

CrateScrollFrame = Instance.new("ScrollingFrame")
CrateScrollFrame.Size = UDim2.new(1, 0, 0, 200)
CrateScrollFrame.BackgroundTransparency = 1
CrateScrollFrame.Parent = Tabs.Crates.Frame
local CrateLayout = Instance.new("UIListLayout"); CrateLayout.Padding = UDim.new(0,5); CrateLayout.Parent = CrateScrollFrame

-- Debug Tab
CreateSection("Debug", "GOD MODE TOOLS")

local GodDumpBtn = Instance.new("TextButton")
GodDumpBtn.Text = "GOD DUMP (Click Once & Wait)"
GodDumpBtn.Size = UDim2.new(1, 0, 0, 50)
GodDumpBtn.BackgroundColor3 = Theme.GodMode
GodDumpBtn.TextColor3 = Theme.Text
GodDumpBtn.Font = Enum.Font.GothamBold
GodDumpBtn.TextSize = 14
GodDumpBtn.Parent = Tabs.Debug.Frame
local GdCorner = Instance.new("UICorner"); GdCorner.Parent = GodDumpBtn
GodDumpBtn.MouseButton1Click:Connect(GodModeDump)

local TestOpenBtn = Instance.new("TextButton")
TestOpenBtn.Text = "TEST OPEN SINGLE CASE (LOGS)"
TestOpenBtn.Size = UDim2.new(1, 0, 0, 35)
TestOpenBtn.BackgroundColor3 = Theme.Error
TestOpenBtn.TextColor3 = Theme.Text
TestOpenBtn.Font = Enum.Font.GothamBold
TestOpenBtn.Parent = Tabs.Debug.Frame
local ToCorner = Instance.new("UICorner"); ToCorner.Parent = TestOpenBtn

TestOpenBtn.MouseButton1Click:Connect(function()
    Log("Test Button Clicked. Selected Case: " .. Config.SelectedCase)
    if Remotes.Open then
        Log("Firing Remote: " .. Remotes.Open:GetFullName())
        local s, e = pcall(function() Remotes.Open:FireServer(Config.SelectedCase) end)
        if s then Log("FireServer Success (No Error)")
        else Log("FireServer Failed: " .. tostring(e)) end
    else
        Log("Cannot Fire: Remote is NIL")
    end
end)

-- Sidebar Layout Order
local Layout = Sidebar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Sidebar)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Init
pcall(ScanRemotes)
pcall(ScrapeCrates)

-- Select First Tab
CurrentTab = Tabs.Main
Tabs.Main.Btn.TextColor3 = Theme.Accent
Tabs.Main.Frame.Visible = true

Log("Case Paradise Script V3.11 GOD DUMP Loaded")
StarterGui:SetCore("SendNotification", {Title="Script Loaded", Text="Go to Debug -> GOD DUMP", Duration=5})

-- [LOOPS]
task.spawn(function()
    while true do
        if Config.AutoOpen then
            if Remotes.Open then
                pcall(function() Remotes.Open:FireServer(Config.SelectedCase) end)
            else
                -- Don't spam warn in loop, UI indicator handles it
            end
        end
        
        if Config.AutoSell and Remotes.Sell then pcall(function() Remotes.Sell:FireServer() end) end
        task.wait(1.0) -- Slower loop to prevent rate limit spam during debug
    end
end)

task.spawn(function() 
    while true do
        if Config.AutoLevelCrates and Remotes.Rewards then
             pcall(function() Remotes.Rewards:FireServer() end) -- Generic claim
             for i=1, 9 do pcall(function() Remotes.Rewards:FireServer("Gift"..i) end) end -- Gifts
        end
        task.wait(5)
    end
end)

task.spawn(function()
    while true do
        SelectedLbl.Text = "Selected: "..Config.SelectedCase
        task.wait(0.5)
    end
end)
