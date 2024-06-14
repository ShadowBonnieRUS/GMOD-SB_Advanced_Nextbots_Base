
/*----- NODEGRAPH MODULE DOCUMENTATION -------

#Enums

SBAdvancedNextbotNodeGraph.NODE_ANY
SBAdvancedNextbotNodeGraph.NODE_DELETED
SBAdvancedNextbotNodeGraph.NODE_GROUND
SBAdvancedNextbotNodeGraph.NODE_AIR
SBAdvancedNextbotNodeGraph.NODE_CLIMB
SBAdvancedNextbotNodeGraph.NODE_WATER

SBAdvancedNextbotNodeGraph.AI_NODE_ZONE_UNKNOWN
SBAdvancedNextbotNodeGraph.AI_NODE_ZONE_SOLO
SBAdvancedNextbotNodeGraph.AI_NODE_ZONE_UNIVERSAL
SBAdvancedNextbotNodeGraph.AI_NODE_FIRST_ZONE

#Functions

----------------------------------------
	Name: SBAdvancedNextbotNodeGraph.Load
	Desc: Loads nodes from maps/graphs/.ain, deletes previous nodes.
	Arg1: 
	Ret1: 
----------------------------------------

----------------------------------------
	Name: SBAdvancedNextbotNodeGraph.GetAllNodes
	Desc: Returns all Nodes on map.
	Arg1: 
	Ret1: table | Table of nodes.
----------------------------------------

----------------------------------------
	Name: SBAdvancedNextbotNodeGraph.GetNodesCount
	Desc: Returns count of loaded nodes. Better performance than #SBAdvancedNextbotNodeGraph.GetAllNodes()
	Arg1: 
	Ret1: number | Count of nodes.
----------------------------------------

----------------------------------------
	Name: SBAdvancedNextbotNodeGraph.Path
	Desc: Returns new SBNodeGraphPathFollower object for path creation using nodegraph.
	Arg1: 
	Ret1: SBNodeGraphPathFollower | Path object.
----------------------------------------

----------------------------------------
	Name: SBAdvancedNextbotNodeGraph.GetNearestNode
	Desc: Returns nearest node to given position.
	Arg1: Vector | Position.
	Arg2: (optional) Vector | Use visibility check from this position.
	Arg3: (optional) number | Mask used in visibility check (default is MASK_NPCSOLID_BRUSHONLY).
	Ret1: SBNodeGraphNode | Nearest node.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetOrigin
	Desc: Returns origin of node.
	Arg1: 
	Ret1: Vector | Origin.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetYaw
	Desc: Returns yaw of node. Not used.
	Arg1: 
	Ret1: number | yaw.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetType
	Desc: Returns type of node. See NODE_* Enums
	Arg1: 
	Ret1: number | type.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetZone
	Desc: Returns zone of node. Not used. See AI_NODE_ZONE_* Enums
	Arg1: 
	Ret1: number | zone.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetID
	Desc: Returns id of node.
	Arg1: 
	Ret1: number | id.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetAdjacentNodes
	Desc: Returns all adjacent nodes of this node.
	Arg1: 
	Ret1: table | Table of adjacent nodes.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphNode:GetAcceptedMoveTypes
	Desc: Returns all accepted move types between given node and this node. See CAP_* Enums
	Arg1: SBNodeGraphNode | Other node.
	Ret1: table | Table move types if other node is neighbor, nil otherwise.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:Compute
	Desc: Computes path using nodegraph.
	Arg1: Entity | Bot for computing path.
	Arg2: Vector | Goal position.
	Arg3: (optional) function | Custom cost generator.
		Arguments:
		`node` - next node
		`from` - previous node
		`cap` - calculated capabilities between nodes, see CAP_* enums
		Returns:
			number cost.
	Ret1: bool | true if path generated successfully, false otherwise.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:FirstSegment
	Desc: See PathFollower:FirstSegment
	Arg1: 
	Ret1: table | Segment data.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetAge
	Desc: See PathFollower:GetAge
	Arg1: 
	Ret1: number | age.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetAllSegments
	Desc: See PathFollower:GetAllSegments
	Arg1: 
	Ret1: table | table of segments data.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetCurrentGoal
	Desc: See PathFollower:GetCurrentGoal
	Arg1: 
	Ret1: table | Segment data.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetEnd
	Desc: See PathFollower:GetEnd
	Arg1: 
	Ret1: Vector | Goal position.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetGoalTolerance
	Desc: See PathFollower:GetGoalTolerance
	Arg1: 
	Ret1: number | distance.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetLength
	Desc: See PathFollower:GetLength
	Arg1: 
	Ret1: number | length.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetMinLookAheadDistance
	Desc: See PathFollower:GetMinLookAheadDistance
	Arg1: 
	Ret1: number | distance.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:GetStart
	Desc: See PathFollower:GetStart
	Arg1: 
	Ret1: Vector | Start position.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:Invalidate
	Desc: Invalidates path.
	Arg1: 
	Ret1: 
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:IsValid
	Desc: Returns valid path or not.
	Arg1: 
	Ret1: bool | path valid or not.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:LastSegment
	Desc: See PathFollower:LastSegment
	Arg1: 
	Ret1: table | Segment data.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:PriorSegment
	Desc: See PathFollower:PriorSegment
	Arg1: 
	Ret1: table | Segment data.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:NextSegment
	Desc: See PathFollower:NextSegment
	Arg1: 
	Ret1: table | Segment data.
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:ResetAge
	Desc: See PathFollower:ResetAge
	Arg1: 
	Ret1: 
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:SetGoalTolerance
	Desc: See PathFollower:SetGoalTolerance
	Arg1: number | distance
	Ret1: 
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:SetMinLookAheadDistance
	Desc: See PathFollower:SetMinLookAheadDistance
	Arg1: number | distance
	Ret1: 
----------------------------------------

----------------------------------------
	Name: SBNodeGraphPathFollower:Update
	Desc: See PathFollower:Update
	Arg1: Entity | Bot for updating
	Ret1: 
----------------------------------------

*/-- END OF MODEGRAPH MODULE DOCUMENTATION ---

if SBAdvancedNextbotNodeGraph then return end

module("SBAdvancedNextbotNodeGraph",package.seeall)

NODE_ANY		= 0
NODE_DELETED	= 1
NODE_GROUND		= 2
NODE_AIR		= 3
NODE_CLIMB		= 4
NODE_WATER		= 5

AI_NODE_ZONE_UNKNOWN	= 0
AI_NODE_ZONE_SOLO		= 1
AI_NODE_ZONE_UNIVERSAL	= 2
AI_NODE_FIRST_ZONE		= 3

PATH_SEGMENT_MOVETYPE_GROUND		= 0
PATH_SEGMENT_MOVETYPE_CROUCHING		= 1
PATH_SEGMENT_MOVETYPE_JUMPING		= 2
PATH_SEGMENT_MOVETYPE_JUMPINGGAP	= 3
PATH_SEGMENT_MOVETYPE_LADDERUP		= 4
PATH_SEGMENT_MOVETYPE_LADDERDOWN	= 5

-- enum NavTraverseType game/server/nav.h
local GO_NORTH			= 0
local GO_EAST			= 1
local GO_SOUTH			= 2
local GO_WEST			= 3
local GO_LADDER_UP		= 4
local GO_LADDER_DOWN	= 5
local GO_JUMP			= 6
local GO_ELEVATOR_UP	= 7
local GO_ELEVATOR_DOWN	= 8

local MAX_NODES				= 3000
local AI_MAX_NODE_LINKS		= 30
local AINET_VERSION_NUMBER	= 37

local NO_NODE				= -1
local LINK_OFF				= 0
local LINK_ON				= 1

local bits_LINK_STALE_SUGGESTED = 0x01
local bits_LINK_OFF			= 0x02
local bits_HULL_BITS_MASK	= 0x000002ff

local HINT_JUMP_OVERRIDE	= 901

local Nodes,NodeNum = {},0
local EditOps,EditOpsInvert = {},{}
local NodesPos,NodesLinks = {},{}
local DynamicLinks = {}
local Hints = {}

