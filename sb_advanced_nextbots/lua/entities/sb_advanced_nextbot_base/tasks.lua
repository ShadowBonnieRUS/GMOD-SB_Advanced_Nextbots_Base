
--[[------------------------------------
	Name: NEXTBOT:SetupTaskList
	Desc: Used to setup bot's list of tasks.
	Arg1: table | list | List of tasks add new tasks to.
	Ret1: 
--]]------------------------------------
function ENT:SetupTaskList(list)
end

--[[------------------------------------
	Name: NEXTBOT:SetupTasks
	Desc: Used to start behaviour tasks on spawn
	Arg1: 
	Ret1: 
--]]------------------------------------
function ENT:SetupTasks()
end

--[[------------------------------------
	Name: NEXTBOT:RunTask
	Desc: Runs active tasks callbacks with given event.
	Arg1: string | event | Event of hook.
	Arg*: vararg | Arguments to callback. NOTE: First argument is always bot entity, second argument is always task data, other arguments starts at third argument.
	Ret*: vararg | Callback return.
--]]------------------------------------

function ENT:RunTask(event,...)
	local callbacks = {}

	for k,v in pairs(self.m_ActiveTasks) do
		local dt = self.m_TaskList[k]
		if !dt or !dt[event] then continue end
		
		callbacks[k] = v
	end
	
	self.m_TaskCallbacks = callbacks
	
	for k,v in pairs(callbacks) do
		if !self:IsTaskActive(k) then continue end
		
		local ivarargs,ovarargs = {self,v,...}
		ProtectedCall(function() ovarargs = {self.m_TaskList[k][event](unpack(ivarargs))} end)
		
		if ovarargs and ovarargs[1]!=nil then
			return unpack(ovarargs)
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:RunCurrentTask
	Desc: Runs give task callback with given event.
	Arg1: any | task | Task name.
	Arg2: string | event | Event of hook.
	Arg*: vararg | Arguments to callback. NOTE: First argument is always bot entity, second argument is always task data, other arguments starts at third argument.
	Ret*: vararg | Callback return.
--]]------------------------------------
function ENT:RunCurrentTask(task,event,...)
	if !self:IsTaskActive(task) then return end

	local k,v = task,self.m_ActiveTasks[task]
	
	local dt = self.m_TaskList[k]
	if !dt or !dt[event] then return end
	
	local ivarargs,ovarargs = {self,v,...}
	ProtectedCall(function() ovarargs = {dt[event](unpack(ivarargs))} end)
	
	if ovarargs and ovarargs[1]!=nil then
		return unpack(varargs)
	end
end

--[[------------------------------------
	Name: NEXTBOT:StartTask
	Desc: Starts new task with given data. Does nothing if given task already exists.
	Arg1: any | task | Task name.
	Arg2: (optional) table | data | Task data.
	Ret1: 
--]]------------------------------------
function ENT:StartTask(task,data)
	if self:IsTaskActive(task) then return end
	
	data = data or {}
	self.m_ActiveTasks[task] = data
	
	self:RunCurrentTask(task,"OnStart")
end

--[[------------------------------------
	Name: NEXTBOT:TaskComplete
	Desc: Calls 'OnComplete' task callback and deletes task. Does nothing if given task not exists.
	Arg1: any | task | Task name.
	Ret1: 
--]]------------------------------------
function ENT:TaskComplete(task)
	if !self:IsTaskActive(task) then return end
	
	self:RunCurrentTask(task,"OnComplete")
	self:RunCurrentTask(task,"OnDelete")
	
	self.m_ActiveTasks[task] = nil
end

--[[------------------------------------
	Name: NEXTBOT:TaskFail
	Desc: Calls 'OnFail' task callback and deletes task. Does nothing if given task not exists.
	Arg1: any | task | Task name.
	Ret1: 
--]]------------------------------------
function ENT:TaskFail(task)
	if !self:IsTaskActive(task) then return end
	
	self:RunCurrentTask(task,"OnFail")
	self:RunCurrentTask(task,"OnDelete")
	
	self.m_ActiveTasks[task] = nil
end

--[[------------------------------------
	Name: NEXTBOT:IsTaskActive
	Desc: Returns whenever given task exists or not.
	Arg1: any | task | Task name.
	Ret1: bool | Returns true if task exists, false otherwise.
--]]------------------------------------
function ENT:IsTaskActive(task)
	return self.m_ActiveTasks[task] and true or false
end