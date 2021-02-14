#include "Shared.h"
#include "CAI_Classes.h"

using namespace GarrysMod::Lua;

extern ILuaBase* CurLUA;
extern int NodeClass_Type;
extern CAI_Node** Nodes;

Vector CAI_Node::GetOrigin() { return m_origin; }
float CAI_Node::GetYaw() { return m_yaw; }
char CAI_Node::GetType() { return m_type; }
unsigned short CAI_Node::GetInfo() { return m_info; }
short CAI_Node::GetZone() { return m_zone; }
int CAI_Node::GetID() { return m_id; }
int CAI_Node::NumLinks() { return m_NumLinks; }

CAI_Node::CAI_Node() {
	m_origin = Vector();
	m_yaw = 0;
	m_id = -1;

	SetupNew();
}

CAI_Node::CAI_Node(int id, Vector& origin, float yaw) {
	m_origin = origin;
	m_yaw = yaw;
	m_id = id;

	SetupNew();
}

void CAI_Node::SetupNew() {
	m_voffset = new float[NUM_HULLS];

	for (int i = 0; i < NUM_HULLS; i++) {
		m_voffset[i] = 0;
	}

	m_links = new CAI_Link*[AI_MAX_NODE_LINKS];
	m_NumLinks = 0;

	m_type = NODE_GROUND;
	m_zone = AI_NODE_ZONE_UNKNOWN;
	m_info = 0;
}

CAI_Node::~CAI_Node() {
	delete[] m_voffset;

	for (int i = 0; i < NumLinks(); i++) {
		delete m_links[i];
	}

	delete[] m_links;
}

void CAI_Node::AddLink(CAI_Link* link){
	if (NumLinks()==AI_MAX_NODE_LINKS){
		ThrowFormatError("AddLink: Node %d has too many links",GetID());
	}
	
	m_links[m_NumLinks++] = link;
}

CAI_Link* CAI_Node::GetLink(const int num) {
	return m_links[num];
}

CAI_Node* CAI_Link::DestNode() {
	return Nodes[m_destID];
}
CAI_Node* CAI_Link::SrcNode() {
	return Nodes[m_srcID];
}

int CAI_Link::DestNodeID() { return m_destID; }

CAI_Link::CAI_Link(){
	m_srcID = -1;
	m_destID = -1;
	m_info = 0;
	
	m_AcceptedMoveTypes = new int[NUM_HULLS];
	
	for (int i = 0; i<NUM_HULLS; i++){
		m_AcceptedMoveTypes[i] = 0;
	}
}

CAI_Link::~CAI_Link(){
	delete [] m_AcceptedMoveTypes;
}

CreateLuaFunction(NodeMeta_GetOrigin){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1,NodeClass_Type);
	CurLUA->PushVector(node->GetOrigin());

	return 1;
}

CreateLuaFunction(NodeMeta_GetYaw){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CurLUA->PushNumber(node->GetYaw());

	return 1;
}

CreateLuaFunction(NodeMeta_GetType){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CurLUA->PushNumber(node->GetType());

	return 1;
}

CreateLuaFunction(NodeMeta_GetInfo){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CurLUA->PushNumber(node->GetInfo());

	return 1;
}

CreateLuaFunction(NodeMeta_GetZone){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CurLUA->PushNumber(node->GetZone());

	return 1;
}

CreateLuaFunction(NodeMeta_GetID){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CurLUA->PushNumber(node->GetID());

	return 1;
}

CreateLuaFunction(NodeMeta_GetAdjacentNodes){
	CurLUA->CheckType(1, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CurLUA->CreateTable();

	for (int i = 0; i < node->NumLinks(); i++) {
		CAI_Link* link = node->GetLink(i);
		CAI_Node* neighbor = link->DestNode();

		CurLUA->PushNumber(i + 1);
		CurLUA->PushUserType(neighbor, NodeClass_Type);
		CurLUA->SetTable(-3);
	}

	return 1;
}

CreateLuaFunction(NodeMeta_GetAcceptedMoveTypes){
	CurLUA->CheckType(1, NodeClass_Type);
	CurLUA->CheckType(2, NodeClass_Type);

	CAI_Node* node = CurLUA->GetUserType<CAI_Node>(1, NodeClass_Type);
	CAI_Node* neighbor = CurLUA->GetUserType<CAI_Node>(2, NodeClass_Type);

	for (int i = 0; i < node->NumLinks(); i++) {
		CAI_Link* link = node->GetLink(i);

		if (link->DestNode() == neighbor) {
			LUA->CreateTable();

			for (int j = 0; j < NUM_HULLS; j++) {
				LUA->PushNumber(j + 1);
				LUA->PushNumber(link->m_AcceptedMoveTypes[j]);
				LUA->SetTable(-3);
			}

			return 1;
		}
	}

	return 0;
}

void CAI_Node::CreateLuaFunctions() {
	CurLUA->PushCFunction(NodeMeta_GetOrigin);
	CurLUA->SetField(-2, "GetOrigin");

	CurLUA->PushCFunction(NodeMeta_GetYaw);
	CurLUA->SetField(-2, "GetYaw");

	CurLUA->PushCFunction(NodeMeta_GetType);
	CurLUA->SetField(-2, "GetType");

	CurLUA->PushCFunction(NodeMeta_GetZone);
	CurLUA->SetField(-2, "GetZone");

	CurLUA->PushCFunction(NodeMeta_GetID);
	CurLUA->SetField(-2, "GetID");

	CurLUA->PushCFunction(NodeMeta_GetAdjacentNodes);
	CurLUA->SetField(-2, "GetAdjacentNodes");

	CurLUA->PushCFunction(NodeMeta_GetAcceptedMoveTypes);
	CurLUA->SetField(-2, "GetAcceptedMoveTypes");
}