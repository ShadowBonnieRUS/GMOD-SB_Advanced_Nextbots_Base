#include "Shared.h"
#include "CAI_Classes.h"
#include "PathFollower.h"
#include "NDebugOverlay.h"
#include <math.h>

using namespace GarrysMod::Lua;

extern ILuaBase* CurLUA;
extern CAI_Node** Nodes;
extern int NodeGraphPathFollower_Type;
extern int NodeClass_Type;
extern int NodeNum;

#define MAX_SEGMENTS 128

static bool luagenerator = false;
static double PathCostGenerator(NodeGraphPathFollower* self, CAI_Node* area, CAI_Node* from,const int cap) {
	if (luagenerator) {
		CurLUA->Push(4);
		CurLUA->PushUserType(area, NodeClass_Type);

		if (from)
			CurLUA->PushUserType(from, NodeClass_Type);
		else
			CurLUA->PushNil();

		CurLUA->PushNumber(cap);

		if (CurLUA->PCall(3, 1, 0)) {
			DevMsg("Skipping node due to cost generator error\n");
			return -1.0;
		}

		double cost = CurLUA->IsType(-1, Type::Number) ? CurLUA->GetNumber() : -1;
		CurLUA->Pop();

		return cost;
	}

	if (from == nullptr)
		return 0.0;

	double cost = VecDistance(area->GetOrigin(), from->GetOrigin());

	float z = area->GetOrigin().z - from->GetOrigin().z;

	if (z < 0 && (cap & (CAP_MOVE_GROUND | CAP_MOVE_JUMP))) {
		float maxh = self->GetDeathDropHeight();
		float h = -z;

		if (h > maxh) {
#define PI 3.14159265f

			float dist = VecDist2D(area->GetOrigin(), from->GetOrigin());
			float ang = (float)atan(h / dist) / PI * 180.0f;

			if (ang > 60)
				return -1.0;
		}
	}

	if (cap & CAP_MOVE_JUMP) {
		float maxh = self->GetMaxJumpHeight();

		if (maxh >= 0 && z > maxh)
			return -1.0;

		return cost * 5.0;
	} else if (cap & (CAP_MOVE_GROUND | CAP_MOVE_FLY))
		return cost;

	return cost * 10.0;
}

inline int TranslateCapToPathSegmentType(const int cap) {
	if (cap & CAP_MOVE_JUMP)
		return PATH_SEGMENT_MOVETYPE_JUMPING;

	return PATH_SEGMENT_MOVETYPE_GROUND;
}

NodeGraphPathFollower::NodeGraphPathFollower() {
	Segments = new PathSegment*[MAX_SEGMENTS];

	for (int i = 0; i < MAX_SEGMENTS; i++) {
		Segments[i] = new PathSegment;
	}
}

NodeGraphPathFollower::~NodeGraphPathFollower() {
	for (int i = 0; i < MAX_SEGMENTS; i++) {
		delete Segments[i];
	}

	delete[] Segments;
}

bool NodeGraphPathFollower::Compute(NextBot* bot,const Vector& to) {
	Start = bot->GetPos();
	Goal = to;
	SetDeathDropHeight(bot->GetDeathDropHeight());

	Valid = false;

	return BuildPath(bot);
}

bool NodeGraphPathFollower::BuildPath(NextBot* bot) {
	int cap = bot->CapabilitiesGet();
	int hull = bot->GetHullType();
	int mask = bot->GetSolidMask();
	float step = bot->GetStepHeight();

	Vector mins = vector(0,0,0), maxs = vector(0,0,0);
	bot->GetCrouchCollisionBounds(&mins, &maxs);
	mins.z += step;

	TraceFilter_table filter(bot);

	if (TrivialPathCheck(Start, Goal, mask, mins, maxs, step, filter)) {
		ConstructTrivial(Start, Goal, GetNearestNode(Start));

		return true;
	}

	return Astar(Start, Goal, hull, cap);
}

