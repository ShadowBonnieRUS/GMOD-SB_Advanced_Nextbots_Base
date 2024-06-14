
--[[------------------------------------
	NEXTBOT:BehaveStart
	Creating behaviour thread using NEXTBOT:BehaviourCoroutine. Also setups task list and default tasks.
--]]------------------------------------
function ENT:BehaveStart()
	self:SetupCollisionBounds()

	self:SetupTaskList(self.m_TaskList)
	self:SetupTasks()

	self.BehaviourThread = coroutine.create(function() self:BehaviourCoroutine() end)
end

--[[------------------------------------
	NEXTBOT:BehaveUpdate
	This is where bot updating
--]]------------------------------------
function ENT:BehaveUpdate(interval)
	self.BehaveInterval = interval
	
	self:StuckCheck()
	
	local disable = self:DisableBehaviour()
	
	if !disable then
		local crouch = self:ShouldCrouch()
		if crouch!=self:IsCrouching() and (crouch or self:CanStandUp()) then
			self:SwitchCrouch(crouch)
		end
	end
	
	if !disable then
		self:SetupEyeAngles()
		self:ForgetOldEnemies()
		
		local ply = self:GetControlPlayer()
		if IsValid(ply) then
			-- Sending current weapon clips data
			
			if self:HasWeapon() then
				local wep = self:GetActiveWeapon()
				local clip1, clip2, maxclip1, maxclip2 = wep:Clip1(), wep:Clip2(), wep:GetMaxClip1(), wep:GetMaxClip2()

				if self:GetWeaponClip1() != clip1 then self:SetWeaponClip1(clip1) end
				if self:GetWeaponClip2() != clip2 then self:SetWeaponClip2(clip2) end
				if self:GetWeaponMaxClip1() != maxclip1 then self:SetWeaponMaxClip1(maxclip1) end
				if self:GetWeaponMaxClip2() != maxclip2 then self:SetWeaponMaxClip2(maxclip2) end
			end
			
			-- Calling behavior think for player control
			self:BehaviourPlayerControlThink(ply)
			
			-- Calling task callbacks
			self:RunTask("PlayerControlUpdate",interval,ply)
			
			self.m_ControlPlayerOldButtons = self.m_ControlPlayerButtons
		else
			-- Calling behaviour with coroutine type
			if self.BehaviourThread then
				if coroutine.status(self.BehaviourThread)=="dead" then
					self.BehaviourThread = nil
					ErrorNoHalt("NEXTBOT:BehaviourCoroutine() has been finished!\n")
				else
					assert(coroutine.resume(self.BehaviourThread))
				end
			end
			
			-- Calling behaviour with think type
			self:BehaviourThink()
			
			-- Calling task callbacks
			self:RunTask("BehaveUpdate",interval)
		end
	end
	
	self:SetupGesturePosture()

	self:LocomotionUpdate(interval)
	self.m_FallSpeed = -self.loco:GetVelocity().z
end

