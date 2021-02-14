AddCSLuaFile()

if CLIENT then
	killicon.AddFont("weapon_crossbow_sb_anb","HL2MPTypeDeath","1",Color(255,80,0))
end

SWEP.PrintName = "#HL2_Crossbow"
SWEP.Spawnable = false
SWEP.Author = "Shadow Bonnie (RUS)"
SWEP.Purpose = "Should only be used internally by advanced nextbots!"

SWEP.ViewModel = "models/weapons/c_crossbow.mdl"
SWEP.WorldModel = "models/weapons/w_crossbow.mdl"
SWEP.Weight = 4

SWEP.Primary = {
	Ammo = "XBowBolt",
	ClipSize = 1,
	DefaultClip = 1,
}

SWEP.Secondary = {
	Ammo = "None",
	ClipSize = -1,
	DefaultClip = -1,
}

function SWEP:Initialize()
	self:SetHoldType("crossbow")
	
	if CLIENT then self:SetNoDraw(true) end
end

function SWEP:CanPrimaryAttack()
	return CurTime()>=self:GetNextPrimaryFire() and self:Clip1()>0
end

function SWEP:CanSecondaryAttack()
	return false
end

local BOLT_AIR_VELOCITY		= 3500
local BOLT_WATER_VELOCITY	= 1500

function SWEP:PrimaryAttack()
	if !self:CanPrimaryAttack() then return end
	
	self:FireBolt()
	self:SetLastShootTime()
end

function SWEP:SecondaryAttack()
	if !self:CanSecondaryAttack() then return end
end

function SWEP:FireBolt()
	if self:Clip1()<=0 then return end
	
	local owner = self:GetOwner()
	
	local src = owner:GetShootPos()
	local dir = owner:GetAimVector()
	
	local bolt = self:CreateBolt(src,dir:Angle(),GetConVarNumber("sk_plr_dmg_crossbow"),owner)
	
	if owner:WaterLevel()==3 then
		bolt:SetVelocity(dir*BOLT_WATER_VELOCITY)
	else
		bolt:SetVelocity(dir*BOLT_AIR_VELOCITY)
	end
	
	self:SetClip1(self:Clip1()-1)
	
	self:GetOwner():EmitSound(Sound("Weapon_Crossbow.Single"))
	
	self:SetNextPrimaryFire(CurTime()+0.75)
	self:SetNextSecondaryFire(CurTime()+0.75)
	
	self:DoLoadEffect()
end

function SWEP:CreateBolt(pos,ang,damage,owner)
	local bolt = ents.Create("crossbow_bolt")
	bolt:SetPos(pos)
	bolt:SetAngles(ang)
	bolt:Spawn()
	bolt:SetOwner(owner)
	bolt:SetSaveValue("m_hOwnerEntity",owner)
	bolt:EmitSound(Sound("Weapon_Crossbow.BoltFly"))
	
	hook.Add("EntityTakeDamage",bolt,function(self,ent,dmg)
		if dmg:GetInflictor()!=self then return end
		
		dmg:SetDamage(damage)
	end)
	
	return bolt
end

function SWEP:DoLoadEffect()
	local ef = EffectData()
	ef:SetAttachment(1)
	ef:SetEntity(self)
	
	local filter = RecipientFilter()
	filter:AddPAS(ef:GetOrigin())
	util.Effect("CrossbowLoad",ef,false,filter)
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
	return 1,1,0
end

function SWEP:GetNPCRestTimes()
	return 0.5,1
end

function SWEP:GetCapabilities()
	return CAP_WEAPON_RANGE_ATTACK1
end

function SWEP:DrawWorldModel()
end