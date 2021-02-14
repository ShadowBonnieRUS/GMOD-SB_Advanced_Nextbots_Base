AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_smg1_sb_anb.muzzleflash")
else
	killicon.AddFont("weapon_smg1_sb_anb","HL2MPTypeDeath","/",Color(255,80,0))
end

SWEP.PrintName = "#HL2_SMG1"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"
SWEP.Weight = 3

SWEP.Primary = {
	Ammo = "SMG1",
	ClipSize = 45,
	DefaultClip = 45,
	Automatic = true
}

SWEP.Secondary = {
	Ammo = "SMG1_Grenade",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("smg")
	
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
		Damage = 4,
		Force = 1,
		Attacker = owner,
	})
	
	self:DoMuzzleFlash()
	self:GetOwner():EmitSound(Sound("Weapon_SMG1.NPC_Single"))
	
	self:SetClip1(self:Clip1()-1)
	self:SetNextPrimaryFire(CurTime()+0.075)
	self:SetLastShootTime()
end

function SWEP:DoMuzzleFlash()
	if SERVER then
		net.Start("weapon_smg1_sb_anb.muzzleflash",true)
			net.WriteEntity(self)
		net.SendPVS(self:GetPos())
	else
		local MUZZLEFLASH_SMG1 = 2
	
		local ef = EffectData()
		ef:SetEntity(self:GetParent())
		ef:SetAttachment(self:LookupAttachment("muzzle"))
		ef:SetScale(1)
		ef:SetFlags(MUZZLEFLASH_SMG1)
		util.Effect("MuzzleFlash",ef,false)
	end
end

if CLIENT then
	net.Receive("weapon_smg1_sb_anb.muzzleflash",function(len)
		local ent = net.ReadEntity()
		
		if IsValid(ent) and ent.DoMuzzleFlash then
			ent:DoMuzzleFlash()
		end
	end)
end

local function RandomAngle(min,max)
	return Angle(
		math.Rand(min,max),
		math.Rand(min,max),
		math.Rand(min,max)
	)
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
	
	if self:WaterLevel()==3 then
		self:SetNextSecondaryFire(CurTime()+0.5)
		return
	end
	
	self:GetOwner():EmitSound(Sound("Weapon_SMG1.Double"))
	
	local pos = self:GetOwner():GetShootPos()
	local vel = self:GetOwner():GetEyeAngles():Forward()*1000
	
	local grenade = ents.Create("grenade_ar2")
	grenade:SetPos(pos)
	grenade:SetVelocity(vel)
	grenade:SetLocalAngularVelocity(RandomAngle(-400,400))
	grenade:SetOwner(self:GetOwner())
	grenade:Spawn()
	grenade:SetCustomCollisionCheck(true)
	
	hook.Add("ShouldCollide",grenade,function(self,ent1,ent2)
		if self==ent1 then print(ent2) end
		if self==ent2 then print(ent1) end
	end)
	
	self:SetNextPrimaryFire(CurTime()+0.5)
	self:SetNextSecondaryFire(CurTime()+1)
end

function SWEP:Equip()
end

function SWEP:OwnerChanged()
end

function SWEP:OnDrop()
end

function SWEP:Reload()
	self:GetOwner():EmitSound(Sound("Weapon_SMG1.NPC_Reload"))
	self:SetClip1(self.Primary.ClipSize)
	self:SetNextSecondaryFire(CurTime()+1.5)
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetNPCBulletSpread(prof)
	local spread = {7,5,10/3,5/3,1}
	return spread[prof+1]
end

function SWEP:GetNPCBurstSettings()
	return 2,5,0.075
end

function SWEP:GetNPCRestTimes()
	return 0.33,0.66
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end