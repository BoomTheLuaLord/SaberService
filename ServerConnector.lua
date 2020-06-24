
local debris = game:GetService("Debris")
local tweenservice = game:GetService("TweenService")

local lightsaber = script.Parent.Parent
local tool = script:FindFirstAncestorOfClass("Tool")
local code = script.Parent

local input = code.InputEvent
local ext = code.External

local animations = lightsaber.Animations
local hitboxes = lightsaber.Hitboxes
local audio = lightsaber.Audio
local assigned = lightsaber.AssignedCharacter
local grip = lightsaber.Grip


local keys = {
	throw = {key = Enum.KeyCode.T, name = "throw"},
	flourish = {key = Enum.KeyCode.F, name = "flourish"},
	target = {key = Enum.KeyCode.Z, name = "target"},
	enable = {key = Enum.KeyCode.Q, name = "enable"},
	attack = {key = Enum.UserInputType.MouseButton1, name = "attack"},
	block = {key = Enum.UserInputType.MouseButton2, name = "block"},
	
}

local setting = {
	damage = {min = 10, max = 17.5},
	
}

local runtime = {
	blocking = false,
	attacking = false,
	parrying = false,
	equipped = false,
	stunned = false,
	enabled = false,
	lastAction = tick(),
	acting = false,
	target = nil,
	stamina = 100,
	dead = false,
	
}

local predefined = {
	stamina = 100,
	parryWindow = 0.15,
	actionInterval = 0.05,
	stunTime = 2,
	stamDrainRate = .75,
	parryDrain = 25,
	attackDrain = 10,
	meltDuration = 2,
	minLockDist = 20,
	
}

local playing = {
	block = nil,
	attack = nil,
	}

function getKey(mouse, keyboard)
	for i, v in pairs(keys) do
		if v.key == mouse or v.key == keyboard then
			return v.name
		end
	end
end

function changeColor(newColor, list, specificHitbox)
	if not newColor or typeof(newColor) ~= "Color3" then newColor = Color3.new(1,1,1) end
	
	
	
	function doColor(v)
		if v:IsA("BasePart") then
			local colorParts = v:FindFirstChild("ColorParts")
			if colorParts then
				for i, v in pairs(colorParts:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Color = newColor
					end
				end
			end
			
			for o, b in pairs(v:GetChildren()) do
				
				local colorList = nil
				if list then
					colorList = {}
					for k, j in pairs(list) do
						colorList[k] = j
					end
				end
				
				if b:IsA("PointLight") then
					b.Color = newColor
				elseif b.Name == "Outer" then
					if colorList then
						
						for p = 1, #colorList-1 do
							
							local temp = colorList[p+1]
							colorList[p+1] = colorList[p]
							colorList[p] = temp
							
						end
						
						
						colorList[1] = newColor
						
						for p = 1, #colorList do
							
							local calc = p / #colorList
							if p == 1 then
								calc = 0
							end
							
							local temp = colorList[p]
							
							colorList[p] = ColorSequenceKeypoint.new(calc, typeof(temp) == "Color3" and temp or Color3.new(1,1,1))
							
						end
					end
					if colorList then
						b.Color = ColorSequence.new(colorList)
					else
						b.Color = ColorSequence.new(newColor)
					end
				end
				
			end
		end
	end
	
	if specificHitbox then
		doColor(specificHitbox)
		return
	end
	
	for i, v in pairs(hitboxes:GetChildren()) do
		doColor(v)
	end
	
end

mainLoop = coroutine.wrap(function()
	local w = wait()
	
	local stamUI = script.StaminaUI:Clone()
	
	while(wait(0.01)) do
		if not runtime.dead then
			
			local hum = assigned.Value and assigned.Value:FindFirstChildOfClass("Humanoid")
			if hum then
				if hum.Health <= 0 then
					runtime.dead = true
				end
			end
			
			if assigned.Value and runtime.equipped then
				
				local plr = game.Players:GetPlayerFromCharacter(assigned.Value)
				stamUI.Parent = plr and plr.PlayerGui or nil
				stamUI.Main.Bar.Size = UDim2.new(runtime.stamina / predefined.stamina,0,1,0)
				
			else
				stamUI.Parent = nil
			end
			
			if runtime.blocking then
				if runtime.stamina > 0 then
					runtime.stamina = runtime.stamina - (predefined.stamDrainRate/1.5)
				else
					runtime.stamina = 0
					endblock()
				end
			else
				if runtime.stamina < predefined.stamina then
					runtime.stamina = runtime.stamina + ((predefined.stamDrainRate/3))
				else
					runtime.stamina = predefined.stamina
				end
			end
			
			local hum = assigned.Value and assigned.Value:FindFirstChildOfClass("Humanoid") or nil
			
			if runtime.target and runtime.equipped and runtime.enabled and runtime.target.Parent and runtime.target.Parent:FindFirstChildOfClass("Humanoid") and runtime.target.Parent:FindFirstChildOfClass("Humanoid").Health > 0 then
				if assigned.Value then
					
					if hum then
						hum.AutoRotate = false
						
						local root = assigned.Value:FindFirstChild("HumanoidRootPart")
						
						if root then
							local dista = dist(root.Position, runtime.target.Position)
							if dista > predefined.minLockDist then
								runtime.target = nil
								if hum then
									hum.AutoRotate = true
								end
							end
							
							if runtime.target then
								input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "target", runtime.target)
								--root.CFrame = CFrame.new(root.Position, Vector3.new(runtime.target.Position.X, root.Position.Y, runtime.target.Position.Z))
							end
						end
					end
					
				end
			else
				runtime.target = nil
				if hum then
					hum.AutoRotate = true
				end
				
				if runtime.equipped and assigned.Value then input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "target", nil) end
			end
			
			--print(runtime.stamina)
		else
			--print(assigned.Value)
			input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "target", nil)
			stamUI.Parent = nil
		end
	end
