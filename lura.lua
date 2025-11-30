-- ================= VSkillModule =================
local VSkillModule = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local currentTool = nil
local lastTool = nil
local sharkZActive, vActive, cursedZActive = false, false, false
local dmgConn = nil
local characterConnections = {}
local rightTouchActive = false
local SilentAimModuleRef = nil

local function clearConnections()
	for _, conn in ipairs(characterConnections) do
		pcall(function() conn:Disconnect() end)
	end
	characterConnections = {}
end

-- =========================
-- Silent Aimbot Control
-- =========================
local function DisableSilentAimbot()
    if SilentAimModuleRef then
        SilentAimModuleRef:Pause()
    end
end

local function EnableSilentAimbot()
    if SilentAimModuleRef then
        SilentAimModuleRef:Restore()
    end
end

-- =========================
-- Tool Watcher
-- =========================
local function hookTool(tool)
    currentTool = tool
    lastTool = tool.Name
    table.insert(characterConnections, tool.AncestryChanged:Connect(function(_, parent)
        if not parent then
            currentTool = nil
            lastTool = nil
            sharkZActive, vActive, cursedZActive = false, false, false
            rightTouchActive = false
            EnableSilentAimbot()
        end
    end))
end

local function isValidStopCondition()
    return (currentTool and currentTool.Name == "Shark Anchor" and sharkZActive)
        or (lastTool == "Dough-Dough" and vActive)
        or (currentTool and currentTool.Name == "Cursed Dual Katana" and cursedZActive)
end

-- =========================
-- Touch Control (Mobile)
-- =========================
UserInputService.TouchStarted:Connect(function(touch)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        rightTouchActive = true

        if isValidStopCondition() then
            DisableSilentAimbot()
        end
    end
end)

UserInputService.TouchEnded:Connect(function(touch)
    local camera = workspace.CurrentCamera
    if not camera then return end
    
    if touch.Position.X > camera.ViewportSize.X / 2 then
        rightTouchActive = false

        EnableSilentAimbot()
        sharkZActive, vActive, cursedZActive = false, false, false
    end
end)

-- =========================
-- Damage Counter Watch
-- =========================
local function watchDamageCounter()
	if dmgConn then
		pcall(function() dmgConn:Disconnect() end)
		dmgConn = nil
	end

	task.spawn(function()
		while true do
			gui = player:FindFirstChild("PlayerGui"):FindFirstChild("Main")
			if not gui then
				warn("[DamageLog] Main GUI not found, retrying...")
				task.wait(1)
				continue
			end

			dmgCounter = gui:FindFirstChild("DmgCounter")
			if not dmgCounter then
				warn("[DamageLog] DmgCounter not found, retrying...")
				task.wait(1)
				continue
			end

			dmgTextLabel = dmgCounter:FindFirstChild("Text")
			if not dmgTextLabel then
				warn("[DamageLog] TextLabel inside DmgCounter not found, retrying...")
				task.wait(1)
				continue
			end

			dmgConn = dmgTextLabel:GetPropertyChangedSignal("Text"):Connect(function()
				local dmgText = tonumber(dmgTextLabel.Text) or 0
				if dmgText > 0 and isValidStopCondition() and rightTouchActive then
					DisableSilentAimbot()
				elseif not rightTouchActive then
					EnableSilentAimbot()
				end
			end)
			table.insert(characterConnections, dmgConn)			
			break
		end
	end)
end

-- =========================
-- Skill Detection
-- =========================
if not getgenv().VSkillHooked then
    getgenv().VSkillHooked = true
    local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
	    local method = getnamecallmethod()
	    local args = {...}
    
	    if (method == "InvokeServer" or method == "FireServer") then
	        local a1 = args[1]

	        if typeof(a1) == "string" and a1:upper() == "Z" then
	            if currentTool and currentTool.Name == "Shark Anchor" then
	                sharkZActive = true
	            end
	        end
        
	        if typeof(a1) == "string" and a1:upper() == "V" then
	            if lastTool == "Dough-Dough" then
	                vActive = true
	            end
	        end
        
	        if typeof(a1) == "string" and a1:upper() == "Z" then
	            if currentTool and currentTool.Name == "Cursed Dual Katana" then
	                cursedZActive = true
	            end
			end
	    end
	    return old(self, ...)
	end)
end

-- =========================
-- Character Handling
-- =========================
local function onCharacterAdded(char)
    clearConnections()
    
    sharkZActive, vActive, cursedZActive = false, false, false
    rightTouchActive = false
    EnableSilentAimbot()

    table.insert(characterConnections, char.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then hookTool(child) end
    end))

    table.insert(characterConnections, char.ChildRemoved:Connect(function(child)
        if child == currentTool and lastTool then
            currentTool = nil
            lastTool = nil
            sharkZActive, vActive, cursedZActive = false, false, false
            rightTouchActive = false
            EnableSilentAimbot()
        end
    end))

    watchDamageCounter()
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- =========================
-- External Entry
-- =========================
function VSkillModule:CheckVSkillUsage(SilentAimModule)
    SilentAimModuleRef = SilentAimModule
    watchDamageCounter()
end

return VSkillModule
