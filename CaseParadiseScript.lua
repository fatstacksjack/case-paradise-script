-- Case Paradise Script
-- Generated for Velocity Executer (Improved & Robust)
-- Author: Antigravity

-- Safe load of OrionLib
local success, OrionLib = pcall(function() return loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))() end)
if not success then
    warn("Failed to load OrionLib")
    return
end

local Window = OrionLib:MakeWindow({Name = "Case Paradise | Velocity", HidePremium = false, SaveConfig = true, ConfigFolder = "CaseParadiseCfg"})

-- Configuration Variables
getgenv().AutoOpen = false
getgenv().AutoSell = false
getgenv().SelectedCase = "Starter Case" 
getgenv().OpenRemoteName = "OpenCase" 
getgenv().SellRemoteName = "SellItems" 

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local OpenRemote = nil
local SellRemote = nil

-- Helper function to find remotes safely
local function FindRemoteRecursively(name)
    local found = ReplicatedStorage:FindFirstChild(name, true)
    if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction")) then
        return found
    end
    -- Fallback: Manual search if FindFirstChild fails (rare but possible)
    for _, child in pairs(ReplicatedStorage:GetDescendants()) do
        if child.Name == name and (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
            return child
        end
    end
    return nil
end

local function UpdateRemotes()
    OpenRemote = FindRemoteRecursively(getgenv().OpenRemoteName)
    SellRemote = FindRemoteRecursively(getgenv().SellRemoteName)
    
    if OpenRemote then
        OrionLib:MakeNotification({Name = "Remote Found", Content = "Open: " .. OpenRemote.Name, Time = 3})
    end
    
    if SellRemote then
         OrionLib:MakeNotification({Name = "Remote Found", Content = "Sell: " .. SellRemote.Name, Time = 3})
    end
end

-- Try automated discovery on load
local possibleOpenNames = {"OpenCase", "BuyCase", "CaseOpen", "Open", "Spin", "Roll"}
local possibleSellNames = {"SellItems", "Sell", "SellAll", "SellInventory"}

for _, name in ipairs(possibleOpenNames) do
    if FindRemoteRecursively(name) then
        getgenv().OpenRemoteName = name
        break
    end
end
for _, name in ipairs(possibleSellNames) do
    if FindRemoteRecursively(name) then
        getgenv().SellRemoteName = name
        break
    end
end
UpdateRemotes()


-- Main Tab
local MainTab = Window:MakeTab({
	Name = "Main",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

MainTab:AddSection({
	Name = "Farming"
})

MainTab:AddToggle({
	Name = "Auto Open Case",
	Default = false,
	Callback = function(Value)
        local success, err = pcall(function()
            getgenv().AutoOpen = Value
            if Value then
                task.spawn(function()
                    while getgenv().AutoOpen do
                        if OpenRemote then
                            pcall(function()
                                if OpenRemote:IsA("RemoteEvent") then
                                    OpenRemote:FireServer(getgenv().SelectedCase)
                                elseif OpenRemote:IsA("RemoteFunction") then
                                    OpenRemote:InvokeServer(getgenv().SelectedCase)
                                end
                            end)
                        end
                        task.wait(1) 
                    end
                end)
            end
        end)
        if not success then warn("Toggle Callback Error: " .. tostring(err)) end
	end    
})

MainTab:AddToggle({
	Name = "Auto Sell Items",
	Default = false,
	Callback = function(Value)
        local success, err = pcall(function()
            getgenv().AutoSell = Value
            if Value then
                task.spawn(function()
                    while getgenv().AutoSell do
                        if SellRemote then
                            pcall(function()
                                if SellRemote:IsA("RemoteEvent") then
                                    SellRemote:FireServer()
                                elseif SellRemote:IsA("RemoteFunction") then
                                    SellRemote:InvokeServer()
                                end
                            end)
                        end
                        task.wait(2)
                    end
                end)
            end
        end)
        if not success then warn("Toggle Callback Error: " .. tostring(err)) end
	end    
})

MainTab:AddTextbox({
	Name = "Case Name",
	Default = "Starter Case",
	TextDisappear = false,
	Callback = function(Value)
		getgenv().SelectedCase = Value
	end	  
})

-- Settings Tab (For Remote Debugging)
local SettingsTab = Window:MakeTab({
	Name = "Settings",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

SettingsTab:AddSection({
    Name = "Remote Configuration"
})

SettingsTab:AddTextbox({
	Name = "Open Remote Name",
	Default = getgenv().OpenRemoteName,
	TextDisappear = false,
	Callback = function(Value)
		getgenv().OpenRemoteName = Value
        UpdateRemotes()
	end	  
})

SettingsTab:AddTextbox({
	Name = "Sell Remote Name",
	Default = getgenv().SellRemoteName,
	TextDisappear = false,
	Callback = function(Value)
		getgenv().SellRemoteName = Value
        UpdateRemotes()
	end	  
})

SettingsTab:AddButton({
	Name = "Scan and Print Remotes (F9)",
	Callback = function()
        pcall(function()
            print("--- Scanning ReplicatedStorage for RemoteEvents ---")
            local count = 0
            for _, child in pairs(ReplicatedStorage:GetDescendants()) do
                if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                    print("Found " .. child.ClassName .. ": " .. child.Name .. " | Parent: " .. child.Parent.Name)
                    count = count + 1
                end
            end
            print("--- Scan Complete: Found " .. count .. " Remotes ---")
            OrionLib:MakeNotification({
                Name = "Scan Complete",
                Content = "Check Console (F9) for results!",
                Time = 5
            })
        end)
  	end    
})

-- Misc Tab
local MiscTab = Window:MakeTab({
	Name = "Misc",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

MiscTab:AddButton({
	Name = "Anti-AFK",
	Callback = function()
        pcall(function()
            local VirtualUser = game:GetService("VirtualUser")
            game:GetService("Players").LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            OrionLib:MakeNotification({
                Name = "Anti-AFK",
                Content = "You will not be kicked for idling.",
                Time = 3
            })
        end)
  	end    
})

OrionLib:Init()