end)

function thingy(v, ignore, points, render)
	
	local returnpart = nil
	
	if (runtime.acting or runtime.blocking or runtime.parrying) and runtime.enabled and runtime.equipped and not runtime.dead then--and runtime.acting then
		local top = v:FindFirstChild("Top")
		local bottom = v:FindFirstChild("Bottom")
		local sparks = v:FindFirstChild("Sparks")
		if top and bottom then
			local lookcf = CFrame.new(bottom.WorldPosition, top.WorldPosition)
			local ray = Ray.new(lookcf.Position, lookcf.LookVector * top.Position.y*2)
			local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, ignore)
			
			if hit then
				
				--print(tostring(hit))
				
				if hit:IsA("BasePart") then
					returnpart = hit
				end
				
				if not render then return returnpart end
				
				table.insert(points, #points+1, pos)
				if #points > 1 then
					
					if sparks then
						local weld = sparks:FindFirstChildOfClass("Weld")
						if weld then
							weld.C0 = CFrame.new(v.Position - pos)
						end
						for i, v in pairs(sparks:GetChildren()) do
							if v:IsA("ParticleEmitter") then
								v:Emit(math.random(10))
							end
						end
					end
					
					playAudio(audio.Melt)
					
					--input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "shake", nil)
					
					for i=1,#points-1 do
						local p = points[i]
						local n = points[i+1]
						
						if p and n then
							
							local part = Instance.new("Part")
							part.Anchored = true
							part.Color = Color3.fromRGB(255,125,25)
							
							part.CFrame = CFrame.new((p+n)/2, n)
							
							part.Name = "LaserSwordBurn"
							part.CanCollide = false
							
							local dist = math.sqrt(math.pow(p.x - n.x,2) + math.pow(p.y - n.y,2) + math.pow(p.z - n.z,2))
							
							part.Size = Vector3.new(0.15,0.15,dist)
							
							part.Material = Enum.Material.Neon
							part.Shape = Enum.PartType.Block
							
							local light = Instance.new("PointLight", part)
							light.Brightness = 25
							light.Color = Color3.fromRGB(255,125,25)
							light.Range = 8
							light.Shadows = true
							
							local goal = {Color = Color3.fromRGB(65,25,0)}
							local lgoal = {Color = Color3.fromRGB(65,25,0), Brightness = 4, Range = 4}
							
							local ti = TweenInfo.new(predefined.meltDuration)
							local tween = tweenservice:Create(part, ti, goal):Play()
							local tween = tweenservice:Create(light, ti, lgoal):Play()
							debris:AddItem(part, ti.Time)
							
							table.remove(points, i)
							
							table.insert(ignore, #ignore+1, part)
							part.Parent = workspace
							
						else -- i or i+1 is nil.
							
						end
					end
				else -- #points <= 0
					
				end
				
			end
		end
	end
	
	return returnpart
end

function find(list, item)
	for i, v in pairs(list) do
		if v == item then
			return v, i
		end
	end
	return nil
end

function dist(a, b)
	if typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		return math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2) + math.pow(a.z - b.z, 2))
	end
