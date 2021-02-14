#ifndef NEXTBOT_H
#define NEXTBOT_H

#include "Shared.h"
#include "Entity.h"

class NextBot : public Entity {
public:
	float GetStepHeight();

	float GetDeathDropHeight();

	void GetCrouchCollisionBounds(Vector* mins, Vector* maxs);

	int GetSolidMask();

	void Approach(const Vector& goal);

	int CapabilitiesGet();

	int GetHullType();

	bool IsOnGround();

	void JumpToPos(const Vector& goal);

	void CheckSBAdvancedNextBot();
};

#endif