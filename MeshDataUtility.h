#pragma once

#include <windows.h>
#include <vector>
#include "VertexTypes.h"

class MeshDataUtility
{
public:
	static std::vector<Vertex> PlaneVertices;
	static std::vector<UINT>   PlaneIndices;

	static std::vector<Vertex> TetrahedronVertices;
	static std::vector<UINT>   TetrahedronIndices;
};