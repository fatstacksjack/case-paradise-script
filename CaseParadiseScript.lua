-- Case Paradise Script (Premium Native UI) v3.16 SCRIPT SCANNER
-- Author: Antigravity
-- Status: V3.16 (Script Scanner + UI Spy)

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
    warn(formatted)
    if #LogBuffer > 2000 then table.remove(LogBuffer, 1) end
end

Log("Script V3.16 (Scanner) Initializing...")

-- [CONFIG]
local Config = {
    AutoOpen = false,
    AutoSell = false,
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
    Spy = Color3.fromRGB(255, 50, 200) -- Pink for Spy
}

-- [REMOTES]
local Remotes = { Open = nil, Sell = nil, Rewards = nil }
local KnownCrates = {}

local function ScanRemotes()
    Log("Scanning Remotes...")
    local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remoteFolder then
        Remotes.Open = remoteFolder:FindFirstChild("OpenCase")
        Remotes.Sell = remoteFolder:FindFirstChild("Sell")
        Remotes.Rewards = remoteFolder:FindFirstChild("UpdateRewards")
    else
         for _, v in pairs(ReplicatedStorage:GetDescendants()) do
            if v.Name == "OpenCase" then Remotes.Open = v end
            if v.Name == "Sell" then Remotes.Sell = v end
            if v.Name == "UpdateRewards" then Remotes.Rewards = v end
         end
    end
end
ScanRemotes()

-- [CRATE LOADING (HYBRID)]
local function LoadCrates()
    KnownCrates = {}
    -- Method 1: Module
    local success, mod = pcall(function() return require(ReplicatedStorage.Modules.Cases) end)
    if success and mod then
        for k,v in pairs(mod) do
            if type(k) == "string" then table.insert(KnownCrates, k) end
            if type(v) == "table" and v.Name then table.insert(KnownCrates, v.Name) end
        end
    end
    -- Method 2: Workspace Scan
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():find("case") or v.Name:lower():find("crate")) then
             table.insert(KnownCrates, v.Name)
        end
    end
    -- Method 3: Fallback
    if #KnownCrates == 0 then
        local fallback = {"Starter Case", "Common Case", "Uncommon Case", "Rare Case", "Epic Case", "Legendary Case", "Tech Case", "Toy Case", "Space Case"}
        for _, v in ipairs(fallback) do table.insert(KnownCrates, v) end
    end
    
    local hash = {}
    local res = {}
    for _,v in ipairs(KnownCrates) do
       if (not hash[v]) and #v > 2 then res[#res+1] = v; hash[v] = true end
    end
    table.sort(res)
    KnownCrates = res
end
LoadCrates()

-- [SCANNER UTILS]
local function ScanScriptsForString(query)
    Log("Scanning ALL LocalScripts for: '" .. query .. "'")
    local hits = 0
    
    local content = ""
    
    local function scan(obj)
        for _, v in pairs(obj:GetDescendants()) do
            if v:IsA("LocalScript") or v:IsA("ModuleScript") then
                local s, src = pcall(function() return v.Source end)
                -- If direct source read fails (likely), try getscriptsource if available
                if not s or src == "" then
                     if getscriptsource then
                        s, src = pcall(function() return getscriptsource(v) end)
                     elseif decompile then
                        s, src = pcall(function() return decompile(v) end)
                     end
                end
                
                if s and src and src:find(query) then
                    hits = hits + 1
                    local snippet = src:sub(src:find(query)-100, src:find(query)+100)
                    Log("HIT! Found in: " .. v:GetFullName())
                    Log("Snippet: " .. snippet)
                    
                    content = content .. "\n\n----------------\nFOUND IN: " .. v:GetFullName() .. "\n" .. snippet
                end
            end
        end
    end
    
    scan(Players.LocalPlayer.PlayerGui)
    scan(Players.LocalPlayer.PlayerScripts)
    scan(ReplicatedStorage)
    
    if hits == 0 then Log("No matches found for '"..query.."'. (Executor might not run decompile/getscriptsource)") end
    
    -- Save dump if hits
    if hits > 0 and writefile then
        writefile("CaseParadise_Scanner_Hit.txt", content)
        Log("Saved hits to 'CaseParadise_Scanner_Hit.txt'")
    end
