-- Case Paradise V3.13.1 (MINIMAL VERIFICATION)
-- Purpose: Verify script loads and Invokes work
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function Log(msg)
    print("[V3.13.1] " .. msg)
    -- Also try to notify
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Debug", Text=msg, Duration=5})
    end)
end

Log("Script Loaded Successfully!")

-- Find Remote
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
    Log("ERROR: Remotes folder not found!")
    return
end

local openRemote = remotes:FindFirstChild("OpenCase")
if not openRemote then
    -- Fallback search
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "OpenCase" then openRemote = v break end
    end
end

if openRemote then
    Log("Found Open Remote: " .. openRemote:GetFullName())
    Log("Type: " .. openRemote.ClassName)
    
    if openRemote:IsA("RemoteFunction") then
        Log("Attempting InvokeServer('Starter Case')...")
        local s, res = pcall(function()
            return openRemote:InvokeServer("Starter Case")
        end)
        if s then
            Log("SUCCESS! Result: " .. tostring(res))
        else
            Log("FAILED! Error: " .. tostring(res))
        end
    else
        Log("Remote is NOT a RemoteFunction? " .. openRemote.ClassName)
    end
else
    Log("ERROR: OpenCase Remote NOT FOUND anywhere!")
end