bool NodeGraphPathFollower::TrivialPathCheck(const Vector& start, const Vector& goal, const int mask, const Vector& mins, const Vector& maxs, const float height,TraceFilter& filter) {
	TraceResult result;

	Vector dir = VecAdd(goal, VecInv(start));
	float len = VecLen(dir);
	float step = maxs.x - mins.x;

	if (len > step * 15) return false;

	dir = VecDiv(dir, len);
	float tlen = len - GetGoalTolerance();

	TraceHull(start, VecAdd(start,VecMul(dir, tlen <0 ? 0 : tlen)), mins, maxs, mask, filter, result);

	if (result.fraction < 1.0f) return false;

	for (float i = step; i < len; i += step*1.5f) {
		Vector pos = VecAdd(start, VecMul(dir, i));
		TraceHull(pos, VecAdd(pos, vector(0,0,-height)), mins, maxs, mask, filter, result);

		if (result.fraction >= 1.0f) return false;
	}

	return true;
}

PathSegment& NodeGraphPathFollower::FirstSegment() {
	return *Segments[0];
}

float NodeGraphPathFollower::GetAge() {
	return CurTime() - ComputeTime;
}

int NodeGraphPathFollower::GetNumSegments() {
	return NumSegments;
}

PathSegment& NodeGraphPathFollower::GetNumSegment(int num) {
	return *Segments[num];
}

PathSegment& NodeGraphPathFollower::GetCurrentGoal() {
	return *CurSegment;
}

Vector NodeGraphPathFollower::GetEnd() {
	return Goal;
}

int NodeGraphPathFollower::GetGoalTolerance() {
	return Tolerance;
}

double NodeGraphPathFollower::GetLength() {
	return Len;
}

int NodeGraphPathFollower::GetMinLookAheadDistance() {
	return MinLook;
}

Vector NodeGraphPathFollower::GetStart() {
	return Start;
}

void NodeGraphPathFollower::Invalidate() {
	Valid = false;
}

bool NodeGraphPathFollower::IsValid() {
	return Valid;
}

PathSegment& NodeGraphPathFollower::LastSegment() {
	return *Segments[NumSegments - 1];
}

void NodeGraphPathFollower::ResetAge() {
	ComputeTime = CurTime();
}

void NodeGraphPathFollower::SetGoalTolerance(int tolerance) {
	Tolerance = tolerance;
}

void NodeGraphPathFollower::SetMinLookAheadDistance(int minlook) {
	MinLook = minlook;
}

void NodeGraphPathFollower::Update(NextBot* bot) {
	Vector curpos = bot->GetPos();

	bool last = CurSegmentID == NumSegments - 1;
	int dist = !last && GetMinLookAheadDistance()!=-1 ? GetMinLookAheadDistance() : GetGoalTolerance();
	PathSegment& goal = GetCurrentGoal();
	Vector goalpos = goal.pos;

	if (VecDist2D(curpos, goalpos) <= dist) {
		if (last) {
			Invalidate();
			return;
		}

		CurSegmentID++;
		CurSegment = Segments[CurSegmentID];
	}

	if (goal.type == PATH_SEGMENT_MOVETYPE_GROUND) {
		Vector forward = VecAdd(goalpos, VecInv(curpos));
		forward.z = 0.0f;
		double range = VecNormalize(forward);

		Vector left = vector(-forward.y, forward.x, 0.0f);

		const float nearRange = 50.0f;
		if (range > nearRange)
			goalpos = Avoid(bot, goalpos, forward, left);

		bot->Approach(goalpos);
	} else if (goal.type == PATH_SEGMENT_MOVETYPE_JUMPING) {
		if (bot->IsOnGround()) {
			//Vector prevpos = CurSegmentID == 0 ? Start : Segments[CurSegmentID - 1]->pos;

			//if (VecDistance(curpos, prevpos) > dist)
			//	bot->Approach(prevpos);
			//else
				bot->JumpToPos(goalpos);
		}
	}

	if (IsConVarActive("sb_anb_nodegraph_pathdebug")) {
		NDebugOverlay::Cross3D(goalpos, 5.0f, 150, 150, 255, true, 0.1f);
		NDebugOverlay::Line(bot->WorldSpaceCenter(), goalpos, 255, 255, 0, true, 0.1f);
	}
}