local sb_anb_nodegraph_drawnodes = CreateConVar("sb_anb_nodegraph_drawnodes","0", FCVAR_ARCHIVE)
local sb_anb_nodegraph_drawnodes_hull = CreateConVar("sb_anb_nodegraph_drawnodes_hull","0", FCVAR_ARCHIVE)
local sb_anb_nodegraph_pathdebug = CreateConVar("sb_anb_nodegraph_pathdebug","0", FCVAR_ARCHIVE)
local sb_anb_nodegraph_accurategetnearestnode = CreateConVar("sb_anb_nodegraph_accurategetnearestnode","1", FCVAR_ARCHIVE)
local sb_anb_nodegraph_trivialcheck = CreateConVar("sb_anb_nodegraph_trivialcheck","1", FCVAR_ARCHIVE)
local sb_anb_nodegraph_trivialcheck_debug = CreateConVar("sb_anb_nodegraph_trivialcheck_debug","0", FCVAR_ARCHIVE)

local function DevMsg(msg) Msg("SBAdvancedNextbotNodeGraph: ",msg) end
local function ThrowError(msg) error("SBAdvancedNextbotNodeGraph: "..msg,2) end
local function AssertValid(self) if !self:IsValid() then ThrowError("Attempt to use "..tostring(self)) end end

local function NewObject(meta)
	local obj = newproxy()
	local data = setmetatable({},{__index = meta.__index})
	
	debug.setmetatable(obj,{
		__newindex = data,
		__index = data,
		__tostring = meta.__tostring,
	})
	
	return obj
end

local function PathCostGenerator(path, from, node, cap)
	if path.m_customcostgen then
		local success, cost = pcall(path.m_customcostgen, node, from, cap)
		
		if !success then
			DevMsg("Path cost generation failed! " .. cost .. "\n")
			
			return -1
		end
		
		return tonumber(cost) or -1
	end
	
	if !from then return 0 end
	
	local frompos = from:GetOrigin()
	local nodepos = node:GetOrigin()
	
	local cost = frompos:Distance(nodepos)
	local z = nodepos.z - frompos.z
	
	if z < 0 and bit.band(cap, bit.bor(CAP_MOVE_GROUND, CAP_MOVE_JUMP)) != 0 then
		local maxh = path.m_Bot.loco:GetDeathDropHeight()
		local h = -z
		
		if h > maxh then
			local dist = math.Distance(frompos.x, frompos.y, nodepos.x, nodepos.y)
			local ang = math.deg(math.atan(h / dist))
			
			if ang > 60 then return -1 end
		end
	end

	if bit.band(cap, CAP_MOVE_CLIMB) != 0 then
		return cost * (z > 0 and 0.5 or 4)
	end
	
	if bit.band(cap, CAP_MOVE_JUMP) != 0 then
		local maxh = path.m_Bot.loco:GetJumpHeight()
		if z >= maxh then return -1 end
		
		return cost * 5
	elseif bit.band(cap, bit.bor(CAP_MOVE_GROUND, CAP_MOVE_FLY)) != 0 then
		return cost
	end
	
	return cost * 10
end

local function TrivialPathCheck(start, goal, botdata, tolerance, distlimit)
	local mins, maxs = Vector(botdata.cbounds[1]), botdata.cbounds[2]
	mins.z = mins.z + botdata.step

	local dir = goal - start
	local len = dir:Length()
	local step = maxs.x - mins.x
	
	if distlimit and len > step * 20 then return false end
	
	dir:Normalize()

	local mask, filter = botdata.mask, botdata.filter
	local height = Vector(0, 0, botdata.step * 2)
	
	local tlen = len - (tolerance or 0)

	local result = {}
	local tr = {start = start, endpos = start + dir * math.max(0, tlen), mins = mins, maxs = maxs, mask = mask, filter = filter, output = result}
	util.TraceHull(tr)

	local debug = sb_anb_nodegraph_trivialcheck_debug:GetBool()
	if debug then
		debugoverlay.SweptBox(start, result.HitPos, mins, maxs, angle_zero, 0.25, result.Fraction < 1 and Color(255, 0, 0) or Color(0, 255, 0))
	end
	
	if result.Fraction < 1 then return false end
	
	for i = step, len, step * 1.5 do
		tr.start = start + dir * i
		tr.endpos = tr.start - height
		util.TraceHull(tr)

		if debug then
			debugoverlay.SweptBox(tr.start, result.HitPos, mins, maxs, angle_zero, 0.25, result.Fraction >= 1 and Color(255, 0, 0) or Color(0, 255, 0))
		end
		
		if result.Fraction >= 1 then return false end
	end

	tr.start = start
	tr.endpos = start + dir * math.max(0, tlen)
	tr.mins = Vector(botdata.bounds[1])
	tr.maxs = botdata.bounds[2]
	tr.mins.z = tr.mins.z + botdata.step
	util.TraceHull(tr)
	
	return true, result.Fraction < 1
end

local function GetLinkCapabilities(link, from, to, botdata)
	local hull, duckhull = botdata.hull, botdata.duckhull
	local bcap, movetypes = botdata.cap, link.m_AcceptedMoveTypes

	local cap, duck = bit.band(movetypes[hull], bcap), false
	if cap == 0 then
		cap, duck = bit.band(movetypes[duckhull], bcap), true
	end

	if cap == 0 then
		duck = false

		if bit.band(bcap, CAP_MOVE_GROUND) != 0 && bit.band(bit.bor(movetypes[hull], movetypes[duckhull]), CAP_MOVE_JUMP) != 0 then
			local delta = to:GetOrigin() - from:GetOrigin()

			if delta.z < 0 && delta.z > -botdata.deathdrop then
				local len = math.sqrt(delta.x * delta.x + delta.y * delta.y)
				local ang = math.deg(math.atan(-delta.z / len))
				
				if ang > 50 then
					cap, duck = CAP_MOVE_GROUND, bit.band(movetypes[hull], CAP_MOVE_JUMP) == 0
				end
			end
		end
	end

	return cap, duck
end

local function GetCapBetweenNodes(from, to, botdata)
	for i = 0, from:_NumLinks() - 1 do
		local link = from:_GetLink(i)
		
		if (link:SrcNode() == from or link:DestNode() == from) and link:DestNode(from) == to then
			return GetLinkCapabilities(link, from, to, botdata)
		end
	end
end

local function GetCapForOutsideSegment(pos, from, to, goal, botdata)
	local cap, duck = GetCapBetweenNodes(from, to, botdata)

	if bit.band(cap, CAP_MOVE_CLIMB) != 0 then
		if botdata.ladder then return end

		return CAP_MOVE_GROUND, duck
	elseif bit.band(cap, CAP_MOVE_JUMP) != 0 then
		return CAP_MOVE_GROUND, duck
	elseif bit.band(cap, CAP_MOVE_GROUND) != 0 then
		local dist = from:GetOrigin():DistToSqr(to:GetOrigin())
		local range = pos:DistToSqr(goal and from:GetOrigin() or to:GetOrigin())

		if range < dist then return end
	end

	return cap, duck
end

local function TranslateCapToPathSegmentType(cap, duckonly, start, goal)
	if bit.band(cap, CAP_MOVE_JUMP) != 0 then
		return PATH_SEGMENT_MOVETYPE_JUMPING
	elseif bit.band(cap, CAP_MOVE_CLIMB) != 0 then
		if goal.z != start.z then
			return goal.z > start.z and PATH_SEGMENT_MOVETYPE_LADDERUP or PATH_SEGMENT_MOVETYPE_LADDERDOWN
		end
	end
	
	return duckonly and PATH_SEGMENT_MOVETYPE_CROUCHING or PATH_SEGMENT_MOVETYPE_GROUND
end

local function debugoverlay_HorzArrow(startpos,endpos,width,time,color,nodepth)
	local forward = endpos-startpos
	forward:Normalize()
	
	local side = forward:Cross(vector_up)
	local radius = width/2
	
	local p1 = startpos-side*radius
	local p2 = endpos-forward*width-side*radius
	local p3 = endpos-forward*width-side*width
	local p4 = endpos
	local p5 = endpos-forward*width+side*width
	local p6 = endpos-forward*width+side*radius
	local p7 = startpos+side*radius
	
	local col = color.a==255 and color or ColorAlpha(color,255)
	
	debugoverlay.Line(p1,p2,time,col,nodepth)
	debugoverlay.Line(p2,p3,time,col,nodepth)
	debugoverlay.Line(p3,p4,time,col,nodepth)
	debugoverlay.Line(p4,p5,time,col,nodepth)
	debugoverlay.Line(p5,p6,time,col,nodepth)
	debugoverlay.Line(p6,p7,time,col,nodepth)
	debugoverlay.Line(p7,p1,time,col,nodepth)
	
	if color.a>0 then
		debugoverlay.Triangle(p5,p4,p3,time,color,nodepth)
		debugoverlay.Triangle(p1,p7,p6,time,color,nodepth)
		debugoverlay.Triangle(p6,p2,p1,time,color,nodepth)
		
		debugoverlay.Triangle(p3,p4,p5,time,color,nodepth)
		debugoverlay.Triangle(p6,p7,p1,time,color,nodepth)
		debugoverlay.Triangle(p1,p2,p6,time,color,nodepth)
	end