end

local function AnalyzeSellButton()
    Log("Analyzing GUI for 'Sell' Button...")
    local found = nil
    for _, v in pairs(Players.LocalPlayer.PlayerGui:GetDescendants()) do
        if (v:IsA("TextButton") or v:IsA("ImageButton")) and v.Visible then
            if (v:IsA("TextButton") and v.Text:lower():find("sell")) or v.Name:lower():find("sell") then
                Log("Potential Sell Button: " .. v:GetFullName())
                found = v
            end
        end
    end
    
    if found then
        -- Check connections? (Executor specific)
        Log("Found Target: " .. found.Name)
        -- Try to find scripts inside/around it
        for _, c in pairs(found.Parent:GetDescendants()) do
            if c:IsA("LocalScript") then
                Log("Script nearby: " .. c.Name)
                if decompile then
                    local s, src = pcall(function() return decompile(c) end)
                    if s then 
                        Log("Decompiled Source (First 200 chars): " .. src:sub(1, 200)) 
                    end
                end
            end
        end
    else
        Log("Could not find a 'Sell' button in GUI.")
    end
end


-- [UI CONSTRUCTION]
task.spawn(function()
    local success, err = pcall(function()
        local PlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if PlayerGui:FindFirstChild("CaseParadiseV316") then PlayerGui.CaseParadiseV316:Destroy() end

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "CaseParadiseV316"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.Parent = PlayerGui

        local MainFrame = Instance.new("Frame")
        MainFrame.Name = "MainFrame"
        MainFrame.Size = UDim2.new(0, 600, 0, 450)
        MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
        MainFrame.BackgroundColor3 = Theme.Background
        MainFrame.BorderSizePixel = 0
        MainFrame.Active = true
        MainFrame.Draggable = true
        MainFrame.Parent = ScreenGui
        local Corner = Instance.new("UICorner"); Corner.CornerRadius = UDim.new(0, 10); Corner.Parent = MainFrame

        -- Sidebar
        local Sidebar = Instance.new("Frame")
        Sidebar.Size = UDim2.new(0, 150, 1, 0)
        Sidebar.BackgroundColor3 = Theme.Sidebar
        Sidebar.Parent = MainFrame
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, 0, 0, 40)
        Title.BackgroundTransparency = 1
        Title.Text = "  V3.16 Scanner"
        Title.TextColor3 = Theme.Accent
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 16
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Parent = Sidebar
        
        -- Content
        local Content = Instance.new("Frame")
        Content.Size = UDim2.new(1, -150, 1, 0)
        Content.Position = UDim2.new(0, 150, 0, 0)
        Content.BackgroundTransparency = 1
        Content.Parent = MainFrame
        
        -- Close
        local Close = Instance.new("TextButton")
        Close.Size = UDim2.new(0, 30, 0, 30)
        Close.Position = UDim2.new(1, -35, 0, 5)
        Close.BackgroundColor3 = Theme.Error
        Close.Text = "X"
        Close.TextColor3 = Theme.Text
        Close.Parent = Content
        local CC = Instance.new("UICorner"); CC.Parent = Close
        Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
        
        -- Tabs
        local Tabs = {}
        local CurrentTab = nil
        
        local function CreateTab(name)
            local TabBtn = Instance.new("TextButton")
            TabBtn.Size = UDim2.new(1, 0, 0, 40)
            TabBtn.BackgroundTransparency = 1
            TabBtn.Text = name
            TabBtn.TextColor3 = Theme.SubText
            TabBtn.Font = Enum.Font.GothamSemibold
            TabBtn.Parent = Sidebar
            
            local TabFrame = Instance.new("ScrollingFrame")
            TabFrame.Size = UDim2.new(1, -20, 1, -50)
            TabFrame.Position = UDim2.new(0, 10, 0, 40)
            TabFrame.BackgroundTransparency = 1
            TabFrame.Visible = false
            TabFrame.Parent = Content
            local UIList = Instance.new("UIListLayout"); UIList.Padding = UDim.new(0,5); UIList.Parent = TabFrame
             UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                TabFrame.CanvasSize = UDim2.new(0,0,0, UIList.AbsoluteContentSize.Y + 10)
            end)
            Tabs[name] = {Btn = TabBtn, Frame = TabFrame}
            TabBtn.MouseButton1Click:Connect(function()
                if CurrentTab then CurrentTab.Frame.Visible = false; CurrentTab.Btn.TextColor3 = Theme.SubText end
                CurrentTab = Tabs[name]
                CurrentTab.Frame.Visible = true; CurrentTab.Btn.TextColor3 = Theme.Accent
            end)
        end
        local SL = Instance.new("UIListLayout"); SL.Parent = Sidebar
        
        CreateTab("Main")
        CreateTab("Scanner") -- New!
        CreateTab("Cases")
        
        -- Scanner Tab (The Focus of V3.16)
        local SpyBtn = Instance.new("TextButton")
        SpyBtn.Size = UDim2.new(1, 0, 0, 40)
        SpyBtn.BackgroundColor3 = Theme.Spy
        SpyBtn.Text = "1. SCAN FOR ERROR MSG"
        SpyBtn.TextColor3 = Theme.Text
        SpyBtn.Font = Enum.Font.GothamBold
        SpyBtn.Parent = Tabs.Scanner.Frame
        local SBC = Instance.new("UICorner"); SBC.Parent = SpyBtn
        SpyBtn.MouseButton1Click:Connect(function()
            ScanScriptsForString("Sell failed due to error")
            StarterGui:SetCore("SendNotification", {Title="Scanning...", Text="Check Console (F9) for results!", Duration=5})
        end)
        
        local SpyBtn2 = Instance.new("TextButton")
        SpyBtn2.Size = UDim2.new(1, 0, 0, 40)
        SpyBtn2.BackgroundColor3 = Theme.Spy
        SpyBtn2.Text = "2. ANALYZE SELL BUTTON"
        SpyBtn2.TextColor3 = Theme.Text
        SpyBtn2.Font = Enum.Font.GothamBold
        SpyBtn2.Parent = Tabs.Scanner.Frame
        local SBC2 = Instance.new("UICorner"); SBC2.Parent = SpyBtn2
        SpyBtn2.MouseButton1Click:Connect(function()
            AnalyzeSellButton()
            StarterGui:SetCore("SendNotification", {Title="Analyzing...", Text="Check Console (F9) for button info!", Duration=5})
        end)
        
        local Info = Instance.new("TextLabel")
        Info.Size = UDim2.new(1, 0, 0, 100)
        Info.BackgroundTransparency = 1
        Info.Text = "Use these buttons to find WHY 'Sell' is failing.\nOpen F9 Console to see the output.\nIf we find the code, we can copy the arguments exactly."
        Info.TextColor3 = Theme.SubText
        Info.TextWrapped = true
        Info.Font = Enum.Font.Code
        Info.TextSize = 12
        Info.Parent = Tabs.Scanner.Frame

        -- Main Tab (Standard)
        local function CreateToggle(parent, text, callback)
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 35)
            Btn.BackgroundColor3 = Theme.Sidebar
            Btn.Text = text .. ": OFF"
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.GothamSemibold
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
        
        -- Cases Tab
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
        CrateListFrame.Size = UDim2.new(1, 0, 0, 300); CrateListFrame.BackgroundTransparency = 1; CrateListFrame.Parent = Tabs.Cases.Frame
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
                    Btn.MouseButton1Click:Connect(function() Config.SelectedCase = name; UpdateCrateList() end)
                end
            end
            Tabs.Cases.Frame.CanvasSize = UDim2.new(0,0,0, #CrateListFrame:GetChildren() * 35 + 50)
        end
        SearchBar:GetPropertyChangedSignal("Text"):Connect(UpdateCrateList)
        UpdateCrateList()
        
        CurrentTab = Tabs.Main
        CurrentTab.Frame.Visible = true
        CurrentTab.Btn.TextColor3 = Theme.Accent

    end)
    if not success then Log("UI FAIL: "..tostring(err)) end
end)


-- [LOOPS]
task.spawn(function()
    while true do
        if Config.AutoOpen and Remotes.Open then
            pcall(function() Remotes.Open:InvokeServer(Config.SelectedCase) end)
        end
        if Config.AutoSell and Remotes.Sell then
             pcall(function() Remotes.Sell:InvokeServer() end)
        end
        task.wait(1.5)
    end
end)
