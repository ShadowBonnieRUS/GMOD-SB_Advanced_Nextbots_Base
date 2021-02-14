AddCSLuaFile()

ENT.Base = "sb_advanced_nextbot_soldier_base"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Soldier (Friendly)"

list.Set("NPC","sb_advanced_nextbot_soldier_friendly",{
	Name = ENT.PrintName,
	Class = "sb_advanced_nextbot_soldier_friendly",
	Category = "SB Advanced Nextbots",
	Weapons = {"weapon_smg1","weapon_ar2","weapon_shotgun","weapon_pistol","weapon_357","weapon_crossbow"},
})

if CLIENT then
	language.Add("sb_advanced_nextbot_soldier_friendly","A.N.B. Soldier (Friendly)")
	return
end

cvars.AddChangeCallback("sb_advanced_nextbot_soldier_playerdisposition",function(cvar,old,new)
	local disposition = tonumber(new)

	for k,v in ipairs(ents.FindByClass("sb_advanced_nextbot_soldier_friendly")) do
		v:SetClassRelationship("player",
			disposition==0 and D_NU or
			disposition==1 and D_LI or
			disposition==2 and D_HT or
			disposition==3 and D_LI or
			D_HT
		)
	end
end,"friendly")

ENT.Models = {
	"models/player/riot.mdl",
	"models/player/swat.mdl",
	"models/player/gasmask.mdl",
	"models/player/urban.mdl",
}

function ENT:Initialize()
	BaseClass.Initialize(self)
	
	self:SetModel(table.Random(self.Models))
	self:SetFriendly(true)
	
	self:SetClassRelationship("sb_advanced_nextbot_soldier_friendly",D_LI)
	self:SetClassRelationship("sb_advanced_nextbot_soldier_hostile",D_HT)
	self:SetClassRelationship("player",
		self.PlayerDisposition==0 and D_NU or
		self.PlayerDisposition==1 and D_LI or
		self.PlayerDisposition==2 and D_HT or
		self.PlayerDisposition==3 and D_LI or
		D_HT
	)
end