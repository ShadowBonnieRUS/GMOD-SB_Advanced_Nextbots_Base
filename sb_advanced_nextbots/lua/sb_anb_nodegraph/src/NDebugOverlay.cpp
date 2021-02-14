#include "NDebugOverlay.h"

extern ILuaBase* CurLUA;

static void PushColor(int r, int g, int b, int a = 255) {
	CurLUA->CreateTable();

	CurLUA->PushNumber(r);
	CurLUA->SetField(-2, "r");

	CurLUA->PushNumber(g);
	CurLUA->SetField(-2, "g");

	CurLUA->PushNumber(b);
	CurLUA->SetField(-2, "b");

	CurLUA->PushNumber(a);
	CurLUA->SetField(-2, "a");
}

void NDebugOverlay::Box(const Vector& origin, const Vector& mins, const Vector& maxs, int r, int g, int b, int a, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Box");
	CurLUA->PushVector(origin);
	CurLUA->PushVector(mins);
	CurLUA->PushVector(maxs);
	CurLUA->PushNumber(flDuration);
	PushColor(r, g, b, a);
	CurLUA->Call(5, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::Triangle(const Vector& pos1, const Vector& pos2, const Vector& pos3, int r, int g, int b, int a, bool noDepthTest, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Triangle");
	CurLUA->PushVector(pos1);
	CurLUA->PushVector(pos2);
	CurLUA->PushVector(pos3);
	CurLUA->PushNumber(flDuration);
	PushColor(r, g, b, a);
	CurLUA->PushBool(noDepthTest);
	CurLUA->Call(6, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::Line(const Vector& origin, const Vector& target, int r, int g, int b, bool noDepthTest, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Line");
	CurLUA->PushVector(origin);
	CurLUA->PushVector(target);
	CurLUA->PushNumber(flDuration);
	PushColor(r, g, b);
	CurLUA->PushBool(noDepthTest);
	CurLUA->Call(5, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::HorzArrow(const Vector& startPos, const Vector& endPos, float width, int r, int g, int b, int a, bool noDepthTest, float flDuration) {
	Vector forward = VecAdd(endPos, VecInv(startPos));
	VecNormalize(forward);

	Vector up = vector(0, 0, 1);

	CurLUA->PushVector(forward);
	CurLUA->GetField(-1, "Cross");
	CurLUA->Push(-2);
	CurLUA->PushVector(up);
	CurLUA->Call(2, 1);

	Vector side = CurLUA->GetVector(-1);

	CurLUA->Pop(2);

	float radius = width / 2.0f;

	Vector p1 = VecAdd(startPos, VecInv(VecMul(side, radius)));
	Vector p2 = VecAdd(VecAdd(endPos, VecInv(VecMul(forward, width))), VecInv(VecMul(side, radius)));
	Vector p3 = VecAdd(VecAdd(endPos, VecInv(VecMul(forward, width))), VecInv(VecMul(side, width)));
	Vector p4 = endPos;
	Vector p5 = VecAdd(VecAdd(endPos, VecInv(VecMul(forward, width))), VecMul(side, width));
	Vector p6 = VecAdd(VecAdd(endPos, VecInv(VecMul(forward, width))), VecMul(side, radius));
	Vector p7 = VecAdd(startPos, VecMul(side, radius));

	Line(p1, p2, r, g, b, noDepthTest, flDuration);
	Line(p2, p3, r, g, b, noDepthTest, flDuration);
	Line(p3, p4, r, g, b, noDepthTest, flDuration);
	Line(p4, p5, r, g, b, noDepthTest, flDuration);
	Line(p5, p6, r, g, b, noDepthTest, flDuration);
	Line(p6, p7, r, g, b, noDepthTest, flDuration);
	Line(p7, p1, r, g, b, noDepthTest, flDuration);

	if (a > 0) {
		Triangle(p5, p4, p3, r, g, b, a, noDepthTest, flDuration);
		Triangle(p1, p7, p6, r, g, b, a, noDepthTest, flDuration);
		Triangle(p6, p2, p1, r, g, b, a, noDepthTest, flDuration);

		Triangle(p3, p4, p5, r, g, b, a, noDepthTest, flDuration);
		Triangle(p6, p7, p1, r, g, b, a, noDepthTest, flDuration);
		Triangle(p1, p2, p6, r, g, b, a, noDepthTest, flDuration);
	}
}

void NDebugOverlay::Sphere(const Vector& position, float radius, int r, int g, int b, int a, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Sphere");
	CurLUA->PushVector(position);
	CurLUA->PushNumber(radius);
	CurLUA->PushNumber(flDuration);
	PushColor(r, g, b);
	CurLUA->Call(4, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::Text(const Vector& origin, const char* text, bool bViewCheck, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Text");
	CurLUA->PushVector(origin);
	CurLUA->PushString(text);
	CurLUA->PushNumber(flDuration);
	CurLUA->PushBool(bViewCheck);
	CurLUA->Call(4, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::Text(const Vector& origin, const double text, bool bViewCheck, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Text");
	CurLUA->PushVector(origin);
	CurLUA->PushNumber(text);
	CurLUA->PushNumber(flDuration);
	CurLUA->PushBool(bViewCheck);
	CurLUA->Call(4, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::SweptBox(const Vector& start, const Vector& end, const Vector& mins, const Vector& maxs, const QAngle& angles, int r, int g, int b, int a, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "SweptBox");
	CurLUA->PushVector(start);
	CurLUA->PushVector(end);
	CurLUA->PushVector(mins);
	CurLUA->PushVector(maxs);
	CurLUA->PushAngle(angles);
	CurLUA->PushNumber(flDuration);
	PushColor(r, g, b, a);
	CurLUA->Call(7, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::Cross3D(const Vector& position, float size, int r, int g, int b, bool noDepthTest, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Cross");
	CurLUA->PushVector(position);
	CurLUA->PushNumber(size);
	CurLUA->PushNumber(flDuration);
	PushColor(r, g, b);
	CurLUA->PushBool(noDepthTest);
	CurLUA->Call(5, 0);
	CurLUA->Pop(2);
}

void NDebugOverlay::Axis(const Vector& position, const QAngle& angles, float size, bool noDepthTest, float flDuration) {
	CurLUA->PushSpecial(SPECIAL_GLOB);
	CurLUA->GetField(-1, "debugoverlay");
	CurLUA->GetField(-1, "Axis");
	CurLUA->PushVector(position);
	CurLUA->PushAngle(angles);
	CurLUA->PushNumber(size);
	CurLUA->PushNumber(flDuration);
	CurLUA->PushBool(noDepthTest);
	CurLUA->Call(5, 0);
	CurLUA->Pop(2);
}