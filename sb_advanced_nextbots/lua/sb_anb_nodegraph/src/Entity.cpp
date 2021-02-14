#include "Entity.h"

bool Entity::IsValid() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "IsValid");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	bool isvalid = CurLUA->GetBool(-1);

	CurLUA->Pop(2);

	return isvalid;
}

int Entity::GetChildren(Entity** childrens, const int size) {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "GetChildren");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int count = 0;
	while (true) {
		CurLUA->PushNumber(count + 1);
		CurLUA->GetTable(-2);

		if (!CurLUA->IsType(-1,Type::Entity)) {
			CurLUA->Pop();
			break;
		}

		childrens[count++] = CurLUA->GetUserType<Entity>(-1, Type::Entity);
		CurLUA->Pop();

		if (count >= size)
			break;
	}

	CurLUA->Pop(2);

	return count;
}

const char* Entity::GetClass() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "GetClass");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	const char* Class = CurLUA->GetString(-1);

	CurLUA->Pop(2);

	return Class;
}

bool Entity::IsClass(const char* Class) {
	const char* myClass = GetClass();
	int myLen = strlen(myClass);
	int len = strlen(Class);

	if (Class[len - 1] != '*') 
		if (len != myLen) return false;
	else
		if (len - 1 != myLen) return false;

	for (int i = 0; i < myLen; i++) {
		if (myClass[i] != Class[i]) return false;
	}

	return true;
}

Vector Entity::GetPos() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1,"GetPos");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	Vector pos = CurLUA->GetVector(-1);

	CurLUA->Pop(2);

	return pos;
}

Vector Entity::WorldSpaceCenter() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "WorldSpaceCenter");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	Vector pos = CurLUA->GetVector(-1);

	CurLUA->Pop(2);

	return pos;
}

QAngle Entity::GetAngles() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "GetAngles");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	QAngle ang = CurLUA->GetAngle(-1);

	CurLUA->Pop(2);

	return ang;
}

float Entity::GetModelScale() {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "GetModelScale");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	float scale = (float)CurLUA->GetNumber(-1);

	CurLUA->Pop(2);

	return scale;
}

bool Entity::operator==(Entity& ent) {
	CurLUA->PushUserType(this, Type::Entity);
	CurLUA->GetField(-1, "EntIndex");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int index_this = (int)CurLUA->GetNumber(-1);

	CurLUA->Pop(2);

	CurLUA->PushUserType(&ent, Type::Entity);
	CurLUA->GetField(-1, "EntIndex");
	CurLUA->Push(-2);
	CurLUA->Call(1, 1);

	int index_ent = (int)CurLUA->GetNumber(-1);

	CurLUA->Pop(2);

	return index_this == index_ent;
}