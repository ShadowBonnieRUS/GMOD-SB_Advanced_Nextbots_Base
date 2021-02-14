#include "Shared.h"
#include "GMOD_NodeGraph.h"
#include "CAI_Classes.h"
#include "PathFollower.h"
#include "NDebugOverlay.h"

using namespace GarrysMod::Lua;

ILuaBase* CurLUA;
int NodeClass_Type;
int NodeGraphPathFollower_Type;
CAI_Node** Nodes;
int NodeNum;

char mapname[MAX_PATH];
int mapversion;
int* EditOps;

void Close(){
	CurLUA->GetField(-1,"Close");
	CurLUA->Push(-2);
	CurLUA->Call(1,0);
	CurLUA->Pop();
}

void Seek(double num){
	CurLUA->GetField(-1,"Seek");
	CurLUA->Push(-2);
	CurLUA->PushNumber(num);
	CurLUA->Call(2,0);
}

char ReadChar(){
	CurLUA->GetField(-1,"Read");
	CurLUA->Push(-2);
	CurLUA->PushNumber(1);
	CurLUA->Call(2,1);
	char value = *CurLUA->GetString();
	CurLUA->Pop();
	
	return value;
}

int ReadInt(){
	CurLUA->GetField(-1,"ReadLong");
	CurLUA->Push(-2);
	CurLUA->Call(1,1);
	int value = (int)CurLUA->GetNumber();
	CurLUA->Pop();
	
	return value;
}

short ReadShort(){
	CurLUA->GetField(-1,"ReadShort");
	CurLUA->Push(-2);
	CurLUA->Call(1,1);
	short value = (short)CurLUA->GetNumber();
	CurLUA->Pop();
	
	return value;
}

unsigned short ReadUShort(){
	CurLUA->GetField(-1,"ReadUShort");
	CurLUA->Push(-2);
	CurLUA->Call(1,1);
	unsigned short value = (unsigned short)CurLUA->GetNumber();
	CurLUA->Pop();
	
	return value;
}

float ReadFloat(){
	CurLUA->GetField(-1,"ReadFloat");
	CurLUA->Push(-2);
	CurLUA->Call(1,1);
	float value = (float)CurLUA->GetNumber();
	CurLUA->Pop();
	
	return value;
}

char ReadByte(){
	CurLUA->GetField(-1,"ReadByte");
	CurLUA->Push(-2);
	CurLUA->Call(1,1);
	char value = (char)CurLUA->GetNumber();
	CurLUA->Pop();
	
	return value;
}

void CreateLink(int srcID,int destID,int* movetypes){
	CAI_Node* src = Nodes[srcID];
	CAI_Node* dest = Nodes[destID];
	
	if (src->NumLinks()>=AI_MAX_NODE_LINKS){
		ThrowFormatError("CreateLink: Node %i has too many links",srcID);
	}
	
	if (dest->NumLinks()>=AI_MAX_NODE_LINKS){
		ThrowFormatError("CreateLink: Node %i has too many links",destID);
	}
	
	CAI_Link* link1 = new CAI_Link;
	CAI_Link* link2 = new CAI_Link;

	for (int i = 0; i < NUM_HULLS; i++) {
		link1->m_AcceptedMoveTypes[i] = movetypes[i];
		link2->m_AcceptedMoveTypes[i] = movetypes[i];
	}

	link1->m_srcID = srcID;
	link1->m_destID = destID;
	src->AddLink(link1);

	link2->m_srcID = destID;
	link2->m_destID = srcID;
	dest->AddLink(link2);
}

CAI_Node* AddNode(Vector origin, float yaw) {
	if (NodeNum > MAX_NODES) {
		DevMsg("ERROR: too many nodes in map, deleting last node.\n");

		NodeNum--;
	}

	Nodes[NodeNum] = new CAI_Node(NodeNum, origin, yaw);

	return Nodes[NodeNum++];
}

CreateLuaFunction(NodeMetaTable_gc){
	LUA->CheckType(1, NodeClass_Type);
	LUA->SetUserType(1,nullptr);

	return 0;
}

CreateLuaFunction(NodeMetaTable_tostring){
	LUA->CheckType(1, NodeClass_Type);
	
	LUA->PushString("SBNodeGraphNode");

	return 1;
}

