-- Case Paradise Script (Native UI) v2
-- Author: Antigravity
-- Removed VirtualUser and Anti-AFK to prevent executor crashes.

print("Case Paradise Script Loading...")

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local Config = {
    AutoOpen = false,
    AutoSell = false,
    AutoQuests = false,
    AutoLevelCrates = false,
    SelectedCase = "Starter Case"
}

-- [1] UI CREATION

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CaseParadiseGUI_v2"
-- Sometimes ResetOnSpawn causes issues with re-init
ScreenGui.ResetOnSpawn = false 

-- Check for existing GUI and destroy it to prevent duplicates
if PlayerGui:FindFirstChild("CaseParadiseGUI_v2") then
    PlayerGui.CaseParadiseGUI_v2:Destroy()
end

ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.Text = "Case Paradise | Antigravity v2"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18
Title.Parent = MainFrame

local Container = Instance.new("ScrollingFrame")
Container.Name = "Container"
Container.Size = UDim2.new(1, -10, 1, -40)
Container.Position = UDim2.new(0, 5, 0, 35)
Container.BackgroundTransparency = 1
Container.ScrollBarThickness = 5
Container.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

-- Helper to create Toggle Buttons
local function CreateToggle(text, callback)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 35)
    Button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Button.Text = text .. ": OFF"
    Button.TextColor3 = Color3.fromRGB(255, 100, 100)
    Button.Font = Enum.Font.SourceSans
    Button.TextSize = 16
    Button.Parent = Container

    local enabled = false
    Button.MouseButton1Click:Connect(function()
        enabled = not enabled
        if enabled then
            Button.Text = text .. ": ON"
            Button.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            Button.Text = text .. ": OFF"
            Button.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
        -- Wrap callback in pcall to prevent crash propagation
        local s, e = pcall(function() callback(enabled) end)
        if not s then warn("Button Callback Error: "..tostring(e)) end
    end)
    return Button
end

-- Helper to create Text Inputs
local function CreateInput(placeholder, callback)
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, 0, 0, 35)
    Input.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Input.Text = ""
    Input.PlaceholderText = placeholder
    Input.TextColor3 = Color3.fromRGB(255, 255, 255)
    Input.Font = Enum.Font.SourceSans
    Input.TextSize = 16
    Input.Parent = Container
    
    Input.FocusLost:Connect(function(enterPressed)
        local s, e = pcall(function() callback(Input.Text) end)
        if not s then warn("Input Callback Error: "..tostring(e)) end
    end)
    return Input
end

-- [2] LOGIC & AUTOMATION

-- Safe Remote Finding
local Remotes = {
    Open = nil,
    Sell = nil,
    Quest = nil
}

local function ScanRemotes()
    print("--- Scanning for Remotes ---")
    local foundCount = 0
    for _, child in pairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local name = child.Name:lower()
            -- Heuristics to identify remotes
            if name:find("open") or name:find("buy") or name:find("case") then
                if not Remotes.Open then Remotes.Open = child; print("Found Open Remote:", child.Name) end
            end
            if name:find("sell") then
                if not Remotes.Sell then Remotes.Sell = child; print("Found Sell Remote:", child.Name) end
            end
            if name:find("quest") or name:find("claim") then
                 if not Remotes.Quest then Remotes.Quest = child; print("Found Quest Remote:", child.Name) end
            end
            foundCount = foundCount + 1
        end
    end
    print("--- Scan Complete ---")
    return Remotes.Open, Remotes.Sell, Remotes.Quest
end

-- Initial Scan
pcall(ScanRemotes)

-- UI ELEMENTS

local CaseInput = CreateInput("Case Name (Default: Starter Case)", function(text)
    if text ~= "" then
        Config.SelectedCase = text
    end
end)


CreateToggle("Auto Open Case", function(val)
    Config.AutoOpen = val
    if val and not Remotes.Open then ScanRemotes() end
    
    task.spawn(function()
        while Config.AutoOpen do
            if Remotes.Open then
                 pcall(function()
                    if Remotes.Open:IsA("RemoteEvent") then
                        Remotes.Open:FireServer(Config.SelectedCase)
                    else
                        Remotes.Open:InvokeServer(Config.SelectedCase)
                    end
                end)
            end
            task.wait(0.5)
        end
    end)
end)

CreateToggle("Auto Sell Items", function(val)
    Config.AutoSell = val
    if val and not Remotes.Sell then ScanRemotes() end

    task.spawn(function()
        while Config.AutoSell do
            if Remotes.Sell then
                pcall(function()
                     if Remotes.Sell:IsA("RemoteEvent") then
                        Remotes.Sell:FireServer()
                    else
                        Remotes.Sell:InvokeServer()
                    end
                end)
            end
            task.wait(1)
        end
    end)
end)

CreateToggle("Auto Quests", function(val)
    Config.AutoQuests = val
    if val and not Remotes.Quest then ScanRemotes() end

    task.spawn(function()
        while Config.AutoQuests do
            if Remotes.Quest then
               -- Try generic claim arguments often used in these games
               pcall(function() 
                    if Remotes.Quest:IsA("RemoteEvent") then
                        Remotes.Quest:FireServer("Claim")
                        Remotes.Quest:FireServer("Equip") -- Sometimes quest remotes handle multiple actions
                    end
               end)
            end
            task.wait(5)
        end
    end)
end)

CreateToggle("Auto Level Crate", function(val)
    Config.AutoLevelCrates = val
    task.spawn(function()
        while Config.AutoLevelCrates do
            -- Level crates are often clicked in Gui or a specific remote
            -- We try to find a remote specifically for Level/Reward
            local levelRemote = nil
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v.Name:lower():find("level") or v.Name:lower():find("reward") then
                    if v:IsA("RemoteEvent") then
                        levelRemote = v
                        break
                    end
                end
            end
            
            if levelRemote then
                pcall(function() levelRemote:FireServer() end)
            end
            task.wait(5)
        end
    end)
end)

print("Case Paradise Script Loaded Successfully!")
