AddCSLuaFile()

if CLIENT then
	killicon.AddFont("weapon_stunstick_sb_anb","HL2MPTypeDeath","6",Color(255,80,0))
end

SWEP.PrintName = "#HL2_StunBaton"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_stunstick.mdl"
SWEP.WorldModel = "models/weapons/c_stunstick.mdl"
SWEP.Weight = 0

SWEP.DrawAmmo = false

SWEP.Primary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = true,
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

local STUNSTICK_RANGE	= 75
local STUNSTICK_REFIRE	= 0.6

local BLUDGEON_HULL_DIM	= 16
local g_bludgeonMins	= Vector(-BLUDGEON_HULL_DIM,-BLUDGEON_HULL_DIM,-BLUDGEON_HULL_DIM)
local g_bludgeonMaxs	= Vector(BLUDGEON_HULL_DIM,BLUDGEON_HULL_DIM,BLUDGEON_HULL_DIM)

local COND_NONE					= 0
local COND_NOT_FACING_ATTACK	= 40
local COND_TOO_FAR_TO_ATTACK	= 39
local COND_CAN_MELEE_ATTACK1	= 23

function SWEP:Initialize()
	self:SetHoldType("melee")
	
	if CLIENT then
		self:DrawShadow(false)
	end
	
	hook.Add(SERVER and "Tick" or "Think",self,function(self) self:WeaponThink() end)
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire()
end

function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	
	local owner = self:GetOwner()
	
	local pos = owner:GetShootPos()
	local forward = owner:GetAimVector()
	local endpos = pos+forward*self:GetRange()
	
	local tr = util.TraceLine({start = pos,endpos = endpos,mask = MASK_SHOT_HULL,filter = owner,collisiongroup = COLLISION_GROUP_NONE})
	
	if tr.Fraction==1 then
		local bludgeonHullRadius = 1.732*BLUDGEON_HULL_DIM
		endpos = endpos-forward*bludgeonHullRadius
		
		local tr = util.TraceHull({start = pos,endpos = endpos,mins = g_bludgeonMins,maxs = g_bludgeonMaxs,mask = MASK_SHOT_HULL,filter = owner,collisiongroup = COLLISION_GROUP_NONE})
		
		if tr.Fraction<1 and tr.Entity!=NULL then
			local dir = tr.Entity:GetPos()-pos
			dir:Normalize()
			
			local dot = dir:Dot(forward)
			
			if dot<0.70721 then
				tr.Fraction = 1
			else
				tr = self:ChooseIntersectionPoint(tr)
			end
		end
	end
	
	if tr.Fraction==1 then
		self:ImpactWater(pos,pos+forward*self:GetRange())
	else
		self:Hit(tr)
	end
	
	self:GetOwner():EmitSound(Sound(tr.Fraction<1 and "Weapon_StunStick.Melee_Hit" or "Weapon_StunStick.Melee_Miss"))
	
	self:SetNextPrimaryFire(CurTime()+self:GetFireRate())
end

function SWEP:ChooseIntersectionPoint(tr)
	local owner = self:GetOwner()
	
	local minmaxs = {g_bludgeonMins,g_bludgeonMaxs}
	local vecSrc,vecHullEnd = tr.StartPos,tr.HitPos
	local trace,dist,vecEnd = {},nil,Vector()
	
	vecHullEnd = vecSrc+(vecHullEnd-vecSrc)*2
	util.TraceLine({start = vecSrc,endpos = vecHullEnd,mask = MASK_SHOT_HULL,filter = owner,collisiongroup = COLLISION_GROUP_NONE,output = trace})
	
	if trace.Fraction==1 then
		for i=1,2 do
			for j=1,2 do
				for k=1,2 do
					vecEnd.x = vecHullEnd.x+minmaxs[i].x
					vecEnd.y = vecHullEnd.y+minmaxs[j].y
					vecEnd.z = vecHullEnd.z+minmaxs[k].z
					
					util.TraceLine({start = vecSrc,endpos = vecEnd,mask = MASK_SHOT_HULL,filter = owner,collisiongroup = COLLISION_GROUP_NONE,output = trace})
					
					if trace.Fraction<1 then
						local d = (trace.HitPos-vecSrc):Length()
						
						if !dist or d<dist then
							tr = trace
							dist = d
						end
					end
				end
			end
		end
	else
		tr = trace
	end
	
	return tr