--[[------------------------------------
	Name: NEXTBOT:BehaviourCoroutine
	Desc: Override this function to control bot using coroutine type.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:BehaviourCoroutine()
	while true do
		coroutine.yield()
	end
end

--[[------------------------------------
	Name: NEXTBOT:DisableBehaviour
	Desc: Decides should behaviour be disabled.
	Arg1: 
	Ret1: bool | Return true to disable.
--]]------------------------------------
function ENT:DisableBehaviour()
	return self:IsPostureActive() or self:IsGestureActive(true) or GetConVar("ai_disabled"):GetBool() and !self:IsControlledByPlayer() or self:RunTask("DisableBehaviour")
end

--[[------------------------------------
	Name: NEXTBOT:BehaviourThink
	Desc: Override this function to control bot using think type.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:BehaviourThink()
	if !game.SinglePlayer() and (!IsValid(Entity(1)) or !Entity(1):IsListenServerHost()) then return end

	local ent = Entity(1)
	local pos = ent:GetPos()
	local near = self:GetPos():Distance(pos)<100
	
	if !near then
		if !self:PathIsValid() or self:GetPathPos():Distance(pos)>100 then
			self:SetupPath(pos)
		end
		
		if self:PathIsValid() then
			self:GetPath():Draw()
			self:ControlPath(true)
		end
	else
		if self:PathIsValid() then
			self:GetPath():Invalidate()
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:BehaviourPlayerControlThink
	Desc: Override this function to control bot with player.
	Arg1: Player | ply | Player who controls bot
	Ret1: 
--]]------------------------------------
function ENT:BehaviourPlayerControlThink(ply)
	local eyeang = ply:EyeAngles()
	local forward,right = eyeang:Forward(),eyeang:Right()
	local f = self:ControlPlayerKeyDown(IN_FORWARD) and 1 or self:ControlPlayerKeyDown(IN_BACK) and -1 or 0
	local r = self:ControlPlayerKeyDown(IN_MOVELEFT) and 1 or self:ControlPlayerKeyDown(IN_MOVERIGHT) and -1 or 0
	
	if f!=0 or r!=0 then
		local eyeang = ply:EyeAngles()
		if !self:IsUsingLadder() then eyeang.p = 0 end
		eyeang.r = 0
		local movedir = eyeang:Forward()*f-eyeang:Right()*r
		
		self:Approach(self:GetPos()+movedir*100)
	end
	
	if self:ControlPlayerKeyPressed(IN_JUMP) then
		self:Jump()
	end
	
	if self:HasWeapon() then
		local wep = self:GetActiveLuaWeapon()
	
		if self[wep.Primary.Automatic and "ControlPlayerKeyDown" or "ControlPlayerKeyPressed"](self,IN_ATTACK) then
			if wep:Clip1()<=0 and wep:GetMaxClip1()>0 then
				self:WeaponReload()
			else
				self:WeaponPrimaryAttack()
			end
		end
		
		if self[wep.Secondary.Automatic and "ControlPlayerKeyDown" or "ControlPlayerKeyPressed"](self,IN_ATTACK2) then
			self:WeaponSecondaryAttack()
		end
		
		if self:ControlPlayerKeyPressed(IN_RELOAD) then
			self:WeaponReload()
		end
	end
	
	if self:ControlPlayerKeyPressed(IN_USE) then
		local pos = self:GetShootPos()
		local tr = util.TraceLine({start = pos,endpos = pos+forward*72,filter = self})
		
		if tr.Hit then
			if self:CanPickupWeapon(tr.Entity) and !self:HasWeapon() then
				self:SetupWeapon(tr.Entity)
			else
				tr.Entity:Input("Use",self,self)
			end
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:CapabilitiesAdd
	Desc: Adds a capability to the bot.
	Arg1: number | cap | Capabilities to add. See CAP_ Enums
	Ret1: 
--]]------------------------------------
function ENT:CapabilitiesAdd(cap)
	self.m_Capabilities = bit.bor(self.m_Capabilities,cap)
end

--[[------------------------------------
	Name: NEXTBOT:CapabilitiesClear
	Desc: Clears all capabilities of bot.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:CapabilitiesClear()
	self.m_Capabilities = 0
end

--[[------------------------------------
	Name: NEXTBOT:CapabilitiesGet
	Desc: Returns all capabilities including weapon capabilities.
	Arg1: 
	Ret1: number | Capabilities. See CAP_ Enums
--]]------------------------------------
function ENT:CapabilitiesGet()
	return bit.bor(self.m_Capabilities,self:HasWeapon() and self:GetActiveLuaWeapon():GetCapabilities() or 0)
end

--[[------------------------------------
	Name: NEXTBOT:CapabilitiesRemove
	Desc: Removes capability from bot.
	Arg1: number | cap | Capabilities to remove. See CAP_ Enums
	Ret1: 
--]]------------------------------------
function ENT:CapabilitiesRemove(cap)
	self.m_Capabilities = bit.bxor(bit.bor(self.m_Capabilities,cap),cap)
end