void CreateNodeMetaTable() {
	NodeClass_Type = CurLUA->CreateMetaTable(METATABLE_NAME_NODE);

	CurLUA->PushCFunction(NodeMetaTable_gc);
	CurLUA->SetField(-2, "__gc");

	CurLUA->PushCFunction(NodeMetaTable_tostring);
	CurLUA->SetField(-2, "__tostring");

	CurLUA->Push(-1);
	CurLUA->SetField(-2, "__index");

	CAI_Node::CreateLuaFunctions();

	CurLUA->Pop();
}

CreateLuaFunction(PathMetaTable_gc){
	LUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	delete path;

	LUA->SetUserType(1, nullptr);

	return 0;
}

CreateLuaFunction(PathMetaTable_tostring){
	LUA->CheckType(1, NodeGraphPathFollower_Type);

	//std::string str = "SBNodeGraphNode [" + std::to_string() + "]";

	LUA->PushString("SBNodeGraphPathFollower");

	return 1;
}

void CreateNodeGraphPathFollowerMetaTable() {
	NodeGraphPathFollower_Type = CurLUA->CreateMetaTable(METATABLE_NAME_PATHFOLLOWER);

	CurLUA->PushCFunction(PathMetaTable_gc);
	CurLUA->SetField(-2, "__gc");

	CurLUA->PushCFunction(PathMetaTable_tostring);
	CurLUA->SetField(-2, "__tostring");

	CurLUA->Push(-1);
	CurLUA->SetField(-2, "__index");

	NodeGraphPathFollower::CreateLuaFunctions();

	CurLUA->Pop();
}

CreateLuaFunction(BuildNodeGraph){
	char filename[MAX_PATH] = "maps/graphs/";
	stradd(filename, mapname);
	stradd(filename, ".ain");

	DevMsg("Loading NodeGraph from %s ...\n",filename);
	
	LUA->PushSpecial(SPECIAL_GLOB);
	LUA->GetField(-1,"file");
	LUA->GetField(-1,"Open");
	LUA->PushString(filename);
	LUA->PushString("rb");
	LUA->PushString("GAME");
	LUA->Call(3,1);
	
	if (!LUA->IsType(-1,Type::File)){
		ThrowFormatError("Couldn't read %s!\n",filename);
	}
	
	if (ReadChar()=='V' && ReadChar()=='e' && ReadChar()=='r'){
		Close();
		ThrowFormatError("AI node graph %s is out of date\n",filename);
	}
	
	Seek(0);
	
	if (ReadInt()!=AINET_VERSION_NUMBER){
		Close();
		ThrowFormatError("AI node graph %s is out of date\n",filename);
	}
	
	int mapver = ReadInt();
	if (mapver!=mapversion){
		Close();
		ThrowFormatError("AI node graph %s is out of date (map version changed) (map: %i, nodegraph: %i)\n", filename, mapversion, mapver);
	}
	
	int numNodes = ReadInt();
	if (numNodes<0 || numNodes>MAX_NODES){
		Close();
		ThrowFormatError("AI node graph %s is corrupt (numNodes %i)\n", filename, numNodes);
	}
	
	for (int i = 0; i < NodeNum; i++) {
		delete Nodes[i];
	}

	delete[] Nodes;
	Nodes = new CAI_Node* [MAX_NODES];
	NodeNum = 0;
	
	for (int node = 0; node<numNodes; node++){
		Vector origin;
		float yaw;
		
		origin.x = ReadFloat();
		origin.y = ReadFloat();
		origin.z = ReadFloat();
		yaw = ReadFloat();
		
		CAI_Node* Node = AddNode(origin,yaw);
		
		for (int i = 0; i<NUM_HULLS; i++){
			Node->m_voffset[i] = ReadFloat();
		}
		
		Node->m_type = (int)ReadChar();
		Node->m_info = ReadUShort();
		Node->m_zone = ReadShort();
	}
	
	int numLinks = ReadInt();
	
	for (int link = 0; link<numLinks; link++){
		int srcID = ReadShort();
		int destID = ReadShort();
		int* movetypes = new int[NUM_HULLS];

		for (int i = 0; i < NUM_HULLS; i++) {
			movetypes[i] = (int)ReadByte();
		}

		CreateLink(srcID,destID,movetypes);

		delete[] movetypes;
	}
	
	delete[] EditOps;
	EditOps = new int[numNodes];
	
	for (int i = 0; i< numNodes; i++){
		EditOps[i] = ReadInt();
	}
	
	DevMsg("Successfully loaded NodeGraph. Nodes: %i, Links: %i.\n", numNodes, numLinks);

	Close();
	return 0;
}

