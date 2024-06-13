AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

--[[-------------------------------------------------------
	NEXTBOT Settings
--]]-------------------------------------------------------

-- Default bot's model
ENT.Model = "models/player/combine_super_soldier.mdl"

-- Default bot's weapon on spawn
ENT.DefaultWeapon = nil

-- Default bot's health
ENT.SpawnHealth = 100

-- Bot's desired move speed
ENT.MoveSpeed = 200

-- Bot's desired run speed
ENT.RunSpeed = 320

-- Bot's desired walk speed
ENT.WalkSpeed = 100

-- Bot's desired crouch walk speed
ENT.CrouchSpeed = 120

-- Bot's acceleration speed
ENT.AccelerationSpeed = 1000

-- Bot's deceleration speed
ENT.DecelerationSpeed = 3000

-- Bot's aiming speed, in degrees per second
ENT.AimSpeed = 360

-- Bot's ladder climb speed
ENT.LadderClimbSpeed = 200

-- Bot's collision bounds, min max
ENT.CollisionBounds = {Vector(-16,-16,0),Vector(16,16,72)}

-- Bot's collision bounds when crouching, min max
ENT.CrouchCollisionBounds = {Vector(-16,-16,0),Vector(16,16,36)}

-- Can bot crouch
ENT.CanCrouch = true

-- Can bot use ladders
ENT.CanUseLadder = true

-- Max height the bot can step up
ENT.StepHeight = 18

-- Bot's jump height
ENT.JumpHeight = 50

-- Height limit for path finding. Using nodegraph for CAP_MOVE_JUMP links, too high nodes will be skipped. For navmesh, not jumping on NAV_MESH_JUMP if too high
ENT.MaxJumpToPosHeight = ENT.JumpHeight

-- Height the bot is scared to fall from
ENT.DeathDropHeight = 200

-- Default gravity for bot
ENT.DefaultGravity = 600

-- Solid mask used for raytracing when detecting collision while moving
ENT.SolidMask = MASK_NPCSOLID

-- Mask used in line of sight test trace
ENT.LineOfSightMask = MASK_BLOCKLOS

-- Time need to forget enemy if bot doesn't see it
ENT.ForgetEnemyTime = 30

-- Distance at which enemy should be to make bot think enemy is very close
ENT.CloseEnemyDistance = 500

-- Max distance at which bot can see enemies
ENT.MaxSeeEnemyDistance = 3000

-- Default motion path minimum look ahead distance
ENT.PathMinLookAheadDistance = 15

-- Default motion path goal tolerance
ENT.PathGoalTolerance = 25

-- Default motion path goal tolerance on last segment
ENT.PathGoalToleranceFinal = 25

-- Default motion path recompute time
ENT.PathRecompute = 5

-- Draws path if valid. Used for debug
ENT.DrawPath = CreateConVar("sb_anb_drawpath", 0, FCVAR_ARCHIVE)

--[[-------------------------------------------------------
	NEXTBOT Meta Table Setup
--]]-------------------------------------------------------

--[[------------------------------------
	NEXTBOT:Initialize
	Initialize our bot
--]]------------------------------------
function ENT:Initialize()
	self:SetModel(self.Model)
	self:SetSolidMask(self.SolidMask)
	self:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	
	self:SetMaxHealth(self.SpawnHealth)
	self:SetHealth(self:GetMaxHealth())
	
	self:AddFlags(FL_OBJECT)
	
	self.BehaveInterval = 0
	self.m_Path = Path("Follow")
	self.m_PathPos = Vector()
	self.m_PathOptions = {}
	self.m_NavArea = navmesh.GetNearestNavArea(self:GetPos())
	self.m_Capabilities = 0
	self.m_ClassRelationships = {}
	self.m_EntityRelationships = {}
	self.m_EnemiesMemory = {}
	self.m_FootstepFoot = false
	self.m_FootstepTime = CurTime()
	self.m_LastMoveTime = CurTime()
	self.m_FallSpeed = 0
	self.m_UseNodeGraph = false
	self.m_TaskList = {}
	self.m_ActiveTasks = {}
	self.m_TaskCallbacks = {}
	self.m_Stuck = false
	self.m_StuckTime = CurTime()
	self.m_StuckTime2 = 0
	self.m_StuckPos = self:GetPos()
	self.m_HullType = HULL_HUMAN
	self.m_DuckHullType = HULL_TINY
	self.m_PassIsNPCCheck = true
	self.m_PitchAim = 0
	self.m_Conditions = {}
	
	self.loco:SetGravity(self.DefaultGravity)
	self.loco:SetAcceleration(self.AccelerationSpeed)
	self.loco:SetDeceleration(self.DecelerationSpeed)
	self.loco:SetStepHeight(self.StepHeight)
	self.loco:SetJumpHeight(self.JumpHeight)
	self.loco:SetDeathDropHeight(self.DeathDropHeight)
	
	self:SetupCollisionBounds()
	self:ReloadWeaponData()
	self:SetDesiredEyeAngles(self:GetAngles())
	self:SetupDefaultCapabilities()
	
	self:SetLagCompensated(true)
	
	self:AddCallback("PhysicsCollide",self.PhysicsObjectCollide)
	
	local wep = self:GetKeyValue("additionalequipment") or self.DefaultWeapon
	if wep then
		self:Give(wep)
	end
end

