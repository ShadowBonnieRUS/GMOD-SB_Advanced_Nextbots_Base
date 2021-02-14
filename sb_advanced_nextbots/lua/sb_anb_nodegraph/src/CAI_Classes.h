#ifndef CAI_CLASSES_H
#define CAI_CLASSES_H

class CAI_Link;

class CAI_Node {
	Vector m_origin;
	float m_yaw = 0;
	int m_id = -1;

	int m_NumLinks;
public:
	CAI_Link** m_links;
	int m_type;
	unsigned short m_info;
	short m_zone;
	float* m_voffset;

	Vector GetOrigin();
	float GetYaw();
	char GetType();
	unsigned short GetInfo();
	short GetZone();
	int GetID();
	int NumLinks();

	CAI_Node();
	CAI_Node(int id, Vector& origin, float yaw);
	~CAI_Node();

	void SetupNew();
	void AddLink(CAI_Link* link);

	CAI_Link* GetLink(const int num);

	static void CreateLuaFunctions();
};

class CAI_Link {
public:
	short m_srcID;
	short m_destID;
	int m_info;
	int* m_AcceptedMoveTypes;

	int DestNodeID();
	CAI_Node* DestNode();
	CAI_Node* SrcNode();

	CAI_Link();
	~CAI_Link();
};

#endif