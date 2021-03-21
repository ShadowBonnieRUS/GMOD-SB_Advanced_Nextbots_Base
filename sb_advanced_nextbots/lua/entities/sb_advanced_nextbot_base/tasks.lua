
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
	Arg*: vararg | Arguments to callback. NOTE: In callback, first argument is always bot entity, second argument is always task data, passed arguments from NEXTBOT:RunTask starts at third argument.
	Ret*: vararg | Callback return.
--]]------------------------------------

function ENT:RunTask(event,...)
	local m_ActiveTasksNum = self.m_ActiveTasksNum
	if !m_ActiveTasksNum then return end
	
	local m_TaskList = self.m_TaskList
	local PassedTasks = {}
	
	local k = 1
	while true do
		local v = m_ActiveTasksNum[k]
		if !v then break end
		
		local task,data = v[1],v[2]
		
		if PassedTasks[task] then
			k = k+1
		
			continue
		end
		PassedTasks[task] = true
		
		local callback = m_TaskList[task][event]
		
		if callback then
			local args = {callback(self,data,...)}
			
			if args[1]!=nil then
				if args[2]==nil then
					return args[1]
				else
					return unpack(args)
				end
			end
			
			while k>0 do
				local cv = m_ActiveTasksNum[k]
				if cv==v then break end
				
				k = k-1
			end
		end
		
		k = k+1
	end
end

--[[------------------------------------
	Name: NEXTBOT:RunCurrentTask
	Desc: Runs one given task callback with given event.
	Arg1: any | task | Task name.
	Arg2: string | event | Event of hook.
	Arg*: vararg | Arguments to callback. NOTE: In callback, first argument is always bot entity, second argument is always task data, passed arguments from NEXTBOT:RunTask starts at third argument.
	Ret*: vararg | Callback return.
--]]------------------------------------
function ENT:RunCurrentTask(task,event,...)
	if !self:IsTaskActive(task) then return end

	local k,v = task,self.m_ActiveTasks[task]
	
	local dt = self.m_TaskList[k]
	if !dt or !dt[event] then return end
	
	local args = {dt[event](self,v,...)}
	
	if args[1]!=nil then
		if args[2]==nil then
			return args[1]
		else
			return unpack(args)
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:StartTask
	Desc: Starts new task with given data and calls 'OnStart' task callback. Does nothing if given task already started.
	Arg1: any | task | Task name.
	Arg2: (optional) table | data | Task data.
	Ret1: 
--]]------------------------------------
function ENT:StartTask(task,data)
	if self:IsTaskActive(task) then return end
	
	data = data or {}
	self.m_ActiveTasks[task] = data
	
	local m_ActiveTasksNum = self.m_ActiveTasksNum
	if !m_ActiveTasksNum then
		m_ActiveTasksNum = {}
		self.m_ActiveTasksNum = m_ActiveTasksNum
	end
	m_ActiveTasksNum[#m_ActiveTasksNum+1] = {task,data}
	
	self:RunCurrentTask(task,"OnStart")
end

--[[------------------------------------
	Name: NEXTBOT:TaskComplete
	Desc: Calls 'OnComplete' and 'OnDelete' task callbacks and deletes task. Does nothing if given task not started.
	Arg1: any | task | Task name.
	Ret1: 
--]]------------------------------------
function ENT:TaskComplete(task)
	if !self:IsTaskActive(task) then return end
	
	self:RunCurrentTask(task,"OnComplete")
	self:RunCurrentTask(task,"OnDelete")
	
	self.m_ActiveTasks[task] = nil
	
	local m_ActiveTasksNum = self.m_ActiveTasksNum
	for i=1,#m_ActiveTasksNum do
		if m_ActiveTasksNum[i][1]==task then
			table.remove(m_ActiveTasksNum,i)
			break
		end
	end
end

--[[------------------------------------
	Name: NEXTBOT:TaskFail
	Desc: Calls 'OnFail' and 'OnDelete' task callbacks and deletes task. Does nothing if given task not started.
	Arg1: any | task | Task name.
	Ret1: 
--]]------------------------------------
function ENT:TaskFail(task)
	if !self:IsTaskActive(task) then return end
	
	self:RunCurrentTask(task,"OnFail")
	self:RunCurrentTask(task,"OnDelete")
	
	self.m_ActiveTasks[task] = nil
	
	local m_ActiveTasksNum = self.m_ActiveTasksNum
	for i=1,#m_ActiveTasksNum do
		if m_ActiveTasksNum[i][1]==task then
			table.remove(m_ActiveTasksNum,i)
			break
		end
	end
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