--[[------------------------------------
	Name: NEXTBOT:GetFallDamage
	Desc: Returns fall damage that should applied to bot.
	Arg1: number | speed | Fall speed
	Ret1: number | Fall damage
--]]------------------------------------
function ENT:GetFallDamage(speed)
	return 10
end

--[[------------------------------------
	NEXTBOT:OnKilled
	Initialize death ragdoll and call hooks
--]]------------------------------------
function ENT:OnKilled(dmg)
	if self:HasWeapon() then
		local wep = self:GetActiveLuaWeapon()
		
		if !dmg:IsDamageType(DMG_DISSOLVE) then
			if self:CanDropWeaponOnDie(wep) and wep:ShouldDropOnDie() then
				self:DropWeapon(nil,true)
			else
				wep:Remove()
			end
		else
			local wep = self:DropWeapon(nil,true)
			self:DissolveEntity(wep)
		end
	end

	if !self:RunTask("PreventBecomeRagdollOnKilled",dmg) then
		if dmg:IsDamageType(DMG_DISSOLVE) then self:DissolveEntity() end
		
		self:BecomeRagdoll(dmg)
	end
	
	self:RunTask("OnKilled",dmg)
	hook.Run("OnNPCKilled",self,dmg:GetAttacker(),dmg:GetInflictor())
end

--[[------------------------------------
	NEXTBOT:OnInjured
	Call task hooks
--]]------------------------------------
function ENT:OnInjured(dmg)
	self:RunTask("OnInjured",dmg)
end

--[[------------------------------------
	NEXTBOT:KeyValue
	Handles KeyValue settings
--]]------------------------------------
function ENT:KeyValue(key,value)
	self.KeyValues = self.KeyValues or {}
	self.KeyValues[key] = value
end

--[[------------------------------------
	Name: NEXTBOT:GetKeyValue
	Desc: Returns KeyValue setting value.
	Arg1: string | key | Key of setting.
	Ret1: any | Value of setting.
--]]------------------------------------
function ENT:GetKeyValue(key)
	return self.KeyValues and self.KeyValues[key]
end

--[[------------------------------------
	Name: NEXTBOT:SetupDefaultCapabilities
	Desc: Used to set default capabilities 
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupDefaultCapabilities()
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND,CAP_USE_WEAPONS))
end

--[[------------------------------------
	Name: NEXTBOT:DissolveEntity
	Desc: Dissolving entity.
	Arg1: (optional) Entity | ent | Entity to dissolve. Without this will be used bot entity.
	Ret1: 
--]]------------------------------------
function ENT:DissolveEntity(ent)
	ent = ent or self

	local dissolver = ents.Create("env_entity_dissolver")
	dissolver:SetMoveParent(ent)
	dissolver:SetSaveValue("m_flStartTime",0)
	dissolver:Spawn()
	dissolver:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
	
	ent:SetSaveValue("m_flDissolveStartTime",0)
	ent:SetSaveValue("m_hEffectEntity",dissolver)
	ent:AddFlags(FL_DISSOLVING)
end

-- Handles Motion methods (Path, Speed, Activity)
include("motion.lua")

-- Handles Weapon methods (support of weapon usage)
include("weapons.lua")

-- Handles Enemy methods (relationships)
include("enemy.lua")

-- Handles Behaviour methods (bot's brain)
include("behaviour.lua")

-- Handles Player Control methods
AddCSLuaFile("cl_playercontrol.lua")
AddCSLuaFile("drive.lua")
include("drive.lua")
include("playercontrol.lua")

-- Handles Node Graph module (allowing build path using nodegraph)
include("nodegraph_path.lua")

-- Handles Tasks methods
AddCSLuaFile("tasks.lua")
include("tasks.lua")

function ENT:SetCondition(condition) self.m_Conditions[condition] = true end
function ENT:HasCondition(condition) return self.m_Conditions[condition] or false end
function ENT:ClearCondition(condition) self.m_Conditions[condition] = nil end

-- NPC Stubs

function ENT:ConditionName(condition) return "" end

function ENT:ClearSchedule() end
function ENT:GetCurrentSchedule() return SCHED_NONE end
function ENT:IsCurrentSchedule(schedule) return schedule==SCHED_NONE end
function ENT:SetSchedule(schedule) end

function ENT:SetNPCState(state) end
function ENT:GetNPCState() return NPC_STATE_NONE end

function ENT:AddEntityRelationship(target,disposition,priority) self:SetEntityRelationship(target,disposition,prioroty) end
function ENT:AddRelationship(str)
	local explode = string.Explode(" ",str)
	
	local class = explode[1]
	if !class then return end
	
	local d = explode[2]=="D_LI" and D_LI or explode[2]=="D_HT" and D_HT or explode[2]=="D_ER" and D_ER or explode[2]=="D_FR" and D_FR
	local priority = tonumber(explode[3])

	self:SetClassRelationship(class,d or D_NU,priority or 0)
end
function ENT:Disposition(ent) return self:GetRelationship(ent) end

--HACK
local meta = FindMetaTable("Entity")

if !meta.sb_anb_IsNPC then
	meta.sb_anb_IsNPC = meta.IsNPC
	
	meta.IsNPC = function(s)
		return s:sb_anb_IsNPC() or s.SBAdvancedNextBot and s.m_PassIsNPCCheck or false
	end
end