CreateLuaFunction(GetAllNodes){
	LUA->CreateTable();

	for (int i = 0; i < NodeNum; i++){
		LUA->PushNumber(i + 1);
		LUA->PushUserType(Nodes[i], NodeClass_Type);
		LUA->SetTable(-3);
	}

	return 1;
}

CreateLuaFunction(GetNodesCount){
	LUA->PushNumber(NodeNum);

	return 1;
}

CreateLuaFunction(Path){
	NodeGraphPathFollower* path = new NodeGraphPathFollower;

	LUA->PushUserType(path,NodeGraphPathFollower_Type);

	return 1;
}

CreateLuaFunction(GetNearestNode_lua){
	LUA->CheckType(1,Type::Vector);

	Vector pos = LUA->GetVector(1);

	CAI_Node* node = GetNearestNode(pos);
	if (!node) return 0;

	CurLUA->PushUserType(node, NodeClass_Type);

	return 1;
}

CreateLuaFunction(GetNodeByID){
	LUA->CheckType(1, Type::Number);

	int id = (int)LUA->GetNumber(1);

	if (id < 0 || id >= NodeNum) return 0;

	CAI_Node* node = Nodes[id];

	LUA->PushUserType(node, NodeClass_Type);

	return 1;
}

CreateLuaFunction(DrawNodesTimer){
	int drawtype = GetConVarInt("sb_anb_nodegraph_drawnodes");
	if (!drawtype) return 0;

	int hull = GetConVarInt("sb_anb_nodegraph_drawnodes_hull");
	hull = hull<HULL_HUMAN ? HULL_HUMAN : hull>NUM_HULLS - 1 ? NUM_HULLS - 1 : hull;

	Vector mins = vector(-5, -5, -5);
	Vector maxs = vector(5, 5, 5);

	bool** drawedlines = new bool*[NodeNum];

	for (int i = 0; i < NodeNum; i++) {
		drawedlines[i] = new bool[NodeNum] {};
	}

	for (int i = 0; i < NodeNum; i++) {
		CAI_Node* node = Nodes[i];

		int r, g, b;

		switch (node->GetType()) {
			case NODE_ANY:		r = 255,	g = 255,	b = 255;	break;
			case NODE_DELETED:	r = 100;	g = 100,	b = 100;	break;
			case NODE_GROUND:	r = 0,		g = 255,	b = 100;	break;
			case NODE_AIR:		r = 0,		g = 255,	b = 255;	break;
			case NODE_CLIMB:	r = 255,	g = 0,		b = 255;	break;
			case NODE_WATER:	r = 0,		g = 0,		b = 255;	break;
			default:			r = 255,	g = 0,		b = 0;		break;
		}

		NDebugOverlay::Box(node->GetOrigin(), mins, maxs, r, g, b, 0, 1.5f);

		if (drawtype > 1)
			NDebugOverlay::Text(VecAdd(node->GetOrigin(), vector(0, 0, 1)), node->GetID(), true, 1.5f);

		for (int j = 0; j < node->NumLinks(); j++) {
			CAI_Link* link = node->GetLink(j);
			if (drawedlines[link->DestNodeID()][i]) continue;

			drawedlines[i][link->DestNodeID()] = true;

			CAI_Node* dest = link->DestNode();

			int info = link->m_info;
			int movetype = link->m_AcceptedMoveTypes[hull];

			r = 255, g = 0, b = 0;

			if (movetype & CAP_MOVE_FLY)			r = 100,	g = 255,	b = 255;
			else if (movetype & CAP_MOVE_CLIMB)		r = 255,	g = 0,		b = 255;
			else if (movetype & CAP_MOVE_GROUND)	r = 0,		g = 255,	b = 50;
			else if (movetype & CAP_MOVE_JUMP)		r = 0,		g = 0,		b = 255;
			else {
				bool fly = node->GetType() == NODE_AIR || dest->GetType() == NODE_AIR;
				bool jump = true;

				for (int u = HULL_HUMAN; u < NUM_HULLS; u++) {
					if (link->m_AcceptedMoveTypes[u] & ~CAP_MOVE_JUMP) {
						jump = false;
						break;
					}
				}

				if (fly || jump || fly && jump)
					r = 100, g = 25, b = 25;
			}

			if (node->GetType()==NODE_GROUND && dest->GetType()==NODE_GROUND)
				NDebugOverlay::Line(VecAdd(node->GetOrigin(),vector(0,0,1)), VecAdd(dest->GetOrigin(),vector(0,0,1)), r, g, b, false, 1.5f);
			else
				NDebugOverlay::Line(node->GetOrigin(), dest->GetOrigin(), r, g, b, false, 1.5f);
		}
	}

	for (int i = 0; i < NodeNum; i++) {
		delete[] drawedlines[i];
	}

	delete[] drawedlines;

	return 0;
}

