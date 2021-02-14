
--[[------------------------------------
	Name: NEXTBOT:NodeGraphPath
	Desc: Returns new SBNodeGraphPathFollower object.
	Arg1: 
	Ret1: SBNodeGraphPathFollower | Path object.
--]]------------------------------------
function ENT:NodeGraphPath()
	return SBAdvancedNextbotNodeGraph.Path()
end

--[[------------------------------------
	Name: NEXTBOT:SetUseNodeGraph
	Desc: Sets should bot use nodegraph instead navmesh.
	Arg1: bool | should | Should use nodegraph
	Ret1: 
--]]------------------------------------
function ENT:SetUseNodeGraph(should)
	self.m_UseNodeGraph = should
end

--[[------------------------------------
	Name: NEXTBOT:UsingNodeGraph
	Desc: Returns true if bot creating path using nodegraph path finding.
	Arg1: 
	Ret1: bool | Using nodegraph or not.
--]]------------------------------------
function ENT:UsingNodeGraph()
	return self.m_UseNodeGraph
end

hook.Add("Initialize","SBAdvancedNextbotNodeGraph",function()
	-- Sometime maps can have old nodegraph and it will be updated in 1-3 seconds, so loading nodes later
	
	timer.Simple(5,SBAdvancedNextbotNodeGraph.Load)
end)