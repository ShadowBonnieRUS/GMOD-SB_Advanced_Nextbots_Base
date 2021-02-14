#include "Trace.h"

TraceFilter_table::TraceFilter_table(Entity* ent) {
	ents = new Entity*[1024]{ent};
	entcount = 1;
}

TraceFilter_table::~TraceFilter_table() {
	delete[] ents;
}

TraceFilter_table& TraceFilter_table::operator+(Entity* ent) {
	ents[entcount++] = ent;

	return *this;
}

TraceFilter_table& TraceFilter_table::operator+=(Entity* ent) {
	ents[entcount++] = ent;

	return *this;
}

void TraceFilter_table::PushFilter() {
	CurLUA->CreateTable();

	for (int i = 0; i < entcount; i++) {
		CurLUA->PushNumber(i + 1);
		CurLUA->PushUserType(ents[i], Type::Entity);
		CurLUA->SetTable(-3);
	}
}

TraceFilter_function::TraceFilter_function(CFunc func) {
	PushFunc = func;
}

TraceFilter_function::~TraceFilter_function() {}

void TraceFilter_function::PushFilter() {
	CurLUA->PushCFunction(PushFunc);
}

void TraceHull(const Vector& start, const Vector& endpos, const Vector& min, const Vector& max, const int mask, TraceFilter& filter, TraceResult& result) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "util");
	CurLUA->GetField(-1, "TraceHull");

	CurLUA->CreateTable();
	CurLUA->PushVector(start);
	CurLUA->SetField(-2, "start");
	CurLUA->PushVector(endpos);
	CurLUA->SetField(-2, "endpos");
	CurLUA->PushVector(min);
	CurLUA->SetField(-2, "mins");
	CurLUA->PushVector(max);
	CurLUA->SetField(-2, "maxs");
	CurLUA->PushNumber(mask);
	CurLUA->SetField(-2, "mask");
	filter.PushFilter();
	CurLUA->SetField(-2, "filter");

	CurLUA->Call(1, 1);

	CurLUA->GetField(-1, "Fraction");
	result.fraction = (float)CurLUA->GetNumber(-1);
	CurLUA->Pop();

	CurLUA->GetField(-1, "StartSolid");
	result.startsolid = CurLUA->GetBool(-1);
	CurLUA->Pop();

	CurLUA->GetField(-1, "HitWorld");
	result.hitworld = CurLUA->GetBool(-1);
	CurLUA->Pop();

	CurLUA->GetField(-1, "Entity");
	result.Entity = CurLUA->GetUserType<Entity>(-1, Type::Entity);
	CurLUA->Pop();

	CurLUA->Pop(3);
}
