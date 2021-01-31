#include <math.h>
#include "MeshDataUtility.h"

std::vector<Vertex> MeshDataUtility::PlaneVertices =
{
	  {{-1.0f, 0.0f,  1.0f}, {0.7f, 0.7f, 0.3f, 1.0f}}, // 0
	  {{-1.0f, 0.0f, -1.0f}, {0.7f, 0.7f, 0.3f, 1.0f}}, // 1
	  {{ 1.0f, 0.0f,  1.0f}, {0.7f, 0.7f, 0.3f, 1.0f}}, // 2
	  {{ 1.0f, 0.0f, -1.0f}, {0.7f, 0.7f, 0.3f, 1.0f}}  // 3
};

std::vector<UINT> MeshDataUtility::PlaneIndices = { 0, 1, 2, 2, 1, 3 };

std::vector<Vertex> MeshDataUtility::TetrahedronVertices =
{
  {{ sqrtf(8.f / 9.f),  0.f,			  -1.f / 3.f}, {1.0f, 0.0f, 0.0f, 1.0f}},
  {{-sqrtf(2.f / 9.f),  sqrtf(2.f / 3.f), -1.f / 3.f}, {0.0f, 1.0f, 0.0f, 1.0f}},
  {{-sqrtf(2.f / 9.f), -sqrtf(2.f / 3.f), -1.f / 3.f}, {0.0f, 0.0f, 1.0f, 1.0f}},
  {{0.f,				0.f,			   1.f},	   {1.0f, 0.0f, 1.0f, 1.0f}}
};
std::vector<UINT>   MeshDataUtility::TetrahedronIndices = { 0, 1, 2, 0, 3, 1, 0, 2, 3, 1, 3, 2 };