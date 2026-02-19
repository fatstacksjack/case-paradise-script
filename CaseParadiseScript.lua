-- Case Paradise Script (Premium Native UI) v3.2
-- Author: Antigravity
-- Status: MODULE SCRAPER + HARDCODED REMOTES.
-- Thanks for the screenshots! Now I know exactly where to look.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [CONFIG]
local Config = {
    AutoOpen = false,
    AutoSell = false,
    AutoQuests = false,
    AutoLevelCrates = false, -- Renamed to "Auto Gifts" based on screenshot
    SelectedCase = "Starter Case" -- Will be updated by scanner
}

-- [THEME]
local Theme = {
    Background = Color3.fromRGB(25, 25, 30),
    Sidebar = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(255, 100, 0), -- Updating to Orange to look fresh
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(100, 255, 100),
    Error = Color3.fromRGB(255, 100, 100),
    ToggleOff = Color3.fromRGB(60, 60, 65),
    ToggleOn = Color3.fromRGB(0, 180, 100)
}

-- [REMOTES & DATA]
local Remotes = { Open = nil, Sell = nil, Rewards = nil, Generic = {} }
local KnownCrates = {}
local CrateScrollFrame = nil

local function ScanRemotes()
    print("Direct Remote Linking...")
    
    -- 1. HARDCODED PATHS (Based on Screenshots)
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remoteFolder then
        Remotes.Open = remoteFolder:FindFirstChild("OpenCase")
        Remotes.Sell = remoteFolder:FindFirstChild("Sell")
        Remotes.Rewards = remoteFolder:FindFirstChild("UpdateRewards") -- Likely handles claims/gifts
        
        -- Store potential "Quest" or "Claim" remotes if found by name
        for _, v in pairs(remoteFolder:GetChildren()) do
            if v.Name:lower():find("claim") or v.Name:lower():find("quest") then
                table.insert(Remotes.Generic, v)
            end
        end
    else
        warn("CRITICAL: 'Remotes' folder not found directly!")
        -- Fallback scan
        for _, child in pairs(ReplicatedStorage:GetDescendants()) do
             if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                if (name:find("open") or name:find("case")) and not Remotes.Open then Remotes.Open = child end
                if name:find("sell") and not Remotes.Sell then Remotes.Sell = child end
            end
        end
    end
end

-- [MODULE SCRAPER]
local function ScrapeCrates()
    print("Reading Game Modules for Crate List...")
    local foundCrates = {}
    
    -- 1. Try to require the 'Cases' module (Based on Screenshot: Modules -> Cases)
    local Success, Module = pcall(function()
        local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
        if modulesFolder then
            local casesModule = modulesFolder:FindFirstChild("Cases")
            if casesModule and casesModule:IsA("ModuleScript") then
                -- Try to require it
                return require(casesModule)
            end
        end
        return nil
    end)
    
    if Success and Module and type(Module) == "table" then
        print("MODULE SUCCESS! Reading case data...")
        -- Assuming module structure is { ["CaseName"] = {Data...}, ... }
        -- Or maybe keys are IDs and names are inside?
        -- Let's just grab all string keys or .Name fields
        for k, v in pairs(Module) do
            if type(k) == "string" then
                table.insert(foundCrates, k)
            elseif type(v) == "table" and v.Name then
                table.insert(foundCrates, v.Name)
            elseif type(v) == "string" then
                table.insert(foundCrates, v)
            end
        end
        print("Found " .. #foundCrates .. " crates from Module.")
    else
        warn("MODULE REQUIRE FAILED. Fallback to scraping GUI/ReplicatedStorage.")
        -- Fallback: Look for "CaseTemplate" or gui names
        local gui = PlayerGui:FindFirstChild("Shop") or PlayerGui
        for _, v in pairs(gui:GetDescendants()) do
            if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text:lower():find("case") then
                table.insert(foundCrates, v.Text) -- Use displayed text
            end
        end
    end

    -- Clean List
    local unique = {}
    KnownCrates = {}
    
    -- Always add defaults just in case
    if #foundCrates == 0 then
        foundCrates = {"Starter Case", "Common Case", "Uncommon Case", "Rare Case", "Epic Case", "Legendary Case"} 
    end
    
    for _, name in ipairs(foundCrates) do
        -- Filter out garbage names
        if type(name) == "string" and #name > 3 and #name < 30 and not unique[name] then
            unique[name] = true
            table.insert(KnownCrates, name)
        end
    end
    table.sort(KnownCrates)
    
    -- UPDATE UI
    if CrateScrollFrame then
        for _, v in pairs(CrateScrollFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        for _, crate in ipairs(KnownCrates) do
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
                -- Update Selected Label elsewhere
            end)
        end
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
MainFrame.Size = UDim2.new(0, 500, 0, 400)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Top Bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Text = "Case Paradise | V3.2 Module Scanner"
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Text
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "X"
CloseBtn.Size = UDim2.new(0, 40, 1, 0)
CloseBtn.Position = UDim2.new(1, -40, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Parent = TopBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 120, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -120, 1, -40)
Content.Position = UDim2.new(0, 120, 0, 40)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Tabs Container
local Tabs = {}
local CurrentTab = nil

local function CreateTab(name)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 40)
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

