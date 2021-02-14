#ifndef TRACE_H
#define TRACE_H

#include "Entity.h"

struct TraceResult {
	float fraction = 0.0f;
	Entity* Entity = nullptr;
	bool startsolid = false;
	bool hitworld = false;
};

class TraceFilter {
public:
	virtual void PushFilter() = 0;
};

class TraceFilter_table : public TraceFilter {
	Entity** ents;
	int entcount;
public:
	TraceFilter_table(Entity* ent);
	~TraceFilter_table();

	TraceFilter_table& operator+(Entity* ent);
	TraceFilter_table& operator+=(Entity* ent);

	void PushFilter();
};

class TraceFilter_function : public TraceFilter {
	CFunc PushFunc;
public:
	TraceFilter_function(CFunc func);
	~TraceFilter_function();

	void PushFilter();
};

void TraceHull(const Vector& start,const Vector& endpos,const Vector& min,const Vector& max, const int mask,TraceFilter& filter,TraceResult& result);

#endif