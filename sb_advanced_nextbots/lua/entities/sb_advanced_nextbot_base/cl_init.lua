include("shared.lua")

function ENT:Initialize()
	self.m_TaskList = {}
	self.m_ActiveTasks = {}
	self.m_ActiveTasksID = {}
	
	self:SetupTaskList(self.m_TaskList)
	self:SetupTasks()
end

function ENT:Draw()
	self:DrawModel()
	
	self:RunTask("Draw")
end

-- Handles Player Control methods
include("cl_playercontrol.lua")
include("drive.lua")

-- Handle Tasks methods
include("tasks.lua")