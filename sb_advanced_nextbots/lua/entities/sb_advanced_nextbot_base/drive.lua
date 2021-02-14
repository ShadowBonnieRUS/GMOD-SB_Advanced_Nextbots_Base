
--[[------------------------------------
	NEXTBOT:GetEntityDriveMode
	Sets right drive mode
--]]------------------------------------
function ENT:GetEntityDriveMode(ply)
	return "drive_sb_advanced_nextbot"
end

--[[------------------------------------
	Name: NEXTBOT:ModifyControlPlayerButtons
	Desc: Allows modify buttons when bot controlled by player.
	Arg1: number | btns | Buttons from MoveData.
	Ret1: any | Return modified buttons (number) or nil to not change.
--]]------------------------------------
function ENT:ModifyControlPlayerButtons(btns)
	return self:RunTask("ModifyControlPlayerButtons",btns)
end

drive.Register("drive_sb_advanced_nextbot",{
	Init = function(self)
		if SERVER then
			self.Entity:StartControlByPlayer(self.Player)
		else
			self.Entity:SetPredictable(false)
		end
	end,
	
	Stop = function(self)
		self.StopDriving = true
		
		if SERVER then
			self.Entity:StopControlByPlayer()
		end
	end,
	
	StartMove = function(self,mv,cmd)
		self.Player:SetObserverMode(OBS_MODE_CHASE)
	
		if mv:KeyPressed(IN_ZOOM) then
			self:Stop()
		end
		
		if SERVER then
			local btns = mv:GetButtons()
			self.Entity.m_ControlPlayerButtons = self.Entity:ModifyControlPlayerButtons(btns) or btns
		end
	end,
	
	CalcView = function(self,view)
		local angles = self.Player:EyeAngles()
	
		local botpos = self.Entity:GetShootPos()
		local campos = LocalToWorld(self.Entity.ControlCameraOffset,angle_zero,botpos,angles)
		
		local tr = util.TraceHull({
			start = botpos,
			endpos = campos,
			mins = Vector(view.znear,view.znear,view.znear)*-3,
			maxs = Vector(view.znear,view.znear,view.znear)*3,
			filter = self.Entity,
		})
		
		view.origin = tr.HitPos
		view.angles = angles
	end,
},"drive_base")

hook.Add("CanDrive","SBAdvancedNextBotControl",function(ply,ent)
	if ent.SBAdvancedNextBot then
		return true
	end
end)