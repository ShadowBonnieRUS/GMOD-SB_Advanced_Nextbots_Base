
--[[------------------------------------
	Name: NEXTBOT:SetEnemy
	Desc: Sets active enemy of bot.
	Arg1: Entity | enemy | Enemy to set.
	Ret1: 
--]]------------------------------------
function ENT:SetEnemy(enemy)
	self.m_Enemy = enemy
end

--[[------------------------------------
	Name: NEXTBOT:GetEnemy
	Desc: Returns active enemy of bot.
	Arg1: 
	Ret1: Entity | Enemy
--]]------------------------------------
function ENT:GetEnemy()
	return self.m_Enemy or NULL
end

--[[------------------------------------
	Name: NEXTBOT:SetClassRelationship
	Desc: Sets how bot feels towards entities with that class.
	Arg1: string | class | Entities classname
	Arg2: number | d | Disposition. See D_* Enums
	Arg3: (optional) number | priority | How strong relationship is.
	Ret1: 
--]]------------------------------------
function ENT:SetClassRelationship(class,d,priority)
	self.m_ClassRelationships[class] = {d,priority or 0}
end

--[[------------------------------------
	Name: NEXTBOT:SetEntityRelationship
	Desc: Sets how bot feels towards entity.
	Arg1: Entity | ent | Entity to apply relationship
	Arg2: number | d | Disposition. See D_* Enums
	Arg3: (optional) number | priority | How strong relationship is.
	Ret1: 
--]]------------------------------------
function ENT:SetEntityRelationship(ent,d,priority)
	self.m_EntityRelationships[ent] = {d,priority or 0}
end

--[[------------------------------------
	Name: NEXTBOT:GetRelationship
	Desc: Returns how bot feels about this entity.
	Arg1: Entity | ent | Entity to get disposition from.
	Ret1: number | Priority disposition. See D_* Enums.
	Ret2: number | Priority of disposition.
--]]------------------------------------
function ENT:GetRelationship(ent)
	local d,priority = D_NU,-1
	
	local entr = self.m_EntityRelationships[ent]
	if entr and entr[2]>priority then
		d,priority = entr[1],entr[2]
	end
	
	local classr = self.m_ClassRelationships[ent:GetClass()]
	if classr and classr[2]>priority then
		d,priority = classr[1],classr[2]
	end
	
	return d,priority
end

