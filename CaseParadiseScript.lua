-- Case Paradise Script (Premium Native UI) v3.6
-- Author: Antigravity
-- Status: SEARCH BAR + FILE EXPORT + COPY (setclipboard)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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
    Search = Color3.fromRGB(40, 40, 45)
}

-- [REMOTES & DATA]
local Remotes = { Open = nil, Sell = nil, Rewards = nil, Generic = {} }
local KnownCrates = {} 
local FilteredCrates = {} 
local CrateScrollFrame = nil
local SearchInput = nil

local function ScanRemotes()
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
        for _, child in pairs(ReplicatedStorage:GetDescendants()) do
             if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                if (name:find("open") or name:find("case")) and not Remotes.Open then Remotes.Open = child end
                if name:find("sell") and not Remotes.Sell then Remotes.Sell = child end
            end
        end
    end
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
            -- Visual feedback
        end)
    end
    CrateScrollFrame.CanvasSize = UDim2.new(0,0,0, #listToUse * 40)
end

-- [MODULE SCRAPER]
local function ScrapeCrates()
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
        for k, v in pairs(Module) do
            if type(k) == "string" then table.insert(foundCrates, k)
            elseif type(v) == "table" and v.Name then table.insert(foundCrates, v.Name)
            elseif type(v) == "string" then table.insert(foundCrates, v) end
        end
    else
        local gui = PlayerGui:FindFirstChild("Shop") or PlayerGui
        for _, v in pairs(gui:GetDescendants()) do
            if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text:lower():find("case") then
                table.insert(foundCrates, v.Text)
            end
        end
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

-- [DEEP MODULE SCAN & EXPORT]
local function DeepScanExport()
    print("--- STARTING EXPORT ---")
    local Success, Cases = pcall(function() return require(ReplicatedStorage.Modules.Cases) end)
    
    if not Success then 
        warn("Failed to require Cases module.")
        StarterGui:SetCore("SendNotification", {Title="Export Failed", Text="Could not require Cases module.", Duration=5})
        return 
    end
    
    local buffer = {}
    table.insert(buffer, "--- CASE PARADISE MODULE DUMP ---")
    
    local function serializeTable(t, indent)
        for k,v in pairs(t) do
            local keyStr = tostring(k)
            local valStr = tostring(v)
            if type(v) == "table" then
                table.insert(buffer, indent .. "[" .. keyStr .. "] (Table):")
                serializeTable(v, indent .. "  ")
            else
                table.insert(buffer, indent .. "[" .. keyStr .. "] = " .. valStr)
            end
        end
    end
    
    -- Try to serialize
    local success, err = pcall(function()
        table.insert(buffer, "Module: Cases")
        serializeTable(Cases, "")
        table.insert(buffer, "--- END DUMP ---")
    end)
    
    local fileContent = table.concat(buffer, "\n")
    
    -- 1. Try SetClipboard (Best option)
    local clipboardSuccess, cerr = pcall(function()
        if setclipboard then
            setclipboard(fileContent)
            return true
        end
        return false
    end)

    if clipboardSuccess then
        StarterGui:SetCore("SendNotification", {Title="COPIED TO CLIPBOARD!", Text="Paste it into the chat!", Duration=5})
        return
    end

    -- 2. Try WriteFile (Backup)
    local fileSuccess, ferr = pcall(function()
        if writefile then
            writefile("CaseParadise_Dump.txt", fileContent)
            return true
        end
        return false
    end)
    
    if fileSuccess then
        print("DUMP SAVED TO WORKSPACE FOLDER: CaseParadise_Dump.txt")
        StarterGui:SetCore("SendNotification", {Title="Saved as File", Text="Check workspace/CaseParadise_Dump.txt", Duration=5})
    else
        -- 3. Last Resort: Print to Console
        print(fileContent)
        warn("Could not Copy or Save. Printing to console (F9) instead.")
        StarterGui:SetCore("SendNotification", {Title="Export Failed", Text="Check console (F9). Copy/Paste failed.", Duration=5})
    end
end

-- [UI BUILDER]
if PlayerGui:FindFirstChild("CaseParadisePremium") then PlayerGui.CaseParadisePremium:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CaseParadisePremium"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 420)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -210)
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
Title.Text = "Case Paradise | V3.6 Clipboard"
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Text
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
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Container
    
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
CreateTab("Crates")
CreateTab("Debug")

-- Main Tab
CreateSection("Main", "Automation settings")
CreateToggle("Main", "Auto Open Case", function(v) Config.AutoOpen = v end)
CreateToggle("Main", "Auto Sell Items", function(v) Config.AutoSell = v end)
CreateToggle("Main", "Auto Rewards/Gifts", function(v) Config.AutoLevelCrates = v end)

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

-- Search Bar
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

SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
    FilterList(SearchInput.Text)
end)

CrateScrollFrame = Instance.new("ScrollingFrame")
CrateScrollFrame.Size = UDim2.new(1, 0, 0, 200)
CrateScrollFrame.BackgroundTransparency = 1
CrateScrollFrame.Parent = Tabs.Crates.Frame
local CrateLayout = Instance.new("UIListLayout"); CrateLayout.Padding = UDim.new(0,5); CrateLayout.Parent = CrateScrollFrame

-- Debug Tab
CreateSection("Debug", "Power Tools")
local DeepScanBtn = Instance.new("TextButton")
DeepScanBtn.Text = "COPY DATA TO CLIPBOARD"
DeepScanBtn.Size = UDim2.new(1, 0, 0, 40)
DeepScanBtn.BackgroundColor3 = Theme.Accent
DeepScanBtn.TextColor3 = Theme.Text
DeepScanBtn.Font = Enum.Font.GothamBold
DeepScanBtn.Parent = Tabs.Debug.Frame
local DsCorner = Instance.new("UICorner"); DsCorner.Parent = DeepScanBtn
DeepScanBtn.MouseButton1Click:Connect(DeepScanExport)

local RefreshBtn2 = Instance.new("TextButton")
RefreshBtn2.Text = "Refresh Crate List"
RefreshBtn2.Size = UDim2.new(1, 0, 0, 35)
RefreshBtn2.BackgroundColor3 = Theme.Sidebar
RefreshBtn2.TextColor3 = Theme.SubText
RefreshBtn2.Font = Enum.Font.GothamBold
RefreshBtn2.Parent = Tabs.Debug.Frame
local RfCorner = Instance.new("UICorner"); RfCorner.Parent = RefreshBtn2
RefreshBtn2.MouseButton1Click:Connect(ScrapeCrates)

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

print("Case Paradise Script V3.6 Loaded")

-- [LOOPS]
task.spawn(function()
    while true do
        if Config.AutoOpen and Remotes.Open then pcall(function() Remotes.Open:FireServer(Config.SelectedCase) end) end
        if Config.AutoSell and Remotes.Sell then pcall(function() Remotes.Sell:FireServer() end) end
        task.wait(0.5) 
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
