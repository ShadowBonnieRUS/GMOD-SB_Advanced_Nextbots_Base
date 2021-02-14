#ifndef PATHFOLLOWER_H
#define PATHFOLLOWER_H

#include "NextBot.h"
#include "Trace.h"

class NodeGraphPathFollower;

struct PathSegment {
	CAI_Node* area;
	Vector forward;
	float length = 0;
	Vector pos;
	int type = 0;
};

class NodeGraphPathFollower {
	PathSegment** Segments;
	int CurSegmentID = 0;
	float ComputeTime = 0.0f;
	PathSegment* CurSegment = nullptr;
	int Tolerance = 25;
	double Len = 0.0;
	int MinLook = -1;
	int NumSegments = 0;
	bool Valid = false;
	Vector Goal;
	Vector Start;
	float MaxJumpHeight = -1.0f;
	float DeathDropHeight = -1.0f;

	float AvoidTimer = 0;
	bool AvoidCheck = false;
	bool AvoidLeftClear = true;
	bool AvoidRightClear = true;
	Vector AvoidHullMin = vector(0, 0, 0);
	Vector AvoidHullMax = vector(0, 0, 0);
	Vector AvoidLeftFrom = vector(0, 0, 0);
	Vector AvoidLeftTo = vector(0, 0, 0);
	Vector AvoidRightFrom = vector(0, 0, 0);
	Vector AvoidRightTo = vector(0, 0, 0);

	bool Astar(const Vector& start,const Vector& goal,const int hull,const int cap);

	bool Construct(const int* nodes,CAI_Node* from,CAI_Node* to,const Vector& start,const Vector& goal, const int hull);

	bool BuildPath(NextBot* bot);

	bool TrivialPathCheck(const Vector& start, const Vector& goal, const int mask, const Vector& mins, const Vector& maxs, const float height, TraceFilter& filter);

	void ConstructTrivial(const Vector& startpos, const Vector& endpos, CAI_Node* node);

	void InsertSegment(const Vector& startpos,const Vector& endpos, CAI_Node* node, const int movetype);

	Vector Avoid(NextBot* bot, const Vector& goalpos, const Vector& forward, const Vector& left);
public:
	NodeGraphPathFollower();

	~NodeGraphPathFollower();

	bool Compute(NextBot* bot,const Vector& to);

	PathSegment& FirstSegment();

	float GetAge();

	int GetNumSegments();

	PathSegment& GetNumSegment(int num);

	PathSegment& GetCurrentGoal();

	Vector GetEnd();

	int GetGoalTolerance();

	double GetLength();

	int GetMinLookAheadDistance();

	Vector GetStart();

	void Invalidate();

	bool IsValid();

	PathSegment& LastSegment();

	void ResetAge();

	void SetGoalTolerance(const int tolerance);

	void SetMinLookAheadDistance(const int minlook);

	void Update(NextBot* bot);

	void SetMaxJumpHeight(const float height);

	float GetMaxJumpHeight();

	void SetDeathDropHeight(const float height);

	float GetDeathDropHeight();

	static void CreateLuaFunctions();

	void Draw();
};

class PathSearchList {
	bool Opened[MAX_NODES]{};
	bool Closed[MAX_NODES]{};
	double CostSoFar[MAX_NODES]{};
	double TotalCost[MAX_NODES]{};
	int NumOpened = 0;
public:
	PathSearchList();

	~PathSearchList();

	bool IsOpenListEmpty();

	double GetCostSoFar(const int node);

	double GetTotalCost(const int node);

	int PopOpenList();

	void AddToClosedList(const int node);

	bool IsOpen(const int node);

	void AddToOpenList(const int node);

	bool IsClosed(const int node);

	void SetCostSoFar(const int node,const double cost);

	void SetTotalCost(const int node,const double cost);

	void RemoveFromClosedList(const int node);
};

#endif