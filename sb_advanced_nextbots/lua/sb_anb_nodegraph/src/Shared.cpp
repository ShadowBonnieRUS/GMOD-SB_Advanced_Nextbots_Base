#include "Shared.h"

extern ILuaBase* CurLUA;

void Msg(const char* msg) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "Msg");
	CurLUA->PushString(MODULE_NAME);
	CurLUA->PushString(": ");
	CurLUA->PushString(msg);
	CurLUA->Call(3, 0);
	CurLUA->Pop();
}

void Msg(char sym) {
	const char str[2]{ sym,'\0' };

	Msg(str);
}

void Msg(bool b) {
	Msg(b ? "true" : "false");
}

Vector VecMul(const Vector& vec1, const Vector& vec2) {
	Vector vec;
	vec.x = vec1.x * vec2.x;
	vec.y = vec1.y * vec2.y;
	vec.z = vec1.z * vec2.z;

	return vec;
}

Vector VecMul(const Vector& vec1, const float mul) {
	Vector vec;
	vec.x = vec1.x * mul;
	vec.y = vec1.y * mul;
	vec.z = vec1.z * mul;

	return vec;
}

Vector VecDiv(const Vector& vec1, const Vector& vec2) {
	Vector vec;
	vec.x = vec1.x / vec2.x;
	vec.y = vec1.y / vec2.y;
	vec.z = vec1.z / vec2.z;

	return vec;
}

Vector VecDiv(const Vector& vec1, const float mul) {
	Vector vec;
	vec.x = vec1.x / mul;
	vec.y = vec1.y / mul;
	vec.z = vec1.z / mul;

	return vec;
}

Vector VecAdd(const Vector& vec1, const Vector& vec2) {
	Vector vec;
	vec.x = vec1.x + vec2.x;
	vec.y = vec1.y + vec2.y;
	vec.z = vec1.z + vec2.z;

	return vec;
}

Vector VecInv(const Vector& vec1) {
	Vector vec;
	vec.x = -vec1.x;
	vec.y = -vec1.y;
	vec.z = -vec1.z;

	return vec;
}

float VecLen(const Vector& vec) {
	return (float)pow(vec.x * vec.x + vec.y * vec.y + vec.z * vec.z, 0.5f);
}

float VecLenSqr(const Vector& vec) {
	return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z;
}

float VecDistance(const Vector& vec1, const Vector& vec2) {
	Vector diff;
	diff.x = vec1.x - vec2.x;
	diff.y = vec1.y - vec2.y;
	diff.z = vec1.z - vec2.z;

	return VecLen(diff);
}

float VecDist2D(const Vector& vec1, const Vector& vec2) {
	Vector diff;
	diff.x = vec1.x - vec2.x;
	diff.y = vec1.y - vec2.y;
	diff.z = 0;

	return VecLen(diff);
}

float VecDistSqr(const Vector& vec1, const Vector& vec2) {
	Vector diff;
	diff.x = vec1.x - vec2.x;
	diff.y = vec1.y - vec2.y;
	diff.z = vec1.z - vec2.z;

	return VecLenSqr(diff);
}

float VecNormalize(Vector& vec) {
	float len = VecLen(vec);
	if (len <= 0.000001) return 0;

	vec.x /= len;
	vec.y /= len;
	vec.z /= len;

	return len;
}

Vector vector(float x, float y, float z) {
	Vector vec;
	vec.x = x, vec.y = y, vec.z = z;

	return vec;
}

QAngle angle(float p, float y, float r) {
	QAngle ang;
	ang.x = p, ang.y = y, ang.z = r;

	return ang;
}

void AngleDirs(const QAngle& ang, Vector& forward, Vector& right, Vector& up) {
	CurLUA->PushAngle(ang);

	CurLUA->GetField(-1, "Forward");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	forward = CurLUA->GetVector(-1);

	CurLUA->Pop();
	
	CurLUA->GetField(-1, "Right");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	right = CurLUA->GetVector(-1);

	CurLUA->Pop();

	CurLUA->GetField(-1, "Up");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	up = CurLUA->GetVector(-1);

	CurLUA->Pop();

	CurLUA->Pop();
}

float CurTime() {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1,"CurTime");
	CurLUA->Call(0, 1);
	float time = (float)CurLUA->GetNumber(-1);
	CurLUA->Pop(2);

	return time;
}