bool NodeGraphPathFollower::Astar(const Vector& start,const Vector& goal,const int hull, const int cap) {
	CAI_Node* from = GetNearestNode(start);
	CAI_Node* to = GetNearestNode(goal);

	if (from == nullptr || to == nullptr)
		return false;

	if (from == to) {
		ConstructTrivial(start,goal,from);

		return true;
	}

	int nodes[MAX_NODES];
	nodes[from->GetID()] = -1;

	PathSearchList SearchList;

	SearchList.AddToOpenList(from->GetID());
	SearchList.SetCostSoFar(from->GetID(), 0);
	SearchList.SetTotalCost(from->GetID(), PathCostGenerator(this, from, nullptr, cap));

	while (!SearchList.IsOpenListEmpty()) {
		int curid = SearchList.PopOpenList();
		CAI_Node* cur = Nodes[curid];

		if (cur == to) {
			return Construct(nodes, from, to, start, goal, hull);
		}

		SearchList.AddToClosedList(curid);

		for (int i = 0; i < cur->NumLinks(); i++) {
			CAI_Link* link = cur->GetLink(i);
			int curcap = link->m_AcceptedMoveTypes[hull];

			if (!(curcap & cap)) continue;

			CAI_Node* neighbor = link->DestNode();
			int nid = neighbor->GetID();

			double dist = PathCostGenerator(this, neighbor, cur, curcap);
			if (dist < 0)
				continue;

			double newcost = SearchList.GetCostSoFar(curid) + dist;

			if (!SearchList.IsClosed(nid) || newcost < SearchList.GetCostSoFar(nid)) {
				SearchList.SetCostSoFar(nid,newcost);
				SearchList.SetTotalCost(nid, newcost + PathCostGenerator(this, neighbor, to, curcap));

				if (SearchList.IsClosed(nid)) {
					SearchList.RemoveFromClosedList(nid);
				}

				if (!SearchList.IsOpen(nid)) {
					SearchList.AddToOpenList(nid);
				}

				nodes[nid] = curid;
			}
		}
	}

	return false;
}

bool NodeGraphPathFollower::Construct(const int* nodes, CAI_Node* from, CAI_Node* to,const Vector& start,const Vector& goal,const int hull) {
	int cid = to->GetID();
	int sequence[MAX_SEGMENTS]{};
	int seqsize = 0;

	int ltype = PATH_SEGMENT_MOVETYPE_GROUND;
	int ftype = PATH_SEGMENT_MOVETYPE_GROUND;

	if (cid == to->GetID() && VecDistSqr(goal, Nodes[nodes[cid]]->GetOrigin()) < VecDistSqr(Nodes[nodes[cid]]->GetOrigin(), Nodes[cid]->GetOrigin()))
		ltype = TranslateCapToPathSegmentType(GetNodesCap(Nodes[cid], nodes[cid], hull));
	else
		sequence[seqsize++] = cid;

	while (nodes[cid]!=-1) {
		int fid = nodes[cid];

		if (nodes[fid] == -1 && VecDistSqr(start, Nodes[cid]->GetOrigin()) < VecDistSqr(Nodes[fid]->GetOrigin(), Nodes[cid]->GetOrigin())) {
			ftype = TranslateCapToPathSegmentType(GetNodesCap(Nodes[cid], fid, hull));
			break;
		}

		sequence[seqsize++] = fid;

		if (seqsize >= MAX_SEGMENTS) {
			return false;
		}

		cid = fid;
	}

	NumSegments = 0;
	Len = 0;

	CAI_Node* cur = Nodes[cid];

	InsertSegment(start, cur->GetOrigin(), cur, ftype);

	for (int i = seqsize - 1; i >= 0; i--) {
		int id = sequence[i];
		CAI_Node* node = Nodes[id];

		InsertSegment(cur->GetOrigin(),node->GetOrigin(), node, TranslateCapToPathSegmentType(GetNodesCap(cur, id, hull)));

		cur = node;
	}

	InsertSegment(cur->GetOrigin(), goal, cur, ltype);

	CurSegmentID = 0;
	CurSegment = Segments[0];
	Valid = true;
	
	ResetAge();

	return true;
}

void NodeGraphPathFollower::ConstructTrivial(const Vector& startpos, const Vector& endpos, CAI_Node* node) {
	NumSegments = 0;
	Len = 0;

	InsertSegment(startpos, endpos, node, PATH_SEGMENT_MOVETYPE_GROUND);

	CurSegmentID = 0;
	CurSegment = Segments[0];
	Valid = true;

	ResetAge();
}