end

visuals = coroutine.wrap(function()
	local ignore = {}
	local points = {}
	
	function getPoints(hitbox)
		for i, v in pairs(points) do
			if v.Hitbox == hitbox then
				return v.List
			end
		end
		table.insert(points, #points+1, {Hitbox = hitbox, List = {}})
		wait()
		return getPoints(hitbox)
	end
	
	local toremove = {}
			
	for i, v in pairs(lightsaber:GetDescendants()) do
		if v:IsA("BasePart") then
			table.insert(ignore, #ignore+1, v)
		end
	end
	
	if tool then
		for i, v in pairs(tool:GetDescendants()) do
			if v:IsA("BasePart") then
				table.insert(ignore, #ignore+1, v)
			end
		end
	end
	
	for i, v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Parent:FindFirstChildOfClass("Humanoid") or not v.CanCollide or v.Transparency >= 1 then
				table.insert(ignore, #ignore+1, v)
			end
		end
	end
	
	workspace.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			if child.Parent:FindFirstChildOfClass("Humanoid") or not child.CanCollide or child.Transparency >= 1 or child.Name == "LaserSwordBurn" then
				table.insert(ignore, #ignore+1, child)
			end
		end
		
		for i, v in pairs(child:GetDescendants()) do
			if v:IsA("BasePart") then
				if v.Parent:FindFirstChildOfClass("Humanoid") or not v.CanCollide or v.Transparency >= 1 then
					table.insert(ignore, #ignore+1, v)
				end
			end
		end
	end)
	
	local lastHitTime = tick()
	local lasthit = nil
	
	for i, v in pairs(hitboxes:GetChildren()) do
		lastHitTime = tick()
		if v:IsA("BasePart") then
			v.Touched:Connect(function(hit)
				
				lasthit = hit
				--table.insert(toremove, #toremove+1, hit)
				
				local found = find(ignore, hit)
				if not found then
					--print(hit.Name)
					
					local connection = nil
					
					connection = v.TouchEnded:Connect(function(endhit)
						local ofound = find(ignore, endhit)
						
						if not found and not ofound then
							local newfound, pos = find(toremove, endhit)
							
							if newfound and newfound == hit then
								local points = getPoints(v)
								table.remove(toremove, pos)
								table.remove(points, 1)
								connection:Disconnect()
								lasthit = nil
							else
								table.insert(toremove, #toremove+1, endhit)
								local points = getPoints(v)
								thingy(v, ignore, points, true)
							end
						end
					end)
					
					if hit:IsA("BasePart") then
						lasthit = hit
					end
					
					local points = getPoints(v)
					thingy(v, ignore, points, true)
				end
				
				
			end)
		end
	end
	
	while(wait()) do
		
		if not runtime.dead then
			
			for i, v in pairs(hitboxes:GetChildren()) do
				
	--			if tick() - lastHitTime >= 0.15 and #points > 0 then
	--				lastHitTime = tick()
	--				table.remove(points, 1)
	--			end
				
				if v:IsA("BasePart") then
					local points = getPoints(v)
					local hit = thingy(v, ignore, points, false)
					if hit then
						local newfound, pos = find(toremove, hit)
								
						if newfound and newfound ~= lasthit then
							table.remove(toremove, pos)
							table.remove(points, 1)
							thingy(v, ignore, points, true)
						else
							table.insert(toremove, #toremove+1, hit)
						end
						lasthit = hit
					end
					
					local hit = thingy(v, ignore, points, true)
				end
			end
		
		end
		
	end
	
end)

function enableVisuals(bool)
	
	for i, v in pairs(hitboxes:GetChildren()) do
		
		for o, obj in pairs(v:GetChildren()) do
			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("PointLight") then
				obj.Enabled = bool
			end
		end
		
	end
end

local loaded = {}

function load(humanoid, animation)
	local list = nil
	for i, v in pairs(loaded) do
		if v.hum == humanoid then
			list = v
			for i, v in pairs(v.anims) do
				if v.Name == animation.Name then
					return v
				end
			end
			
		end
	end
	if not list then
		table.insert(loaded, #loaded+1, {hum = humanoid, anims = {}})
	elseif list then
		table.insert(list.anims, #list.anims+1, humanoid:LoadAnimation(animation))
	end
	return load(humanoid, animation)
end

function playAnimation(folder)
	if assigned.Value then
		local chr = assigned.Value
		local hum = chr:FindFirstChildOfClass("Humanoid")
		
		if hum then
			local list = folder:GetChildren()
			if #list > 0 then
				local randomAnim = list[math.random(1, #list)]
				local anim = load(hum, randomAnim)
				anim:Play()
				return anim.Length, randomAnim
			end
		end
	end
end

function stopAnimation(folder)
	local chr = assigned.Value
	if chr then
		local hum = chr:FindFirstChildOfClass("Humanoid")
		if hum then
			for i, v in pairs(folder:GetDescendants()) do
				for o, b in pairs(hum:GetPlayingAnimationTracks()) do
					if v.Name == b.Name then
						b:Stop()
					end
				end
			end
		end
	end
end

function stopAnimByName(name)
	local chr = assigned.Value
	if chr then
		local hum = chr:FindFirstChildOfClass("Humanoid")
		if hum then
			for o, b in pairs(hum:GetPlayingAnimationTracks()) do
				if name == b.Name then
					b:Stop()
				end
			end
		end
	end
end

function playAudio(folder)
	local list = folder:GetChildren()
	if #list > 0 then
		local ran = list[math.random(1,#list)]
		if ran:IsA("Sound") then
			local rran = ran:Clone()
			rran.Parent = grip
			rran:Play()
			
			if not ran.Looped then
				debris:AddItem(rran, rran.TimeLength)
			end
		end
	end
end

function playAllAudio(folder)
	local list = folder:GetChildren()
	if #list > 0 then
		for i, ran in pairs(list) do
			
			if ran:IsA("Sound") then
				local rran = ran:Clone()
				rran.Parent = grip
				rran:Play()
				
				if not ran.Looped then
					debris:AddItem(rran, rran.TimeLength)
				end
			end
			
		end
	end
end

function stopAudio(folder)
	for i, v in pairs(folder:GetDescendants()) do
		if v:IsA("Sound") then
			local gripped = grip:FindFirstChild(v.Name)
			--print(gripped)
			if gripped then
				gripped:Stop()
				gripped:Destroy()
			end
		end
	end
end


function external(lightsaberObj, list, hit, otherext)
	if lightsaberObj ~= lightsaber then -- this is the blade you hit receiving your input
		----print("sent")
		local isHit = hit:FindFirstChild("DidHit")
		if isHit then
			isHit.Value = true
		end
		
		otherext:Invoke(lightsaberObj, {runtime = runtime, character = assigned.value}, hit)
	else -- this is when you receive input from the blade you hit
		local sparks = hit:FindFirstChild("Sparks")
		if list.runtime.parrying then
			playAudio(audio.Hit)
			stun()
			if sparks then
				local weld = sparks:FindFirstChildOfClass("Weld")
				if weld then
					weld.C0 = CFrame.new()
				end
				for i, v in pairs(sparks:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(math.random(125))
					end
				end
			end
		elseif list.runtime.blocking then
			if assigned.Value then input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "shake", nil) end
			playAudio(audio.Hit)
			if sparks then
				local weld = sparks:FindFirstChildOfClass("Weld")
				if weld then
					weld.C0 = CFrame.new()
				end
				for i, v in pairs(sparks:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(math.random(125))
					end
				end
			end
		else
			if list.character then
				local hum = list.character:FindFirstChildOfClass("Humanoid")
				if hum then
					playAudio(audio.Hit)
					hum:TakeDamage(math.random(setting.damage.min, setting.damage.max))
				end
			end
		end
		----print("returned")
	end
end
ext.OnInvoke = external

for i, v in pairs(hitboxes:GetChildren()) do
	if v:IsA("BasePart") then
		local isHit = Instance.new("BoolValue")
		isHit.Name = "DidHit"
		isHit.Parent = v
		
		v.Touched:Connect(function(hit)
			if runtime.equipped and runtime.enabled and runtime.attacking then
				if not isHit.Value then
					
					local chr = hit.Parent
					local hum = chr:FindFirstChildOfClass("Humanoid")
					if hum and chr ~= workspace then
						
						local ls = chr:FindFirstChildOfClass("Tool")
						
						if ls then ls = ls:FindFirstChild("Lightsaber") end
						
						if ls then
							local c = ls.Code
							local exte = c.External
							
							exte:Invoke(lightsaber, {runtime = runtime}, v, ext)
						else
							playAudio(audio.Hit)
							hum:TakeDamage(math.random(setting.damage.min, setting.damage.max))
							isHit.Value = true
						end
						
					end
				
				end
			end
		end)
	end
end

function enable(t)
	playAllAudio(audio.Enable)
	playAnimation(animations.Stances)
	playAnimation(animations.Enable)
	for i, v in pairs(hitboxes:GetChildren()) do
		local top = v:FindFirstChild("Top")
		if top and top:IsA("Attachment") then
			local goal = {Position = Vector3.new(0, v.Size.Y/2, 0)}
			local ti = TweenInfo.new(t)
			local tween = tweenservice:Create(top, ti, goal):Play()
		end
	end
	enableVisuals(true)
	--wait(t)
end

function disable(t)
	if t then playAllAudio(audio.Disable) end
	stopAudio(audio.Enable)
	playAnimation(animations.Disable)
	for i, v in pairs(hitboxes:GetChildren()) do
		local top = v:FindFirstChild("Top")
		if top and top:IsA("Attachment") then
			local goal = {Position = Vector3.new(0, -v.Size.Y/2, 0)}
			local ti = TweenInfo.new(t or 0.03)
			local tween = tweenservice:Create(top, ti, goal):Play()
		end
	end
	wait(t or 0.03)
	stopAnimation(animations)
	enableVisuals(false)
	stopAudio(audio.Enable)
end

function stun()
	if runtime.stunned then return end
	runtime.acting = true
	runtime.stunned = true
	
	local chr = assigned.Value
	local hum = nil
	if chr then
		hum = chr:FindFirstChildOfClass("Humanoid")
	end
	
	local oldSpeed = 16
	
	if hum then
		--oldSpeed = hum.WalkSpeed
		hum.AutoRotate = false
		hum.WalkSpeed = 0
	end
	
	local len = playAnimation(animations.Stun)
	
	playAudio(audio.Stun)
	wait(predefined.stunTime+0.15)
	
	if hum then
		hum.AutoRotate = true
		hum.WalkSpeed = oldSpeed
	end
	
	runtime.stunned = false
	runtime.acting = false
end

function attack()
	runtime.attacking = true
	
	if runtime.stamina < predefined.attackDrain then runtime.attacking = false return end
	
	runtime.stamina = runtime.stamina - predefined.attackDrain
	
	local chr = assigned.Value
	local hum = nil
	if chr then
		hum = chr:FindFirstChildOfClass("Humanoid")
	end
	
	--local oldspeed = 16
	
	if hum then
		--oldspeed = hum.WalkSpeed
		--hum.WalkSpeed = 4
		--hum.AutoRotate = false
	end
	
	local len = playAnimation(animations.Attacks)
	playAudio(audio.Attacks)
	wait(len+predefined.actionInterval)
	
	if hum and not runtime.stunned then
		--hum.WalkSpeed = oldspeed
		--hum.AutoRotate = true
	end
	
	runtime.attacking = false
	
	for i, v in pairs(hitboxes:GetDescendants()) do
		if v.Name == "DidHit" then
			v.Value = false
		end
	end
end

function block()
	runtime.blocking = true
	runtime.parrying = false
	
	local len, obj = playAnimation(animations.Blocks)
	playAnimation(obj.Start)
	playing.block = obj
	playAudio(audio.Blocks)
	
	--runtime.blocking = false
end

function endblock()
	if not runtime.blocking then return end
	local len = playAnimation(playing.block.End)
	playAudio(audio.Blocks)
	wait(len)
	stopAnimation(animations.Blocks)
	runtime.blocking = false
end

function parry()
	runtime.parrying = true
	
	endblock()
	if runtime.stamina >= predefined.parryDrain then
		runtime.stamina = runtime.stamina - predefined.parryDrain
		
		local len = playAnimation(animations.Parries)
		playAudio(audio.Parries)
		wait(len)
	end
	
	runtime.parrying = false
end

function flourish()
	local len = playAnimation(animations.Flourish)
	playAudio(audio.Flourish)
	
	wait(len + .25)
	
	
end
function throw()
	runtime.attacking = true
	local len = playAnimation(animations.throw)
	wait(len + .25)
	runtime.attacking = false
	
end

function act(action)
	if not action or runtime.dead then return end
	if runtime.acting then return end
	if runtime.stunned then return end
	if tick() - runtime.lastAction <= predefined.actionInterval then return end
	
	if action == "equip" then
		runtime.equipped = true--not runtime.equipped
		playAudio(audio.Equip)
	end
	
	if action == "unequip" then
		runtime.equipped = false
		playAudio(audio.Unequip)
		stopAnimation(animations.Stances)
		if assigned.Value then input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "target", nil) end

		runtime.enabled = false
		disable()
	end
	
	
	if not runtime.equipped then runtime.acting = false return end
	
	runtime.lastAction = tick()
	runtime.acting = true
	
	if action == "target" then
		
		if runtime.target then runtime.target = nil runtime.acting = false input:FireClient(game.Players:GetPlayerFromCharacter(assigned.Value), "target", nil) return end
		
		local closest = nil
		
		for i, v in pairs(workspace:GetDescendants()) do
			if v:IsA("Humanoid") then
				if v.Health > 0 then
					local root = v.Parent:FindFirstChild("HumanoidRootPart")
					if root and v.Parent ~= assigned.Value then
						if not closest then
							local myroot = assigned.Value:FindFirstChild("HumanoidRootPart")
							local check = dist(myroot.Position, root.Position)
							if check <= predefined.minLockDist then closest = v.Parent end
						end
						if closest and closest ~= v then
							local oroot = closest:FindFirstChild("HumanoidRootPart")
							if oroot then
								if assigned.Value then
									local myroot = assigned.Value:FindFirstChild("HumanoidRootPart")
									local dista = dist(myroot.Position, oroot.Position)
									local distb = dist(myroot.Position, root.Position)
									if distb < dista and distb <= predefined.minLockDist then
										closest = v.Parent
									end
								end
							end
						end
						--runtime.target = root
					end
				end
			end
		end
		
		runtime.target = closest and closest:FindFirstChild("HumanoidRootPart") or nil
		
	end
	
	if action == "enable" then
		--print("test")
		runtime.enabled = not runtime.enabled
		
		if runtime.enabled then
			enable(0.5)
		else
			disable(0.25)
		end
		
	elseif action == "attack" then
		if not runtime.enabled or runtime.attacking or runtime.blocking or runtime.parrying then runtime.acting = false return end
		attack()
		
	elseif action == "block" then
		if not runtime.enabled or runtime.blocking or runtime.attacking or runtime.parrying then runtime.acting = false return end
		block()
		
	end
	
	if action == "flourish" and runtime.equipped and runtime.enabled then
		flourish()
		
	end
	if action == "throw" and runtime.equipped and runtime.enabled then
		throw()
		
	end
	
	runtime.acting = false
	
end

function finish(action)
	if not action then return end
	if not runtime.equipped then return end
	
	if action == "block" then
		if tick() - runtime.lastAction <= predefined.parryWindow and not runtime.attacking and not runtime.parrying and runtime.equipped and runtime.enabled then
			parry()
		else
			endblock()
		end
	end
	
end

input.OnServerEvent:Connect(function(client, mouse, keyboard, fin, gpe)
	if gpe then return end
	
	assigned.Value = client.Character
	
	local action = getKey(mouse, keyboard)
	
	if fin == "start" then
		act(action)
	elseif fin == "end" then
		finish(action)
	end
	
end)

local tool = script:FindFirstAncestorOfClass("Tool")

if tool then
	tool.Equipped:Connect(function()
		act("equip")
	end)
	
	tool.Unequipped:Connect(function()
		act("unequip")
	end)
end

enableVisuals(runtime.enabled)

mainLoop()
visuals()

assigned.Changed:Connect(function()
	if not assigned or not assigned.Value then
		runtime.dead = true
	end
end)

--changeColor(Color3.new(0,1,0))--, {Color3.new(.1,.1,.9), Color3.new(.1,.5,.9), Color3.new(.1,.75,.1), Color3.new(.75,.75,.1), Color3.new(.95,.75,.1), Color3.new(.9,.1,.1), })

-- just testing here --

--assigned.Changed:Connect(function()
--	if assigned.Value then
--		
--		local hum = assigned.Value:FindFirstChildOfClass("Humanoid")
--		if hum then
--			hum.Touched:Connect(function(hit)
--				if runtime.equipped and hit.Name == "ColorPart" then
--					changeColor(hit.Color)
--				end
--			end)
--		end
--		
--	end
--end)

for i, v in pairs(hitboxes:GetChildren()) do
	local color = v:FindFirstChild("BladeColor")
	if not color then
		color = Instance.new("Color3Value")
		color.Value = Color3.new(1,1,1)
		color.Name = "BladeColor"
		color.Parent = v
	end
	
	changeColor(color.Value, nil, v)
	
	color.Changed:Connect(function()
		changeColor(color.Value, nil, v)
	end)
end
