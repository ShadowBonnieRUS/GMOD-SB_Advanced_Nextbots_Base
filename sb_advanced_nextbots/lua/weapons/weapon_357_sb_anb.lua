AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_357_sb_anb.muzzleflash")
else
	killicon.AddFont("weapon_357_sb_anb","HL2MPTypeDeath",".",Color(255,80,0))
end

SWEP.PrintName = "#HL2_357"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/v_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"
SWEP.Weight = 3

SWEP.Primary = {
	Ammo = "357",
	ClipSize = 6,
	DefaultClip = 6,
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("revolver")
	
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
	
	self:FireBullets({
		Num = 1,
		Src = owner:GetShootPos(),
		Dir = owner:GetAimVector(),
		Spread = vec3_origin,
		Distance = MAX_TRACE_LENGTH,
		AmmoType = self:GetPrimaryAmmoType(),
		Damage = 40,
		Attacker = owner,
	})
	
	self:DoMuzzleFlash()
	self:GetParent():EmitSound(Sound("Weapon_357.Single"))
	
	self:SetClip1(self:Clip1()-1)
	self:SetNextPrimaryFire(CurTime()+0.1)
	self:SetLastShootTime()
end

function SWEP:DoMuzzleFlash()
	if SERVER then
		net.Start("weapon_357_sb_anb.muzzleflash",true)
			net.WriteEntity(self)
		net.SendPVS(self:GetPos())
	else
		local MUZZLEFLASH_357 = 6
	
		local ef = EffectData()
		ef:SetEntity(self:GetParent())
		ef:SetAttachment(self:LookupAttachment("muzzle"))
		ef:SetScale(1)
		ef:SetFlags(MUZZLEFLASH_357)
		util.Effect("MuzzleFlash",ef,false)
	end
end

function SWEP:GetTracerOrigin()
	return self:GetParent():GetAttachment(self:GetParent():LookupAttachment("muzzle")).Pos
end

if CLIENT then
	net.Receive("weapon_357_sb_anb.muzzleflash",function(len)
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
	self:SetClip1(self.Primary.ClipSize)
end

function SWEP:CanBePickedUpByNPCs()
	return true
end

function SWEP:GetNPCBulletSpread(prof)
	local spread = {3,2.5,2,1.5,1}
	return spread[prof+1]
end

function SWEP:GetNPCBurstSettings()
	return 1,1,0.75
end

function SWEP:GetNPCRestTimes()
	return 0.75,0.75
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end