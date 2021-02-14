AddCSLuaFile()

--[[------------------------------------
	Soldier Advanced NextBot
	
	This bot uses SB Advanced NextBot Base.
	
	He will follow you if you spawn it as Follower. Otherwise he will be neutral to you and other players.
	If you damage bot, he will shoot you. Also he will shoot enemies if found. If bot friendly, he marks combine as enemies,
	otherwise he marks rebels and other friendly to player npcs as enemies.
	
	Also he will inform other bots in same group and same friendly status about enemies, so other bots can help him take down enemy.
--]]------------------------------------

ENT.Base = "sb_advanced_nextbot_base"
DEFINE_BASECLASS(ENT.Base)

if CLIENT then return end

local PlayerDisposition = CreateConVar(
	"sb_advanced_nextbot_soldier_playerdisposition",
	"0",
	bit.bor(FCVAR_NEVER_AS_STRING,FCVAR_ARCHIVE),
	"Defines player disposition for friendly/hostile bots: 0 - Neutral; 1 - Like; 2 - Hate; 3 - Like for friendly, hate for hostile; 4 - Hate for friendly, like for hostile.",
	0,
	4
)

local UseNodeGraph = CreateConVar(
	"sb_advanced_nextbot_soldier_usenodegraph",
	"0",
	bit.bor(FCVAR_NEVER_AS_STRING,FCVAR_ARCHIVE),
	"Should bots use nodegraph or navmesh when finding path",
	0,
	1
)

--[[------------------------------------
	CONFIG
--]]------------------------------------

ENT.SpawnHealth = 70

local ENEMY_CLASSES

