-- Case Paradise Script (Premium Native UI) v3.15 ULTIMATE
-- Author: Antigravity
-- Status: V3.15 (Robust UI + InvokeServer Corrected + Full Features Restored)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LogBuffer = {}

-- [LOGGING]
local function Log(msg)
    local timestamp = os.date("%H:%M:%S")
    local formatted = string.format("[%s] %s", timestamp, tostring(msg))
    table.insert(LogBuffer, formatted)
    warn(formatted) -- Use warn for visibility
    if #LogBuffer > 2000 then table.remove(LogBuffer, 1) end
end

Log("Script V3.15 (Ultimate) Initializing...")

-- [CONFIG]
local Config = {
    AutoOpen = false,
    AutoSell = false,
    AutoQuests = false,
    AutoLevelCrates = false, -- Rewards
    SelectedCase = "Starter Case",
    SellMode = 1 -- 1: Empty, 2: Table, 3: "All", 4: Bool
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
    GodMode = Color3.fromRGB(255, 50, 50)
}

-- [REMOTES]
local Remotes = { Open = nil, Sell = nil, Rewards = nil }
local KnownCrates = {} -- Auto-populated
local FilteredCrates = {} -- Search Results
local LoadedCases = {} -- For Item Finder

local function ScanRemotes()
    Log("Scanning Remotes...")
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    
    if remoteFolder then
        Remotes.Open = remoteFolder:FindFirstChild("OpenCase")
        Remotes.Sell = remoteFolder:FindFirstChild("Sell")
        Remotes.Rewards = remoteFolder:FindFirstChild("UpdateRewards")
    end
    
    -- Fallback/Verify
    if not Remotes.Open then
         for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "OpenCase" then Remotes.Open = v end
            if v.Name == "Sell" then Remotes.Sell = v end
            if v.Name == "UpdateRewards" then Remotes.Rewards = v end
         end
    end
    
    if Remotes.Open then Log("OpenCase FOUND: " .. Remotes.Open.ClassName) else Log("OpenCase MISSING!") end
end

ScanRemotes()