bool IsConVarActive(const char* convar) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "GetConVar");
	CurLUA->PushString(convar);
	CurLUA->Call(1, 1);
	CurLUA->GetField(-1, "GetBool");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	bool result = CurLUA->GetBool(-1);

	CurLUA->Pop(3);

	return result;
}

int GetConVarInt(const char* convar) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "GetConVar");
	CurLUA->PushString(convar);
	CurLUA->Call(1, 1);
	CurLUA->GetField(-1, "GetInt");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int result = (int)CurLUA->GetNumber(-1);

	CurLUA->Pop(3);

	return result;
}

int strlen(const char* str) {
	int len = 0;

	while (str[len] != '\0') len++;

	return len;
}

void stradd(char* str, const char* src) {
	int len = strlen(str);
	int len2 = strlen(src);

	for (int i = 0; i < len2; i++) str[len + i] = src[i];
}

void strcpy(char* str, const char* src) {
	int i = 0;
	while (src[i] != '\0') str[i] = src[i++];
	str[i] = '\0';
}

extern int NodeNum;
extern CAI_Node** Nodes;

CAI_Node* GetNearestNode(const Vector& pos) {
	CAI_Node* curnode = nullptr;
	float curdist = -1;

	if (IsConVarActive("sb_anb_nodegraph_accurategetnearestnode")) {
		CurLUA->PushSpecial(SPECIAL_GLOB);
		CurLUA->GetField(-1, "util");

		bool** used = new bool*[NodeNum]{};

		for (int i = 0; i < NodeNum; i++) {
			used[i] = new bool[NodeNum]{};
		}

		for (int nodeid = 0; nodeid < NodeNum; nodeid++) {
			CAI_Node* node = Nodes[nodeid];
			Vector startpos = node->GetOrigin();

			if (node->NumLinks()) {
				for (int linkid = 0; linkid < node->NumLinks(); linkid++) {
					CAI_Link* link = node->GetLink(linkid);
					if (used[link->DestNodeID()][nodeid]) continue;

					used[nodeid][link->DestNodeID()] = true;

					CAI_Node* dest = link->DestNode();
					Vector endpos = dest->GetOrigin();

					CurLUA->GetField(-1, "DistanceToLine");
					CurLUA->PushVector(startpos);
					CurLUA->PushVector(endpos);
					CurLUA->PushVector(pos);
					CurLUA->Call(3, 2);

					float dist = (float)CurLUA->GetNumber(-2);
					Vector nearpos = CurLUA->GetVector(-1);

					CurLUA->Pop(2);

					if (curdist == -1 || dist*dist < curdist) {
						curdist = dist*dist;
						curnode = (VecDistSqr(startpos, nearpos) < VecDistSqr(nearpos, endpos)) ? node : dest;
					}
				}
			} else {
				float dist = VecDistSqr(startpos, pos);

				if (curdist == -1 || dist < curdist) {
					curdist = dist;
					curnode = node;
				}
			}
		}

		CurLUA->Pop(2);

		for (int i = 0; i < NodeNum; i++) {
			delete[] used[i];
		}

		delete[] used;
	} else {
		for (int nodeid = 0; nodeid < NodeNum; nodeid++) {
			CAI_Node* node = Nodes[nodeid];
			Vector startpos = node->GetOrigin();

			float dist = VecDistSqr(startpos, pos);

			if (curdist == -1 || dist < curdist) {
				curdist = dist;
				curnode = node;
			}
		}
	}

	return curnode;
}

int GetNodesCap(CAI_Node* node1, CAI_Node* node2, const int hull) {
	for (int i = 0; i < node1->NumLinks(); i++) {
		CAI_Link* link = node1->GetLink(i);

		if (link->DestNode() == node2) {
			return link->m_AcceptedMoveTypes[hull];
		}
	}
}

int GetNodesCap(CAI_Node* node1, const int node2, const int hull) {
	for (int i = 0; i < node1->NumLinks(); i++) {
		CAI_Link* link = node1->GetLink(i);

		if (link->DestNodeID() == node2) {
			return link->m_AcceptedMoveTypes[hull];
		}
	}

	return CAP_MOVE_GROUND;
}