-- UI Element Helpers
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
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn
    
    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, 1, 0.5, -9)
    Circle.BackgroundColor3 = Theme.Text
    Circle.Parent = ToggleBtn
    
    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle
    
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
CreateSection("Main", "Automation")
CreateToggle("Main", "Auto Open Case", function(v) Config.AutoOpen = v; if v then ScanRemotes() end end)
CreateToggle("Main", "Auto Sell Items", function(v) Config.AutoSell = v; if v then ScanRemotes() end end)
CreateToggle("Main", "Auto Rewards/Gifts", function(v) Config.AutoLevelCrates = v; if v then ScanRemotes() end end)

-- Crates Tab
CreateSection("Crates", "Click to Select Case")

local CrateDisplay = Instance.new("TextLabel")
CrateDisplay.Text = "Selected: "..Config.SelectedCase
CrateDisplay.Size = UDim2.new(1, 0, 0, 30)
CrateDisplay.BackgroundColor3 = Theme.Accent
CrateDisplay.TextColor3 = Theme.Text
CrateDisplay.Font = Enum.Font.GothamBold
CrateDisplay.TextSize = 14
CrateDisplay.Parent = Tabs.Crates.Frame
local CornerCrate = Instance.new("UICorner"); CornerCrate.Parent = CrateDisplay

CrateScrollFrame = Tabs.Crates.Frame 

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Text = "Scan Modules Again"
RefreshBtn.Size = UDim2.new(1, 0, 0, 35)
RefreshBtn.BackgroundColor3 = Theme.Sidebar
RefreshBtn.TextColor3 = Theme.Accent
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Parent = Tabs.Crates.Frame
local RefreshCorner = Instance.new("UICorner"); RefreshCorner.Parent = RefreshBtn
RefreshBtn.MouseButton1Click:Connect(ScrapeCrates)

local ManualBox = Instance.new("TextBox")
ManualBox.PlaceholderText = "Or Type Case Name Here..."
ManualBox.Text = ""
ManualBox.Size = UDim2.new(1, 0, 0, 35)
ManualBox.BackgroundColor3 = Theme.Sidebar
ManualBox.TextColor3 = Theme.Text
ManualBox.Font = Enum.Font.Gotham
ManualBox.Parent = Tabs.Crates.Frame
local ManualCorner = Instance.new("UICorner"); ManualCorner.Parent = ManualBox
ManualBox.FocusLost:Connect(function()
    if ManualBox.Text ~= "" then
        Config.SelectedCase = ManualBox.Text
        CrateDisplay.Text = "Selected: "..ManualBox.Text
    end
end)

-- Debug Tab (Status)
CreateSection("Debug", "Remote Status")

local function AddStatus(name, key)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundTransparency = 1
    Frame.Parent = Tabs.Debug.Frame
    
    local Lbl = Instance.new("TextLabel")
    Lbl.Text = name
    Lbl.Size = UDim2.new(0.7, 0, 1, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.TextColor3 = Theme.Text
    Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left
    Lbl.Parent = Frame
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 10, 0, 10)
    Indicator.Position = UDim2.new(1, -20, 0.5, -5)
    Indicator.BackgroundColor3 = Theme.Error
    Indicator.Parent = Frame
    
    local IndCorner = Instance.new("UICorner"); IndCorner.CornerRadius = UDim.new(1,0); IndCorner.Parent = Indicator
    
    task.spawn(function()
        while true do
            if Remotes[key] then Indicator.BackgroundColor3 = Theme.Success else Indicator.BackgroundColor3 = Theme.Error end
            task.wait(1)
        end
    end)
end

AddStatus("OpenCase Remote", "Open")
AddStatus("Sell Remote", "Sell")
AddStatus("UpdateRewards (Gifts)", "Rewards")

-- Sidebar Layout Order
local Layout = Sidebar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Sidebar)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Init
pcall(ScanRemotes)
pcall(ScrapeCrates)

-- Select First Tab
Tabs.Main.Btn.TextColor3 = Theme.Accent
Tabs.Main.Frame.Visible = true

print("Case Paradise Script V3.2 Loaded")

-- [AUTOMATION LOOPS]
task.spawn(function()
    while true do
        if Config.AutoOpen and Remotes.Open then
             pcall(function() 
                Remotes.Open:FireServer(Config.SelectedCase)
            end)
        end
        if Config.AutoSell and Remotes.Sell then
             pcall(function() 
                Remotes.Sell:FireServer()
            end)
        end
        task.wait(0.5) 
    end
end)

task.spawn(function() 
    while true do
        if Config.AutoLevelCrates then
             -- Try firing found reward remotes
             if Remotes.Rewards then pcall(function() Remotes.Rewards:FireServer() end) end
             
             -- Try firing any generic remotes found
             for _, r in pairs(Remotes.Generic) do
                 pcall(function() r:FireServer() end)
             end
             
             -- Try claiming Gifts 1-9 (from screenshot)
             -- Assuming OpenCase or UpdateRewards handles them?
             -- Usually "Gifts" are clicked. 
             -- We can try to FireServer("Gift1") etc on the Rewards remote
             if Remotes.Rewards then
                for i=1, 9 do
                     pcall(function() Remotes.Rewards:FireServer("Gift"..i) end)
                end
             end
        end
        task.wait(5)
    end
end)
