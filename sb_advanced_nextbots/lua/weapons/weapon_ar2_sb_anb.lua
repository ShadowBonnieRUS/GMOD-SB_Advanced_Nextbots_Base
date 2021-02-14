AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_ar2_sb_anb.muzzleflash")
	util.AddNetworkString("weapon_ar2_sb_anb.combineballwhiz")
else
	killicon.AddFont("weapon_ar2_sb_anb","HL2MPTypeDeath","2",Color(255,80,0))
end

SWEP.PrintName = "#HL2_Pulse_Rifle"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_irifle.mdl"
SWEP.WorldModel = "models/weapons/w_irifle.mdl"
SWEP.Weight = 5

SWEP.Primary = {
	Ammo = "AR2",
	ClipSize = 30,
	DefaultClip = 30,
	Automatic = true,
}

SWEP.Secondary = {
	Ammo = "AR2AltFire",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("ar2")
	
	if CLIENT then self:SetNoDraw(true) end
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire() and self:Clip1()>0
end

function SWEP:CanSecondaryAttack()
	return CurTime()>=self:GetNextSecondaryFire()
end

local MAX_TRACE_LENGTH	= 56756
local vec3_origin		= vector_origin

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	
	local owner = self:GetOwner()
	
	owner:FireBullets({
		Num = 1,
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Spread = vec3_origin,
		Distance = MAX_TRACE_LENGTH,
		AmmoType = self:GetPrimaryAmmoType(),
		Damage = 8,
		Force = 1,
		Attacker = owner,
		TracerName = "AR2Tracer",
	})
	
	self:DoMuzzleFlash()
	self:GetOwner():EmitSound(Sound("Weapon_AR2.NPC_Single"))
	
	self:SetClip1(self:Clip1()-1)
	self:SetNextPrimaryFire(CurTime()+0.1)
	self:SetLastShootTime()
end

function SWEP:DoMuzzleFlash()
	if SERVER then
		net.Start("weapon_ar2_sb_anb.muzzleflash",true)
			net.WriteEntity(self)
		net.SendPVS(self:GetPos())
	else
		local MUZZLEFLASH_COMBINE = 5
	
		local ef = EffectData()
		ef:SetEntity(self:GetParent())
		ef:SetAttachment(self:LookupAttachment("muzzle"))
		ef:SetScale(1)
		ef:SetFlags(MUZZLEFLASH_COMBINE)
		util.Effect("MuzzleFlash",ef,false)
	end
end

if CLIENT then
	net.Receive("weapon_ar2_sb_anb.muzzleflash",function(len)
		local ent = net.ReadEntity()
		
		if IsValid(ent) and ent.DoMuzzleFlash then
			ent:DoMuzzleFlash()
		end
	end)
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
	
	self:GetOwner():EmitSound(Sound("Weapon_AR2.NPC_Double"))
	
	local pos = self:GetOwner():GetShootPos()
	local target = self:GetOwner():GetAimVector()
	local velocity = target*1000
	
	local duration = GetConVarNumber("sk_weapon_ar2_alt_fire_duration")
	local radius = GetConVarNumber("sk_weapon_ar2_alt_fire_radius")
	local mass = GetConVarNumber("sk_weapon_ar2_alt_fire_mass")
	
	self:CreateCombineBall(pos,velocity,radius,mass,duration,self:GetOwner())
end

function SWEP:Equip()
end

function SWEP:OwnerChanged()
end

function SWEP:OnDrop()
end

function SWEP:Reload()
	self:GetOwner():EmitSound(Sound("Weapon_AR2.NPC_Reload"))
	self:SetClip1(self.Primary.ClipSize)
end

function SWEP:DoImpactEffect(tr,dmg)
	local data = EffectData()
	data:SetOrigin(tr.HitPos+tr.HitNormal)
	data:SetNormal(tr.HitNormal)
	util.Effect("AR2Impact",data)
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetNPCBulletSpread(prof)
	local spread = {7,5,3,5/3,1}
	return spread[prof+1]
end

function SWEP:GetNPCBurstSettings()
	return 2,5,0.1
end

function SWEP:GetNPCRestTimes()
	return 0.33,0.66
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end

-- Combine ball shit starts here. That code very similar to engine code

local SNDLVL_NORM = 75

if SERVER then
	local MAX_COMBINEBALL_RADIUS = 12
	local STATE_THROWN = 2
	local SOUND_NORMAL_CLIP_DIST = 1000
	local ATTN_NORM = 0.8

	local function VectorMA(start,scale,dir,dest)
		dest.x = start.x+dir.x*scale
		dest.y = start.y+dir.y*scale
		dest.z = start.z+dir.z*scale
	end

	local function SetContextThink(self,func,usetime,context)
		local name = self:GetCreationID()..context

		hook.Add("Think",name,function()
			if !IsValid(self) then
				hook.Remove("Think",name)
				return
			end
			
			if CurTime()>=usetime then
				func(self)
			end
		end)
	end

	local function WhizSoundThink(self)
		local phys = self:GetPhysicsObject()
		
		if !IsValid(phys) then
			SetContextThink(self,WhizSoundThink,CurTime()+2*engine.TickInterval(),"WhizThinkContext")
			return
		end
		
		local pos,vel = phys:GetPos(),phys:GetVelocity()
		local clients = player.GetHumans()
		
		for i=1,#clients do
			local ply = clients[i]
			
			local delta = ply:GetPos()-pos
			delta:Normalize()
			
			if delta:Dot(vel)>0.5 then
				local endPoint = Vector()
				VectorMA(pos,2*engine.TickInterval(),vel,endPoint)
				
				local dist = util.DistanceToLine(pos,endPoint,ply:GetPos())
				if dist<200 then
					local relative = ply:EyePos()-pos
					local dist = relative:Length()
					local maxAudible = 2*SOUND_NORMAL_CLIP_DIST/ATTN_NORM
					
					if dist<maxAudible then continue end
					
					net.Start("weapon_ar2_sb_anb.combineballwhiz",true)
						net.WriteEntity(self)
					net.Send(ply)
				end
			end
		end
		
		SetContextThink(self,WhizSoundThink,CurTime()+2*engine.TickInterval(),"WhizThinkContext")
	end

	local function DoExplosion(self)
		self:Fire("Explode")
		
		SetContextThink(self,self.Remove,CurTime()+0.5,"ExplodeTimerContext")
	end

	local function ExplodeThink(self)
		DoExplosion(self)
	end

	local function StartLifeTime(self,duration)
		SetContextThink(self,ExplodeThink,CurTime()+duration,"ExplodeTimerContext")
	end

	local function StartWhizSoundThink(self)
		SetContextThink(self,WhizSoundThink,CurTime()+2*engine.TickInterval(),"WhizThinkContext")
	end

	function SWEP:CreateCombineBall(pos,vel,radius,mass,duration,owner)
		local ball = ents.Create("prop_combine_ball")
		ball:SetSaveValue("m_flRadius",math.Clamp(radius,1,MAX_COMBINEBALL_RADIUS))
		
		ball:SetPos(pos)
		ball:SetOwner(owner)
		ball.Owner = owner
		
		ball:Spawn()
		ball:Activate()
		
		ball:SetSaveValue("m_nState",STATE_THROWN)
		ball:SetSaveValue("m_flSpeed",vel:Length())
		
		ball:EmitSound("NPC_CombineBall.Launch")
		
		ball:GetPhysicsObject():AddGameFlag(FVPHYSICS_WAS_THROWN)
		
		StartWhizSoundThink(ball)
		
		ball:GetPhysicsObject():SetMass(mass)
		ball:GetPhysicsObject():SetInertia(Vector(500,500,500))
		ball:GetPhysicsObject():SetVelocity(vel)
		StartLifeTime(ball,duration)
		ball:SetSaveValue("m_bWeaponLaunched",true)
		ball:SetSaveValue("m_bLaunched",true)
	end
end

if CLIENT then
	net.Receive("weapon_ar2_sb_anb.combineballwhiz",function(len)
		local ent = net.ReadEntity()
		
		if IsValid(ent) then
			ent:EmitSound(Sound("NPC_CombineBall.WhizFlyby"),SNDLVL_NORM,100,1,CHAN_STATIC)
		end
	end)
end