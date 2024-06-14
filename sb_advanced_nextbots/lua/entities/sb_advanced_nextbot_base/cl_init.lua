include("shared.lua")

--[[------------------------------------
	NEXTBOT:Initialize
	Initialize our bot
--]]------------------------------------
function ENT:Initialize()
	self.m_TaskList = {}
	self.m_ActiveTasks = {}
	self.m_TaskCallbacks = {}
	
	self:SetupTaskList(self.m_TaskList)
	self:SetupTasks()
end

--[[------------------------------------
	NEXTBOT:Draw
	Drawing our bot and run Draw task
--]]------------------------------------
function ENT:Draw()
	self:DrawModel()
	
	self:RunTask("Draw")
end

-- Handles Player Control methods
include("cl_playercontrol.lua")
include("drive.lua")

-- Handle Tasks methods
include("tasks.lua")