end

local function debugoverlay_VertArrow(startpos, endpos, width, time, color, nodepth)
	local lineDir = endpos - startpos
	lineDir:Normalize()

	local sideDir = lineDir:Cross(vector_up)
	sideDir:Normalize()

	local upVec = sideDir:Cross(lineDir)
	upVec:Normalize()

	local radius = width / 2

	local p1 = startpos - upVec * radius
	local p2 = endpos - lineDir * width - upVec * radius
	local p3 = endpos - lineDir * width - upVec * width
	local p4 = endpos
	local p5 = endpos - lineDir * width + upVec * width
	local p6 = endpos - lineDir * width + upVec * radius
	local p7 = startpos + upVec * radius

	local col = color.a == 255 and color or ColorAlpha(color, 255)

	debugoverlay.Line(p1, p2, time, col, nodepth)
	debugoverlay.Line(p2, p3, time, col, nodepth)
	debugoverlay.Line(p3, p4, time, col, nodepth)
	debugoverlay.Line(p4, p5, time, col, nodepth)
	debugoverlay.Line(p5, p6, time, col, nodepth)
	debugoverlay.Line(p6, p7, time, col, nodepth)

	if color.a > 0 then
		debugoverlay.Triangle(p5, p4, p3, time, color, nodepth)
		debugoverlay.Triangle(p1, p7, p6, time, color, nodepth)
		debugoverlay.Triangle(p6, p2, p1, time, color, nodepth)

		debugoverlay.Triangle(p3, p4, p5, time, color, nodepth)
		debugoverlay.Triangle(p6, p7, p1, time, color, nodepth)
		debugoverlay.Triangle(p1, p2, p6, time, color, nodepth)
	end
end

local function NameMatch(query,name)
	if name=="" then
		return !query or query=="*"
	end
	
	if query==name then
		return true
	end
	
	if !query and !name then
		return true
	end
	
	if query:lower()==name:lower() then
		return true
	end
	
	if query=="*" then
		return true
	end
	
	return false
end

