-- Motion Type Enums
SB_ADVANCED_NEXTBOT_MOTIONTYPE_IDLE = 0
SB_ADVANCED_NEXTBOT_MOTIONTYPE_MOVE = 1
SB_ADVANCED_NEXTBOT_MOTIONTYPE_RUN = 2
SB_ADVANCED_NEXTBOT_MOTIONTYPE_WALK = 3
SB_ADVANCED_NEXTBOT_MOTIONTYPE_CROUCH = 4
SB_ADVANCED_NEXTBOT_MOTIONTYPE_CROUCHWALK = 5

--[[------------------------------------
	Name: NEXTBOT:SetMotionType
	Desc: (INTERNAL) Sets bot motion type.
	Arg1: number | type | Motion Type. See SB_ADVANCED_NEXTBOT_MOTIONTYPE_ Enums
	Ret1:
--]]------------------------------------
function ENT:SetMotionType(type)
	self.m_MotionType = type
end

--[[------------------------------------
	Name: NEXTBOT:GetMotionType
	Desc: (INTERNAL) Returns bot motion type.
	Arg1: 
	Ret1: number | Motion Type. See SB_ADVANCED_NEXTBOT_MOTIONTYPE_ Enums
--]]------------------------------------
function ENT:GetMotionType()
	return self.m_MotionType or SB_ADVANCED_NEXTBOT_MOTIONTYPE_IDLE
end

