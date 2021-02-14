#ifndef SHARED_H
#define SHARED_H

#include "Interface.h"
#include <stdarg.h>
#include <cstdio>
#include "CAI_Classes.h"

#define CAP_MOVE_GROUND	(1 << 0)
#define CAP_MOVE_JUMP	(1 << 1)
#define CAP_MOVE_FLY	(1 << 2)
#define CAP_MOVE_CLIMB	(1 << 3)
#define CAP_MOVE_SWIM	(1 << 4)
#define CAP_MOVE_CRAWL	(1 << 5)
#define CAP_MOVE_GROUNDJUMP (CAP_MOVE_GROUND & CAP_MOVE_JUMP)
#define CAP_MOVE_ALL	(CAP_MOVE_GROUNDJUMP & CAP_MOVE_FLY & CAP_MOVE_CLIMB & CAP_MOVE_SWIM & CAP_MOVE_CRAWL)

enum {
	NODE_ANY,
	NODE_DELETED,
	NODE_GROUND,
	NODE_AIR,
	NODE_CLIMB,
	NODE_WATER,
};

enum {
	AI_NODE_ZONE_UNKNOWN,
	AI_NODE_ZONE_SOLO,
	AI_NODE_ZONE_UNIVERSAL,
	AI_NODE_FIRST_ZONE,
};

enum {
	HULL_HUMAN,
	HULL_SMALL_CENTERED,
	HULL_WIDE_HUMAN,
	HULL_TINY,
	HULL_WIDE_SHORT,
	HULL_MEDIUM,
	HULL_TINY_CENTERED,
	HULL_LARGE,
	HULL_LARGE_CENTERED,
	HULL_MEDIUM_TALL,
	NUM_HULLS,
};

enum {
	PATH_SEGMENT_MOVETYPE_GROUND,
	PATH_SEGMENT_MOVETYPE_FALLINGDOWN,
	PATH_SEGMENT_MOVETYPE_JUMPING,
	PATH_SEGMENT_MOVETYPE_JUMPINGGAP,
	PATH_SEGMENT_MOVETYPE_LADDERUP,
	PATH_SEGMENT_MOVETYPE_LADDERDOWN,
};

using namespace GarrysMod::Lua;

#define MODULE_NAME "SBAdvancedNextbotNodeGraph"
#define METATABLE_NAME_NODE "SBNodeGraphNode"
#define METATABLE_NAME_PATHFOLLOWER "SBNodeGraphPathFollower"

#define ADD_MODULE_FUNCTION(name,func)		\
	CurLUA->PushSpecial(SPECIAL_GLOB);		\
	CurLUA->GetField(-1,MODULE_NAME);		\
	CurLUA->PushCFunction(##func);			\
	CurLUA->SetField(-2,name);				\
	CurLUA->Pop(2)

#define ADD_MODULE_VARIABLE(name,func,value)	\
	CurLUA->PushSpecial(SPECIAL_GLOB);			\
	CurLUA->GetField(-1,MODULE_NAME);			\
	CurLUA->PushString(name);					\
	CurLUA->Push##func(value);					\
	CurLUA->SetTable(-3);						\
	CurLUA->Pop(2)

#define ADD_MODULE_CONVAR(name,defvalue)		\
	CurLUA->PushSpecial(SPECIAL_GLOB);			\
	CurLUA->GetField(-1,"CreateConVar");		\
	CurLUA->PushString(name);					\
	CurLUA->PushString(defvalue);				\
	CurLUA->Call(2,0);							\
	CurLUA->Pop(1)

#define MAX_NODES 1500
#define AI_MAX_NODE_LINKS 30
#define AINET_VERSION_NUMBER 37

#define MAX_PATH 256

#define CreateLuaFunction(name)					\
	int name##_Act(ILuaBase* LUA);				\
	LUA_FUNCTION(##name){						\
		CurLUA = LUA;							\
		return name##_Act(LUA);					\
	}											\
	int name##_Act(ILuaBase* LUA)

#define FUNC_RUNTIME_DEFINE()					\
	CurLUA->PushSpecial(SPECIAL_GLOB);			\
	CurLUA->GetField(-1,"SysTime");				\
	CurLUA->Call(0,1);							\
	double FUNC_TIME = CurLUA->GetNumber(-1);	\
	CurLUA->Pop(2)

#define FUNC_RUNTIME_RESET()					\
	CurLUA->PushSpecial(SPECIAL_GLOB);			\
	CurLUA->GetField(-1,"SysTime");				\
	CurLUA->Call(0,1);							\
	FUNC_TIME = CurLUA->GetNumber(-1);			\
	CurLUA->Pop(2)

#define FUNC_RUNTIME_PRINT(name)				\
	CurLUA->PushSpecial(SPECIAL_GLOB);			\
	CurLUA->GetField(-1,"SysTime");				\
	CurLUA->Call(0,1);							\
	DevMsg("FUNC_TIME (%s): %.17f\n",name,CurLUA->GetNumber(-1)-FUNC_TIME);	\
	CurLUA->Pop(2)

void Msg(const char* msg);

void Msg(char sym);

void Msg(bool b);

extern ILuaBase* CurLUA;
template<typename... Args> void DevMsg(const char* format, Args... args) {
	char str[1000];

	snprintf(str, 1000, format, args...);

	Msg(str);
}

template<typename... Args> void ThrowFormatError(const char* format, Args... args) {
	char str[1000];

	snprintf(str, 1000, format, args...);

	CurLUA->ThrowError(str);
}

Vector VecMul(const Vector& vec1, const Vector& vec2);
Vector VecMul(const Vector& vec1, const float mul);
Vector VecDiv(const Vector& vec1, const Vector& vec2);
Vector VecDiv(const Vector& vec1, const float mul);
Vector VecAdd(const Vector& vec1, const Vector& vec2);
Vector VecInv(const Vector& vec1);
float VecLen(const Vector& vec);
float VecLenSqr(const Vector& vec);
float VecDistance(const Vector& vec1, const Vector& vec2);
float VecDist2D(const Vector& vec1, const Vector& vec2);
float VecDistSqr(const Vector& vec1, const Vector& vec2);
float VecNormalize(Vector& vec);
Vector vector(float x, float y, float z);
QAngle angle(float p, float y, float r);
void AngleDirs(const QAngle& ang, Vector& forward, Vector& right, Vector& up);

float CurTime();

bool IsConVarActive(const char* convar);

int GetConVarInt(const char* convar);

int strlen(const char* str);

void stradd(char* str, const char* src);

void strcpy(char* str, const char* src);

CAI_Node* GetNearestNode(const Vector& pos);

int GetNodesCap(CAI_Node* node1, CAI_Node* node2, const int hull);

int GetNodesCap(CAI_Node* node1, const int node2, const int hull);

#endif