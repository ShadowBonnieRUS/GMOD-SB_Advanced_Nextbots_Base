-- Lua analogs to engine weapons
local EngineAnalogs = {
	weapon_ar2 = "weapon_ar2_sb_anb",
	weapon_smg1 = "weapon_smg1_sb_anb",
	weapon_pistol = "weapon_pistol_sb_anb",
	weapon_357 = "weapon_357_sb_anb",
	weapon_crossbow = "weapon_crossbow_sb_anb",
	weapon_rpg = "weapon_rpg_sb_anb",
	weapon_shotgun = "weapon_shotgun_sb_anb",
}

local EngineAnalogsReverse = {}
for k,v in pairs(EngineAnalogs) do EngineAnalogsReverse[v] = k end

--[[------------------------------------
	Name: NEXTBOT:Give
	Desc: Gives weapon to bot.
	Arg1: string | wepname | Class name of weapon.
	Ret1: Weapon | Weapon given to bot. Returns NULL if failed to give this weapon.
--]]------------------------------------
function ENT:Give(wepname)
	local wep = ents.Create(wepname)
	
	if IsValid(wep) then
		if !wep:IsScripted() and !EngineAnalogs[wepname] then
			wep:Remove()
			
			return NULL
		end
	
		wep:SetPos(self:GetPos())
		wep:SetOwner(self)
		wep:Spawn()
		wep:Activate()
		
		return self:SetupWeapon(wep)
	end
end

--[[------------------------------------
	Name: NEXTBOT:GetActiveLuaWeapon
	Desc: Returns current weapon entity. If active weapon is engine weapon, returns lua analog.
	Arg1: 
	Ret1: Weapon | Active weapon.
--]]------------------------------------
function ENT:GetActiveLuaWeapon()
	return self.m_ActualWeapon or NULL
end

--[[------------------------------------
	Name: NEXTBOT:SetupWeapon
	Desc: Makes bot hold this weapon.
	Arg1: Weapon | wep | Weapon to hold.
	Ret1: Weapon | Parented weapon. If give weapon is engine weapon, then this will be lua analog. Returns nil if failed to setup.
--]]------------------------------------
function ENT:SetupWeapon(wep)
	if !IsValid(wep) or wep==self:GetActiveWeapon() then return end
	
	-- Cannot hold engine weapons
	if !wep:IsScripted() and !EngineAnalogs[wep:GetClass()] then return end
	
	-- Clear old weapon
	if self:HasWeapon() then
		self:GetActiveWeapon():Remove()
	end
	
	ProtectedCall(function() self:OnWeaponEquip(wep) end)
	
	self:SetActiveWeapon(wep)
	
	-- Custom lua weapon analog for engine weapon, this need to have WEAPON metatable
	if EngineAnalogs[wep:GetClass()] then
		local actwep = ents.Create(EngineAnalogs[wep:GetClass()])
		actwep:SetOwner(self)
		actwep:Spawn()
		actwep:Activate()
		actwep:SetParent(wep)
		actwep:SetLocalPos(vector_origin)
		actwep:SetLocalAngles(angle_zero)
		actwep:PhysicsDestroy()
		actwep:AddSolidFlags(FSOLID_NOT_SOLID)
		actwep:AddEffects(EF_BONEMERGE)
		actwep:SetTransmitWithParent(true)
		
		actwep:SetClip1(wep:Clip1())
		actwep:SetClip2(wep:Clip2())
		
		hook.Add("Think",actwep,function(self)
			wep:SetClip1(self:Clip1())
			wep:SetClip2(self:Clip2())
		end)
		
		hook.Add("EntityRemoved",actwep,function(self,ent)
			if ent==wep then self:Remove() end
		end)
		actwep:DeleteOnRemove(wep)
		
		self.m_ActualWeapon = actwep
	else
		self.m_ActualWeapon = wep
	end
	
	local actwep = self:GetActiveLuaWeapon()
	actwep:SetWeaponHoldType(wep:GetHoldType())
	
	self:ReloadWeaponData()
	
	-- Actually setup weapon. Very similar to engine code.
	
	wep:SetVelocity(vector_origin)
	wep:RemoveSolidFlags(FSOLID_TRIGGER)
	wep:SetOwner(self)
	wep:RemoveEffects(EF_ITEM_BLINK)
	wep:PhysicsDestroy()
	
	wep:SetParent(self)
	wep:SetMoveType(MOVETYPE_NONE)
	wep:AddEffects(EF_BONEMERGE)
	wep:AddSolidFlags(FSOLID_NOT_SOLID)
	wep:SetLocalPos(vector_origin)
	wep:SetLocalAngles(angle_zero)
	
	wep:SetTransmitWithParent(true)
	
	ProtectedCall(function() actwep:OwnerChanged() end)
	ProtectedCall(function() actwep:Equip(self) end)
	
	return actwep