end

function SWEP:ImpactWater(from,to)
	if bit.band(util.PointContents(from),bit.bor(CONTENTS_WATER,CONTENTS_SLIME))!=0 then return end
	if bit.band(util.PointContents(to),bit.bor(CONTENTS_WATER,CONTENTS_SLIME))==0 then return end
	
	local tr = util.TraceLine({start = from,endpos = to,mask = bit.bor(CONTENTS_WATER,CONTENTS_SLIME),filter = self:GetOwner(),collisiongroup = COLLISION_GROUP_NONE})
	
	if tr.Fraction<1 then
		local ef = EffectData()
		ef:SetFlags(0)
		ef:SetOrigin(tr.HitPos)
		ef:SetNormal(tr.HitNormal)
		ef:SetScale(8)
		
		if bit.band(tr.Contents,CONTENTS_SLIME)!=0 then
			local FX_WATER_IN_SLIME = 0x1
			
			ef:SetFlags(FX_WATER_IN_SLIME)
		end
		
		util.Effect("watersplash",ef)
	end
	
	return true
end

function SWEP:Hit(tr)
	local owner = self:GetOwner()
	local ent = tr.Entity
	
	if IsValid(ent) or ent==game.GetWorld() then
		local dir = owner:GetAimVector()
		
		local dmg = DamageInfo()
		dmg:SetAttacker(owner)
		dmg:SetInflictor(owner)
		dmg:SetDamageType(DMG_CLUB)
		dmg:SetDamagePosition(tr.HitPos)
		dmg:SetDamageForce(dir)
		dmg:SetDamage(GetConVar("sk_plr_dmg_stunstick"):GetFloat())
		
		ent:DispatchTraceAttack(dmg,tr,dir)
		
		if ent:IsPlayer() then
			ent:ViewPunch(Angle(-16,math.Rand(-48,-24),2))
			ent:ScreenFade(SCREENFADE.IN,Color(128,0,0,128),0.5,0.1)
		end
	end
	
	if !self:ImpactWater(tr.StartPos,tr.HitPos) then
		local ef = EffectData()
		ef:SetOrigin(tr.HitPos)
		ef:SetStart(tr.StartPos)
		ef:SetSurfaceProp(tr.SurfaceProps)
		ef:SetDamageType(DMG_CLUB)
		ef:SetHitBox(tr.HitBox)
		ef:SetEntIndex(tr.Entity:EntIndex())
		
		util.Effect("Impact",ef)
		
		local ef = EffectData()
		ef:SetOrigin(tr.HitPos)
		ef:SetEntIndex(tr.Entity:EntIndex())
		
		util.Effect("StunstickImpact",ef)
	end
end

function SWEP:GetRange()
	return STUNSTICK_RANGE
end

function SWEP:GetFireRate()
	return STUNSTICK_REFIRE
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
end

function SWEP:Equip()
	local ef = EffectData()
	ef:SetOrigin(self:GetAttachment(1).Pos)
	ef:SetEntity(self)
	ef:SetMagnitude(1)
	ef:SetNormal(vector_origin)
	ef:SetRadius(5)
	ef:SetScale(1)
	
	util.Effect("Sparks",ef)
	
	self:GetOwner():EmitSound(Sound("Weapon_StunStick.Activate"))
end

function SWEP:OwnerChanged()
end

function SWEP:OnDrop()
	if IsValid(self:GetOwner()) then
		self:SetupCondition()
	end
end

function SWEP:Reload()
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetNPCBulletSpread(prof)
	return 0
end

function SWEP:GetNPCBurstSettings()
	return 1,1,self:GetFireRate()
end

function SWEP:GetNPCRestTimes()
	return 0,0
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_MELEE_ATTACK1
end

