AddCSLuaFile()

ENT.Base = "sb_advanced_nextbot_soldier_base"
DEFINE_BASECLASS(ENT.Base)

ENT.PrintName = "Soldier (Hostile)"

list.Set("NPC","sb_advanced_nextbot_soldier_hostile",{
	Name = ENT.PrintName,
	Class = "sb_advanced_nextbot_soldier_hostile",
	Category = "SB Advanced Nextbots",
	Weapons = {"weapon_smg1","weapon_ar2","weapon_shotgun","weapon_pistol","weapon_357","weapon_crossbow"},
})

if CLIENT then
	language.Add("sb_advanced_nextbot_soldier_hostile","A.N.B. Soldier (Hostile)")
	return
end

cvars.AddChangeCallback("sb_advanced_nextbot_soldier_playerdisposition",function(cvar,old,new)
	local disposition = tonumber(new)

	for k,v in ipairs(ents.FindByClass("sb_advanced_nextbot_soldier_hostile")) do
		v:SetClassRelationship("player",
			disposition==0 and D_NU or
			disposition==1 and D_LI or
			disposition==2 and D_HT or
			disposition==3 and D_HT or
			D_LI
		)
	end
end,"hostile")

ENT.Models = {
	"models/player/guerilla.mdl",
	"models/player/leet.mdl",
	"models/player/phoenix.mdl",
	"models/player/arctic.mdl",
}

function ENT:Initialize()
	BaseClass.Initialize(self)
	
	self:SetModel(table.Random(self.Models))
	self:SetFriendly(false)
	
	self:SetClassRelationship("sb_advanced_nextbot_soldier_friendly",D_HT)
	self:SetClassRelationship("sb_advanced_nextbot_soldier_hostile",D_LI)
	self:SetClassRelationship("player",
		self.PlayerDisposition==0 and D_NU or
		self.PlayerDisposition==1 and D_LI or
		self.PlayerDisposition==2 and D_HT or
		self.PlayerDisposition==3 and D_HT or
		D_LI
	)
end