end

--[[------------------------------------
	Name: NEXTBOT:DropWeapon
	Desc: Drops current active weapon.
	Arg1: (optional) Vector | velocity | Sets velocity of weapon. Max speed is 400.
	Arg2: (optional) bool | justdrop | If true, just drop weapon from current hand position. Don't apply velocity and position.
	Ret1: Weapon | Dropped weapon. If active weapon is lua analog of engine weapon, then this will be engine weapon, not lua analog.
--]]------------------------------------
function ENT:DropWeapon(velocity,justdrop)
	local wep = self:GetActiveWeapon()
	if !IsValid(wep) then return end
	
	local actwep = self:GetActiveLuaWeapon()
	
	if !justdrop then
		velocity = velocity or self:GetEyeAngles():Forward()*200
		local spd = velocity:Length()
		velocity = velocity/spd
		velocity:Mul(math.min(spd,400))
	end
	
	self:SetActiveWeapon(NULL)
	
	-- Unparenting weapon. Very similar to engine code.
	
	wep:SetParent()
	wep:RemoveEffects(EF_BONEMERGE)
	wep:RemoveSolidFlags(FSOLID_NOT_SOLID)
	wep:CollisionRulesChanged()
	
	wep:SetOwner(NULL)
	
	wep:SetMoveType(MOVETYPE_FLYGRAVITY)
	
	local SF = wep:GetSolidFlags()
	if !wep:PhysicsInit(SOLID_VPHYSICS) then
		wep:SetSolid(SOLID_BBOX)
	else
		wep:SetMoveType(MOVETYPE_VPHYSICS)
		wep:PhysWake()
	end
	wep:SetSolidFlags(bit.bor(SF,FSOLID_TRIGGER))
	
	wep:SetTransmitWithParent(false)
	
	ProtectedCall(function() actwep:OwnerChanged() end)
	ProtectedCall(function() actwep:OnDrop() end)
	
	-- Restoring engine weapon from lua analog
	if wep!=actwep then
		wep:SetClip1(actwep:Clip1())
		wep:SetClip2(actwep:Clip2())
		
		actwep:DontDeleteOnRemove(wep)
		actwep:Remove()
	end
	
	ProtectedCall(function() self:OnWeaponDrop(wep) end)
	
	if !justdrop then
		wep:SetPos(self:GetShootPos())
		wep:SetAngles(self:GetEyeAngles())
		
		local phys = wep:GetPhysicsObject()
		if IsValid(phys) then
			phys:AddVelocity(velocity)
			phys:AddAngleVelocity(Vector(200,200,200))
		else
			wep:SetVelocity(velocity)
		end
	else
		local iBIndex,iWeaponBoneIndex
		
		if wep:GetBoneCount()>0 then
			for i=0,wep:GetBoneCount()-1 do
				iBIndex = self:LookupBone(wep:GetBoneName(i))
				
				if iBIndex then
					iWeaponBoneIndex = i
					break
				end
			end
			
			if !iBIndex then
				iWeaponBoneIndex = wep:LookupBone("ValveBiped.Weapon_bone")
				iBIndex = iWeaponBoneIndex and self:LookupBone("ValveBiped.Weapon_bone")
			end
		else
			iWeaponBoneIndex = wep:LookupBone("ValveBiped.Weapon_bone")
			iBIndex = iWeaponBoneIndex and self:LookupBone("ValveBiped.Weapon_bone")
		end
		
		if iBIndex then
			local wm = wep:GetBoneMatrix(iWeaponBoneIndex)
			local m = self:GetBoneMatrix(iBIndex)
		
			local lp,la = WorldToLocal(wep:GetPos(),wep:GetAngles(),wm:GetTranslation(),wm:GetAngles())
			local p,a = LocalToWorld(lp,la,m:GetTranslation(),m:GetAngles())
			
			wep:SetPos(p)
			wep:SetAngles(a)
		else
			local dir = self:GetAimVector()
			dir.z = 0
		
			wep:SetPos(self:GetShootPos()+dir*10)
		end
		
		local phys = wep:GetPhysicsObject()
		if IsValid(phys) then
			phys:AddVelocity(self.loco:GetVelocity())
		else
			wep:SetVelocity(self.loco:GetVelocity())
		end
	end
	
	return wep
end

