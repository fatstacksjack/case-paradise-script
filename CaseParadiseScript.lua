-- Case Paradise Script (Premium Native UI) v3
-- Author: Antigravity
-- Features: Modern Dark Theme, Automated Logic, Crate List, Status Dashboard.
-- No external libraries. 100% Native.

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
    AutoLevelCrates = false,
    SelectedCase = "Starter Case"
}

-- [THEME]
local Theme = {
    Background = Color3.fromRGB(25, 25, 30),
    Sidebar = Color3.fromRGB(35, 35, 40),
    Accent = Color3.fromRGB(0, 120, 215),
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(150, 150, 150),
    Success = Color3.fromRGB(100, 255, 100),
    Error = Color3.fromRGB(255, 100, 100),
    ToggleOff = Color3.fromRGB(60, 60, 65),
    ToggleOn = Color3.fromRGB(0, 180, 100)
}

-- [REMOTES]
local Remotes = { Open = nil, Sell = nil, Quest = nil, Level = nil }

local function ScanRemotes()
    for _, child in pairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local name = child.Name:lower()
            if (name:find("open") or name:find("buy") or name:find("case")) and not Remotes.Open then Remotes.Open = child end
            if name:find("sell") and not Remotes.Sell then Remotes.Sell = child end
            if (name:find("quest") or name:find("claim")) and not Remotes.Quest then Remotes.Quest = child end
            if (name:find("level") or name:find("reward")) and not Remotes.Level then Remotes.Level = child end
        end
    end
end
pcall(ScanRemotes)

-- [UI BUILDER]
if PlayerGui:FindFirstChild("CaseParadisePremium") then PlayerGui.CaseParadisePremium:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CaseParadisePremium"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -175)
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
Title.Text = "Case Paradise | V3"
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
    
    -- List layout logic
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
CreateTab("Settings")

-- Main Tab
CreateSection("Main", "Automation")
CreateToggle("Main", "Auto Open Case", function(v) Config.AutoOpen = v; if v then ScanRemotes() end end)
CreateToggle("Main", "Auto Sell Items", function(v) Config.AutoSell = v; if v then ScanRemotes() end end)
CreateToggle("Main", "Auto Do Quests", function(v) Config.AutoQuests = v; if v then ScanRemotes() end end)
CreateToggle("Main", "Auto Level Crates", function(v) Config.AutoLevelCrates = v end)

-- Crates Tab (Scrolling List)
CreateSection("Crates", "Click to Select Case")

local CrateListAPI = {}
local CrateDisplay = Instance.new("TextLabel")
CrateDisplay.Text = "Selected: "..Config.SelectedCase
CrateDisplay.Size = UDim2.new(1, 0, 0, 30)
CrateDisplay.BackgroundColor3 = Theme.Accent
CrateDisplay.TextColor3 = Theme.Text
CrateDisplay.Font = Enum.Font.GothamBold
CrateDisplay.TextSize = 14
CrateDisplay.Parent = Tabs.Crates.Frame
local CornerCrate = Instance.new("UICorner"); CornerCrate.Parent = CrateDisplay

local KnownCrates = {
    "Starter Case", "Common Case", "Uncommon Case", "Rare Case", 
    "Epic Case", "Legendary Case", "Mythical Case", "Candy Case",
    "Toy Case", "Space Case", "Void Case", "Ocean Case"
}

for _, crate in ipairs(KnownCrates) do
    local Btn = Instance.new("TextButton")
    Btn.Text = crate
    Btn.Size = UDim2.new(1, 0, 0, 35)
    Btn.BackgroundColor3 = Theme.Sidebar
    Btn.TextColor3 = Theme.Text
    Btn.Font = Enum.Font.GothamMedium
    Btn.TextSize = 13
    Btn.Parent = Tabs.Crates.Frame
    
    local CCorner = Instance.new("UICorner")
    CCorner.Parent = Btn
    
    Btn.MouseButton1Click:Connect(function()
        Config.SelectedCase = crate
        CrateDisplay.Text = "Selected: "..crate
    end)
end

-- Settings Tab (Remote Status)
CreateSection("Settings", "Remote Status")

local function AddStatus(name, key)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, 0, 0, 30)
    Frame.BackgroundTransparency = 1
    Frame.Parent = Tabs.Settings.Frame
    
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

AddStatus("Open Remote", "Open")
AddStatus("Sell Remote", "Sell")
AddStatus("Quest Remote", "Quest")
AddStatus("Level Remote", "Level")

local ScanBtn = Instance.new("TextButton")
ScanBtn.Text = "Re-Scan Remotes"
ScanBtn.Size = UDim2.new(1, 0, 0, 40)
ScanBtn.BackgroundColor3 = Theme.Accent
ScanBtn.TextColor3 = Theme.Text
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.Parent = Tabs.Settings.Frame
local ScanCorner = Instance.new("UICorner"); ScanCorner.Parent = ScanBtn; 
ScanBtn.MouseButton1Click:Connect(ScanRemotes)

-- [AUTOMATION LOGIC]

task.spawn(function()
    while true do
        if Config.AutoOpen and Remotes.Open then
             pcall(function() 
                if Remotes.Open:IsA("RemoteEvent") then Remotes.Open:FireServer(Config.SelectedCase) 
                else Remotes.Open:InvokeServer(Config.SelectedCase) end 
            end)
        end
        if Config.AutoSell and Remotes.Sell then
             pcall(function() 
                if Remotes.Sell:IsA("RemoteEvent") then Remotes.Sell:FireServer() else Remotes.Sell:InvokeServer() end 
            end)
        end
        task.wait(0.5) -- Fast loop for opening/selling
    end
end)

task.spawn(function() 
    while true do
        if Config.AutoQuests and Remotes.Quest then
             pcall(function() 
                if Remotes.Quest:IsA("RemoteEvent") then 
                    Remotes.Quest:FireServer("Claim")
                    Remotes.Quest:FireServer("Equip")
                end 
            end)
        end
        if Config.AutoLevelCrates then
             -- Try dynamic find for level crates if remote is missing
             if not Remotes.Level then ScanRemotes() end
             if Remotes.Level then pcall(function() Remotes.Level:FireServer() end) end
        end
        task.wait(5) -- Slower loop for quests/levels
    end
end)

-- Sidebar Layout Order
local Layout = Sidebar:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Sidebar)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Select First Tab
Tabs.Main.Btn.TextColor3 = Theme.Accent
Tabs.Main.Frame.Visible = true

print("Case Paradise Script V3 Loaded")