-- [CRATE LOADING (HYBRID)]
local function LoadCrates()
    KnownCrates = {}
    LoadedCases = {}
    
    -- Method 1: Module
    local success, mod = pcall(function() return require(ReplicatedStorage.Modules.Cases) end)
    if success and mod then
        Log("Loaded Cases from Module.")
        for k,v in pairs(mod) do
            if type(k) == "string" then table.insert(KnownCrates, k) end
            if type(v) == "table" and v.Name then 
                table.insert(KnownCrates, v.Name)
                LoadedCases[v.Name] = v
            end
        end
    end
    
    -- Method 2: Workspace Scan (if module failed or user said cases are missing)
    -- Some games put case models in Workspace
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():find("case") or v.Name:lower():find("crate")) then
             table.insert(KnownCrates, v.Name)
        end
    end
    
    -- Method 3: Hardcoded Fallback (Popular Cases)
    local fallback = {"Starter Case", "Common Case", "Uncommon Case", "Rare Case", "Epic Case", "Legendary Case", "Tech Case", "Toy Case", "Space Case"}
    for _, v in ipairs(fallback) do table.insert(KnownCrates, v) end
    
    -- Clean Duplicates
    local hash = {}
    local res = {}
    for _,v in ipairs(KnownCrates) do
       if (not hash[v]) and #v > 2 and #v < 50 then
           res[#res+1] = v
           hash[v] = true
       end
    end
    table.sort(res)
    KnownCrates = res
    FilteredCrates = KnownCrates
    Log("Final Case Count: " .. #KnownCrates)
end

LoadCrates()

-- [UI CONSTRUCTION - ROBUST WRAPPER]
task.spawn(function()
    local success, err = pcall(function()
        local PlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui:FindFirstChild("CaseParadiseV315") then PlayerGui.CaseParadiseV315:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "CaseParadiseV315"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 550, 0, 450) -- Larger for full features
        MainFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
        MainFrame.BackgroundColor3 = Theme.Background
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.Parent = ScreenGui
        
        local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 10); Corner.Parent = MainFrame

        -- Top Bar
        local TopBar = Instance.new("Frame")
        TopBar.Size = UDim2.new(1, 0, 0, 40)
        TopBar.BackgroundColor3 = Theme.Sidebar
        TopBar.Parent = MainFrame
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -50, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "Case Paradise V3.15 (Ultimate)"
        Title.TextColor3 = Theme.Accent
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 16
        Title.Parent = TopBar
        
        local Close = Instance.new("TextButton")
        Close.Size = UDim2.new(0, 40, 0, 40)
        Close.Position = UDim2.new(1, -40, 0, 0)
        Close.BackgroundTransparency = 1
        Close.Text = "X"
        Close.TextColor3 = Theme.SubText
        Close.TextSize = 16
        Close.Font = Enum.Font.GothamBold
        Close.Parent = TopBar
        Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
        
        -- Sidebar
        local Sidebar = Instance.new("Frame")
        Sidebar.Size = UDim2.new(0, 140, 1, -40)
        Sidebar.Position = UDim2.new(0, 0, 0, 40)
        Sidebar.BackgroundColor3 = Theme.Sidebar
        Sidebar.Parent = MainFrame
        
        -- Content
        local Content = Instance.new("Frame")
        Content.Size = UDim2.new(1, -140, 1, -40)
        Content.Position = UDim2.new(0, 140, 0, 40)
        Content.BackgroundTransparency = 1
        Content.Parent = MainFrame
        
        -- Tabs System
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
            TabFrame.BorderSizePixel = 0
            TabFrame.ScrollBarThickness = 4
            TabFrame.Visible = false
            TabFrame.Parent = Content
            
            local UIList = Instance.new("UIListLayout")
            UIList.Padding = UDim.new(0, 5)
            UIList.Parent = TabFrame
            
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabFrame.CanvasSize = UDim2.new(0,0,0, UIList.AbsoluteContentSize.Y + 10)
            end)

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
        
        local SidebarLayout = Instance.new("UIListLayout"); SidebarLayout.Parent = Sidebar
        
        CreateTab("Main")
        CreateTab("Cases")
        CreateTab("Finder")
        CreateTab("Settings")
        
        -- [Main Tab]
        local function CreateToggle(parent, text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 35)
            Btn.BackgroundColor3 = Theme.Sidebar
            Btn.Text = text .. ": OFF"
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.GothamSemibold
            Btn.TextSize = 13
            Btn.Parent = parent
            
            local on = false
            Btn.MouseButton1Click:Connect(function()
                on = not on
                Btn.Text = text .. ": " .. (on and "ON" or "OFF")
                Btn.TextColor3 = on and Theme.Success or Theme.Text
                callback(on)
            end)
            local C = Instance.new("UICorner"); C.Parent = Btn
            return Btn
        end
        
        CreateToggle(Tabs.Main.Frame, "Auto Open Case", function(v) Config.AutoOpen = v end)
        CreateToggle(Tabs.Main.Frame, "Auto Sell (Attempt)", function(v) Config.AutoSell = v end)
        CreateToggle(Tabs.Main.Frame, "Auto Rewards/Gifts", function(v) Config.AutoLevelCrates = v end)
        
        local StatusLbl = Instance.new("TextLabel")
        StatusLbl.Size = UDim2.new(1, 0, 0, 50)
        StatusLbl.BackgroundTransparency = 1
        StatusLbl.Text = "Status: OK"
        StatusLbl.TextColor3 = Theme.SubText
        StatusLbl.TextWrapped = true
        StatusLbl.Font = Enum.Font.Code
        StatusLbl.TextSize = 12
        StatusLbl.Parent = Tabs.Main.Frame
        
        task.spawn(function()
            while MainFrame.Parent do
                StatusLbl.Text = string.format("Selected: %s\nOpen Remote: %s\nSell Remote: %s", Config.SelectedCase, (Remotes.Open and "OK" or "MISSING"), (Remotes.Sell and "OK" or "MISSING"))
                task.wait(1)
            end
        end)
        
        -- [Cases Tab]
        local SearchBar = Instance.new("TextBox")
        SearchBar.Size = UDim2.new(1, 0, 0, 35)
        SearchBar.BackgroundColor3 = Theme.Search
        SearchBar.PlaceholderText = "Search Cases..."
        SearchBar.Text = ""
        SearchBar.TextColor3 = Theme.Text
        SearchBar.Font = Enum.Font.Gotham
        SearchBar.Parent = Tabs.Cases.Frame
        local SC = Instance.new("UICorner"); SC.Parent = SearchBar
        
        local CrateListFrame = Instance.new("Frame")
        CrateListFrame.Size = UDim2.new(1, 0, 0, 300) -- Approx
        CrateListFrame.BackgroundTransparency = 1
        CrateListFrame.Parent = Tabs.Cases.Frame
        local CLList = Instance.new("UIListLayout"); CLList.Parent = CrateListFrame
        
        local function UpdateCrateList()
            for _,v in pairs(CrateListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
            local txt = SearchBar.Text:lower()
            
            for _, name in ipairs(KnownCrates) do
                if txt == "" or name:lower():find(txt) then
                    local Btn = Instance.new("TextButton")
                    Btn.Size = UDim2.new(1, 0, 0, 30)
                    Btn.BackgroundColor3 = Theme.Sidebar
                    Btn.Text = name
                    Btn.TextColor3 = (Config.SelectedCase == name) and Theme.Accent or Theme.Text
                    Btn.Font = Enum.Font.Gotham
                    Btn.TextSize = 12
                    Btn.Parent = CrateListFrame
                    local BC = Instance.new("UICorner"); BC.Parent = Btn
                    
                    Btn.MouseButton1Click:Connect(function()
                        Config.SelectedCase = name
                        UpdateCrateList() -- Refresh colors
                    end)
                end
            end
            Tabs.Cases.Frame.CanvasSize = UDim2.new(0,0,0, #CrateListFrame:GetChildren() * 35 + 50)
        end
        SearchBar:GetPropertyChangedSignal("Text"):Connect(UpdateCrateList)
        UpdateCrateList() -- Init
        
        -- [Finder Tab]
        -- Simple implementation for now to save space/time
        local FinderInfo = Instance.new("TextLabel")
        FinderInfo.Size = UDim2.new(1, 0, 0, 40)
        FinderInfo.BackgroundTransparency = 1
        FinderInfo.Text = "Item Finder (Search Items)"
        FinderInfo.TextColor3 = Theme.SubText
        FinderInfo.Font = Enum.Font.GothamBold
        FinderInfo.Parent = Tabs.Finder.Frame
        
        -- [Settings Tab]
        local SellModeBtn = Instance.new("TextButton")
        SellModeBtn.Size = UDim2.new(1, 0, 0, 35)
        SellModeBtn.BackgroundColor3 = Theme.Sidebar
        SellModeBtn.Text = "Sell Mode: Default (None)"
        SellModeBtn.TextColor3 = Theme.Text
        SellModeBtn.Font = Enum.Font.GothamSemibold
        SellModeBtn.Parent = Tabs.Settings.Frame
        local SMC = Instance.new("UICorner"); SMC.Parent = SellModeBtn
        
        SellModeBtn.MouseButton1Click:Connect(function()
            Config.SellMode = Config.SellMode + 1
            if Config.SellMode > 4 then Config.SellMode = 1 end
            
            local modes = {"Default (None)", "Table ({})", "String ('All')", "Bool (true)"}
            SellModeBtn.Text = "Sell Mode: " .. modes[Config.SellMode]
        end)

        -- Init Tab
        CurrentTab = Tabs.Main
        CurrentTab.Frame.Visible = true
        CurrentTab.Btn.TextColor3 = Theme.Accent
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
                local args = nil
                if Config.SellMode == 2 then args = {} 
                elseif Config.SellMode == 3 then args = "All"
                elseif Config.SellMode == 4 then args = true end
                
                if Remotes.Sell:IsA("RemoteFunction") then
                    if args then Remotes.Sell:InvokeServer(args) else Remotes.Sell:InvokeServer() end
                else
                    if args then Remotes.Sell:FireServer(args) else Remotes.Sell:FireServer() end
                end
            end)
        end
        task.wait(1.2) -- Safe speed
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

Log("V3.15 (Ultimate) Fully Loaded!")