--[[------------------------------------
	Name: NEXTBOT:ReloadWeaponData
	Desc: (INTERNAL) Reloads weapon data like burst and reload settings.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:ReloadWeaponData()
	self.m_WeaponData = {
		Primary = {
			BurstBullets = -1,
			BurstBullet = 0,
			NextShootTime = 0,
		},
		Secondary = {
			NextShootTime = 0,
		},
		NextReloadTime = 0,
	}
end

--[[------------------------------------
	Name: NEXTBOT:CanWeaponPrimaryAttack
	Desc: Returns can bot do primary attack or not.
	Arg1: 
	Ret1: bool | Can do primary attack
--]]------------------------------------
function ENT:CanWeaponPrimaryAttack()
	if !self:HasWeapon() or CurTime()<self.m_WeaponData.Primary.NextShootTime then return false end
	
	local wep = self:GetActiveLuaWeapon()
	if CurTime()<wep:GetNextPrimaryFire() then return false end

	return true
end

--[[------------------------------------
	Name: NEXTBOT:WeaponPrimaryAttack
	Desc: Does primary attack from bot's active weapon. This also uses burst data from weapon.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:WeaponPrimaryAttack()
	if !self:CanWeaponPrimaryAttack() then return end
	
	local wep = self:GetActiveLuaWeapon()
	local data = self.m_WeaponData.Primary
	
	ProtectedCall(function() wep:NPCShoot_Primary(self:GetShootPos(),self:GetAimVector()) end)
	self:DoRangeGesture()
	
	if self:ShouldWeaponAttackUseBurst(wep) then
		local bmin,bmax,frate = wep:GetNPCBurstSettings()
		local rmin,rmax = wep:GetNPCRestTimes()
		
		if data.BurstBullets==-1 then
			data.BurstBullets = math.random(bmin,bmax)
		end
		
		data.BurstBullet = data.BurstBullet+1
		
		if data.BurstBullet>=data.BurstBullets then
			data.BurstBullets = -1
			data.BurstBullet = 0
			data.NextShootTime = math.max(CurTime()+math.Rand(rmin,rmax),data.NextShootTime)
		else
			data.NextShootTime = math.max(CurTime()+frate,data.NextShootTime)
		end
	else
		local bmin,bmax,frate = wep:GetNPCBurstSettings()
		data.NextShootTime = math.max(CurTime()+frate,data.NextShootTime)
	end
end

--[[------------------------------------
	Name: NEXTBOT:CanWeaponSecondaryAttack
	Desc: Returns can bot do secondary attack or not.
	Arg1: 
	Ret1: bool | Can do secondary attack
--]]------------------------------------
function ENT:CanWeaponSecondaryAttack()
	if !self:HasWeapon() or CurTime()<self.m_WeaponData.Secondary.NextShootTime then return false end
	
	local wep = self:GetActiveLuaWeapon()
	if CurTime()<wep:GetNextSecondaryFire() then return false end

	return true
end

--[[------------------------------------
	Name: NEXTBOT:WeaponSecondaryAttack
	Desc: Does secondary attack from bot's active weapon.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:WeaponSecondaryAttack()
	if !self:CanWeaponSecondaryAttack() then return end
	
	local wep = self:GetActiveLuaWeapon()
	
	ProtectedCall(function() wep:NPCShoot_Secondary(self:GetShootPos(),self:GetAimVector()) end)
	self:DoRangeGesture()
end

--[[------------------------------------
	Name: NEXTBOT:GetAimVector
	Desc: Returns direction that used for weapon, including spread.
	Arg1: 
	Ret1: Vector | Aim direction.
--]]------------------------------------
function ENT:GetAimVector()
	local dir = self:GetEyeAngles():Forward()
	
	if self:HasWeapon() then
		local deg = self:GetActiveLuaWeapon():GetNPCBulletSpread(self:GetCurrentWeaponProficiency())
		deg = math.sin(math.rad(deg))/2
		
		dir:Add(Vector(math.Rand(-deg,deg),math.Rand(-deg,deg),math.Rand(-deg,deg)))
	end
	
	return dir
end

--[[------------------------------------
	Name: NEXTBOT:DoRangeGesture
	Desc: Make primary attack range animation.
	Arg1: 
	Ret1: number | Animation duration.
--]]------------------------------------
function ENT:DoRangeGesture()
	local act = self:TranslateActivity(ACT_MP_ATTACK_STAND_PRIMARYFIRE)
	local seq = self:SelectWeightedSequence(act)
	
	self:DoGesture(act)
	
	return self:SequenceDuration(seq)
end

--[[------------------------------------
	Name: NEXTBOT:DoReloadGesture
	Desc: Make reload animation.
	Arg1: 
	Ret1: number | Animation duration.
--]]------------------------------------
function ENT:DoReloadGesture()
	local act = self:TranslateActivity(ACT_MP_RELOAD_STAND)
	local seq = self:SelectWeightedSequence(act)
	
	self:DoGesture(act)
	
	return self:SequenceDuration(seq)
end

--[[------------------------------------
	Name: NEXTBOT:WeaponReload
	Desc: Reloads active weapon and do reload animation. Does nothing if we reloading already or if weapon clip is full.
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:WeaponReload()
	if !self:HasWeapon() then return end
	
	local wep = self:GetActiveLuaWeapon()
	if wep:Clip1()>=wep:GetMaxClip1() then return end
	if CurTime()<self.m_WeaponData.NextReloadTime then return end
	
	wep:SetClip1(wep:GetMaxClip1())
	
	local time = CurTime()+self:DoReloadGesture()
	
	self.m_WeaponData.Primary.NextShootTime = math.max(time,self.m_WeaponData.Primary.NextShootTime)
	self.m_WeaponData.Secondary.NextShootTime = math.max(time,self.m_WeaponData.Secondary.NextShootTime)
	self.m_WeaponData.NextReloadTime = time
end

--[[------------------------------------
	Name: NEXTBOT:SetCurrentWeaponProficiency
	Desc: Sets how skilled bot with weapons. See WEAPON_PROFICIENCY_ Enums.
	Arg1: number | prof | Weapon proficiency
	Ret1: 
--]]------------------------------------
function ENT:SetCurrentWeaponProficiency(prof)
	self.m_WeaponProficiency = prof
end

--[[------------------------------------
	Name: NEXTBOT:GetCurrentWeaponProficiency
	Desc: Returns how skilled bot with weapons. See WEAPON_PROFICIENCY_ Enums.
	Arg1: 
	Ret1: number | Weapon proficiency
--]]------------------------------------
function ENT:GetCurrentWeaponProficiency()
	return self.m_WeaponProficiency or WEAPON_PROFICIENCY_GOOD
end

--[[------------------------------------
	Name: NEXTBOT:OnWeaponEquip
	Desc: Called when bot equips weapon.
	Arg1: Entity | wep | Equiped weapon. It will be not lua analog.
	Ret1: 
--]]------------------------------------
function ENT:OnWeaponEquip(wep)
	self:RunTask("OnWeaponEquip",wep)
end

--[[------------------------------------
	Name: NEXTBOT:OnWeaponDrop
	Desc: Called when bot drops weapon.
	Arg1: Entity | wep | Dropped weapon. It will be not lua analog.
	Ret1: 
--]]------------------------------------
function ENT:OnWeaponDrop(wep)
	self:RunTask("OnWeaponDrop",wep)
end

--[[------------------------------------
	Name: NEXTBOT:CanPickupWeapon
	Desc: Returns can we pickup this weapon.
	Arg1: Entity | wep | Entity to test. Not necessary Weapon entity.
	Ret1: bool | Can pickup or not.
--]]------------------------------------
function ENT:CanPickupWeapon(wep)
	return wep:IsWeapon() and IsValid(wep) and (wep:IsScripted() and wep.CanBePickedUpByNPCs and wep:CanBePickedUpByNPCs() or EngineAnalogs[wep:GetClass()]) and !IsValid(wep:GetOwner()) or false
end

--[[------------------------------------
	Name: NEXTBOT:CanDropWeaponOnDie
	Desc: Decides can bot drop weapon on die. NOTE: Weapon also may not drop even with `true` if weapon's `SWEP:ShouldDropOnDie` returns `false`.
	Arg1: Weapon | wep | Current active weapon (this will be lua analog for engine weapon).
	Ret1: bool | Can drop.
--]]------------------------------------
function ENT:CanDropWeaponOnDie(wep)
	return true
end

--[[------------------------------------
	Name: NEXTBOT:ShouldWeaponAttackUseBurst
	Desc: Decides should bot shoot with bursts.
	Arg1: Weapon | wep | Current active weapon (this will be lua analog for engine weapon).
	Ret1: bool | Should use bursts.
--]]------------------------------------
function ENT:ShouldWeaponAttackUseBurst(wep)
	return !self:IsControlledByPlayer()
end

--[[------------------------------------
	Name: NEXTBOT:IsMeleeWeapon
	Desc: Returns true if weapon marked as for melee attacks (using CAP_* Enums).
	Arg1: (optional) Weapon | wep | Weapon to check (this should be lua analog for engine weapon). Without passing will be used active weapon.
	Ret1: bool | Weapon is melee weapon.
--]]------------------------------------
function ENT:IsMeleeWeapon(wep)
	wep = wep or self:GetActiveWeapon()
	
	return IsValid(wep) and wep.GetCapabilities and bit.band(wep:GetCapabilities(),CAP_WEAPON_MELEE_ATTACK1)!=0 or false
end

hook.Add("PlayerCanPickupWeapon","SBAdvancedNextBot",function(ply,wep)
	-- Do not allow pickup when bot carries this weapon
	if IsValid(wep:GetOwner()) and wep:GetOwner().SBAdvancedNextBot then
		return false
	end
	
	-- Do not allow pickup engine weapon analogs
	if EngineAnalogsReverse[wep:GetClass()] then
		return false
	end
end)