local function DrawHalo(mat,pos,scale,r,g,b,a)
	local dir = (pos-EyePos()):Angle()
	scale = scale
	
	render.SetMaterial(mat)
	
	mesh.Begin(MATERIAL_QUADS,1)
		
		mesh.Color(r,g,b,a)
		mesh.TexCoord(0,0,1)
		mesh.Position(pos-dir:Up()*scale-dir:Right()*scale)
		mesh.AdvanceVertex()
		
		mesh.Color(r,g,b,a)
		mesh.TexCoord(0,0,0)
		mesh.Position(pos+dir:Up()*scale-dir:Right()*scale)
		mesh.AdvanceVertex()
		
		mesh.Color(r,g,b,a)
		mesh.TexCoord(0,1,0)
		mesh.Position(pos+dir:Up()*scale+dir:Right()*scale)
		mesh.AdvanceVertex()
		
		mesh.Color(r,g,b,a)
		mesh.TexCoord(0,1,1)
		mesh.Position(pos-dir:Up()*scale+dir:Right()*scale)
		mesh.AdvanceVertex()
		
	mesh.End()
end

local mat = Material("sprites/glow04_noz")
local mat2 = Material("effects/stunstick")
function SWEP:DrawWorldModel()
	local wep = self:GetParent()
	if !IsValid(wep) then return end
	
	local pos = wep:GetAttachment(1).Pos
	
	local color = math.Rand(0.5,0.8)*255
	DrawHalo(mat,pos,math.Rand(4,6)*2,color,color,color,255)
	
	local color = math.Rand(0.9,1)*127
	DrawHalo(mat2,pos,math.Rand(2,3),color,color,color,255)
	
	if FrameTime()!=0 and math.random(0,5)==0 then
		local dir = VectorRand()
		local length = math.Rand(4,15)
		local width = math.Rand(2,5)
		local segments = 8
		
		render.SetMaterial(mat)
		
		render.StartBeam(segments)
			render.AddBeam(pos,width,0,color_white)
			
			for i=1,segments do
				local fr = i/segments
				render.AddBeam(pos+dir*length*fr+dir:Angle():Right()*(1-fr)*math.Rand(-width,width)/2,width*(1-fr),fr,color_white)
			end
		
		render.EndBeam()
	end
end

local mat = Material("sprites/physbeam")
function SWEP:WeaponThink()
	if SERVER then
		if IsValid(self:GetOwner()) then
			self:SetupCondition(self:WeaponAttackCondition())
		end
	else
		
	end
end

function SWEP:OnRemove()
	if CLIENT then return end
	
	self:OnDrop()
end

function SWEP:SetupCondition(condition)
	local owner = self:GetOwner()
	
	if self.COND and owner:HasCondition(self.COND) then
		owner:ClearCondition(self.COND)
	end
	
	self.COND = condition
	
	if condition and !owner:HasCondition(condition) then
		owner:SetCondition(condition)
	end
end

function SWEP:WeaponAttackCondition()
	local owner = self:GetOwner()
	local enemy = owner:GetEnemy()
	
	if !IsValid(enemy) then
		return COND_NONE
	end
	
	local vel = enemy:GetVelocity()
	local dt = GetConVar("sk_crowbar_lead_time"):GetFloat()+math.Rand(-0.3,0.2)
	
	if dt<0 then dt = 0 end
	
	local vecExtrapolatedPos = enemy:WorldSpaceCenter()+vel*dt
	local delta = vecExtrapolatedPos-owner:WorldSpaceCenter()
	
	if math.abs(delta.z)>70 then
		return COND_TOO_FAR_TO_ATTACK
	end
	
	local forward = owner:GetAngles():Forward()
	delta.z = 0
	
	local ExtrapolatedDot = delta:GetNormalized():Dot(forward)
	if ExtrapolatedDot<0.7 then
		return COND_NOT_FACING_ATTACK
	end
	
	local dist = delta:Length2D()
	if dist>self:GetRange() then
		return COND_TOO_FAR_TO_ATTACK
	end
	
	return COND_CAN_MELEE_ATTACK1
end