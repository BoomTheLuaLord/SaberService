local targ = script:WaitForChild("Target")

local input = script.Parent:WaitForChild("InputEvent")
local uis = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer

local cam = workspace.CurrentCamera

uis.InputBegan:Connect(function(inp, gpe)
	input:FireServer(inp.UserInputType, inp.KeyCode, "start", gpe)
end)

uis.InputEnded:Connect(function(inp, gpe)
	input:FireServer(inp.UserInputType, inp.KeyCode, "end", gpe)
end)


local tool = script:FindFirstAncestorWhichIsA("Tool")
tool.Equipped:Connect(function()
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		local function stoptoolnone()
			local bool = false
			for i, v in pairs(hum:GetPlayingAnimationTracks()) do
				if v.Name == "ToolNoneAnim" then
					bool = true
					v:Stop()
				end
			end
			return bool
		end
		local bool = false
		repeat
			bool = stoptoolnone()
			wait()
		until bool
	end
end)

input.OnClientEvent:Connect(function(name, other)
	
	if name == "shake" then
		cam.CameraType = Enum.CameraType.Scriptable
		
		local r = 0
		
		repeat
			local chr = plr.Character
			if chr then
				r = r + 1
				local root = chr:WaitForChild("HumanoidRootPart")
				local add = Vector3.new((math.random() * math.sign(math.random(-1,1))), (math.random() * math.sign(math.random(-1,1))), (math.random() * math.sign(math.random(-1,1))))
				cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position + add, cam.CFrame.Position + add + cam.CFrame.LookVector), 0.25)
				wait()
			end
			
		until r > 5
	end
	
	if other then
		cam.CameraType = Enum.CameraType.Scriptable
	else
		cam.CameraType = Enum.CameraType.Custom
	end
	
	if name == "target" and other then
		local chr = plr.Character
		if chr then
			local root = chr:WaitForChild("HumanoidRootPart")
			root.CFrame = CFrame.new(root.Position, Vector3.new(other.Position.X, root.Position.Y, other.Position.Z))
			
			cam.CameraType = Enum.CameraType.Scriptable
			
			local offset = root.CFrame.RightVector * 2.25 - root.CFrame.LookVector * 5 + root.CFrame.UpVector * 3.5
			
			cam.CFrame = cam.CFrame:Lerp(CFrame.new(root.Position + offset, other.Position), 0.1)
			
		end
	end
	
	targ.Adornee = other
	targ.Enabled = other ~= nil
end)