void CreateDrawNodesTimer() {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "timer");
	CurLUA->GetField(-1, "Create");
	CurLUA->PushString("sb_anb_nodegraph_drawnodes");
	CurLUA->PushNumber(1);
	CurLUA->PushNumber(0);
	CurLUA->PushCFunction(DrawNodesTimer);
	CurLUA->Call(4, 0);
	CurLUA->Pop(2);
}

GMOD_MODULE_OPEN(){
	CurLUA = LUA;

	Nodes = new CAI_Node*[MAX_NODES];
	NodeNum = 0;
	
	EditOps = new int [MAX_NODES];
	
	LUA->PushSpecial(SPECIAL_GLOB);
	LUA->GetField(-1,"game");
	LUA->GetField(-1,"GetMap");
	LUA->Call(0,1);
	
	strcpy(mapname, LUA->GetString());
	LUA->Pop();
	
	LUA->GetField(-1,"GetMapVersion");
	LUA->Call(0,1);

	mapversion = (int)LUA->GetNumber();
	LUA->Pop(2);
	
	LUA->CreateTable();
	LUA->SetField(-2, MODULE_NAME);
	LUA->Pop();
	
	ADD_MODULE_FUNCTION("Load",BuildNodeGraph);
	ADD_MODULE_FUNCTION("GetAllNodes", GetAllNodes);
	ADD_MODULE_FUNCTION("GetNodesCount", GetNodesCount);
	ADD_MODULE_FUNCTION("GetNearestNode", GetNearestNode_lua);
	ADD_MODULE_FUNCTION("GetNodeByID", GetNodeByID);
	ADD_MODULE_FUNCTION("Path", Path);

	ADD_MODULE_VARIABLE("NODE_ANY", Number, NODE_ANY);
	ADD_MODULE_VARIABLE("NODE_DELETED", Number, NODE_DELETED);
	ADD_MODULE_VARIABLE("NODE_GROUND", Number, NODE_GROUND);
	ADD_MODULE_VARIABLE("NODE_AIR", Number, NODE_AIR);
	ADD_MODULE_VARIABLE("NODE_CLIMB", Number, NODE_CLIMB);
	ADD_MODULE_VARIABLE("NODE_WATER", Number, NODE_WATER);

	ADD_MODULE_VARIABLE("AI_NODE_ZONE_UNKNOWN", Number, AI_NODE_ZONE_UNKNOWN);
	ADD_MODULE_VARIABLE("AI_NODE_ZONE_SOLO", Number, AI_NODE_ZONE_SOLO);
	ADD_MODULE_VARIABLE("AI_NODE_ZONE_UNIVERSAL", Number, AI_NODE_ZONE_UNIVERSAL);
	ADD_MODULE_VARIABLE("AI_NODE_FIRST_ZONE", Number, AI_NODE_FIRST_ZONE);

	ADD_MODULE_CONVAR("sb_anb_nodegraph_drawnodes", "0");
	ADD_MODULE_CONVAR("sb_anb_nodegraph_drawnodes_hull", "0");
	ADD_MODULE_CONVAR("sb_anb_nodegraph_pathdebug", "0");
	ADD_MODULE_CONVAR("sb_anb_nodegraph_accurategetnearestnode", "0");

	CreateNodeMetaTable();
	CreateNodeGraphPathFollowerMetaTable();

	CreateDrawNodesTimer();

	DevMsg("%s module loaded.\n", MODULE_NAME);

	return 0;
}

GMOD_MODULE_CLOSE(){
	CurLUA = LUA;

	for (int i = 0; i < NodeNum; i++) {
		delete Nodes[i];
	}

	delete [] Nodes;
	delete [] EditOps;

	return 0;
}