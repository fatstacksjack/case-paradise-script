-- Case Paradise Script - EMERGENCY VERSION
-- Author: Antigravity
-- Ultra-simple. No scanning logic on startup. Manual config only.

print("--- STARTED EXECUTION ---")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- 1. CLEANUP OLD GUI
if PlayerGui:FindFirstChild("SimpleGUI") then
    PlayerGui.SimpleGUI:Destroy()
end

-- 2. CREATE ULTRA-SIMPLE GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 250, 0, 300)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.Text = "EMERGENCY SCRIPT"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.TextSize = 20
Title.Parent = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 1, -20)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Waiting..."
StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
StatusLabel.Parent = MainFrame

local AutoOpen = false
local AutoSell = false
local AutoLevel = false
local CaseName = "Starter Case"

-- 3. LOGIC (NO FANCY SCANNING)

local function GetRemote(name)
    -- Try direct lookup first (fastest)
    local r = ReplicatedStorage:FindFirstChild(name)
    if r then return r end
    
    -- Try recursive if direct fails
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == name then return v end
    end
    return nil
end

-- Buttons
local function CreateBtn(text, pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, pos)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.Text = text .. " [OFF]"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Parent = MainFrame
    
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        if on then
            btn.Text = text .. " [ON]"
            btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        else
             btn.Text = text .. " [OFF]"
             btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        callback(on)
    end)
end

-- Input
local Input = Instance.new("TextBox")
Input.Size = UDim2.new(0.9, 0, 0, 30)
Input.Position = UDim2.new(0.05, 0, 0, 40)
Input.Text = "Starter Case"
Input.PlaceholderText = "Case Name"
Input.Parent = MainFrame
Input.FocusLost:Connect(function()
    CaseName = Input.Text
    print("Selected Case:", CaseName)
end)

-- ADD BUTTONS
CreateBtn("Auto Open", 80, function(val)
    AutoOpen = val
    if val then
        task.spawn(function()
            while AutoOpen do
                StatusLabel.Text = "Opening..."
                -- Guess typical names
                local remote = GetRemote("OpenCase") or GetRemote("Open") or GetRemote("BuyCase")
                if remote then
                    pcall(function() 
                        if remote:IsA("RemoteEvent") then remote:FireServer(CaseName) 
                        else remote:InvokeServer(CaseName) end 
                    end)
                else
                    StatusLabel.Text = "NO REMOTE FOUND!"
                end
                task.wait(0.5)
            end
            StatusLabel.Text = "Stopped."
        end)
    end
end)

CreateBtn("Auto Sell", 130, function(val)
    AutoSell = val
    if val then
        task.spawn(function()
            while AutoSell do
                StatusLabel.Text = "Selling..."
                 local remote = GetRemote("SellItems") or GetRemote("Sell") or GetRemote("SellInventory")
                if remote then
                    pcall(function() 
                        if remote:IsA("RemoteEvent") then remote:FireServer() 
                        else remote:InvokeServer() end 
                    end)
                end
                task.wait(1)
            end
             StatusLabel.Text = "Stopped."
        end)
    end
end)

CreateBtn("Auto Level", 180, function(val)
    AutoLevel = val
    if val then
        task.spawn(function()
            while AutoLevel do
                 StatusLabel.Text = "Leveling..."
                 -- Try to find anything with "Reward" or "Level"
                 for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                    if (v.Name == "Claim" or v.Name == "Reward") and v:IsA("RemoteEvent") then
                        pcall(function() v:FireServer() end)
                    end
                 end
                task.wait(5)
            end
             StatusLabel.Text = "Stopped."
        end)
    end
end)

print("--- FINISHED LOADING ---")
