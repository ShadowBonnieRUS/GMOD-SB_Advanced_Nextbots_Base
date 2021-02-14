#include "NextBot.h"

float NextBot::GetStepHeight() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "loco");
	CurLUA->GetField(-1, "GetStepHeight");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	float step = (float)CurLUA->GetNumber(-1);

	CurLUA->Pop(3);

	return step;
}

float NextBot::GetDeathDropHeight() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "loco");
	CurLUA->GetField(-1, "GetDeathDropHeight");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	float height = (float)CurLUA->GetNumber(-1);

	CurLUA->Pop(3);

	return height;
}

void NextBot::GetCrouchCollisionBounds(Vector* mins, Vector* maxs) {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1,"CrouchCollisionBounds");
	CurLUA->PushNumber(1);
	CurLUA->GetTable(-2);
	CurLUA->PushNumber(2);
	CurLUA->GetTable(-3);

	Vector min = CurLUA->GetVector(-2);
	Vector max = CurLUA->GetVector(-1);

	CurLUA->Pop(4);

	*mins = min;
	*maxs = max;
}

int NextBot::GetSolidMask() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "GetSolidMask");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int mask = (int)CurLUA->GetNumber(-1);

	CurLUA->Pop(2);

	return mask;
}

void NextBot::Approach(const Vector& goal) {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "loco");
	CurLUA->GetField(-1, "Approach");
	CurLUA->Push(-2);
	CurLUA->PushVector(goal);
	CurLUA->PushNumber(1);
	CurLUA->Call(3, 0);
	CurLUA->Pop(2);
}

int NextBot::CapabilitiesGet() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "CapabilitiesGet");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int cap = (int)CurLUA->GetNumber(-1);

	CurLUA->Pop(2);

	return cap;
}

int NextBot::GetHullType() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "GetHullType");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int hull = (int)CurLUA->GetNumber(-1);

	CurLUA->Pop(2);

	return hull;
}

bool NextBot::IsOnGround() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "loco");
	CurLUA->GetField(-1, "IsOnGround");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	bool onground = CurLUA->GetBool(-1);

	CurLUA->Pop(3);

	return onground;
}

void NextBot::JumpToPos(const Vector& goal) {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "JumpToPos");
	CurLUA->Push(-2);
	CurLUA->PushVector(goal);
	CurLUA->Call(2, 0);
	CurLUA->Pop(1);
}

void NextBot::CheckSBAdvancedNextBot() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "SBAdvancedNextBot");
	
	bool IsSBANB = CurLUA->IsType(-1,Type::Bool) ? CurLUA->GetBool(-1) : false;

	CurLUA->Pop(2);

	if (!IsSBANB) ThrowFormatError("Entity is not SB Advanced NextBot!!");
}