void NodeGraphPathFollower::InsertSegment(const Vector& startpos, const Vector& endpos, CAI_Node* node,const int movetype) {
	PathSegment* segment = Segments[NumSegments++];

	float length = VecDistance(startpos, endpos);
	Vector forward = VecAdd(endpos, VecInv(startpos));
	VecNormalize(forward);

	segment->area = node;
	segment->pos = endpos;
	segment->length = length;
	segment->forward = forward;
	segment->type = movetype;

	Len += length;
}

Vector NodeGraphPathFollower::Avoid(NextBot* bot, const Vector& goalpos, const Vector& forward, const Vector& left) {
	const float avoidInterval = 0.25f;
	float CT = CurTime();

	if (CT < AvoidTimer)
		return goalpos;

	AvoidTimer = CT+avoidInterval;
	AvoidCheck = true;

	Vector bmin, bmax;
	bot->GetCrouchCollisionBounds(&bmin, &bmax);

	const Vector curpos = bot->GetPos();
	const float scale = bot->GetModelScale();
	const int mask = bot->GetSolidMask();
	const float step = bot->GetStepHeight();

	const float range = 30.0f * scale;
	const float size = (bmax.x - bmin.x) / 4.0f;
	const float offset = size + 2.0f;

	AvoidHullMin = vector(-size, -size, step);
	AvoidHullMax = vector(size, size, bmax.z);

	TraceFilter_table filter(bot);
	
	Entity* filterents[1024];
	int count = bot->GetChildren(filterents, 1024);

	for (int i = 0; i < count; i++) {
		filter + filterents[i];
	}

	TraceResult result;
	Entity* door = nullptr;

	AvoidLeftFrom = VecAdd(curpos, VecMul(left, offset));
	AvoidLeftTo = VecAdd(AvoidLeftFrom, VecMul(forward, range));

	AvoidLeftClear = true;
	float leftavoid = 0.0f;

	TraceHull(AvoidLeftFrom, AvoidLeftTo, AvoidHullMin, AvoidHullMax, mask, filter, result);
	if (result.fraction < 1 || result.startsolid) {
		if (result.startsolid)
			result.fraction = 0;

		leftavoid = 1.0f - result.fraction;

		AvoidLeftClear = false;

		if (!result.hitworld && (result.Entity->IsClass("func_door*") || result.Entity->IsClass("prop_door*")))
			door = result.Entity;
	}

	AvoidRightFrom = VecAdd(curpos, VecMul(VecInv(left), offset));
	AvoidRightTo = VecAdd(AvoidRightFrom, VecMul(forward, range));

	AvoidRightClear = true;
	float rightavoid = 0.0f;

	TraceHull(AvoidRightFrom, AvoidRightTo, AvoidHullMin, AvoidHullMax, mask, filter, result);
	if (result.fraction < 1 || result.startsolid) {
		if (result.startsolid)
			result.fraction = 0;

		rightavoid = 1.0f - result.fraction;

		AvoidRightClear = false;

		if (!door && !result.hitworld && (result.Entity->IsClass("func_door*") || result.Entity->IsClass("prop_door*")))
			door = result.Entity;
	}

	Vector newgoal = goalpos;

	if (door && !AvoidLeftClear && !AvoidRightClear) {
		const Vector pos = door->GetPos();
		const QAngle ang = door->GetAngles();

		Vector fward, right, up;
		AngleDirs(ang, fward, right, up);

		const float width = 100.0f;

		const Vector edge = VecAdd(pos, VecMul(VecInv(right), width));

		if (IsConVarActive("sb_anb_nodegraph_pathdebug")) {
			NDebugOverlay::Axis(pos, ang, 20.0f, true, 10.0f);
			NDebugOverlay::Line(pos, edge, 255, 255, 0, true, 10.0f);
		}

		newgoal.x = edge.x;
		newgoal.y = edge.y;

		AvoidTimer = CT;
	} else if (!AvoidLeftClear || !AvoidRightClear) {
		float avoidval = 0.0f;

		if (AvoidLeftClear) {
			avoidval = -rightavoid;
		} else if (AvoidRightClear) {
			avoidval = leftavoid;
		} else {
			const float equalTolerance = 0.01f;
			float diff = rightavoid - leftavoid;
			diff = diff < 0.0f ? -diff : diff;

			if (diff < equalTolerance) {
				return newgoal;
			} else if (rightavoid > leftavoid) {
				avoidval = -rightavoid;
			} else {
				avoidval = leftavoid;
			}
		}

		Vector dir = VecAdd(VecMul(forward, 0.5f), VecMul(VecInv(left), avoidval));
		VecNormalize(dir);

		newgoal = VecAdd(curpos,VecMul(dir,100.0f));

		AvoidTimer = CT;
	}

	return newgoal;
}