--[[------------------------------------
	Name: NEXTBOT:EntShootPos
	Desc: Returns where bot should aim while shooting at this entity. Also used in line of sight tests.
	Arg1: Entity | ent | Entity to get shoot pos.
	Arg2: (optional) bool | random | Should choose random hitbox to get position.
	Ret1: Vector | Position where we should aim.
--]]------------------------------------
function ENT:EntShootPos(ent,random)
	local hitboxes = {}
	local sets = ent:GetHitboxSetCount()
	
	if sets then
		for i=0,sets-1 do
			for j=0,ent:GetHitBoxCount(i)-1 do
				local group = ent:GetHitBoxHitGroup(j,i)
				
				hitboxes[group] = hitboxes[group] or {}
				hitboxes[group][#hitboxes[group]+1] = {ent:GetHitBoxBone(j,i),ent:GetHitBoxBounds(j,i)}
			end
		end
		
		local data
		
		if hitboxes[HITGROUP_HEAD] then
			data = hitboxes[HITGROUP_HEAD][random and math.random(#hitboxes[HITGROUP_HEAD]) or 1]
		elseif hitboxes[HITGROUP_CHEST] then
			data = hitboxes[HITGROUP_CHEST][random and math.random(#hitboxes[HITGROUP_CHEST]) or 1]
		elseif hitboxes[HITGROUP_GENERIC] then
			data = hitboxes[HITGROUP_GENERIC][random and math.random(#hitboxes[HITGROUP_GENERIC]) or 1]
		end
		
		if data then
			local bonem = ent:GetBoneMatrix(data[1])
			local center = data[2]+(data[3]-data[2])/2
			
			local pos = LocalToWorld(center,angle_zero,bonem:GetTranslation(),bonem:GetAngles())
			return pos
		end
	end
	
	return ent.GetShootPos and ent:GetShootPos() or ent:WorldSpaceCenter()
end

--[[------------------------------------
	Name: NEXTBOT:CanSeePosition
	Desc: Line of sight test. Returns should we see that position.
	Arg1: Vector | pos | Position to test. Can be also Entity, in this case will be used NEXTBOT:EntShootPos position.
	Ret1: bool | Bot see position or not.
--]]------------------------------------
function ENT:CanSeePosition(pos)
	local p = isentity(pos) and self:EntShootPos(pos) or pos
	local tr = util.TraceLine({start = self:GetShootPos(),endpos = p,mask = self.LineOfSightMask,filter = self})
	
	return !tr.Hit or isentity(pos) and tr.Entity==pos
end

--[[------------------------------------
	Name: NEXTBOT:UpdateEnemyMemory
	Desc: Updates bot's memory of this enemy.
	Arg1: Entity | enemy | Enemy to update.
	Arg2: Vector | pos | Position where bot see enemy.
	Ret1: 
--]]------------------------------------
function ENT:UpdateEnemyMemory(enemy,pos)
	self.m_EnemiesMemory[enemy] = self.m_EnemiesMemory[enemy] or {}
	self.m_EnemiesMemory[enemy].lastupdate = CurTime()
	self.m_EnemiesMemory[enemy].pos = pos
end

--[[------------------------------------
	Name: NEXTBOT:ClearEnemyMemory
	Desc: Clears bot memory of this enemy.
	Arg1: (optional) Entity | enemy | Enemy to clear memory of. If unset, will be used NEXTBOT:GetEnemy 
	Ret1: 
--]]------------------------------------
function ENT:ClearEnemyMemory(enemy)
	enemy = enemy or self:GetEnemy()
	self.m_EnemiesMemory[enemy] = nil
	
	if self:GetEnemy()==enemy then
		self:SetEnemy(NULL)
	end
end

--[[------------------------------------
	Name: NEXTBOT:FindEnemies
	Desc: Finds all enemies that can be seen from bot position and updates memory.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:FindEnemies()
	for k,v in ipairs(ents.GetAll()) do
		if v==self or !self:ShouldBeEnemy(v) or !self:CanSeePosition(v) then continue end
		
		self:UpdateEnemyMemory(v,self:EntShootPos(v))
	end
end

--[[------------------------------------
	Name: NEXTBOT:GetKnownEnemies
	Desc: Returns all entities that in bot's enemy memory.
	Arg1: 
	Ret1: table | Enemies table
--]]------------------------------------
function ENT:GetKnownEnemies()
	local t = {}
	
	for k,v in pairs(self.m_EnemiesMemory) do
		if IsValid(k) and self:ShouldBeEnemy(k) then
			table.insert(t,k)
		end
	end
	
	return t
end

--[[------------------------------------
	Name: NEXTBOT:GetLastEnemyPosition
	Desc: Returns last updated position of enemy.
	Arg1: Entity | enemy | Enemy to get position.
	Ret1: Vector | Last known position. Returns nil if enemy is not in bot memory.
--]]------------------------------------
function ENT:GetLastEnemyPosition(enemy)
	return self.m_EnemiesMemory[enemy] and self.m_EnemiesMemory[enemy].pos
end

--[[------------------------------------
	Name: NEXTBOT:HaveEnemy
	Desc: Returns if bot have enemy.
	Arg1: 
	Ret1: bool | Bot have enemy or not.
--]]------------------------------------
function ENT:HaveEnemy()
	local enemy = self:GetEnemy()
	return IsValid(enemy) and self:ShouldBeEnemy(enemy)
end

--[[------------------------------------
	Name: NEXTBOT:ForgetOldEnemies
	Desc: (INTERNAL) Clears bot memory from enemies that not valid, not updating very long time or not should be enemy.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:ForgetOldEnemies()
	for k,v in pairs(self.m_EnemiesMemory) do
		if !IsValid(k) or CurTime()-v.lastupdate>=self.ForgetEnemyTime or !self:ShouldBeEnemy(k) then
			self:ClearEnemyMemory(k)
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:ShouldBeEnemy
	Desc: Returns should bot mark this entity as enemy.
	Arg1: Entity | ent | Entity to check
	Ret1: bool | Should be enemy or not
--]]------------------------------------
function ENT:ShouldBeEnemy(ent)
	if ent:IsPlayer() and GetConVar("ai_ignoreplayers"):GetBool() then return false end
	if ent:IsPlayer() and ent:IsFlagSet(FL_NOTARGET) then return false end
	if self:GetRelationship(ent)!=D_HT then return false end
	if !ent.SBAdvancedNextBot and ent:IsNPC() and (ent:GetNPCState()==NPC_STATE_DEAD or ent:GetClass()=="npc_barnacle" and ent:GetInternalVariable("m_takedamage")==0) then return false end
	if (ent.SBAdvancedNextBot or !ent:IsNPC()) and ent:Health()<=0 then return false end
	if self:GetRangeTo(ent)>self.MaxSeeEnemyDistance then return false end
	
	return true
end

--[[------------------------------------
	Name: NEXTBOT:FindPriorityEnemy
	Desc: Returns highest priority enemy.
	Arg1: 
	Ret1: Entity | Highest priority enemy or NULL
--]]------------------------------------
function ENT:FindPriorityEnemy()
	local notsee = {}
	local enemy,range,priority
	local byrange = false
	
	for k,v in pairs(self.m_EnemiesMemory) do
		if !IsValid(k) or !self:ShouldBeEnemy(k) then continue end
		
		if !self:CanSeePosition(k) then
			notsee[#notsee+1] = k
			continue
		end
		
		local rang = self:GetRangeTo(k)
		local d,pr = self:GetRelationship(k)
		
		if !byrange and rang<=self.CloseEnemyDistance then
			-- too close, ignore priority
			byrange = true
		end
		
		if !enemy or Either(byrange,rang<range,Either(pr==priority,rang<range,pr>priority)) then
			enemy,range,priority = k,rang,pr
		end
	end
	
	if !enemy then
		-- we dont see any enemy, but we know last position
	
		for k,v in ipairs(notsee) do
			local rang = self:GetRangeTo(self:GetLastEnemyPosition(v))
			
			if !enemy or rang<range then
				enemy,range = v,rang
			end
		end
	end
	
	return enemy or NULL
end
