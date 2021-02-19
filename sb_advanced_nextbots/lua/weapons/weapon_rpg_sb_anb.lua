AddCSLuaFile()

if SERVER then
	util.AddNetworkString("weapon_rpg_sb_anb.muzzleflash")
else
	killicon.AddFont("weapon_rpg_sb_anb","HL2MPTypeDeath","3",Color(255,80,0))
end

SWEP.PrintName = "#HL2_RPG"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/c_rpg.mdl"
SWEP.WorldModel = "models/weapons/w_rocket_launcher.mdl"
SWEP.Weight = 2

SWEP.Primary = {
	Ammo = "RPG_Round",
	ClipSize = 1,
	DefaultClip = 1,
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("rpg")
	
	if CLIENT then self:SetNoDraw(true) end
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire() and self:Clip1()!=0
end

function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	if IsValid(self.Missile) then return end
	
	local owner = self:GetOwner()
	
	self:SetNextPrimaryFire(CurTime()+0.5)
	
	local dir = owner:GetAimVector()
	
	local missile = self:CreateMissile(owner:GetShootPos(),dir:Angle(),owner)
	missile:SetSaveValue("m_hOwner",self:GetParent())
	missile:SetSaveValue("m_flGracePeriodEndsAt",CurTime()+0.3)
	missile:AddSolidFlags(FSOLID_NOT_SOLID)
	missile:SetSaveValue("m_flDamage",GetConVarNumber("sk_plr_dmg_rpg"))
	
	self.Missile = missile
	
	self:GetOwner():EmitSound(Sound("Weapon_RPG.NPC_Single"))
	
	self:SetClip1(self:Clip1()-1)
	self:SetLastShootTime()
end

function SWEP:CreateMissile(pos,ang,owner)
	local missile = ents.Create("rpg_missile")
	missile:SetPos(pos)
	missile:SetAngles(ang)
	missile:SetOwner(owner)
	missile:Spawn()
	missile:AddEffects(EF_NOSHADOW)
	
	local forward = ang:Forward()
	missile:SetVelocity(forward*300+Vector(0,0,90))
	
	return missile
end

function SWEP:DoMuzzleFlash()
	if SERVER then
		net.Start("weapon_rpg_sb_anb.muzzleflash",true)
			net.WriteEntity(self)
		net.SendPVS(self:GetPos())
	else
		local MUZZLEFLASH_RPG = 7
	
		local ef = EffectData()
		ef:SetEntity(self:GetParent())
		ef:SetAttachment(self:LookupAttachment("muzzle"))
		ef:SetScale(1)
		ef:SetFlags(MUZZLEFLASH_RPG)
		util.Effect("MuzzleFlash",ef,false)
	end
end

if CLIENT then
	net.Receive("weapon_rpg_sb_anb.muzzleflash",function(len)
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
	return 0
end

function SWEP:GetNPCBurstSettings()
	return 1,1,1
end

function SWEP:GetNPCRestTimes()
	return 4,4
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end
