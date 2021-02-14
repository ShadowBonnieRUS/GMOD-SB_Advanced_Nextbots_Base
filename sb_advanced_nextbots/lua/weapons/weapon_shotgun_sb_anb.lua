AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_shotgun_sb_anb.muzzleflash")
else
	killicon.AddFont("weapon_shotgun_sb_anb","HL2MPTypeDeath","0",Color(255,80,0))
end

SWEP.PrintName = "#HL2_Shotgun"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.Weight = 4

SWEP.Primary = {
	Ammo = "Buckshot",
	ClipSize = 6,
	DefaultClip = 6,
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("shotgun")
	
	if CLIENT then self:SetNoDraw(true) end
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire() and self:Clip1()>0
end

function SWEP:CanSecondaryAttack()
	return CurTime()>=self:GetNextSecondaryFire() and self:Clip1()>1
end

local MAX_TRACE_LENGTH		= 56756
local VECTOR_CONE_10DEGREES	= Vector(0.08716,0.08716,0.08716)

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	
	local owner = self:GetOwner()
	
	owner:FireBullets({
		Num = 8,
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Spread = VECTOR_CONE_10DEGREES,
		Distance = MAX_TRACE_LENGTH,
		AmmoType = self:GetPrimaryAmmoType(),
		Damage = 8,
		Force = 1,
		Attacker = owner,
	})
	
	self:DoMuzzleFlash()
	self:GetOwner():EmitSound(Sound("Weapon_Shotgun.NPC_Single"))
	
	self:SetClip1(self:Clip1()-1)
	self:SetNextPrimaryFire(CurTime()+1)
	self:SetNextSecondaryFire(CurTime()+1)
	self:SetLastShootTime()
end

function SWEP:DoMuzzleFlash()
	if SERVER then
		net.Start("weapon_shotgun_sb_anb.muzzleflash",true)
			net.WriteEntity(self)
		net.SendPVS(self:GetPos())
	else
		local MUZZLEFLASH_SHOTGUN = 1
	
		local ef = EffectData()
		ef:SetEntity(self:GetParent())
		ef:SetAttachment(self:LookupAttachment("muzzle"))
		ef:SetScale(1)
		ef:SetFlags(MUZZLEFLASH_SHOTGUN)
		util.Effect("MuzzleFlash",ef,false)
	end
end

if CLIENT then
	net.Receive("weapon_shotgun_sb_anb.muzzleflash",function(len)
		local ent = net.ReadEntity()
		
		if IsValid(ent) and ent.DoMuzzleFlash then
			ent:DoMuzzleFlash()
		end
	end)
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
	
	local owner = self:GetOwner()
	
	self:FireBullets({
		Num = 12,
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Spread = VECTOR_CONE_10DEGREES,
		Distance = MAX_TRACE_LENGTH,
		AmmoType = self:GetPrimaryAmmoType(),
		Damage = 8,
		Attacker = owner,
	})
	
	self:DoMuzzleFlash()
	self:GetOwner():EmitSound(Sound("Weapon_Shotgun.Double"))
	
	self:SetClip1(self:Clip1()-2)
	self:SetNextPrimaryFire(CurTime()+1.5)
	self:SetNextSecondaryFire(CurTime()+1.5)
	self:SetLastShootTime()
end

function SWEP:Equip()
end

function SWEP:OwnerChanged()
end

function SWEP:OnDrop()
end

function SWEP:Reload()
	self:GetOwner():EmitSound(Sound("Weapon_Shotgun.NPC_Reload"))
	self:SetClip1(self.Primary.ClipSize)
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetNPCBulletSpread(prof)
	local spread = {5,4,3,2,1}
	return spread[prof+1]
end

function SWEP:GetNPCBurstSettings()
	return 1,3,0.7
end

function SWEP:GetNPCRestTimes()
	return 1.2,1.5
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end