void NodeGraphPathFollower::Draw() {
	if (IsValid()) {
		if (AvoidCheck) {
			AvoidCheck = false;

			QAngle angles = angle(0,0,0);

			if (AvoidLeftClear) 
				NDebugOverlay::SweptBox(AvoidLeftFrom, AvoidLeftTo, AvoidHullMin, AvoidHullMax, angles, 0, 255, 0, 255, 0.1f);
			else
				NDebugOverlay::SweptBox(AvoidLeftFrom, AvoidLeftTo, AvoidHullMin, AvoidHullMax, angles, 255, 0, 0, 255, 0.1f);

			if (AvoidRightClear)
				NDebugOverlay::SweptBox(AvoidRightFrom, AvoidRightTo, AvoidHullMin, AvoidHullMax, angles, 0, 255, 0, 255, 0.1f);
			else
				NDebugOverlay::SweptBox(AvoidRightFrom, AvoidRightTo, AvoidHullMin, AvoidHullMax, angles, 255, 0, 0, 255, 0.1f);
		}

		NDebugOverlay::Sphere(GetCurrentGoal().pos, 5.0f, 255, 255, 0, true, 0.1f);

		if (CurSegmentID >= 1) {
			PathSegment* prev = Segments[CurSegmentID - 1];

			NDebugOverlay::Line(prev->pos, GetCurrentGoal().pos, 255, 255, 0, true, 0.1f);
		}

		Vector lastpos = Start;

		for (int i = 0; i < GetNumSegments(); i++) {
			PathSegment& cur = GetNumSegment(i);
			Vector& curpos = cur.pos;

			int r, g, b;

			switch (cur.type) {
				case PATH_SEGMENT_MOVETYPE_FALLINGDOWN:	r = 255;	g = 0;		b = 255;	break;
				case PATH_SEGMENT_MOVETYPE_JUMPING:		r = 0;		g = 0;		b = 255;	break;
				case PATH_SEGMENT_MOVETYPE_JUMPINGGAP:	r = 0;		g = 255;	b = 255;	break;
				case PATH_SEGMENT_MOVETYPE_LADDERDOWN:	r = 0;		g = 255;	b = 0;		break;
				case PATH_SEGMENT_MOVETYPE_LADDERUP:	r = 0;		g = 100;	b = 0;		break;
				default:								r = 255;	g = 77;		b = 0;		break;
			}

			NDebugOverlay::Line(lastpos, curpos, r, g, b, true, 0.1f);

			const float arrowlen = 25.0f;
			Vector endpos;
			endpos.x = lastpos.x + cur.forward.x * arrowlen;
			endpos.y = lastpos.y + cur.forward.y * arrowlen;
			endpos.z = lastpos.z + cur.forward.z * arrowlen;

			NDebugOverlay::HorzArrow(lastpos, endpos, 5.0f, r, g, b, 255, true, 0.1f);
			NDebugOverlay::Text(cur.pos, i, true, 0.1f);

			lastpos = curpos;
		}
	}
}

void NodeGraphPathFollower::SetMaxJumpHeight(const float height) {
	MaxJumpHeight = height;
}

float NodeGraphPathFollower::GetMaxJumpHeight() {
	return MaxJumpHeight;
}

void NodeGraphPathFollower::SetDeathDropHeight(const float height) {
	DeathDropHeight = height;
}

float NodeGraphPathFollower::GetDeathDropHeight() {
	return DeathDropHeight;
}

PathSearchList::PathSearchList() {
	for (int i = 0; i < MAX_NODES; i++) {
		Opened[i] = false;
		Closed[i] = false;
		CostSoFar[i] = 0;
		TotalCost[i] = 0;
	}
}

PathSearchList::~PathSearchList() {}

