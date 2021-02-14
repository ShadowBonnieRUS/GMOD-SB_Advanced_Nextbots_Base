AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_pistol_sb_anb.muzzleflash")
else
	killicon.AddFont("weapon_pistol_sb_anb","HL2MPTypeDeath","-",Color(255,80,0))
end

SWEP.PrintName = "#HL2_Pistol"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.Weight = 2

SWEP.Primary = {
	Ammo = "Pistol",
	ClipSize = 18,
	DefaultClip = 18,
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("pistol")
	
	if CLIENT then self:SetNoDraw(true) end
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire() and self:Clip1()>0
end

function SWEP:CanSecondaryAttack()
	return false
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
		Damage = 5,
		Force = 1,
		Attacker = owner,
	})
	
	self:DoMuzzleFlash()
	self:GetOwner():EmitSound(Sound("Weapon_Pistol.NPC_Single"))
	
	self:SetClip1(self:Clip1()-1)
	self:SetNextPrimaryFire(CurTime()+0.1)
	self:SetLastShootTime()
end

function SWEP:DoMuzzleFlash()
	if SERVER then
		net.Start("weapon_pistol_sb_anb.muzzleflash",true)
			net.WriteEntity(self)
		net.SendPVS(self:GetPos())
	else
		local MUZZLEFLASH_PISTOL = 4
	
		local ef = EffectData()
		ef:SetEntity(self:GetParent())
		ef:SetAttachment(self:LookupAttachment("muzzle"))
		ef:SetScale(1)
		ef:SetFlags(MUZZLEFLASH_PISTOL)
		util.Effect("MuzzleFlash",ef,false)
	end
end

if CLIENT then
	net.Receive("weapon_pistol_sb_anb.muzzleflash",function(len)
		local ent = net.ReadEntity()
		
		if IsValid(ent) and ent.DoMuzzleFlash then
			ent:DoMuzzleFlash()
		end
	end)
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
end

function SWEP:Equip()
end

function SWEP:OwnerChanged()
end

function SWEP:OnDrop()
end

function SWEP:Reload()
	self:GetOwner():EmitSound(Sound("Weapon_Pistol.NPC_Reload"))
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
	return 1,3,0.5
end

function SWEP:GetNPCRestTimes()
	return 0.33,0.66
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end