ENT.TaskList = {
	["shooting_handler"] = {
		OnStart = function(self,data)
			data.PassBlockerTime = CurTime()
		
			data.PassBlocker = function(blocker)
				local dir = blocker:WorldSpaceCenter()-self:GetPos()
				dir.z = 0
				
				local _,diff = WorldToLocal(vector_origin,dir:Angle(),vector_origin,self:GetDesiredEyeAngles())
				local side = diff.y>0 and 1 or -1
				local b1,b2 = self:GetCollisionBounds()
				
				self:Approach(self:GetPos()+dir:Angle():Right()*side*10)
			end
		end,
		BehaveUpdate = function(self,data,interval)
			if !self:HasWeapon() then return end
			
			local wep = self:GetActiveWeapon()
			local enemy = self:GetEnemy()
		
			if self.IsSeeEnemy and IsValid(enemy) then
				local pos = self:GetShootPos()
				local endpos = self.LastEnemyShootPos
				local dir = endpos-pos
				dir:Normalize()
			
				self:SetDesiredEyeAngles(dir:Angle())
				
				if wep:Clip1()<=0 then
					self:WeaponReload()
				end
				
				if self:RunTask("PreventShooting") then return end
				
				local dot = math.Clamp(self:GetEyeAngles():Forward():Dot(dir),0,1)
				local ang = math.deg(math.acos(dot))
				
				if ang<=25 then
					local filter = self:GetChildren()
					filter[#filter+1] = self
					filter[#filter+1] = enemy
				
					if self.LastShootBlocker then
						if self:IsTaskActive("movement_wait") and CurTime()-data.PassBlockerTime>0.5 then
							data.PassBlocker(self.LastShootBlocker)
						end
					else
						data.PassBlockerTime = CurTime()
					
						self:WeaponPrimaryAttack()
					end
				end
			elseif wep:Clip1()<wep:GetMaxClip1()/2 then
				self:WeaponReload()
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("shooting_handler")
		end,
	},
	["enemy_handler"] = {
		OnStart = function(self,data)
			data.UpdateEnemies = CurTime()
			data.HasEnemy = false
			self.IsSeeEnemy = false
			self:SetEnemy(NULL)
			
			self.UpdateEnemyHandler = function(forceupdateenemies)
				local prevenemy = self:GetEnemy()
				local newenemy = prevenemy

				if forceupdateenemies or !data.UpdateEnemies or CurTime()>data.UpdateEnemies or data.HasEnemy and !IsValid(prevenemy) then
					data.UpdateEnemies = CurTime()+0.5
					
					self:FindEnemies()
					
					local enemy = self:FindPriorityEnemy()
					if IsValid(enemy) then
						newenemy = enemy
						self.IsSeeEnemy = self:CanSeePosition(enemy)
					end
				end
				
				if IsValid(newenemy) then
					if !data.HasEnemy then
						self:RunTask("EnemyFound",newenemy)
					elseif prevenemy!=newenemy then
						self:RunTask("EnemyChanged",newenemy,prevenemy)
					end
					
					data.HasEnemy = true
					
					if self:CanSeePosition(newenemy) then
						self.LastEnemyShootPos = self:EntShootPos(newenemy)
						self:UpdateEnemyMemory(newenemy,newenemy:GetPos())
					end
				else
					if data.HasEnemy then
						self:RunTask("EnemyLost",prevenemy)
					end
					
					data.HasEnemy = false
					self.IsSeeEnemy = false
				end
				
				self:SetEnemy(newenemy)
			end
		end,
		BehaveUpdate = function(self,data,interval)
			self.UpdateEnemyHandler()
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("enemy_handler")
		end,
	},
	["movement_handler"] = {
		OnStart = function(self,data)
			self:TaskComplete("movement_handler")
			
			local task,data = "movement_wait"
			local findwep = !self:HasWeapon() and self:FindWeapon()
			
			if self.CustomPosition then
				task,data = "movement_custompos",{Position = self.CustomPosition}
				self.CustomPosition = nil
			elseif findwep then
				task,data = "movement_getweapon",{Wep = findwep}
			else
				if IsValid(self.Target) then
					if self:GetRangeTo(self.Target)>300 or !self:CanSeePosition(self.Target) then
						task = "movement_followtarget"
					end
				else
					if IsValid(self:GetEnemy()) then
						if self:GetRangeTo(self:GetEnemy())>300 then
							task = "movement_followenemy"
						end
					else
						task = "movement_randomwalk"
					end
				end
			end
			
			self:StartTask(task,data)
		end,
	},
	["movement_wait"] = {
		OnStart = function(self,data)
			data.Time = CurTime()+(data.Time or math.random(1,2))
		end,
		BehaveUpdate = function(self,data,interval)
			if CurTime()>=data.Time then
				self:TaskComplete("movement_wait")
				self:StartTask("movement_handler")
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("movement_wait")
		end,
	},
	["playercontrol_handler"] = {
		StopControlByPlayer = function(self,data,ply)
			self:StartTask("enemy_handler")
			self:StartTask("movement_wait")
			self:StartTask("shooting_handler")
		end,
	},
	["movement_getweapon"] = {
		OnStart = function(self,data)
			self:SetupPath(data.Wep:GetPos())
			
			if !self:PathIsValid() then
				self:TaskFail("movement_getweapon")
				self:StartTask("movement_wait")
			end
		end,
		BehaveUpdate = function(self,data)
			if !self:CanPickupWeapon(data.Wep) then
				self:TaskFail("movement_getweapon")
				self:StartTask("movement_wait")
				
				return
			end
		
			local result = self:ControlPath(true)
			
			if result then
				self:TaskComplete("movement_getweapon")
				self:StartTask("movement_wait")
				
				if self:GetRangeTo(data.Wep)<50 then
					self:SetupWeapon(data.Wep)
				end
			elseif result==false then
				self:TaskFail("movement_getweapon")
				self:StartTask("movement_wait")
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("movement_getweapon")
		end,
	},
	["movement_followtarget"] = {
		BehaveUpdate = function(self,data)
			if !IsValid(self.Target) then
				self:TaskFail("movement_followtarget")
				self:StartTask("movement_wait")
				
				return
			end
			
			if !data.Pos or self.Target:GetPos():Distance(data.Pos)>50 then
				data.Pos = self.Target:GetPos()
				self:SetupPath(data.Pos)
				
				if !self:PathIsValid() then
					self:TaskComplete("movement_followtarget")
					self:StartTask("movement_wait")
				
					return
				end
			end
		
			local result = self:ControlPath(!self.IsSeeEnemy)
			
			if result then
				self:TaskComplete("movement_followtarget")
				self:StartTask("movement_wait")
			elseif result==false then
				self:TaskFail("movement_followtarget")
				self:StartTask("movement_wait")
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("movement_followtarget")
		end,
	},
	["movement_followenemy"] = {
		OnStart = function(self,data)
			local pos = self:GetLastEnemyPosition(self:GetEnemy())
		
			self:SetupPath(pos)
			data.Walk = !self:CanSeePosition(pos) and self:GetRangeTo(pos)<2000
			
			if !self:PathIsValid() then
				self:TaskFail("movement_followenemy")
				self:StartTask("movement_wait")
			end
		end,
		BehaveUpdate = function(self,data)
			local result = self:ControlPath(!self.IsSeeEnemy)
			
			if result then
				self:TaskComplete("movement_followenemy")
				self:StartTask("movement_wait")
			elseif result==false then
				self:TaskFail("movement_followenemy")
				self:StartTask("movement_wait",{Time = math.random(3,6)})
			else
				if self.IsSeeEnemy then
					data.Walk = false
				end
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("movement_followenemy")
		end,
		ShouldWalk = function(self,data)
			if data.Walk then
				return true
			end
		end,
	},
	["movement_randomwalk"] = {
		OnStart = function(self,data)
			local pos = self:GetRandomWalkPosition()
			
			if pos then
				self:SetupPath(pos)
			else
				self:GetPath():Invalidate()
			end
			
			if !self:PathIsValid() then
				self:TaskFail("movement_randomwalk")
				self:StartTask("movement_wait")
			end
		end,
		BehaveUpdate = function(self,data)
			local result = self:ControlPath(!self.IsSeeEnemy)
			
			if result then
				self:TaskComplete("movement_randomwalk")
				self:StartTask("movement_wait",{Time = math.random(3,6)})
			elseif result==false or self.IsSeeEnemy then
				self:TaskFail("movement_randomwalk")
				self:StartTask("movement_wait")
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("movement_randomwalk")
		end,
		ShouldWalk = function(self,data)
			return true
		end,
	},
	["movement_custompos"] = {
		OnStart = function(self,data)
			self:SetupPath(data.Position,{tolerance = 50})
			
			if !self:PathIsValid() then
				self:TaskFail("movement_custompos")
				self:StartTask("movement_wait")
			end
		end,
		BehaveUpdate = function(self,data)
			local result = self:ControlPath(!self.IsSeeEnemy)
			
			if result then
				self:TaskComplete("movement_custompos")
				self:StartTask("movement_wait")
			elseif result==false then
				self:TaskFail("movement_custompos")
				self:StartTask("movement_wait")
			end
		end,
		StartControlByPlayer = function(self,data,ply)
			self:TaskFail("movement_custompos")
		end,
	},
	["inform_handler"] = {
		OnStart = function(self,data)
			data.Inform = function(enemy,pos)
				for k,v in ipairs(ents.FindByClass(self:GetClass())) do
					if v==self or v.m_InformGroup!=self.m_InformGroup or self:GetRangeTo(v)>self.InformRadius then continue end
					
					v:RunTask("InformReceive",enemy,pos)
				end
			end
		end,
		BehaveUpdate = function(self,data,interval)
			if IsValid(self.Target) then return end
		
			if self.IsSeeEnemy and (!data.EnemyPosInform or CurTime()>=data.EnemyPosInform) then
				data.EnemyPosInform = CurTime()+5
				
				data.Inform(self:GetEnemy(),self:EntShootPos(self:GetEnemy()))
			end
		end,
		InformReceive = function(self,data,enemy,pos)
			self:SetEntityRelationship(enemy,D_HT,1)
			self:UpdateEnemyMemory(enemy,pos)
			
			if self:IsTaskActive("movement_randomwalk") then
				self:TaskFail("movement_randomwalk")
				
				self.CustomPosition = pos
				self:StartTask("movement_wait")
			end
		end,
		OnKilled = function(self,data,dmg)
			local att = dmg:GetAttacker()
		
			if IsValid(att) and self:GetRelationship(att)==D_NU and (ENEMY_CLASSES[att:GetClass()] or att:IsPlayer()) then
				data.Inform(att,self:EntShootPos(att))
			end
		end,
	},
}

ENT.InformRadius = 5000
ENT.InformGroup = "Soldiers"

--[[------------------------------------
	CONFIG END
--]]------------------------------------

local ENEMY_FRIENDLY,ENEMY_HOSTILE,ENEMY_MONSTER,ENEMY_NEUTRAL = 0,1,2,3
ENEMY_CLASSES = {
	npc_crow = ENEMY_NEUTRAL,
	npc_monk = ENEMY_FRIENDLY,
	npc_pigeon = ENEMY_NEUTRAL,
	npc_seagull = ENEMY_NEUTRAL,
	npc_combine_camera = ENEMY_NEUTRAL,
	npc_turret_ceiling = ENEMY_HOSTILE,
	npc_cscanner = ENEMY_HOSTILE,
	npc_combinedropship = ENEMY_HOSTILE,
	npc_combinegunship = ENEMY_HOSTILE,
	npc_combine_s = ENEMY_HOSTILE,
	npc_helicopter = ENEMY_HOSTILE,
	npc_manhack = ENEMY_HOSTILE,
	npc_metropolice = ENEMY_HOSTILE,
	npc_rollermine = ENEMY_HOSTILE,
	npc_clawscanner = ENEMY_HOSTILE,
	npc_stalker = ENEMY_HOSTILE,
	npc_strider = ENEMY_HOSTILE,
	npc_turret_floor = ENEMY_HOSTILE,
	npc_sniper = ENEMY_HOSTILE,
	npc_alyx = ENEMY_FRIENDLY,
	npc_barney = ENEMY_FRIENDLY,
	npc_citizen = ENEMY_FRIENDLY,
	npc_dog = ENEMY_FRIENDLY,
	npc_kleiner = ENEMY_FRIENDLY,
	npc_mossman = ENEMY_FRIENDLY,
	npc_eli = ENEMY_FRIENDLY,
	npc_gman = ENEMY_NEUTRAL,
	npc_odessa = ENEMY_FRIENDLY,
	npc_vortigaunt = ENEMY_FRIENDLY,
	npc_magnusson = ENEMY_FRIENDLY,
	npc_breen = ENEMY_NEUTRAL,
	npc_antlion = ENEMY_MONSTER,
	npc_antlionguard = ENEMY_MONSTER,
	npc_barnacle = ENEMY_MONSTER,
	npc_headcrab_fast = ENEMY_MONSTER,
	npc_fastzombie = ENEMY_MONSTER,
	npc_fastzombie_torso = ENEMY_MONSTER,
	npc_headcrab = ENEMY_MONSTER,
	npc_headcrab_poison = ENEMY_MONSTER,
	npc_headcrab_black = ENEMY_MONSTER,
	npc_poisonzombie = ENEMY_MONSTER,
	npc_zombie = ENEMY_MONSTER,
	npc_zombie_torso = ENEMY_MONSTER,
	npc_antlion_grub = ENEMY_MONSTER,
	npc_antlionguardian = ENEMY_MONSTER,
	npc_antlion_worker = ENEMY_MONSTER,
	npc_zombine = ENEMY_MONSTER,
	npc_hunter = ENEMY_HOSTILE,
}

function ENT:Initialize()
	BaseClass.Initialize(self)
	
	self:SetUseNodeGraph(UseNodeGraph:GetBool())
	self.PlayerDisposition = PlayerDisposition:GetInt()
	
	self.m_InformRadius = self.InformRadius
	self.m_InformGroup = self.InformGroup
end

function ENT:SetFriendly(fr)
	self.m_Friendly = fr
	self:SetupRelationships()
end

function ENT:IsFriendly()
	return self.m_Friendly
end

function ENT:SetupRelationships()
	for k,v in ipairs(ents.GetAll()) do
		self:SetupEntityRelationship(v)
	end
	
	hook.Add("OnEntityCreated",self,function(self,ent)
		self:SetupEntityRelationship(ent)
	end)
end

function ENT:SetupEntityRelationship(ent)
	local stdd = ENEMY_CLASSES[ent:GetClass()]
	
	if stdd then
		local d = self:GetDesiredEnemyRelationship(ent,stdd)
		self:SetEntityRelationship(ent,d,1)
	
		if ent:IsNPC() then
			ent:AddEntityRelationship(self,d,1)
		end
	end
end

function ENT:BehaviourThink()
	if self:PathIsValid() and !self:IsControlledByPlayer() and !self:DisableBehaviour() then
		local filter = self:GetChildren()
		filter[#filter+1] = self
		
		local pos = self:GetShootPos()
		local endpos = pos+self:GetAimVector()*100
		local blocker = self:ShootBlocker(pos,endpos,filter)
		
		self.LastShootBlocker = blocker
		
		if blocker then
			local class = blocker:GetClass()
		
			if self:HasWeapon() and class:StartWith("func_breakable") then
				self:WeaponPrimaryAttack()
			elseif class=="prop_door_rotating" and blocker:GetInternalVariable("m_eDoorState")!=2 and (!self.OpenDoorTime or CurTime()-self.OpenDoorTime>2) then
				self.OpenDoorTime = CurTime()
				blocker:Fire("Use")
			elseif class=="func_door_rotating" and blocker:GetInternalVariable("m_toggle_state")==1 and (!self.OpenDoorTime or CurTime()-self.OpenDoorTime>2) then
				self.OpenDoorTime = CurTime()
				blocker:Fire("Use")
			elseif class=="func_door" and blocker:GetInternalVariable("m_toggle_state")==1 and (!self.OpenDoorTime or CurTime()-self.OpenDoorTime>2) then
				self.OpenDoorTime = CurTime()
				blocker:Fire("Use")
			end
		end
	else
		self.LastShootBlocker = false
	end
	
	//self.OnContactAllowed = true
end

/*function ENT:OnContact(ent)
	if self==ent or !self.OnContactAllowed then return end

	local vel = ent:GetVelocity()

	if !vel:IsZero() then
		local pos = self:GetPos()
	
		self.loco:Approach(pos+vel:GetNormalized()+(pos-ent:GetPos()):GetNormalized(),1)
		self.OnContactAllowed = false
	end
end*/

function ENT:FindWeapon()
	local distlimit = 500
	local searchrange = 3000
	
	local wep,range,weight

	for k,v in ipairs(ents.GetAll()) do
		local r = self:GetRangeTo(v)
	
		if r>searchrange or !self:CanPickupWeapon(v) or !self:CanSeePosition(v) then continue end
		
		local w = v:GetWeight()
		
		if !wep or w>weight and r-range<distlimit or w<weight and r-range>distlimit or w==weight and r<range then
			wep,range,weight = v,r,w
		end
	end
	
	return wep
end

function ENT:GetDesiredEnemyRelationship(ent,stdd)
	if stdd==ENEMY_NEUTRAL then return D_NU end
	
	local efr = self:EntityIsFriendly(ent)
	
	if stdd==ENEMY_MONSTER and !efr then return D_HT end
	
	local fr = self:IsFriendly()
	
	return fr==efr and D_LI or D_HT
end

function ENT:EntityIsFriendly(ent)
	if ent:IsNPC() then
		if ent:Classify()==CLASS_PLAYER_ALLY then return true end
		
		if (ent:GetClass()=="npc_antlion" or ent:GetClass()=="npc_antlion_worker") and game.GetGlobalState("antlion_allied")==GLOBAL_ON then
			return true
		end
	end
	
	return ENEMY_CLASSES[ent:GetClass()]==ENEMY_FRIENDLY
end

function ENT:ShouldBeEnemy(ent)
	local class = ent:GetClass()
	
	if class=="npc_strider" or class=="npc_combinegunship" or class=="npc_helicopter" or class=="npc_combinedropship" then
		if !self:HasWeapon() or self:GetActiveWeapon():GetClass()!="weapon_rpg" then
			return false
		end
	end
	
	return BaseClass.ShouldBeEnemy(self,ent)
end

function ENT:OnInjured(dmg)
	BaseClass.OnInjured(self,dmg)

	local att = dmg:GetAttacker()
	
	if IsValid(att) and self:GetRelationship(att)==D_NU and (ENEMY_CLASSES[att:GetClass()] or att:IsPlayer()) then
		self:SetEntityRelationship(att,D_HT,0)
	end
end

function ENT:ShootBlocker(start,pos,filter)
	local tr = util.TraceHull({
		start = start,
		endpos = pos,
		filter = filter,
		mask = MASK_SHOT,
		mins = Vector(-2,-2,-2),
		maxs = Vector(2,2,2),
	})
	
	return tr.Hit and tr.Entity
end

function ENT:GetRandomWalkPosition()
	local destlen = 500^2
	local pos = self:GetPos()

	if self:UsingNodeGraph() then
		local cur = SBAdvancedNextbotNodeGraph.GetNearestNode(pos)
		if !cur then return end
		
		local opened = {[cur:GetID()] = true}
		local closed = {}
		local costs = {[cur:GetID()] = cur:GetOrigin():DistToSqr(pos)}
		
		while !table.IsEmpty(opened) do
			local _,nodeid = table.Random(opened)
			opened[nodeid] = nil
			closed[nodeid] = true
			
			local node = SBAdvancedNextbotNodeGraph.GetNodeByID(nodeid)
			
			if costs[nodeid]>=destlen then
				return node:GetOrigin()
			end
			
			for k,v in ipairs(node:GetAdjacentNodes()) do
				if !closed[v:GetID()] then
					local cost = costs[nodeid]+v:GetOrigin():DistToSqr(node:GetOrigin())
					costs[v:GetID()] = cost
					
					opened[v:GetID()] = true
				end
			end
		end
	else
		local cur = navmesh.GetNearestNavArea(pos)
		if !IsValid(cur) then return end
		
		local opened = {[cur:GetID()] = true}
		local closed = {}
		local costs = {[cur:GetID()] = cur:GetCenter():DistToSqr(pos)}
		
		while !table.IsEmpty(opened) do
			local _,areaid = table.Random(opened)
			opened[areaid] = nil
			closed[areaid] = true
			
			local area = navmesh.GetNavAreaByID(areaid)
			
			if costs[areaid]>=destlen then
				return area:GetRandomPoint()
			end
			
			for k,v in ipairs(area:GetAdjacentAreas()) do
				if !closed[v:GetID()] then
					local cost = costs[areaid]+v:GetCenter():DistToSqr(area:GetCenter())
					costs[v:GetID()] = cost
					
					opened[v:GetID()] = true
				end
			end
		end
	end
end

function ENT:SetupTaskList(list)
	BaseClass.SetupTaskList(self,list)
	
	for k,v in pairs(self.TaskList) do
		list[k] = v
	end
end

function ENT:SetupTasks()
	BaseClass.SetupTasks(self)
	
	self:StartTask("enemy_handler")
	self:StartTask("shooting_handler")
	self:StartTask("movement_handler")
	self:StartTask("playercontrol_handler")
	self:StartTask("inform_handler")
end

function ENT:SetupDefaultCapabilities()
	BaseClass.SetupDefaultCapabilities(self)

	self:CapabilitiesAdd(CAP_MOVE_JUMP)
end