--[[------------------------------------
	Name: NEXTBOT:SetupSpeed
	Desc: (INTERNAL) Called to set locomotion desired motion speed сonsidering NEXTBOT:Should* and NEXTBOT:IsCrouching funcs.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupSpeed()
	local speed = 0
	
	if self:IsCrouching() then
		speed = self:ShouldWalk() and self.WalkSpeed or self.CrouchSpeed
	else
		if self:ShouldRun() then
			speed = self.RunSpeed
		elseif self:ShouldWalk() then
			speed = self.WalkSpeed
		else
			speed = self.MoveSpeed
		end
	end
	
	speed = self:RunTask("ModifyMovementSpeed",speed) or speed
	
	self.loco:SetDesiredSpeed(speed)
	self.m_Speed = speed
end

--[[------------------------------------
	Name: NEXTBOT:GetCurrentSpeed()
	Desc: Returns bot current motion speed.
	Arg1: 
	Ret1: number | Motion speed.
--]]------------------------------------
function ENT:GetCurrentSpeed()
	return self.loco:GetVelocity():Length2D()
end

--[[------------------------------------
	Name: NEXTBOT:GetDesiredSpeed()
	Desc: Returns bots Locomotion desired speed.
	Arg1: 
	Ret1: number | Motion speed.
--]]------------------------------------
function ENT:GetDesiredSpeed()
	return self.m_Speed or 0
end

--[[------------------------------------
	Name: NEXTBOT:IsMoving()
	Desc: Returns bot is moving or not.
	Arg1: 
	Ret1: bool | Bot is moving.
--]]------------------------------------
function ENT:IsMoving()
	return self:GetCurrentSpeed()>0.1
end

--[[------------------------------------
	Name: NEXTBOT:SetupMotionType()
	Desc: (INTERNAL) Called to setup motion type сonsidering motion speed and NEXTBOT:IsCrouching.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupMotionType()
	local moving = self:IsMoving()
	local type = SB_ADVANCED_NEXTBOT_MOTIONTYPE_IDLE
	
	if self:IsCrouching() then
		type = moving and SB_ADVANCED_NEXTBOT_MOTIONTYPE_CROUCHWALK or SB_ADVANCED_NEXTBOT_MOTIONTYPE_CROUCH
	elseif moving then
		local speed = self:GetCurrentSpeed()
		
		if speed>self.MoveSpeed+1 then
			type = SB_ADVANCED_NEXTBOT_MOTIONTYPE_RUN
		elseif speed<self.MoveSpeed/2+1 then
			type = SB_ADVANCED_NEXTBOT_MOTIONTYPE_WALK
		else
			type = SB_ADVANCED_NEXTBOT_MOTIONTYPE_MOVE
		end
	end
	
	self:SetMotionType(type)
end

--[[------------------------------------
	Name: NEXTBOT:SetDesiredEyeAngles
	Desc: Sets direction where bot want aim. You should use this in behaviour.
	Arg1: Angle | ang | Desired direction.
	Ret1:
--]]------------------------------------
function ENT:SetDesiredEyeAngles(ang)
	self.m_DesiredEyeAngles = ang
end

--[[------------------------------------
	Name: NEXTBOT:GetDesiredEyeAngles
	Desc: Returns direction where bot want aim.
	Arg1: 
	Ret1: Angle | Desired direction.
--]]------------------------------------
function ENT:GetDesiredEyeAngles()
	return self.m_DesiredEyeAngles or angle_zero
end

--[[------------------------------------
	Name: NEXTBOT:SetupEyeAngles
	Desc: (INTERNAL) Aiming bot to desired direction.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupEyeAngles()
	local angp = self.m_PitchAim
	local angy = self:GetAngles().y
	
	local desired = self:GetDesiredEyeAngles()
	local punch = self:GetViewPunchAngles()

	if self:IsControlledByPlayer() then
		desired = self:GetControlPlayer():EyeAngles()
	end
	
	local diffp = math.AngleDifference(desired.p,angp)
	local diffy = math.AngleDifference(desired.y,angy)
	local max = self.BehaveInterval*self.AimSpeed
	
	diffp = diffp<0 and math.max(-max,diffp) or math.min(max,diffp)
	diffy = diffy<0 and math.max(-max,diffy) or math.min(max,diffy)
	
	angp = angp+diffp
	angy = angy+diffy
	
	self:SetAngles(Angle(0,angy,0))
	
	self.m_PitchAim = angp
	self:SetPoseParameter("aim_pitch",self.m_PitchAim+punch.p)
	self:SetPoseParameter("aim_yaw",punch.y)
	
	self:SetEyeTarget(self:GetShootPos()+self:GetEyeAngles():Forward()*100)
end

--[[------------------------------------
	Name: NEXTBOT:ViewPunch
	Desc: Performs simple view punch.
	Arg1: Angle | ang | view punch angles.
	Ret1: 
--]]------------------------------------
function ENT:ViewPunch(ang)
	self:SetViewPunchTime(CurTime())
	self:SetViewPunchAngle(ang)
end

-- From gamemodes/base/gamemode/animations.lua
local IdleActivity = ACT_HL2MP_IDLE
local IdleActivityTranslate = {
	[ACT_MP_STAND_IDLE]					= IdleActivity,
	[ACT_MP_WALK]						= IdleActivity+1,
	[ACT_MP_RUN]						= IdleActivity+2,
	[ACT_MP_CROUCH_IDLE]				= IdleActivity+3,
	[ACT_MP_CROUCHWALK]					= IdleActivity+4,
	[ACT_MP_ATTACK_STAND_PRIMARYFIRE]	= IdleActivity+5,
	[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]	= IdleActivity+5,
	[ACT_MP_RELOAD_STAND]				= IdleActivity+6,
	[ACT_MP_RELOAD_CROUCH]				= IdleActivity+7,
	[ACT_MP_JUMP]						= ACT_HL2MP_JUMP_SLAM,
	[ACT_MP_SWIM]						= IdleActivity+9,
	[ACT_LAND]							= ACT_LAND,
}

--[[------------------------------------
	Name: NEXTBOT:TranslateActivity
	Desc: (INTERNAL) Translate ACT_MP_* activity to right activity сonsidering weapon.
	Arg1: number | act | Activity to translate
	Ret1: number | Translated activity
--]]------------------------------------
function ENT:TranslateActivity(act)
	local task = self:RunTask("TranslateActivity",act)
	if task then return task end
	
	if self:HasWeapon() then
		self.m_PassIsNPCCheck = false
		local newact
		ProtectedCall(function() newact = self:GetActiveLuaWeapon():TranslateActivity(act) end)
		self.m_PassIsNPCCheck = true
		
		return newact
	end
	
	return IdleActivityTranslate[act] or IdleActivity
end

local MotionTypeActivity = {
	[SB_ADVANCED_NEXTBOT_MOTIONTYPE_IDLE] = ACT_MP_STAND_IDLE,
	[SB_ADVANCED_NEXTBOT_MOTIONTYPE_MOVE] = ACT_MP_RUN,
	[SB_ADVANCED_NEXTBOT_MOTIONTYPE_RUN] = ACT_MP_RUN,
	[SB_ADVANCED_NEXTBOT_MOTIONTYPE_WALK] = ACT_MP_WALK,
	[SB_ADVANCED_NEXTBOT_MOTIONTYPE_CROUCH] = ACT_MP_CROUCH_IDLE,
	[SB_ADVANCED_NEXTBOT_MOTIONTYPE_CROUCHWALK] = ACT_MP_CROUCHWALK,
}

--[[------------------------------------
	Name: NEXTBOT:SetupActivity
	Desc: (INTERNAL) Sets right activity to bot.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupActivity()
	local curact = self:GetActivity()
	local act = self:RunTask("GetDesiredActivity")
	
	if !act then
		act = self:IsJumping() and ACT_MP_JUMP or MotionTypeActivity[self:GetMotionType()]	
		act = self:TranslateActivity(act)
	end
	
	if act and curact!=act then
		self:StartActivity(act)
	end
end

--[[------------------------------------
	Name: NEXTBOT:DoGesture
	Desc: Creates gesture animation (e.g. reload animation). Removes previous gesture.
	Arg1: number | act | Animation to run. See ACT_* Enums.
	Arg2: (optional) number | speed | Playback rate.
	Arg3: (optional) bool | wait | Should behaviour be stopped while gesture active (like DoPosture).
	Ret1: 
--]]------------------------------------
function ENT:DoGesture(act,speed,wait)
	self.m_DoGesture = {act,speed or 1,wait}
end

--[[------------------------------------
	Name: NEXTBOT:DoPosture
	Desc: Creates posture animation (e.g. reload animation). Removes previous posture. NOTE: While posture active behaviour will be disabled and activities will not be updated.
	Arg1: number | act | Animation to run. See ACT_* Enums. If `issequence` is true, sequence id (also can be string).
	Arg2: (optional) bool | issequence | If set, creates sequence with `act` argument id, otherwise gest random weighted sequence to `act` activity.
	Arg3: (optional) number | speed | Playback rate.
	Arg4: (optional) bool | noautokill | If set, disables autokill when sequence has finished.
	Ret1: number | Length of created sequence.
--]]------------------------------------
function ENT:DoPosture(act,issequence,speed,noautokill)
	local seq = issequence and act or self:SelectWeightedSequence(act)
	
	self.m_DoPosture = {seq,speed or 1,!noautokill}
	
	return self:SequenceDuration(seq)
end

--[[------------------------------------
	Name: NEXTBOT:StopGesture
	Desc: Removes current gesture. Does nothing if gesture not active.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:StopGesture()
	if self.m_CurGesture then
		self:RemoveGesture(self.m_CurGesture[1])
		self.m_CurGesture = nil
	end
end

--[[------------------------------------
	Name: NEXTBOT:StopPosture
	Desc: Removes current posture. Does nothing if posture not active.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:StopPosture()
	if self.m_CurPosture then
		self.m_CurPosture = nil
		
		self:ResetSequenceInfo()
		self:StartActivity(self:GetActivity())
	end
end

--[[------------------------------------
	Name: NEXTBOT:IsGestureActive
	Desc: Returns whenever we currently playing a gesture or not.
	Arg1: (optional) bool | wait | If true, function will return true only if behaviour should be stopped while gesture active.
	Ret1: bool | Gesture active or not.
--]]------------------------------------
function ENT:IsGestureActive(wait)
	return self.m_CurGesture and CurTime()<self.m_CurGesture[2] and (!wait or self.m_CurGesture[3]) or false
end

--[[------------------------------------
	Name: NEXTBOT:IsPostureActive
	Desc: Returns whenever we currently playing a posture or not.
	Arg1: 
	Ret1: bool | Posture active or not.
--]]------------------------------------
function ENT:IsPostureActive()
	return self.m_CurPosture and (!self.m_CurPosture[2] or CurTime()<self.m_CurPosture[1]) or false
end

--[[------------------------------------
	Name: NEXTBOT:SetupGesturePosture
	Desc: (INTERNAL) Setups gestures and postures. DoGesture and DoPosture not actually creates animations, because for correctly work it should be done in BehaveUpdate. SetupGesturePosture will called in BehaveUpdate.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupGesturePosture()
	if self.m_DoGesture then
		local act = self.m_DoGesture[1]
		local spd = self.m_DoGesture[2]
		local wait = self.m_DoGesture[3]
		self.m_DoGesture = nil
		
		self:StopGesture()
		
		local layer = self:AddGesture(act)
		self:SetLayerPlaybackRate(layer,spd)
		self:SetLayerBlendIn(layer,0.2)
		self:SetLayerBlendOut(layer,0.2)
		
		self.m_CurGesture = {act,CurTime()+self:GetLayerDuration(layer),wait}
	end
	
	if self.m_DoPosture then
		local seq = self.m_DoPosture[1]
		local spd = self.m_DoPosture[2]
		local autokill = self.m_DoPosture[3]
		self.m_DoPosture = nil
		
		self:StopPosture()
		
		local len = self:SetSequence(seq)
		self:ResetSequenceInfo()
		self:SetCycle(0)
		self:SetPlaybackRate(spd)
		
		self.m_CurPosture = {CurTime()+len/spd,autokill}
	end
	
	if self.m_CurPosture and self.m_CurPosture[2] and CurTime()>self.m_CurPosture[1] then
		self:StopPosture()
	end
end

--[[------------------------------------
	NEXTBOT:BodyUpdate
	Updating animations and activities.
--]]------------------------------------
function ENT:BodyUpdate()
	if !self:IsPostureActive() then
		self:SetupActivity()
	end
	
	if self:IsMoving() then
		self:BodyMoveXY()
	else
		self:FrameAdvance(0)
	end
	
	self:RunTask("BodyUpdate")
end

--[[------------------------------------
	Name: NEXTBOT:ShouldRun
	Desc: Decides should bot run or not.
	Arg1: 
	Ret1: bool | Should run or not
--]]------------------------------------
function ENT:ShouldRun()
	if self:IsControlledByPlayer() then
		if self:ControlPlayerKeyDown(IN_SPEED) then
			return true
		end
		
		return false
	else
		return self:RunTask("ShouldRun") or false
	end
end

--[[------------------------------------
	Name: NEXTBOT:ShouldWalk
	Desc: Decides should bot walk or not.
	Arg1: 
	Ret1: bool | Should walk or not
--]]------------------------------------
function ENT:ShouldWalk()
	if self:IsControlledByPlayer() then
		if self:ControlPlayerKeyDown(IN_WALK) then
			return true
		end
		
		return false
	else
		return self:RunTask("ShouldWalk") or false
	end
end

--[[------------------------------------
	Name: NEXTBOT:ShouldCrouch
	Desc: Decides should bot crouch or not.
	Arg1: 
	Ret1: bool | Should crouch or not
--]]------------------------------------
function ENT:ShouldCrouch()
	if !self.CanCrouch then return false end

	if self:IsControlledByPlayer() then
		if self:ControlPlayerKeyDown(IN_DUCK) then
			return true
		end
		
		return false
	else
		if self.m_Jumping then return true end
		
		if !self:UsingNodeGraph() and IsValid(self:GetCurrentNavArea()) and self:GetCurrentNavArea():HasAttributes(NAV_MESH_CROUCH) then
			return true
		end
	
		return self:RunTask("ShouldCrouch") or false
	end
end

--[[------------------------------------
	Name: NEXTBOT:CanStandUp
	Desc: (INTERNAL) Can bot stand up from crouch and dont stuck anywhere.
	Arg1: 
	Ret1: bool | Can stand up or not
--]]------------------------------------
function ENT:CanStandUp()
	if !self:IsCrouching() then return true end
	
	local pos = self:GetPos()
	local bounds = self.CollisionBounds
	
	return !util.TraceHull({
		start = pos,
		endpos = pos,
		mask = self:GetSolidMask(),
		collisiongroup = self:GetCollisionGroup(),
		filter = self,
		mins = bounds[1],
		maxs = bounds[2],
	}).Hit
end

--[[------------------------------------
	Name: NEXTBOT:SetupCollisionBounds
	Desc: (INTERNAL) Sets collision bounds сonsidering crouch status. Also recreating physics object using new bounds
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupCollisionBounds()
	local data = self:IsCrouching() and self.CrouchCollisionBounds or self.CollisionBounds
	
	self:SetCollisionBounds(data[1],data[2])
	
	if self:PhysicsInitShadow(false,false) then
		self:GetPhysicsObject():SetMass(85)	-- 85 is default player's physics object mass
	end
end

--[[------------------------------------
	Name: NEXTBOT:UpdatePhysicsObject
	Desc: (INTERNAL) Updates physics object position and angles.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:UpdatePhysicsObject()
	local phys = self:GetPhysicsObject()
	
	if IsValid(phys) then
		phys:SetAngles(angle_zero)
	
		phys:UpdateShadow(self:GetPos(),angle_zero,self.BehaveInterval)
		
		phys:SetPos(self:GetPos())
	end
end

--[[------------------------------------
	Name: NEXTBOT:PhysicsObjectCollide
	Desc: Called when physics object collides something. Works like ENT:PhysicsCollide.
	Arg1: table | data | The collision data.
	Ret1: 
--]]------------------------------------
function ENT:PhysicsObjectCollide(data)
	local phys = data.PhysObject
end

--[[------------------------------------
	Name: NEXTBOT:OnContact
	Desc: (INTERNAL) Used to call NEXTBOT:OnTouch when there is a actual contact.
	Arg1: Entity | ent | Entity the nextbot came contact with.
	Ret1: 
--]]------------------------------------
function ENT:OnContact(ent)
	local trace = self:GetTouchTrace()
	
	if trace.Hit then
		self:OnTouch(ent,trace)
	end
end

--[[------------------------------------
	Name: NEXTBOT:OnTouch
	Desc: Called when bot touches something.
	Arg1: Entity | ent | Entity that bot touches.
	Arg2: table | trace | TraceResult touch data.
	Ret1: 
--]]------------------------------------
function ENT:OnTouch(ent,trace)
end

--[[------------------------------------
	Name: NEXTBOT:SwitchCrouch
	Desc: (INTERNAL) Change crouch status.
	Arg1: bool | crouch | Should change from stand to crouch, otherwise change from crouch to stand
	Ret1: 
--]]------------------------------------
function ENT:SwitchCrouch(crouch)
	self:SetCrouching(crouch)
	self:SetupCollisionBounds()
end

--[[------------------------------------
	Name: NEXTBOT:GetCurrentNavArea
	Desc: Returns current nav area where bot is.
	Arg1: 
	Ret1: NavArea | Current nav area
--]]------------------------------------
function ENT:GetCurrentNavArea()
	return self.m_NavArea
end

--[[------------------------------------
	Name: NEXTBOT:GetPath
	Desc: Returns last PathFollower object used for path finding.
	Arg1: 
	Ret1: PathFollower | PathFollower object
--]]------------------------------------
function ENT:GetPath()
	return self.m_Path
end

--[[------------------------------------
	Name: NEXTBOT:PathIsValid
	Desc: Returns whenever PathFollower object is valid or not.
	Arg1: 
	Ret1: bool | PathFollower object is valid or not
--]]------------------------------------
function ENT:PathIsValid()
	return self:GetPath():IsValid()
end

--[[------------------------------------
	Name: NEXTBOT:NavMeshPathCostGenerator
	Desc: (INTERNAL) Used to remove some nav areas from path.
	Arg1: PathFollower | path | Path object.
	Arg2: NavArea | area | Current area generating cost to.
	Arg3: NavArea | from | Current area generating cost from.
	Arg4: NavLadder | ladder | Ladder object.
	Arg5: 
	Arg6: number | len | Distance between areas.
	Ret1: number | New cost for area. -1 to remove area from path.
--]]------------------------------------
function ENT:NavMeshPathCostGenerator(path,area,from,ladder,elevator,len)
	if !IsValid(from) then return 0 end
	if !self.loco:IsAreaTraversable(area) then return -1 end
	if !self.CanCrouch and area:HasAttributes(NAV_MESH_CROUCH) then return -1 end
	
	local dist = 0
	
	if IsValid(ladder) then
		dist = ladder:GetLength()
	elseif len>0 then
		dist = len
	else
		dist = area:GetCenter():Distance(from:GetCenter())
	end
	
	if area:HasAttributes(NAV_MESH_JUMP) then
		dist = dist*5
	end
	
	if area:HasAttributes(NAV_MESH_AVOID) then
		dist = dist*10
	end
	
	local cost = dist+from:GetCostSoFar()
	
	local deltaZ = from:ComputeAdjacentConnectionHeightChange(area)
	if deltaZ>=self.loco:GetStepHeight() then
		if deltaZ>=self.loco:GetMaxJumpHeight() then return -1 end

		cost = cost+dist*5
	elseif deltaZ<-self.loco:GetDeathDropHeight() then
		return -1
	end
	
	return cost
end

--[[------------------------------------
	Name: NEXTBOT:SetupPath
	Desc: Creates new PathFollower object and computes path to goal. Invalidates old path.
	Arg1: Vector | pos | Goal position.
	Arg2: (optional) table | options | Table with options:
		`mindist` - SetMinLookAheadDistance
		`tolerance` - SetGoalTolerance
		`generator` - Custom cost generator
		`recompute` - recompute path every x seconds
	Ret1: any | PathFollower object if created succesfully, otherwise false
--]]------------------------------------
function ENT:SetupPath(pos,options)
	self:GetPath():Invalidate()
	
	options = options or {}
	options.mindist = options.mindist or self.PathMinLookAheadDistance
	options.tolerance = options.tolerance or self.PathGoalTolerance
	options.recompute = options.recompute or self.PathRecompute
	
	if !options.generator and !self:UsingNodeGraph() then
		options.generator = function(area,from,ladder,elevator,len) return self:NavMeshPathCostGenerator(self:GetPath(),area,from,ladder,elevator,len) end
	end
	
	local path = self:UsingNodeGraph() and self:NodeGraphPath() or Path("Follow")
	self.m_Path = path
	
	path:SetMinLookAheadDistance(options.mindist)
	path:SetGoalTolerance(options.tolerance)
	
	self.m_PathOptions = options
	self.m_PathPos = pos
	
	if !self:ComputePath(pos,options.generator) then
		path:Invalidate()
		return false
	end
	
	return path
end

--[[------------------------------------
	Name: NEXTBOT:ComputePath
	Desc: (INTERNAL) Computes path to goal.
	Arg1: Vector | pos | Goal position.
	Arg2: (optional) function | generator | Custom cost generator for A* algorithm
	Ret1: bool | Path generated succesfully
--]]------------------------------------
function ENT:ComputePath(pos,generator)
	local path = self:GetPath()
	
	if path:Compute(self,pos,generator) then
		local ang = self:GetAngles()
		path:Update(self)
		self:SetAngles(ang)
		
		return path:IsValid()
	end
	
	return false
end

--[[------------------------------------
	Name: NEXTBOT:ControlPath
	Desc: Moves along path with name or creates new path if names not equal or path is invalid. You should use this to move your bot.
	Arg1: bool | lookatgoal | Should Bot look at goal while moving.
	Ret1: any | true on path successfully ended, false on path invalidate, nothing otherwise
--]]------------------------------------
function ENT:ControlPath(lookatgoal)
	if !self:PathIsValid() then return false end
	
	local path = self:GetPath()
	local pos = self:GetPathPos()
	local options = self.m_PathOptions

	if self:GetRangeTo(pos)<options.tolerance then
		path:Invalidate()
		return true
	end
	
	if path:GetAge()>options.recompute then
		path:ResetAge()
		
		if !self:ComputePath(pos,options.generator) then
			return false
		end
	end
	
	if self:MoveAlongPath(lookatgoal) then
		return true
	end
end

--[[------------------------------------
	NEXTBOT:OnNavAreaChanged
	Saving new area as current. Also stops bot if area has NAV_MESH_STOP attribute.
--]]------------------------------------
function ENT:OnNavAreaChanged(old,new)
	self.m_NavArea = new
	
	if new:HasAttributes(NAV_MESH_STOP) and self.loco:IsOnGround() then
		local vel = self.loco:GetVelocity()
		vel.x = 0
		vel.y = 0
		
		self.loco:SetVelocity(vel)
	end
end

--[[------------------------------------
	Name: NEXTBOT:Approach
	Desc: (INTERNAL) Moving bot to goal.
	Arg1: Vector | pos | Goal.
	Ret1:
--]]------------------------------------
function ENT:Approach(pos)
	if self.loco:IsOnGround() then
		self.loco:Approach(pos,1)
	else
		-- In air we using player alike motion, moving with small speed.
	
		local dt = self.BehaveInterval
		local maxspd = math.min(50,self.m_Speed)
		local dir = pos-self:GetPos()
		dir.z = 0
		
		local ang = dir:Angle()
		local vel = self.loco:GetVelocity()
		vel = WorldToLocal(vel,angle_zero,vector_origin,ang)
		
		if vel.x<maxspd then
			if vel.x<0 then
				vel.x = vel.x+self.loco:GetDeceleration()*dt
			else
				vel.x = vel.x+self.loco:GetAcceleration()*dt
			end
			
			vel.x = math.min(vel.x,maxspd)
		end
		
		local decy = self.loco:GetDeceleration()*dt
		if math.abs(vel.y)>decy then
			vel.y = vel.y>0 and vel.y-decy or vel.y+decy
		else
			vel.y = 0
		end
		
		vel = LocalToWorld(vel,angle_zero,vector_origin,ang)
		self.loco:SetVelocity(vel)
	end
end

--[[------------------------------------
	Name: NEXTBOT:GetPathPos
	Desc: Returns goal of path.
	Arg1: 
	Ret1: Vector | Goal position
--]]------------------------------------
function ENT:GetPathPos()
	return self.m_PathPos
end

local function GetJumpBlockState(self,dir)
	-- Returns state of jump block (nil - clear; true - should step back to jump correctly; false - can't reach goal, fully blocked)

	local pos = self:GetPos()
	local b1,b2 = self:GetCollisionBounds()
	local step = self.loco:GetStepHeight()
	
	b1.x = b1.x/2
	b1.y = b1.y/2
	b2.x = b2.x/2
	b2.y = b2.y/2
	
	b1.z = b1.z+step
	
	local tr = {}
	local t = {
		start = pos,
		endpos = pos+dir*(b2.x-b1.x),
		mins = b1,
		maxs = b2,
		filter = self,
		mask = self:GetSolidMask(),
		collisiongroup = self:GetCollisionGroup(),
		output = tr,
	}
	
	util.TraceHull(t)
	
	if tr.Hit then
		local maxjump = self.MaxJumpToPosHeight-step
		local bounds = self.CanCrouch and self.CrouchCollisionBounds or self.CollisionBounds
		
		local bsize = bounds[2].z-bounds[1].z
		local z = b1.z-step
	
		local i = step
		
		while i<=maxjump do
			b1.z = z+i
			b2.z = b1.z+bsize
			
			util.TraceHull(t)
			
			if !tr.Hit then
				return true
			end
		
			if i==maxjump then break end
			
			i = math.min(i+bsize,maxjump)
		end
		
		return false
	end
	
	return nil
end

--[[------------------------------------
	Name: NEXTBOT:MoveAlongPath
	Desc: (INTERNAL) Process movement along path.
	Arg1: bool | lookatgoal | Should bot look at goal while moving.
	Ret1: bool | Path was completed right now
--]]------------------------------------
function ENT:MoveAlongPath(lookatgoal)
	local t = SysTime()

	local path = self:GetPath()
	local segment = path:GetCurrentGoal()
	
	if !segment then return false end
	
	if lookatgoal then
		local ang = (segment.pos-self:GetShootPos()):Angle()
		ang.p = 0
		
		self:SetDesiredEyeAngles(ang)
	end
	
	local pos = self:GetPos()
	local dontupdate = false
	
	local jumptype = segment.type==2
	if jumptype and self:GetRangeTo(segment.pos)<path:GetGoalTolerance() then
		-- Using previous segment data, because segment with type 2 can't be used properly
	
		local prev
	
		for k,v in ipairs(path:GetAllSegments()) do
			if prev and prev.pos==segment.pos then
				segment = v
				
				break
			end
		
			prev = v
		end
	end
	
	if self:PathIsValid() and !self:UsingNodeGraph() and self.loco:IsOnGround() and segment.pos.z-pos.z<self.MaxJumpToPosHeight then
		-- Jump support for navmesh PathFollower
	
		local area = self:GetCurrentNavArea()
	
		if !IsValid(area) or !area:HasAttributes(NAV_MESH_NO_JUMP) and !area:HasAttributes(NAV_MESH_STAIRS) then		
			local dir = segment.pos-pos
			dir.z = 0
			dir:Normalize()
			
			local jumpstate = GetJumpBlockState(self,dir)
			
			self.m_PathJumpTime = self.m_PathJumpTime or CurTime()
			if jumpstate==nil then
				self.m_PathJumpTime = CurTime()
			end
			
			if
				jumptype or	-- jump segment
				area:HasAttributes(NAV_MESH_JUMP) or	-- jump area
				jumpstate and CurTime()-self.m_PathJumpTime>self.PathStuckJumpTime or	-- founded obstacle, can be jumped and seems we stuck
				jumpstate==nil and self.m_PathJump	-- we are back enough to jump
			then
				if jumpstate then
					-- We are too close to obstacle, should step back
				
					self.m_PathJump = true
					
					self:Approach(pos-dir*100)
				else
					-- Performing jump
				
					self.m_PathJump = false
				
					self:JumpToPos(segment.pos)
					
					local ang = self:GetAngles()
					path:Update(self)
					self:SetAngles(ang)
				end
				
				-- Trying deal with jump, don't update path
				dontupdate = true
			end
		end
	end
	
	if !dontupdate and self.loco:IsOnGround() then
		local ang = self:GetAngles()
		path:Update(self)
		self:SetAngles(ang)
		
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetAngles(angle_zero)
		end
	end
	
	if !self.loco:IsOnGround() then
		self:Approach(segment.pos)
	end
	
	if self.DrawPath:GetBool() then
		path:Draw()
	end
	
	if !path:IsValid() and self:GetRangeTo(self:GetPathPos())<=self.m_PathOptions.tolerance then
		return true
	end
	
	return false
end

--[[------------------------------------
	Name: NEXTBOT:Jump
	Desc: Use this to make bot jump.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:Jump()
	if !self.loco:IsOnGround() then return end

	local vel = self.loco:GetVelocity()
	vel.z = (2*self.loco:GetGravity()*self.JumpHeight)^0.5
	local pos = self:GetPos()
	local b1,b2 = self:GetCollisionBounds()
	
	self.loco:Jump()
	self.loco:SetVelocity(vel)
	//self:SetPos(util.TraceHull({start = pos,endpos = pos+Vector(0,0,self.StepHeight),mask = self:GetSolidMask(),mins = b1,maxs = b2,filter = self}).HitPos)
	
	self:SetupActivity()
	
	self:SetupCollisionBounds()
	self:MakeFootstepSound(1)
	
	self.m_Jumping = true
	
	self:RunTask("OnJump")
end

--[[------------------------------------
	Name: NEXTBOT:IsJumping
	Desc: Bot is not on ground because he jump.
	Arg1: 
	Ret1: bool | Bot is jumped
--]]------------------------------------
function ENT:IsJumping()
	return self.m_Jumping or false
end

--[[------------------------------------
	NEXTBOT:OnLandOnGround
	Some functional with jumps
--]]------------------------------------
function ENT:OnLandOnGround(ent)
	if self.m_Jumping then
		self.m_Jumping = false
		
		-- Restoring from jump
		
		if !self:IsPostureActive() then
			self:SetupActivity()
		end
		
		self:SetupCollisionBounds()
	end
	
	local fallspeed = self.m_FallSpeed
	if fallspeed>=300 then
		local layer = self:AddGesture(self:TranslateActivity(ACT_LAND))
		self:SetLayerPlaybackRate(layer,1)
		
		if fallspeed>=530 then
			self:MakeFootstepSound(1)
			
			self:EmitSound("Player.FallDamage",75,math.random(90,110),0.75)
			
			local dmg = DamageInfo()
			dmg:SetAttacker(game.GetWorld())
			dmg:SetInflictor(game.GetWorld())
			dmg:SetDamageType(DMG_FALL)
			dmg:SetDamage(self:GetFallDamage(fallspeed))
			dmg:SetDamagePosition(self:GetPos())
			
			self:TakeDamageInfo(dmg)
		else
			self:MakeFootstepSound(0.85)
		end
	end
	
	self:RunTask("OnLandOnGroud",ent)
end

--[[------------------------------------
	Name: NEXTBOT:GetFootstepSoundTime
	Desc: Returns next footstep sound time in ms.
	Arg1: 
	Ret1: number | Next time for footstep
--]]------------------------------------
function ENT:GetFootstepSoundTime()
	local time = 350
	local speed = self:GetDesiredSpeed()

	if speed<=100 then
		time = 400
	elseif speed<=300 then
		time = 350
	else
		time = 250
	end

	if self:IsCrouching() then
		time = time+50
	end

	return time
end

--[[------------------------------------
	Name: NEXTBOT:OnFootstep
	Desc: Called when footstep sound should be played
	Arg1: Vector | pos | Footstep sound position.
	Arg2: bool | foot | false - left foot, true - right foot.
	Arg3: string | sound | Path to default sound to play.
	Arg4: number | volume | Volume of footstep.
	Arg4: CRecipientFilter | filter | Decides who can hear footstep.
	Ret1: bool | Should we prevent default sound
--]]------------------------------------
function ENT:OnFootstep(pos,foot,sound,volume,filter)
	return self:RunTask("OnFootstep",pos,foot,sound,volume,filter)
end

--[[------------------------------------
	Name: NEXTBOT:ProcessFootsteps
	Desc: (INTERNAL) Called to update footstep data.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:ProcessFootsteps()
	if !self.loco:IsOnGround() then return end

	local foot = self.m_FootstepFoot
	local time = self.m_FootstepTime
	local curspeed = self:GetCurrentSpeed()
	
	if curspeed>self.WalkSpeed and CurTime()-time>=self:GetFootstepSoundTime()/1000 then
		local walk = curspeed<self.RunSpeed
	
		local tr = util.TraceEntity({
			start = self:GetPos(),
			endpos = self:GetPos()-Vector(0,0,5),
			filter = self,
			mask = self:GetSolidMask(),
			collisiongroup = self:GetCollisionGroup(),
		},self)
	
		local surface = util.GetSurfaceData(tr.SurfaceProps)
		if !surface then return end
		
		local m = surface.material
		local vol = 0
		
		if m==MAT_CONCRETE then
			vol = walk and 0.2 or 0.5
		elseif m==MAT_METAL then
			vol = walk and 0.2 or 0.5
		elseif m==MAT_DIRT then
			vol = walk and 0.25 or 0.55
		elseif m==MAT_VENT then
			vol = walk and 0.4 or 0.7
		elseif m==MAT_GRATE then
			vol = walk and 0.2 or 0.5
		elseif m==MAT_TILE then
			vol = walk and 0.2 or 0.5
		elseif m==MAT_SLOSH then
			vol = walk and 0.2 or 0.5
		end
	
		self:MakeFootstepSound(vol,tr.SurfaceProps)
	end
end

--[[------------------------------------
	Name: NEXTBOT:MakeFootstepSound
	Desc: (INTERNAL) Creates footstep sound.
	Arg1: number | volume | Sound volume.
	Arg2: (optional) number | surface | ID of surface property
	Ret1: 
--]]------------------------------------
function ENT:MakeFootstepSound(volume,surface)
	local foot = self.m_FootstepFoot
	self.m_FootstepFoot = !foot
	self.m_FootstepTime = CurTime()
	
	if !surface then
		local tr = util.TraceEntity({
			start = self:GetPos(),
			endpos = self:GetPos()-Vector(0,0,5),
			filter = self,
			mask = self:GetSolidMask(),
			collisiongroup = self:GetCollisionGroup(),
		},self)
		
		surface = tr.SurfaceProps
	end
	
	if !surface then return end
	
	local surface = util.GetSurfaceData(surface)
	if !surface then return end
	
	local sound = foot and surface.stepRightSound or surface.stepLeftSound
	
	if sound then
		local pos = self:GetPos()
		
		local filter = RecipientFilter()
		filter:AddPAS(pos)
		
		if !self:OnFootstep(pos,foot,sound,volume,filter) then
			self:EmitSound(sound,75,100,volume,CHAN_BODY)
		end
	end
end

local function TraceHit(tr)
	return tr.Hit// or !tr.HitNoDraw and tr.HitTexture!="**empty**"
end

local function TryStuck(self,pos,t,tr)
	t.start = pos
	t.endpos = pos
	
	util.TraceHull(t)
	
	local b1,b2 = self:GetCollisionBounds()
	
	if !TraceHit(tr) then
		self:SetPos(pos)
		self.loco:SetVelocity(vector_origin)
		self.loco:ClearStuck()
		
		self:OnUnStuck()
		
		return true
	end
	
	return false
end

--[[------------------------------------
	NEXTBOT:OnStuck
	Trying teleport if we stuck
--]]------------------------------------
function ENT:OnStuck()
	self.m_Stuck = true

	self:RunTask("OnStuck")

	local pos = self:GetPos()
	local b1,b2 = self:GetCollisionBounds()
	
	if !self.loco:IsOnGround() then
		-- Seems in air trace check can return false, but bot is stuck (close to the wall). So we making test bounds bigger.
	
		b1.x = b1.x-1
		b1.y = b1.y-1
		b2.x = b2.x+1
		b2.y = b2.y+1
	end
	
	local tr = {}
	local t = {
		mask = self:GetSolidMask(),
		collisongroup = self:GetCollisionGroup(),
		output = tr,
		filter = function(ent)
			return ent!=self and !self:StuckCheckShouldIgnoreEntity(ent)
		end,
		mins = b1,
		maxs = b2,
	}

	local w = b2.x-b1.x
	
	for z=0,w*1.2,w*0.2 do
		for x=0,w*1.2,w*0.2 do
			for y=0,w*1.2,w*0.2 do
				if TryStuck(self,pos+Vector(x,y,z),t,tr) then return end
				if TryStuck(self,pos+Vector(-x,y,z),t,tr) then return end
				if TryStuck(self,pos+Vector(x,-y,z),t,tr) then return end
				if TryStuck(self,pos+Vector(-x,-y,z),t,tr) then return end
				if TryStuck(self,pos+Vector(x,y,-z),t,tr) then return end
				if TryStuck(self,pos+Vector(-x,y,-z),t,tr) then return end
				if TryStuck(self,pos+Vector(x,-y,-z),t,tr) then return end
				if TryStuck(self,pos+Vector(-x,-y,-z),t,tr) then return end
			end
		end
	end
end

--[[------------------------------------
	NEXTBOT:OnUnStuck
	Handling OnUnStuck
--]]------------------------------------
function ENT:OnUnStuck()
	self.m_Stuck = false
	self.m_StuckTime = CurTime()+1
	self.m_StuckTime2 = 0
	
	self:RunTask("OnUnStuck")
end

--[[------------------------------------
	Name: NEXTBOT:StuckCheckShouldIgnoreEntity
	Desc: Decides should stuck check ignore entity or not.
	Arg1: Entity | ent | Entity to check.
	Ret1: bool | Return true to skip entity.
--]]------------------------------------
function ENT:StuckCheckShouldIgnoreEntity(ent)
	-- You can add here parented stuff, like shield or something...

	return self:RunTask("StuckCheckShouldIgnoreEntity",ent)
end

--[[------------------------------------
	Name: NEXTBOT:StuckCheck
	Desc: (INTERNAL) Updates bot stuck status.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:StuckCheck()
	if CurTime()>=self.m_StuckTime then
		self.m_StuckTime = CurTime()+1
		
		local pos = self:GetPos()
		
		if self.m_StuckPos!=pos then
			self.m_StuckPos = pos
			self.m_StuckTime2 = 0
			
			if self.m_Stuck then
				self:OnUnStuck()
			end
		else
			local b1,b2 = self:GetCollisionBounds()
			
			if !self.loco:IsOnGround() then
				-- Seems in air trace check can return false, but bot is stuck (close to the wall). So we making test bounds bigger.
			
				b1.x = b1.x-1
				b1.y = b1.y-1
				b2.x = b2.x+1
				b2.y = b2.y+1
			end
			
			local tr = util.TraceHull({
				start = pos,
				endpos = pos,
				filter = function(ent)
					return ent!=self and !self:StuckCheckShouldIgnoreEntity(ent)
				end,
				mask = self:GetSolidMask(),
				collisiongroup = self:GetCollisionGroup(),
				mins = b1,
				maxs = b2,
			})
			
			if !self.m_Stuck then
				if TraceHit(tr) then
					self.m_StuckTime2 = self.m_StuckTime2+1
					
					if self.m_StuckTime2>=5 then
						self:OnStuck()
					end
				else
					self.m_StuckTime2 = 0
				end
			else
				if !TraceHit(tr) then
					self:OnUnStuck()
				end
			end
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:SetHullType
	Desc: Sets hull type for bot.
	Arg1: number | type | Hull type. See HULL_* Enums
	Ret1: 
--]]------------------------------------
function ENT:SetHullType(type)
	self.m_HullType = type
end

--[[------------------------------------
	Name: NEXTBOT:GetHullType
	Desc: Returns hull type for bot.
	Arg1: 
	Ret1: number | Hull type. See HULL_* Enums
--]]------------------------------------
function ENT:GetHullType()
	return self.m_HullType
end

--[[------------------------------------
	Name: NEXTBOT:JumpToPos
	Desc: Makes bot jump to given position. Jump height depends on height difference of given position and current position.
	Arg1: Vector | pos | Position to jump to.
	Arg2: (optional) height | Jump height. Default is CLuaLocomotion:GetJumpHeight()
	Ret1: 
--]]------------------------------------
function ENT:JumpToPos(pos,height)
	height = height or self.loco:GetJumpHeight()

	local curpos = self:GetPos()
	local dir = pos-curpos
	local dist = dir:Length()
	dir:Div(dist)
	local g = self.loco:GetGravity()
	
	local maxh = math.max(pos.z,curpos.z)+height
	local h1 = maxh-curpos.z
	local h2 = maxh-pos.z
	
	local t1 = (2/g*h1)^0.5
	local t2 = (2/g*h2)^0.5
	local t = t1+t2
	
	self:Jump()
	self.loco:SetVelocity(Vector(dir.x*dist/t,dir.y*dist/t,(2*g*h1)^0.5))
end

hook.Add("OnPhysgunPickup","SBAdvancedNextBots",function(ply,ent)
	if ent.SBAdvancedNextBot then
		ent.m_Physguned = true
		ent.loco:SetGravity(0)
	end
end)

hook.Add("PhysgunDrop","SBAdvancedNextBots",function(ply,ent)
	if ent.SBAdvancedNextBot then
		ent.m_Physguned = false
		ent.loco:SetGravity(ent.DefaultGravity)
	end
end)