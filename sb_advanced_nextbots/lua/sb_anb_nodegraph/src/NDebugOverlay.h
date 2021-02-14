#ifndef NDEBUGOVERLAY_H
#define NDEBUGOVERLAY_H
#include "Shared.h"

namespace NDebugOverlay
{
	void Box(const Vector& origin, const Vector& mins, const Vector& maxs, int r, int g, int b, int a, float flDuration);

	void Triangle(const Vector& pos1, const Vector& pos2, const Vector& pos3, int r, int g, int b, int a, bool noDepthTest, float flDuration);

	void Line(const Vector& origin, const Vector& target, int r, int g, int b, bool noDepthTest, float flDuration);

	void HorzArrow(const Vector& startPos, const Vector& endPos, float width, int r, int g, int b, int a, bool noDepthTest, float flDuration);

	void Sphere(const Vector& position, float radius, int r, int g, int b, int a, float flDuration);

	void Text(const Vector& origin, const char* text, bool bViewCheck, float flDuration);

	void Text(const Vector& origin, const double text, bool bViewCheck, float flDuration);

	void SweptBox(const Vector& start, const Vector& end, const Vector& mins, const Vector& maxs, const QAngle& angles, int r, int g, int b, int a, float flDuration);

	void Cross3D(const Vector& position, float size, int r, int g, int b, bool noDepthTest, float flDuration);

	void Axis(const Vector& position, const QAngle& angles, float size, bool noDepthTest, float flDuration);
};

#endif