local CAI_Node = {
	_initialize = function(self,index,origin,yaw)
		self.m_yaw = yaw
		self.m_id = index
		
		self.m_voffset = {}
		
		for i=0,NUM_HULLS-1 do
			self.m_voffset[i] = 0
		end
		
		self.m_links = {}
		self.m_NumLinks = 0
		
		self.m_type = NODE_GROUND
		self.m_zone = AI_NODE_ZONE_UNKNOWN
		self.m_info = 0
		
		self:_SetOrigin(origin)
	end,

	_NumLinks = function(self) AssertValid(self) return self.m_NumLinks end,
	_AddLink = function(self,link)
		AssertValid(self)
		
		if self.m_NumLinks>=AI_MAX_NODE_LINKS then
			ThrowError("AddLink: Node "..self.m_id.." has too many links")
		end
		
		self.m_links[self.m_NumLinks] = link
		self.m_NumLinks = self.m_NumLinks+1
	end,
	_GetLink = function(self,num)
		AssertValid(self)
		
		return self.m_links[num]
	end,
	
	GetOrigin = function(self) AssertValid(self) return Vector(self.m_origin) end,
	GetYaw = function(self) AssertValid(self) return self.m_yaw end,
	GetID = function(self) AssertValid(self) return self.m_id end,
	GetType = function(self) AssertValid(self) return self.m_type end,
	GetInfo = function(self) AssertValid(self) return self.m_info end,
	GetZone = function(self) AssertValid(self) return self.m_zone end,
	
	GetAdjacentNodes = function(self)
		AssertValid(self)
	
		local t = {}
		
		for i=0,self.m_NumLinks-1 do
			local link = self.m_links[i]
			
			local neighbor = link:DestNode()
			if neighbor==self then neighbor = link:SrcNode() end
			
			t[#t+1] = neighbor
		end
		
		return t
	end,
	
	GetAcceptedMoveTypes = function(self,neighbor)
		AssertValid(self)
	
		for i=0,self.m_NumLinks-1 do
			local link = self.m_links[i]
			
			if link:SrcNode()==self and link:DestNode()==neighbor or link:SrcNode()==neighbor and link:DestNode()==self then
				local t = {}
				
				for j=0,NUM_HULLS-1 do
					t[j+1] = link.m_AcceptedMoveTypes[j]
				end
				
				return t
			end
		end
	end,
	
	IsValid = function(self)
		return !self.m_Removed
	end,
	
	_Remove = function(self)
		AssertValid(self)
		
		NodesPos[self.m_id] = nil
		NodesLinks[self.m_id] = nil
		
		for i=0,self:_NumLinks()-1 do
			local link = self:_GetLink(i)
			
			local neighbor = link:DestNode()
			if neighbor==self then neighbor = link:SrcNode() end
			
			NodesLinks[self.m_id.."_"..neighbor:GetID()] = nil
			NodesLinks[neighbor:GetID().."_"..self.m_id] = nil
			
			for j=0,neighbor:_NumLinks()-1 do
				local nlink = neighbor:_GetLink(j)
				
				if link==nlink then
					for k=j,neighbor:_NumLinks()-1 do
						neighbor.m_links[k] = Either(k==neighbor:_NumLinks()-1,nil,neighbor.m_links[k+1])
					end
					
					neighbor.m_NumLinks = neighbor.m_NumLinks-1
					
					if neighbor:_NumLinks()==0 then
						NodesLinks[neighbor:GetID()] = neighbor:GetOrigin()
					end
					
					break
				end
			end
		end
		
		self.m_Removed = true
	end,

	_SetOrigin = function(self, origin)
		self.m_origin = Vector(origin)

		NodesPos[self.m_id] = self.m_origin
		NodesLinks[self.m_id] = self.m_origin
	end,

	_InitPosition = function(self)
		if self.m_type == NODE_CLIMB then
			local normal = -Vector(math.cos(math.rad(self.m_yaw)), math.sin(math.rad(self.m_yaw)))
			local endpos = self.m_origin + normal * 100

			local tr = util.TraceLine({start = self.m_origin, endpos = endpos, mask = MASK_NPCSOLID_BRUSHONLY})
			if tr.StartSolid and !tr.AllSolid then
				local delta = endpos - self.m_origin
				local offset = delta * tr.FractionLeftSolid + delta:GetNormalized() * 5

				self:_SetOrigin(self.m_origin + offset)

				local linknodes = self:GetAdjacentNodes()
				for i=1,#linknodes do
					if linknodes[i].m_type == NODE_CLIMB then
						linknodes[i]:_SetOrigin(linknodes[i].m_origin + offset)
					end
				end
			end
		end
	end,
}

local SBNodeGraphNode = {
	__index = CAI_Node,
	__tostring = function(self)
		return "SBNodeGraphNode ["..(self:IsValid() and self:GetID() or "NULL").."]"
	end,
}
debug.getregistry().SBNodeGraphNode = SBNodeGraphNode

local CAI_Link = {
	_initialize = function(self)
		self.m_info = 0
		self.m_AcceptedMoveTypes = {}
		
		for i=0,NUM_HULLS-1 do
			self.m_AcceptedMoveTypes[i] = 0
		end
	end,
	
	DestNode = function(self, src) return src == self.dest and self.src or self.dest end,
	SrcNode = function(self) return self.src end,
	DestNodeID = function(self, src) return self:DestNode(src):GetID() end,
	SrcNodeID = function(self) return self.src:GetID() end,
}

local CAI_DynamicLink = {
	_initialize = function(self)
		self.m_SrcEditID = self.dlink:GetInternalVariable("startnode")
		self.m_DestEditID = self.dlink:GetInternalVariable("endnode")
		self.m_SrcID = EditOpsInvert[self.m_SrcEditID] or NO_NODE
		self.m_DestID = EditOpsInvert[self.m_DestEditID] or NO_NODE
		self.m_LinkState = self.dlink:GetInternalVariable("initialstate")
		self.m_LinkType = CAP_MOVE_GROUND
		self.m_AllowUse = self.dlink:GetInternalVariable("AllowUse")
		self.m_InvertAllow = self.dlink:GetInternalVariable("m_bInvertAllow")
	
		DynamicLinks[self] = true
	end,
	
	GetSrcNodeID = function(self) return self.m_SrcID end,
	GetDestNodeID = function(self) return self.m_DestID end,
	GetStrAllowUse = function(self) return self.m_AllowUse end,
	GetLinkState = function(self) return self.m_LinkState end,
	GetInvertAllow = function(self) return self.m_InvertAllow end,
	
	IsValid = function(self) return IsValid(self.dlink) end,
	
	UpdateState = function(self)
		local state = self.dlink:GetInternalVariable("initialstate")
		
		if self.m_LinkState!=state then
			self.m_LinkState = state
			
			self:SetLinkState()
		end
	end,
	
	SetLinkState = function(self)
		if self.m_SrcID==NO_NODE or self.m_DestID==NO_NODE then
			DevMsg("Dynamic link at "..tostring(self.dlink:GetPos()).." pointing to invalid node ID!!\n")
			
			return
		end
		
		local srcnode = Nodes[self.m_SrcID]
		if srcnode then
			local link = self:FindLink()
			
			if link then
				link.dlink = self
				
				if self.m_LinkState==LINK_OFF then
					link.m_info = bit.bor(link.m_info,bits_LINK_OFF)
				else
					link.m_info = bit.band(link.m_info,bit.bnot(bits_LINK_OFF))
				end
			else
				DevMsg("Dynamic Link Error: "..tostring(self.dlink).." unable to form between nodes "..self.m_SrcID.." and "..self.m_DestID.."\n")
			end
		end
	end,
	
	FindLink = function(self)
		local node = Nodes[self.m_SrcID]
		
		if node then
			for i=0,node:_NumLinks()-1 do
				local link = node:_GetLink(i)
				
				if link:SrcNodeID()==self.m_SrcID and link:DestNodeID()==self.m_DestID or link:SrcNodeID()==self.m_DestID and link:DestNodeID()==self.m_SrcID then
					return link
				end
			end
		end
	end,
}

local CAI_Hint = {
	_initialize = function(self)
		self.m_HintType = self.hint:GetInternalVariable("hinttype")
		self.m_Group = self.hint:GetInternalVariable("Group")
		self.m_Disabled = self.hint:GetInternalVariable("StartHintDisabled")
		self.m_ActivityName = self.hint:GetInternalVariable("hintactivity")
		self.m_TargetWCNodeID = self.hint:GetInternalVariable("TargetNode")
		self.m_WCNodeID = self.hint:GetInternalVariable("nodeid")
		self.m_IgnoreFacing = self.hint:GetInternalVariable("IgnoreFacing")
		self.m_minState = self.hint:GetInternalVariable("MinimumState")
		self.m_maxState = self.hint:GetInternalVariable("MaximumState")

		self.m_Origin = Vector()
		self.m_Name = ""
		self.m_SpawnFlags = 0
	end,

	HintType = function(self) return self.m_HintType end,

	SetOrigin = function(self, origin) self.m_Origin = Vector(origin) end,
	GetOrigin = function(self) return Vector(self.m_Origin) end,

	SetName = function(self, name) self.m_Name = name end,
	GetName = function(self) return self.m_Name end,

	AddSpawnFlags = function(self, flags) self.m_SpawnFlags = bit.bor(self.m_SpawnFlags, flags) end,
	GetSpawnFlags = function(self) return self.m_SpawnFlags end,
}

local SearchList = {
	_initialize = function(self)
		self.Opened = {}
		self.Closed = {}
		self.CostSoFar = {}
		self.TotalCost = {}
		
		self.NumOpened = 0
	end,

	IsOpenListEmpty = function(self)
		return self.NumOpened == 0
	end,
	
	GetCostSoFar = function(self,node)
		return self.CostSoFar[node]
	end,
	
	GetTotalCost = function(self,node)
		return self.TotalCost[node]
	end,
	
	PopOpenList = function(self)
		local node,cost
		
		for k,v in pairs(self.Opened) do
			local c = self.TotalCost[k]
			
			if !cost or c<cost then
				node,cost = k,c
			end
		end
		
		self.Opened[node] = nil
		self.NumOpened = self.NumOpened-1
		
		return node
	end,
	
	AddToClosedList = function(self,node)
		self.Closed[node] = true
	end,
	
	IsOpen = function(self,node)
		return self.Opened[node]==true
	end,
	
	AddToOpenList = function(self,node)
		self.Opened[node] = true
		self.NumOpened = self.NumOpened+1
	end,
	
	IsClosed = function(self,node)
		return self.Closed[node]==true
	end,
	
	SetCostSoFar = function(self,node,cost)
		self.CostSoFar[node] = cost
	end,
	
	SetTotalCost = function(self,node,cost)
		self.TotalCost[node] = cost
	end,
	
	RemoveFromClosedList = function(self,node)
		self.Closed[node] = nil
	end,
}

local PathFollower = {
	_initialize = function(self)
		self.Segments = {}
		self.NumSegments = 0
		
		self.Start = Vector()
		self.Goal = Vector()
		self.Length = 0
		self.Tolerance = 25
		self.MinLook = -1
		self.ComputeTime = 0
		
		self.Valid = false
		
		self.AvoidTimer = 0
		self.AvoidCheck = false
		self.AvoidLeftClear = true
		self.AvoidRightClear = true
		self.AvoidHullMin = Vector()
		self.AvoidHullMax = Vector()
		self.AvoidLeftFrom = Vector()
		self.AvoidLeftTo = Vector()
		self.AvoidRightFrom = Vector()
		self.AvoidRightTo = Vector()
	end,
	
	_Astar = function(self, start, goal, botdata)
		local from = GetNearestNode(start, botdata.center)
		local to = GetNearestNode(goal, goal + (botdata.center - botdata.pos))
		
		if !from or !to then return false end
		
		if from == to then
			self:_ConstructTrivial(start, goal, from)
			
			return true
		end
		
		local bot = self.m_Bot
		local nodes = {}
		nodes[from] = "start"
		
		local list = NewObject({__index = SearchList})
		list:_initialize()
		
		list:AddToOpenList(from)
		list:SetCostSoFar(from,0)
		list:SetTotalCost(from,from:GetOrigin():Distance(to:GetOrigin()))
		
		while !list:IsOpenListEmpty() do
			local node = list:PopOpenList()
			
			if node == to then
				return self:_Construct(nodes, from, to, start, goal, botdata)
			end
			
			list:AddToClosedList(node)
			
			for i=0,node:_NumLinks()-1 do
				local link = node:_GetLink(i)
				
				if bit.band(link.m_info,bits_LINK_OFF)!=0 then
					local dlink = link.dlink
					
					if !dlink or !dlink:IsValid() or dlink:GetStrAllowUse()=="" then
						continue
					end
					
					local allowuse = dlink:GetStrAllowUse()
					
					if dlink:GetInvertAllow() then
						if NameMatch(allowuse, bot:GetName()) or NameMatch(allowuse, bot:GetClass()) then
							continue
						end
					else
						if !NameMatch(allowuse, bot:GetName()) and !NameMatch(allowuse, bot:GetClass()) then
							continue
						end
					end
				end

				local neighbor = link:DestNode(node)
				
				local curcap, duck = GetLinkCapabilities(link, node, neighbor, botdata)
				if curcap == 0 then continue end
				
				local cost = PathCostGenerator(self, node, neighbor, curcap)
				if cost < 0 then continue end
				
				local newcost = list:GetCostSoFar(node) + cost
				
				if !list:IsClosed(neighbor) or newcost < list:GetCostSoFar(neighbor) then
					list:SetCostSoFar(neighbor, newcost)
					list:SetTotalCost(neighbor, newcost + neighbor:GetOrigin():Distance(to:GetOrigin()))
					
					if !list:IsOpen(neighbor) then
						list:AddToOpenList(neighbor)
					end
					
					if list:IsClosed(neighbor) then
						list:RemoveFromClosedList(neighbor)
					end
					
					nodes[neighbor] = node
				end
			end
		end
		
		return false
	end,
	
	_Construct = function(self, nodes, from, to, start, goal, botdata)
		local sequence = {}
		local curnode = to
		
		while nodes[curnode] do
			local prevnode = nodes[curnode]
			local curid = #sequence+1
			
			sequence[curid] = {prevnode:GetOrigin(), curnode:GetOrigin(), prevnode, curnode, GetCapBetweenNodes(prevnode, curnode, botdata)}
			
			if curnode == to then
				local cap, duck = GetCapForOutsideSegment(goal, prevnode, curnode, true, botdata)

				if !cap then
					sequence[curid][2] = goal
					sequence[curid][4] = nil
				else
					sequence[curid+1] = sequence[curid]
					
					sequence[curid] = {curnode:GetOrigin(), goal, curnode, nil, cap, duck}
					curid = curid + 1
				end
			end
			
			if prevnode == from then
				local cap, duck = GetCapForOutsideSegment(start, prevnode, curnode, false, botdata)

				if !cap then
					sequence[curid][1] = start
				else
					sequence[curid+1] = {start, prevnode:GetOrigin(), nil, prevnode, cap, duck}
				end
				
				break
			end
			
			curnode = prevnode
		end
		
		self.Segments = {}
		self.NumSegments = 0
		self.Length = 0
		
		curnode = from
		local prevsegment
		
		for i=#sequence,1,-1 do
			local data = sequence[i]
			
			local curnode = data[3] or data[4]
			local movetype = TranslateCapToPathSegmentType(data[5], data[6], data[1], data[2])
			
			prevsegment = self:_InsertSegment(data[1], data[2], curnode, movetype, prevsegment)
		end
		
		self.CurSegmentID = 0
		self.CurSegment = self.Segments[0]
		self.Valid = true
		
		self:ResetAge()
		
		return true
	end,
	
	_BuildPath = function(self, bot)
		self.m_Bot = bot

		local botdata = {
			pos = bot:GetPos(),
			center = bot:WorldSpaceCenter(),
			cap = bot:CapabilitiesGet(),
			hull = bot:GetHullType(),
			duckhull = bot:GetDuckHullType(),
			mask = bot:GetSolidMask(),
			step = bot.loco:GetStepHeight(),
			bounds = {Vector(bot.CollisionBounds[1]), Vector(bot.CollisionBounds[2])},
			cbounds = {Vector(bot.CrouchCollisionBounds[1]), Vector(bot.CrouchCollisionBounds[2])},
			deathdrop = bot.loco:GetDeathDropHeight(),
			ladder = bot.m_Ladder,
			filter = bot:GetChildren(),
		}
		botdata.filter[#botdata.filter + 1] = bot
		
		local trivial, duckonly = TrivialPathCheck(self.Start, self.Goal, botdata, bot.PathGoalToleranceFinal, true)
		if trivial then
			self:_ConstructTrivial(self.Start, self.Goal, GetNearestNode(self.Start, botdata.center), duckonly)
			
			return true
		end
		
		return self:_Astar(self.Start, self.Goal, botdata)
	end,
	
	_ConstructTrivial = function(self, startpos, endpos, node, duckonly)
		self.Segments = {}
		self.NumSegments = 0
		self.Length = 0
		
		self:_InsertSegment(startpos,endpos,node,duckonly and PATH_SEGMENT_MOVETYPE_CROUCHING or PATH_SEGMENT_MOVETYPE_GROUND)
		
		self.CurSegmentID = 0
		self.CurSegment = self.Segments[0]
		self.Valid = true
		
		self:ResetAge()
	end,
	
	_InsertSegment = function(self,startpos,endpos,node,movetype,prevsegment)
		local dir = endpos-startpos
		local length = dir:Length()
		dir:Normalize()
	
		local segment = {
			area = node,
			pos = endpos,
			length = length,
			forward = dir,
			type = movetype,
			curvature = 0,
		}

		if movetype == PATH_SEGMENT_MOVETYPE_GROUND or movetype == PATH_SEGMENT_MOVETYPE_CROUCHING then
			local yaw = math.atan2(dir.x, -dir.y)

			if yaw >= -45 && yaw < 45 then
				segment.how = GO_NORTH
			elseif yaw >= 45 && yaw < 135 then
				segment.how = GO_EAST
			elseif yaw >= 135 || yaw < -135 then
				segment.how = GO_SOUTH
			elseif yaw >= -135 && yaw < -45 then
				segment.how = GO_WEST
			end
		elseif movetype == PATH_SEGMENT_MOVETYPE_JUMPING or movetype == PATH_SEGMENT_MOVETYPE_JUMPINGGAP then
			segment.how = GO_JUMP
		elseif movetype == PATH_SEGMENT_MOVETYPE_LADDERUP then
			segment.how = GO_LADDER_UP
		elseif movetype == PATH_SEGMENT_MOVETYPE_LADDERDOWN then
			segment.how = GO_LADDER_DOWN
		end
		
		if prevsegment then
			prevsegment.curvature = math.acos(dir:Dot(prevsegment.forward))/math.pi
		end
		
		self.Segments[self.NumSegments] = segment
		self.NumSegments = self.NumSegments+1
		
		self.Length = self.Length+length
		
		return segment
	end,
	
	_Avoid = function(self,bot,goalpos,forward,left)
		if CurTime()<self.AvoidTimer then return goalpos end
		
		local avoidInterval = 0.25
		
		self.AvoidTimer = CurTime()+avoidInterval
		self.AvoidCheck = true
		
		local bounds = bot.CrouchCollisionBounds
		local bmin,bmax = bounds[1],bounds[2]
		
		local curpos = bot:GetPos()
		local scale = bot:GetModelScale()
		local mask = bot:GetSolidMask()
		local step = bot.loco:GetStepHeight()
		
		local range = 30*scale
		local size = (bmax.x-bmin.x)/4
		local offset = size+2
		
		self.AvoidHullMin = Vector(-size,-size,step)
		self.AvoidHullMax = Vector(size,size,bmax.z)
		
		local filter = bot:GetChildren()
		filter[#filter+1] = bot
		
		local door
		
		self.AvoidLeftFrom = curpos+left*offset
		self.AvoidLeftTo = self.AvoidLeftFrom+forward*range
		
		self.AvoidLeftClear = true
		local leftavoid = 0
		
		local result = util.TraceHull({start = self.AvoidLeftFrom,endpos = self.AvoidLeftTo,mins = self.AvoidHullMin,maxs = self.AvoidHullMax,mask = mask,filter = filter})
		if result.Fraction<1 or result.StartSolid then
			if result.StartSolid then
				result.Fraction = 0
			end
			
			leftavoid = 1-result.Fraction
			self.AvoidLeftClear = false
			
			if !result.HitWorld and (result.Entity:GetClass():StartWith("func_door") or result.Entity:GetClass():StartWith("prop_door")) then
				door = result.Entity
			end
		end
		
		self.AvoidRightFrom = curpos-left*offset
		self.AvoidRightTo = self.AvoidRightFrom+forward*range
		
		self.AvoidRightClear = true
		local rightavoid = 0
		
		local result = util.TraceHull({start = self.AvoidRightFrom,endpos = self.AvoidRightTo,mins = self.AvoidHullMin,maxs = self.AvoidHullMax,mask = mask,filter = filter})
		if result.Fraction<1 or result.StartSolid then
			if result.StartSolid then
				result.Fraction = 0
			end
			
			rightavoid = 1-result.Fraction
			self.AvoidRightClear = false
			
			if !door and !result.HitWorld and (result.Entity:GetClass():StartWith("func_door") or result.Entity:GetClass():StartWith("prop_door")) then
				door = result.Entity
			end
		end
		
		local newgoal = Vector(goalpos)
		
		if door and !self.AvoidLeftClear and !self.AvoidRightClear then
			local pos = door:GetPos()
			local ang = door:GetAngles()
			
			local right = ang:Right()
			local width = 100
			local edge = pos-right*width
			
			if sb_anb_nodegraph_pathdebug:GetBool() then
				debugoverlay.Axis(pos,ang,20,10,true)
				debugoverlay.Line(pos,edge,10,Color(255,255,0),true)
			end
			
			newgoal.x = edge.x
			newgoal.y = edge.y
			
			self.AvoidTimer = CurTime()
		elseif !self.AvoidLeftClear or !self.AvoidRightClear then
			local avoidval = 0
			
			if self.AvoidLeftClear then
				avoidval = -rightavoid
			elseif self.AvoidRightClear then
				avoidval = leftavoid
			else
				local equalTolerance = 0.01
				local diff = math.abs(rightavoid-leftavoid)
				
				if diff<equalTolerance then
					return newgoal
				elseif rightavoid>leftavoid then
					avoidval = -rightavoid
				else
					avoidval = leftavoid
				end
			end
			
			local dir = forward*0.25-left*avoidval
			dir:Normalize()
			
			newgoal = curpos+dir*100
			
			self.AvoidTimer = CurTime()
		end
		
		return newgoal
	end,
	
	_GetNumSegments = function(self)
		return self.NumSegments
	end,
	
	_GetNumSegment = function(self,num)
		return self.Segments[num]
	end,

	_UpdateSegment = function(self)
		self.CurSegmentID = self.CurSegmentID + 1
		self.CurSegment = self.Segments[self.CurSegmentID]

		if !self.CurSegment then
			self:Invalidate()
		end
	end,
	
	Compute = function(self,bot,to,customgen)
		self.Start = bot:GetPos()
		self.Goal = Vector(to)
		
		self.Valid = false
		self.m_customcostgen = customgen
		
		return self:_BuildPath(bot)
	end,
	
	FirstSegment = function(self)
		if !self:IsValid() then return end
	
		return self:_GetNumSegment(0)
	end,
	
	GetAge = function(self)
		return CurTime()-self.ComputeTime
	end,
	
	GetAllSegments = function(self)
		if !self:IsValid() then return end
		
		local t = {}
		
		for i=0,self:_GetNumSegments()-1 do
			t[i+1] = table.Copy(self:_GetNumSegment(i))
		end
		
		return t
	end,
	
	GetCurrentGoal = function(self)
		if !self:IsValid() then return end
		
		return table.Copy(self.CurSegment)
	end,
	
	GetEnd = function(self)
		return Vector(self.Goal)
	end,
	
	GetGoalTolerance = function(self)
		return self.Tolerance
	end,
	
	GetLength = function(self)
		return self.Length
	end,
	
	GetMinLookAheadDistance = function(self)
		return self.MinLook
	end,
	
	GetStart = function(self)
		return Vector(self.Start)
	end,
	
	Invalidate = function(self)
		self.Valid = false
	end,
	
	IsValid = function(self)
		return self.Valid
	end,
	
	LastSegment = function(self)
		if !self:IsValid() then return end
	
		return self:_GetNumSegment(self:_GetNumSegments()-1)
	end,

	PriorSegment = function(self)
		if !self:IsValid() then return end

		return self:_GetNumSegment(self.CurSegmentID - 1)
	end,

	NextSegment = function(self)
		if !self:IsValid() then return end

		return self:_GetNumSegment(self.CurSegmentID + 1)
	end,
	
	ResetAge = function(self)
		self.ComputeTime = CurTime()
	end,
	
	SetGoalTolerance = function(self,tolerance)
		self.Tolerance = tolerance
	end,
	
	SetMinLookAheadDistance = function(self,minlook)
		self.MinLook = minlook
	end,
	
	Update = function(self,bot)
		if !self:IsValid() then return end
	
		local curpos = bot:GetPos()
		local dist = self:GetGoalTolerance()
		
		local goal = self.CurSegment
		local goalpos = goal.pos
		
		if !bot.m_Ladder && math.Distance(curpos.x,curpos.y,goalpos.x,goalpos.y)<=dist then
			self:_UpdateSegment()
			if !self:IsValid() then return end
			
			goal = self.CurSegment
			goalpos = goal.pos
		end

		if bot.m_Ladder and goal.how != GO_LADDER_UP and goal.how != GO_LADDER_DOWN then
			local next = self:NextSegment()

			if next and (next.how == GO_LADDER_UP or next.how == GO_LADDER_DOWN) then
				self:_UpdateSegment()
				return self:Update(bot)
			else
				bot:DetachFromLadder()
			end
		end
		
		if goal.how == GO_LADDER_UP or goal.how == GO_LADDER_DOWN then
			if !bot.m_Ladder then
				if Either(goal.how == GO_LADDER_UP, curpos.z >= goalpos.z - bot.StepHeight, curpos.z <= goalpos.z + bot.StepHeight) then
					self:_UpdateSegment()
					return self:Update(bot)
				else
					local prev = self.Segments[self.CurSegmentID - 1]
					local bottom = goal.how == GO_LADDER_UP and prev or goal
					local top = goal.how == GO_LADDER_UP and goal or prev
					
					local yaw = math.rad(bottom.area:GetYaw())
					local normal = -Vector(math.cos(yaw), math.sin(yaw), 0)

					local mins, maxs = Vector(-1, -1, -1), Vector(1, 1, 1)
					local width = bot:GetHullWidth() / 2
					local tr = util.TraceHull({start = bottom.pos, endpos = bottom.pos + normal * width, mask = MASK_NPCSOLID_BRUSHONLY, mins = mins, maxs = maxs + top.pos - bottom.pos})
					local offset = vector_origin

					if tr.StartSolid and !tr.AllSolid then
						offset = normal * width * tr.FractionLeftSolid
					end

					bot:AttachToLadder({bottom = bottom.pos + offset, top = top.pos + offset, normal = normal})
					bot:Approach(curpos + Vector(0, 0, goal.how == GO_LADDER_UP and 1 or -1))
				end
			else
				bot:Approach(curpos + Vector(0, 0, goal.how == GO_LADDER_UP and 1 or -1))
			end
		elseif goal.type == PATH_SEGMENT_MOVETYPE_GROUND or goal.type == PATH_SEGMENT_MOVETYPE_CROUCHING then
			if sb_anb_nodegraph_trivialcheck:GetBool() and (!self.GroundAhead or CurTime() > self.GroundAhead) then
				self.GroundAhead = CurTime() + 0.5

				while true do
					local next = self.Segments[self.CurSegmentID + 1]

					if next and next.type == goal.type then
						local bounds = goal.type == PATH_SEGMENT_MOVETYPE_CROUCHING and bot.CrouchCollisionBounds or bot.CollisionBounds
						local trivial, duck = TrivialPathCheck(curpos, next.pos, {
							cbounds = bot.CrouchCollisionBounds,
							bounds = bot.CollisionBounds,
							mask = MASK_NPCSOLID_BRUSHONLY,
							step = bot.loco:GetStepHeight(),
						})

						if trivial then
							self:_UpdateSegment()
							if !self:IsValid() then return end
							
							goal = self.CurSegment
							goalpos = goal.pos
						else
							break
						end
					else
						break
					end
				end
			end

			local forward = goalpos-curpos
			forward.z = 0
			
			local range = forward:Length()
			forward:Normalize()
			
			local left = Vector(-forward.y,forward.x,0)
			local nearRange = 50 + bot:GetHullWidth() / 2
			
			if range>nearRange then
				goalpos = self:_Avoid(bot,goalpos,forward,left)
			end
			
			bot:Approach(goalpos)
		elseif goal.how == GO_JUMP then
			if bot.loco:IsOnGround() then
				local result = bot:CalcJumpHeightOverObstacles(goalpos)
				
				if isnumber(result) then
					bot:JumpToPos(goalpos, result)
				elseif result == true then
					local dir = curpos - goalpos
					dir.z = 0
					dir:Normalize()

					bot:Approach(curpos + dir * 100)
				else
					// We failed to calc jump height, don't move to prevent stuck or something
				end
			end
		end
		
		if sb_anb_nodegraph_pathdebug:GetBool() then
			debugoverlay.Cross(goalpos,5,0.1,Color(150,150,255),true)
			debugoverlay.Line(bot:WorldSpaceCenter(),goalpos,0.1,Color(255,255,0),true)
		end
	end,
	
	Draw = function(self)
		if self:IsValid() then
			if self.AvoidCheck then
				self.AvoidCheck = false
				
				if self.AvoidLeftClear then
					debugoverlay.SweptBox(self.AvoidLeftFrom,self.AvoidLeftTo,self.AvoidHullMin,self.AvoidHullMax,angle_zero,0.1,Color(0,255,0))
				else
					debugoverlay.SweptBox(self.AvoidLeftFrom,self.AvoidLeftTo,self.AvoidHullMin,self.AvoidHullMax,angle_zero,0.1,Color(255,0,0))
				end

				if self.AvoidRightClear then
					debugoverlay.SweptBox(self.AvoidRightFrom,self.AvoidRightTo,self.AvoidHullMin,self.AvoidHullMax,angle_zero,0.1,Color(0,255,0))
				else
					debugoverlay.SweptBox(self.AvoidRightFrom,self.AvoidRightTo,self.AvoidHullMin,self.AvoidHullMax,angle_zero,0.1,Color(255,0,0))
				end
			end
			
			debugoverlay.Sphere(self.CurSegment.pos,5,0.1,Color(255,255,0),true)
			
			if self.CurSegmentID>0 then
				local prev = self.Segments[self.CurSegmentID-1]
				
				debugoverlay.Line(prev.pos,self.CurSegment.pos,0.1,Color(255,255,0),true)
			end
			
			local lastpos = self.Start
			
			for i=0,self.NumSegments-1 do
				local cur = self.Segments[i]
				local curpos = cur.pos

				local to = curpos - lastpos
				local horiz = math.max(math.abs(to.x), math.abs(to.y))
				local vert = math.abs(to.z)
				
				local r,g,b = 255,77,0
				
				if cur.type==PATH_SEGMENT_MOVETYPE_CROUCHING then
					r,g,b = 255,0,255
				elseif cur.type==PATH_SEGMENT_MOVETYPE_JUMPING then
					r,g,b = 0,0,255
				elseif cur.type==PATH_SEGMENT_MOVETYPE_JUMPINGGAP then
					r,g,b = 0,255,255
				elseif cur.type==PATH_SEGMENT_MOVETYPE_LADDERUP then
					r,g,b = 0,255,0
				elseif cur.type==PATH_SEGMENT_MOVETYPE_LADDERDOWN then
					r,g,b = 0,100,0
				end
				
				local color = Color(r,g,b)

				if cur.how == GO_LADDER_UP or cur.how == GO_LADDER_DOWN then
					debugoverlay_VertArrow(lastpos, curpos, 5, 0.1, color, true)
				else
					debugoverlay.Line(lastpos, curpos, 0.1, color, true)
				end
				
				local nodeLength = 25
				local nodePos = lastpos + cur.forward * nodeLength

				if horiz > vert then
					debugoverlay_HorzArrow(lastpos, nodePos, 5, 0.1, color, true)
				else
					debugoverlay_VertArrow(lastpos, nodePos, 5, 0.1, color, true)
				end

				debugoverlay.Text(cur.pos, i, 0.1, true)
				
				lastpos = curpos
			end
		end
	end,
}

local SBNodeGraphPathFollower = {
	__index = PathFollower,
	__tostring = function(self)
		return "SBNodeGraphPathFollower"
	end,
}
debug.getregistry().SBNodeGraphPathFollower = SBNodeGraphPathFollower

local function new_Node(index,origin,yaw)
	local node = NewObject(SBNodeGraphNode)
	node:_initialize(index,origin,yaw)
	
	return node
end

local function new_Link()
	local link = NewObject({__index = CAI_Link})
	link:_initialize()
	
	return link
end

local function new_DynamicLink(dlink)
	local link = NewObject({__index = CAI_DynamicLink})
	link.dlink = dlink
	link:_initialize()
	
	return link
end

local function new_Hint(hint, nodeid)
	local _hint = NewObject({__index = CAI_Hint})
	_hint.hint = hint
	_hint.nodeid = nodeid
	_hint:_initialize()
	
	return _hint
end

local function CreateNode(origin,yaw)
	if NodeNum>=MAX_NODES then
		DevMsg("ERROR: too many nodes in map, deleting last node.\n")

		Nodes[NodeNum]:_Remove()
	end
	
	local node = new_Node(NodeNum,origin,yaw)
	Nodes[NodeNum] = node
	NodeNum = NodeNum+1

	return node
end

local function CreateLink(src,dest)
	if src==dest then DevMsg("CreateLink: Attempted to link a node to itself") return end
	if src:_NumLinks()>=AI_MAX_NODE_LINKS then DevMsg("CreateLink: Node "..src:GetID().." has too many links") return end
	if dest:_NumLinks()>=AI_MAX_NODE_LINKS then DevMsg("CreateLink: Node "..dest:GetID().." has too many links") return end
	
	local link = new_Link()
	
	link.src = src
	link.dest = dest
	
	src:_AddLink(link)
	dest:_AddLink(link)
	
	local center = (src:GetOrigin() + dest:GetOrigin()) / 2
	NodesLinks[src:GetID() .. "_" .. dest:GetID()] = {src:GetID(), dest:GetID(), center, src:GetOrigin():DistToSqr(center)}
	
	return link
end

local function CreateHint(hint, nodeid)
	local _hint = new_Hint(hint, nodeid)

	_hint:SetName(hint:GetName())
	_hint:SetOrigin(hint:GetPos())

	Hints[#Hints + 1] = _hint

	return _hint
end

function Load()
	local filename = "maps/graphs/"..game.GetMap()..".ain"
	
	DevMsg("Loading NodeGraph from "..filename.." ...\n")
	
	local f = file.Open(filename,"rb","GAME")
	
	if !f then
		DevMsg("Couldn't read "..filename.."!\n")
		return false
	end
	
	if f:Read(3)=="Ver" then
		DevMsg("AI node graph "..filename.." is out of date (old structure)\n")
		
		f:Close()
		return false
	end
	
	DevMsg("Passed first ver check\n")
	
	f:Seek(0)
	
	local aiver = f:ReadLong()
	DevMsg("Got version "..aiver.."\n")
	
	if aiver!=AINET_VERSION_NUMBER then
		DevMsg("AI node graph "..filename.." is out of date\n")
		
		f:Close()
		return false
	end
	
	local mapversion = game.GetMapVersion()
	local mapver = f:ReadLong()
	DevMsg("Map version "..mapver.."\n")
	
	if mapver!=mapversion/* and !GetConVar("g_ai_norebuildgraph"):GetBool()*/ then
		DevMsg("AI node graph "..filename.." is out of date (map version changed)\n")
		
		--[[ f:Close()
		return false ]]
	end
	
	DevMsg("Done version checks\n")
	
	local numNodes = f:ReadLong()
	
	if numNodes<0 or numNodes>MAX_NODES then
		DevMsg("AI node graph "..filename.." is corrupt (numNodes: "..numNodes..")\n")
		
		f:Close()
		return false
	end
	
	DevMsg("Finishing load\n")
	
	for i=0,NodeNum-1 do
		Nodes[i]:_Remove()
	end
	
	Nodes,NodeNum = {},0
	
	for i=1,numNodes do
		local origin = Vector()
		origin.x = f:ReadFloat()
		origin.y = f:ReadFloat()
		origin.z = f:ReadFloat()
		
		local yaw = f:ReadFloat()
		
		local node = CreateNode(origin,yaw)
		
		for j=0,NUM_HULLS-1 do
			node.m_voffset[j] = f:ReadFloat()
		end
		
		node.m_type = f:ReadByte()
		node.m_info = f:ReadUShort()
		node.m_zone = f:ReadShort()
	end
	
	local numLinks = f:ReadLong()
	
	for i=1,numLinks do
		local src = Nodes[f:ReadShort()]
		local dest = Nodes[f:ReadShort()]
		
		local link = CreateLink(src,dest)
		local movetypes = link and link.m_AcceptedMoveTypes or {}
		
		for j=0,NUM_HULLS-1 do
			movetypes[j] = f:ReadByte()
		end
	end
	
	EditOps,EditOpsInvert = {},{}
	
	for i=0,numNodes-1 do
		local wcid = f:ReadLong()
		
		EditOps[i] = wcid
		EditOpsInvert[wcid] = i

		Nodes[i]:_InitPosition()
	end
	
	local dlinks = 0
	DynamicLinks = {}
	
	for k,v in ipairs(ents.FindByClass("info_node_link")) do
		local dlink = new_DynamicLink(v)
		
		if dlink.m_SrcID==NO_NODE then
			DevMsg("Dynamic link source WC node "..dlink.m_SrcEditID.." not found\n")
			DynamicLinks[dlink] = nil
			
			continue
		end
		
		if dlink.m_DestID==NO_NODE then
			DevMsg("Dynamic link dest WC node "..dlink.m_DestEditID.." not found\n")
			DynamicLinks[dlink] = nil
			
			continue
		end
		
		if bit.band(v:GetSpawnFlags(),bits_HULL_BITS_MASK)!=0 then
			local link = dlink:FindLink()
			
			if !link then
				local srcnode = Nodes[dlink.m_SrcID]
				local destnode = Nodes[dlink.m_DestID]
				
				if srcnode and destnode then
					link = CreateLink(srcnode,destnode,movetypes)
					
					if !link then
						DevMsg("Failed to create dynamic link ("..dlink.m_SrcEditID.." <--> "..dlink.m_DestEditID..")\n")
					end
				end
			end
			
			if link then
				link.dlink = dlink
			
				local hullbits = bit.band(v:GetSpawnFlags(),bits_HULL_BITS_MASK)
				
				for i=0,NUM_HULLS-1 do
					if bit.band(hullbits,bit.lshift(1,i))!=0 then
						link.m_AcceptedMoveTypes[i] = dlink.m_LinkType
					end
				end
			end
		end
		
		dlink:SetLinkState()
		dlinks = dlinks+1
	end
	
	DevMsg("NodeGraph loaded successfully. Nodes: "..numNodes..", Links: "..numLinks..", Dynamic Links: "..dlinks.."\n")
	
	f:Close()
	
	return true
end

function GetAllNodes()
	local t = {}
	
	for i=0,NodeNum-1 do
		t[i+1] = Nodes[i]
	end
	
	return t
end

function GetNodesCount()
	return NodeNum
end

local DistToSqr = debug.getregistry().Vector.DistToSqr
local DistanceToLine = util.DistanceToLine

local VisibilityCheck = function(start, endpos, mask)
	local tr = util.TraceLine({start = start, endpos = endpos, mask = mask or MASK_NPCSOLID_BRUSHONLY})
	if !tr.Hit then return true end

	local dist = start:Distance(endpos)
	local trdist = start:Distance(tr.HitPos)

	return dist - trdist < 5
end

function GetNearestNode(pos, visiblepos, mask)
	local curnode,curdist
	
	if sb_anb_nodegraph_accurategetnearestnode:GetBool() then
		local used = {}
	
		for k,v in pairs(NodesLinks) do
			if istable(v) then
				if DistToSqr(pos,v[3])>v[4] then continue end
				
				local start,endpos = NodesPos[v[1]],NodesPos[v[2]]
				local dist,nearpos = DistanceToLine(start,endpos,pos)
				
				if !curdist or dist*dist<curdist then
					local newnode = DistToSqr(nearpos,start)<DistToSqr(nearpos,endpos) and
					(!visiblepos or VisibilityCheck(visiblepos, start, mask)) and Nodes[v[1]] or
					(!visiblepos or VisibilityCheck(visiblepos, endpos, mask)) and Nodes[v[2]]

					if newnode then
						curnode = newnode
						curdist = dist*dist    
					end
				end
			else
				local dist = DistToSqr(pos,v)
			
				if (!curdist or dist<curdist) and (!visiblepos or VisibilityCheck(visiblepos, v, mask)) then
					curnode,curdist = Nodes[k],dist
				end
			end
		end
	else
		for i=0,NodeNum-1 do
			local dist = DistToSqr(pos,NodesPos[i])
			
			if (!curdist or dist<curdist) and (!visiblepos or VisibilityCheck(visiblepos, NodesPos[i], mask)) then
				curnode,curdist = Nodes[i],dist
			end
		end
	end
	
	return curnode
end

function GetNodeByID(id)
	return Nodes[id]
end

function GetEditOps()
	local t = {}
	
	for i=1,#EditOps do
		t[i] = EditOps[i]
	end
	
	return t
end

function Path()
	local path = NewObject(SBNodeGraphPathFollower)
	path:_initialize()
	
	return path
end

hook.Add("Think","sb_anb_nodegraph_dlinks",function()
	for link,_ in pairs(DynamicLinks) do
		if !link:IsValid() then
			DynamicLinks[link] = nil
		else
			link:UpdateState()
		end
	end
end)

timer.Create("sb_anb_nodegraph_drawnodes",1,0,function()
	local drawtype = sb_anb_nodegraph_drawnodes:GetInt()
	if drawtype<=0 then return end
	
	local hull = math.Clamp(sb_anb_nodegraph_drawnodes_hull:GetInt(),HULL_HUMAN,NUM_HULLS-1)
	
	local mins = Vector(-5,-5,-5)
	local maxs = Vector(5,5,5)
	
	for i=0,NodeNum-1 do
		local node = Nodes[i]
		local origin = node:GetOrigin()
		
		local r,g,b = 255,0,0
		
		if node:GetType()==NODE_ANY then
			r,g,b = 255,255,255
		elseif node:GetType()==NODE_DELETED then
			r,g,b = 100,100,100
		elseif node:GetType()==NODE_GROUND then
			r,g,b = 0,255,100
		elseif node:GetType()==NODE_AIR then
			r,g,b = 0,255,255
		elseif node:GetType()==NODE_CLIMB then
			r,g,b = 255,0,255
		elseif node:GetType()==NODE_WATER then
			r,g,b = 0,0,255
		end
		
		debugoverlay.Box(origin,mins,maxs,1.5,Color(r,g,b,0))

		if node:GetType()==NODE_CLIMB then 
			local offset = 12 * Vector(math.cos(math.rad(node:GetYaw())), math.sin(math.rad(node:GetYaw())), 3)
			debugoverlay.Line(origin, origin + offset, 1.5, Color(r,g,b,0))
		end
		
		if drawtype>1 then
			debugoverlay.Text(node:GetOrigin()+Vector(0,0,1),node:GetID().."(WC: "..EditOps[node:GetID()]..")",1.5,true)
		end
		
		for j=0,node:_NumLinks()-1 do
			local link = node:_GetLink(j)
			local dest = link:DestNode()
			if dest==node then dest = link:SrcNode() end
			
			if dest:GetID()<node:GetID() then continue end
			
			local movetype = link.m_AcceptedMoveTypes[hull]
			local linkinfo = link.m_info
			
			r,g,b = 255,0,0
			
			if bit.band(linkinfo,bits_LINK_STALE_SUGGESTED)!=0 then
				r,g,b = 255,0,0
			elseif bit.band(linkinfo,bits_LINK_OFF)!=0 then
				r,g,b = 100,100,100
			elseif bit.band(movetype,CAP_MOVE_FLY)!=0 then
				r,g,b = 100,255,255
			elseif bit.band(movetype,CAP_MOVE_CLIMB)!=0 then
				r,g,b = 255,0,255
			elseif bit.band(movetype,CAP_MOVE_GROUND)!=0 then
				r,g,b = 0,255,50
			elseif bit.band(movetype,CAP_MOVE_JUMP)!=0 then
				r,g,b = 0,0,255
			else
				local fly = node:GetType()==NODE_AIR or dest:GetType()==NODE_AIR
				local jump = true
				
				for k=HULL_HUMAN,NUM_HULLS-1 do
					if bit.band(link.m_AcceptedMoveTypes[k],bit.bnot(CAP_MOVE_JUMP))!=0 then
						jump = false
						break
					end
				end
				
				if fly or jump then
					r,g,b = 100,25,25
				end
			end
			
			if node:GetType()==NODE_GROUND && dest:GetType()==NODE_GROUND then
				debugoverlay.Line(node:GetOrigin()+vector_up,dest:GetOrigin()+vector_up,1.5,Color(r,g,b),false)
			else
				debugoverlay.Line(node:GetOrigin(),dest:GetOrigin(),1.5,Color(r,g,b),false)
			end
		end
	end
end)

local HintNodeCount = 0
local HintClasses = {
	info_hint = true,
	info_node = true,
	info_node_hint = true,
	info_node_air = true,
	info_node_air_hint = true,
	info_node_climb = true,
}

hook.Add("Initialize", "sb_anb_nodegraph_hints", function()
	hook.Add("OnEntityCreated", "sb_anb_nodegraph_hints", function(ent)
		local class = ent:GetClass()
		if !HintClasses[class] then return end

		if class == "info_hint" then
			if ent:GetInternalVariable("hinttype") != 0 then
				CreateHint(ent, NO_NODE)
			end

			return
		end

		local hint

		if class == "info_node_hint" || class == "info_node_air_hint" then
			if ent:GetInternalVariable("hinttype") != 0 || ent:GetInternalVariable("Group") != "" || ent:GetName() != "" then
				hint = CreateHint(ent, HintNodeCount)
				hint:AddSpawnFlags(ent:GetSpawnFlags())

				print(ent)
				PrintTable(ent:GetSaveTable(true))
			end
		end

		HintNodeCount = HintNodeCount + 1
	end)
end)

hook.Add("PostInitEntity", "sb_anb_nodegraph_hints", function()
	hook.Remove("OnEntityCreated", "sb_anb_nodegraph_hints")
end)