bool PathSearchList::IsOpenListEmpty() {
	return NumOpened == 0;
}

double PathSearchList::GetCostSoFar(const int node) {
	return CostSoFar[node];
}

double PathSearchList::GetTotalCost(const int node) {
	return TotalCost[node];
}

int PathSearchList::PopOpenList() {
	int node = -1;
	double cost = -1;

	for (int i = 0; i < MAX_NODES; i++) {
		if (!IsOpen(i)) continue;

		double curcost = TotalCost[i];

		if (node == -1 || curcost<cost) {
			node = i;
			cost = curcost;
		}
	}

	if (node == -1)
		perror("node id is -1");

	Opened[node] = false;
	NumOpened--;

	return node;
}

void PathSearchList::AddToClosedList(const int node) {
	Closed[node] = true;
}

bool PathSearchList::IsOpen(const int node) {
	return Opened[node];
}

void PathSearchList::AddToOpenList(const int node) {
	Opened[node] = true;
	NumOpened++;
}

bool PathSearchList::IsClosed(const int node) {
	return Closed[node];
}

void PathSearchList::SetCostSoFar(const int node,const double cost) {
	CostSoFar[node] = cost;
}

void PathSearchList::SetTotalCost(const int node,const double cost) {
	TotalCost[node] = cost;
}

void PathSearchList::RemoveFromClosedList(const int node) {
	Closed[node] = false;
}

void PushPathSegment(const PathSegment& segment) {
	CurLUA->CreateTable();

	CurLUA->PushUserType(segment.area, NodeClass_Type);
	CurLUA->SetField(-2, "area");

	CurLUA->PushVector(segment.forward);
	CurLUA->SetField(-2, "forward");

	CurLUA->PushNumber(segment.length);
	CurLUA->SetField(-2, "length");

	CurLUA->PushVector(segment.pos);
	CurLUA->SetField(-2, "pos");

	CurLUA->PushNumber(segment.type);
	CurLUA->SetField(-2, "type");
}

CreateLuaFunction(PathMeta_Compute){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);
	CurLUA->CheckType(2, Type::Entity);
	CurLUA->CheckType(3, Type::Vector);
	int gentype = CurLUA->GetType(4);

	if (gentype!=Type::None && gentype!=Type::Nil && gentype!=Type::Function) {
		CurLUA->CheckType(4, Type::Function);
	}

	NextBot* bot = CurLUA->GetUserType<NextBot>(2, Type::Entity);
	bot->CheckSBAdvancedNextBot();

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	Vector pos = CurLUA->GetVector(3);

	luagenerator = (gentype == Type::Function);

	bool result = path->Compute(bot,pos);

	luagenerator = false;

	CurLUA->PushBool(result);

	return 1;
}

CreateLuaFunction(PathMeta_FirstSegment){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	
	if (path->IsValid()) {
		PushPathSegment(path->FirstSegment());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_GetAge){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		CurLUA->PushNumber(path->GetAge());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_GetAllSegments){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		CurLUA->CreateTable();

		for (int i = 0; i < path->GetNumSegments(); i++) {
			CurLUA->PushNumber(i + 1);
			PushPathSegment(path->GetNumSegment(i));
			CurLUA->SetTable(-3);
		}

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_GetCurrentGoal){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		PushPathSegment(path->GetCurrentGoal());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_GetEnd){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		CurLUA->PushVector(path->GetEnd());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_GetGoalTolerance){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	CurLUA->PushNumber(path->GetGoalTolerance());

	return 1;
}

CreateLuaFunction(PathMeta_GetLength){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		CurLUA->PushNumber(path->GetLength());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_GetMinLookAheadDistance){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	CurLUA->PushNumber(path->GetMinLookAheadDistance());

	return 1;
}

CreateLuaFunction(PathMeta_GetStart){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		CurLUA->PushVector(path->GetStart());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_Invalidate){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower * path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	path->Invalidate();

	return 0;
}

CreateLuaFunction(PathMeta_IsValid){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	CurLUA->PushBool(path->IsValid());

	return 1;
}

CreateLuaFunction(PathMeta_LastSegment){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	if (path->IsValid()) {
		PushPathSegment(path->LastSegment());

		return 1;
	}

	return 0;
}

CreateLuaFunction(PathMeta_ResetAge){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	path->ResetAge();

	return 0;
}

CreateLuaFunction(PathMeta_SetGoalTolerance){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);
	CurLUA->CheckType(2, Type::Number);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	path->SetGoalTolerance((int)CurLUA->GetNumber(2));

	return 0;
}

CreateLuaFunction(PathMeta_SetMinLookAheadDistance){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);
	CurLUA->CheckType(2, Type::Number);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	path->SetMinLookAheadDistance((int)CurLUA->GetNumber(2));

	return 0;
}

CreateLuaFunction(PathMeta_Update){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);
	CurLUA->CheckType(2, Type::Entity);

	NextBot* bot = CurLUA->GetUserType<NextBot>(2, Type::Entity);
	bot->CheckSBAdvancedNextBot();

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	
	if (path->IsValid())
		path->Update(bot);

	return 0;
}

CreateLuaFunction(PathMeta_Draw){
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	
	if (path->IsValid())
		path->Draw();

	return 0;
}

CreateLuaFunction(PathMeta_SetMaxJumpHeight) {
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);
	CurLUA->CheckType(2, Type::Number);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);
	path->SetMaxJumpHeight((float)CurLUA->GetNumber(2));

	return 0;
}

CreateLuaFunction(PathMeta_GetMaxJumpHeight) {
	CurLUA->CheckType(1, NodeGraphPathFollower_Type);

	NodeGraphPathFollower* path = CurLUA->GetUserType<NodeGraphPathFollower>(1, NodeGraphPathFollower_Type);

	CurLUA->PushNumber(path->GetMaxJumpHeight());

	return 1;
}

void NodeGraphPathFollower::CreateLuaFunctions() {
	CurLUA->PushCFunction(PathMeta_Compute);
	CurLUA->SetField(-2, "Compute");

	CurLUA->PushCFunction(PathMeta_FirstSegment);
	CurLUA->SetField(-2, "FirstSegment");

	CurLUA->PushCFunction(PathMeta_GetAge);
	CurLUA->SetField(-2, "GetAge");

	CurLUA->PushCFunction(PathMeta_GetAllSegments);
	CurLUA->SetField(-2, "GetAllSegments");

	CurLUA->PushCFunction(PathMeta_GetCurrentGoal);
	CurLUA->SetField(-2, "GetCurrentGoal");

	CurLUA->PushCFunction(PathMeta_GetEnd);
	CurLUA->SetField(-2, "GetEnd");

	CurLUA->PushCFunction(PathMeta_GetGoalTolerance);
	CurLUA->SetField(-2, "GetGoalTolerance");

	CurLUA->PushCFunction(PathMeta_GetLength);
	CurLUA->SetField(-2, "GetLength");

	CurLUA->PushCFunction(PathMeta_GetMinLookAheadDistance);
	CurLUA->SetField(-2, "GetMinLookAheadDistance");

	CurLUA->PushCFunction(PathMeta_GetStart);
	CurLUA->SetField(-2, "GetStart");

	CurLUA->PushCFunction(PathMeta_Invalidate);
	CurLUA->SetField(-2, "Invalidate");

	CurLUA->PushCFunction(PathMeta_IsValid);
	CurLUA->SetField(-2, "IsValid");

	CurLUA->PushCFunction(PathMeta_LastSegment);
	CurLUA->SetField(-2, "LastSegment");

	CurLUA->PushCFunction(PathMeta_ResetAge);
	CurLUA->SetField(-2, "ResetAge");

	CurLUA->PushCFunction(PathMeta_SetGoalTolerance);
	CurLUA->SetField(-2, "SetGoalTolerance");

	CurLUA->PushCFunction(PathMeta_SetMinLookAheadDistance);
	CurLUA->SetField(-2, "SetMinLookAheadDistance");

	CurLUA->PushCFunction(PathMeta_Update);
	CurLUA->SetField(-2, "Update");

	CurLUA->PushCFunction(PathMeta_Draw);
	CurLUA->SetField(-2, "Draw");

	CurLUA->PushCFunction(PathMeta_SetMaxJumpHeight);
	CurLUA->SetField(-2, "SetMaxJumpHeight");

	CurLUA->PushCFunction(PathMeta_GetMaxJumpHeight);
	CurLUA->SetField(-2, "GetMaxJumpHeight");
}