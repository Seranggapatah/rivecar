-- Load a tire/wheel GLB into GPU-ready vertex buffers (pos+normal, stride 24).
local json = require("json")

export type WheelMeshPart = {
	name: string,
	vertices: buffer,
	vertexCount: number,
	indices: buffer,
	indexCount: number,
	r: number,
	g: number,
	b: number,
}

export type LoadedWheel = {
	parts: { WheelMeshPart },
	-- Mesh AABB half-extents before any runtime scale (axle assumed along +Y).
	radius: number,
	halfWidth: number,
	sizeX: number,
	sizeY: number,
	sizeZ: number,
}

local COMP_BYTES: { [number]: number } = {
	[5120] = 1,
	[5121] = 1,
	[5122] = 2,
	[5123] = 2,
	[5125] = 4,
	[5126] = 4,
}

local TYPE_COUNT: { [string]: number } = {
	SCALAR = 1,
	VEC2 = 2,
	VEC3 = 3,
	VEC4 = 4,
	MAT4 = 16,
}

local function asTable(value: any): { [string]: any }?
	if type(value) == "table" then
		return value
	end
	return nil
end

local function asArray(value: any): { any }?
	if type(value) == "table" then
		return value
	end
	return nil
end

local function asNumber(value: any, fallback: number): number
	if type(value) == "number" then
		return value
	end
	return fallback
end

local function asString(value: any, fallback: string): string
	if type(value) == "string" then
		return value
	end
	return fallback
end

local function quatMat(x: number, y: number, z: number, w: number): Mat4
	local xx, yy, zz = x * x, y * y, z * z
	local xy, xz, yz = x * y, x * z, y * z
	local wx, wy, wz = w * x, w * y, w * z
	return Mat4.values(
		1 - 2 * (yy + zz),
		2 * (xy + wz),
		2 * (xz - wy),
		0,
		2 * (xy - wz),
		1 - 2 * (xx + zz),
		2 * (yz + wx),
		0,
		2 * (xz + wy),
		2 * (yz - wx),
		1 - 2 * (xx + yy),
		0,
		0,
		0,
		0,
		1
	)
end

local function nodeLocal(node: { [string]: any }): Mat4
	local t = asArray(node.translation)
	local r = asArray(node.rotation)
	local s = asArray(node.scale)
	local tx, ty, tz = 0, 0, 0
	if t then
		tx = asNumber(t[1], 0)
		ty = asNumber(t[2], 0)
		tz = asNumber(t[3], 0)
	end
	local qx, qy, qz, qw = 0, 0, 0, 1
	if r then
		qx = asNumber(r[1], 0)
		qy = asNumber(r[2], 0)
		qz = asNumber(r[3], 0)
		qw = asNumber(r[4], 1)
	end
	local sx, sy, sz = 1, 1, 1
	if s then
		sx = asNumber(s[1], 1)
		sy = asNumber(s[2], 1)
		sz = asNumber(s[3], 1)
	end
	return Mat4.fromTranslation(tx, ty, tz) * quatMat(qx, qy, qz, qw) * Mat4.fromScale(sx, sy, sz)
end

local function accessorOffset(doc: { [string]: any }, accessorIndex: number): (number, number, number, string, number)
	local accessors = asArray(doc.accessors)
	local bufferViews = asArray(doc.bufferViews)
	if accessors == nil or bufferViews == nil then
		error("missing accessors")
	end
	local acc = asTable(accessors[accessorIndex + 1])
	if acc == nil then
		error("bad accessor")
	end
	local view = asTable(bufferViews[asNumber(acc.bufferView, 0) + 1])
	if view == nil then
		error("bad bufferView")
	end
	local componentType = asNumber(acc.componentType, 5126)
	local typeName = asString(acc.type, "SCALAR")
	local count = asNumber(acc.count, 0)
	local comps = TYPE_COUNT[typeName] or 1
	local elemBytes = (COMP_BYTES[componentType] or 4) * comps
	local stride = asNumber(view.byteStride, elemBytes)
	local offset = asNumber(view.byteOffset, 0) + asNumber(acc.byteOffset, 0)
	return offset, stride, count, typeName, componentType
end

local function copyIndices(bin: buffer, doc: { [string]: any }, accessorIndex: number): (buffer, number)
	local offset, stride, count, _, componentType = accessorOffset(doc, accessorIndex)
	local out = buffer.create(count * 2)
	for i = 0, count - 1 do
		local src = offset + i * stride
		local value = 0
		if componentType == 5123 then
			value = buffer.readu16(bin, src)
		elseif componentType == 5125 then
			value = buffer.readu32(bin, src)
		elseif componentType == 5121 then
			value = buffer.readu8(bin, src)
		else
			value = buffer.readu16(bin, src)
		end
		buffer.writeu16(out, i * 2, value)
	end
	return out, count
end

local function copyMesh(
	bin: buffer,
	doc: { [string]: any },
	primitive: { [string]: any },
	world: Mat4
): (buffer, number, buffer, number)
	local attributes = asTable(primitive.attributes)
	if attributes == nil then
		error("mesh primitive missing attributes")
	end
	local posAcc = asNumber(attributes.POSITION, 0)
	local nrmAcc = attributes.NORMAL
	local posOff, posStride, posCount = accessorOffset(doc, posAcc)
	local nrmOff, nrmStride = posOff, posStride
	local hasNormal = type(nrmAcc) == "number"
	if hasNormal then
		nrmOff, nrmStride = accessorOffset(doc, nrmAcc :: number)
	end
	local vertices = buffer.create(posCount * 24)
	for i = 0, posCount - 1 do
		local px = buffer.readf32(bin, posOff + i * posStride)
		local py = buffer.readf32(bin, posOff + i * posStride + 4)
		local pz = buffer.readf32(bin, posOff + i * posStride + 8)
		local nx, ny, nz = 0, 1, 0
		if hasNormal then
			nx = buffer.readf32(bin, nrmOff + i * nrmStride)
			ny = buffer.readf32(bin, nrmOff + i * nrmStride + 4)
			nz = buffer.readf32(bin, nrmOff + i * nrmStride + 8)
		end
		local wp = world:transformPoint(px, py, pz)
		local origin = world:transformPoint(0, 0, 0)
		local npt = world:transformPoint(nx, ny, nz)
		local nnx = npt.x - origin.x
		local nny = npt.y - origin.y
		local nnz = npt.z - origin.z
		local nlen = math.sqrt(nnx * nnx + nny * nny + nnz * nnz)
		if nlen > 1e-6 then
			nnx /= nlen
			nny /= nlen
			nnz /= nlen
		end
		local dst = i * 24
		buffer.writef32(vertices, dst, wp.x)
		buffer.writef32(vertices, dst + 4, wp.y)
		buffer.writef32(vertices, dst + 8, wp.z)
		buffer.writef32(vertices, dst + 12, nnx)
		buffer.writef32(vertices, dst + 16, nny)
		buffer.writef32(vertices, dst + 20, nnz)
	end
	local indexAcc = primitive.indices
	if type(indexAcc) ~= "number" then
		error("mesh primitive missing indices")
	end
	local indices, indexCount = copyIndices(bin, doc, indexAcc :: number)
	return vertices, posCount, indices, indexCount
end

local function materialColor(doc: { [string]: any }, materialIndex: any): (number, number, number)
	if type(materialIndex) ~= "number" then
		return 0.15, 0.15, 0.17
	end
	local materials = asArray(doc.materials)
	if materials == nil then
		return 0.15, 0.15, 0.17
	end
	local mat = asTable(materials[(materialIndex :: number) + 1])
	if mat == nil then
		return 0.15, 0.15, 0.17
	end
	local pbr = asTable(mat.pbrMetallicRoughness)
	if pbr == nil then
		return 0.15, 0.15, 0.17
	end
	local factor = asArray(pbr.baseColorFactor)
	if factor == nil then
		return 0.15, 0.15, 0.17
	end
	return asNumber(factor[1], 0.15), asNumber(factor[2], 0.15), asNumber(factor[3], 0.17)
end

local wheel_glb = {}

function wheel_glb.load(data: buffer): LoadedWheel
	if buffer.readu32(data, 0) ~= 0x46546C67 then
		error("not a GLB file")
	end
	local total = buffer.len(data)
	local offset = 12
	local doc: { [string]: any }? = nil
	local bin: buffer? = nil
	while offset + 8 <= total do
		local chunkLen = buffer.readu32(data, offset)
		local chunkType = buffer.readu32(data, offset + 4)
		local dataStart = offset + 8
		if dataStart + chunkLen > total then
			break
		end
		if chunkType == 0x4E4F534A then
			local jsonBuf = buffer.create(chunkLen)
			buffer.copy(jsonBuf, 0, data, dataStart, chunkLen)
			doc = asTable(json.parse(buffer.tostring(jsonBuf)))
		elseif chunkType == 0x004E4942 then
			local chunk = buffer.create(chunkLen)
			buffer.copy(chunk, 0, data, dataStart, chunkLen)
			bin = chunk
		end
		offset = dataStart + chunkLen
		local pad = offset % 4
		if pad ~= 0 then
			offset += 4 - pad
		end
	end
	if doc == nil or bin == nil then
		error("GLB missing JSON or BIN chunk")
	end
	local jsonDoc = doc :: { [string]: any }
	local binData = bin :: buffer

	local nodes = asArray(jsonDoc.nodes)
	local meshes = asArray(jsonDoc.meshes)
	local scenes = asArray(jsonDoc.scenes)
	if nodes == nil or meshes == nil or scenes == nil then
		error("GLB missing nodes/meshes")
	end

	local sceneIndex = asNumber(jsonDoc.scene, 0)
	local scene = asTable(scenes[sceneIndex + 1])
	local roots = if scene then asArray(scene.nodes) else nil
	if roots == nil then
		error("GLB missing scene roots")
	end

	local world: { Mat4 } = table.create(#nodes, Mat4.identity())
	local function visit(index: number, parent: Mat4)
		local node = asTable(nodes[index + 1])
		if node == nil then
			return
		end
		local worldM = parent * nodeLocal(node)
		world[index + 1] = worldM
		local children = asArray(node.children)
		if children then
			for _, child in children do
				if type(child) == "number" then
					visit(child :: number, worldM)
				end
			end
		end
	end
	for _, root in roots do
		if type(root) == "number" then
			visit(root :: number, Mat4.identity())
		end
	end

	local parts: { WheelMeshPart } = {}
	local minx, miny, minz = 1e9, 1e9, 1e9
	local maxx, maxy, maxz = -1e9, -1e9, -1e9

	for nodeIndex, nodeAny in nodes do
		local node = asTable(nodeAny)
		if node == nil or type(node.mesh) ~= "number" then
			continue
		end
		local mesh = asTable(meshes[(node.mesh :: number) + 1])
		if mesh == nil then
			continue
		end
		local primitives = asArray(mesh.primitives)
		if primitives == nil then
			continue
		end
		local nodeName = asString(node.name, asString(mesh.name, "wheel"))
		local worldM = world[nodeIndex]
		for _, primAny in primitives do
			local primitive = asTable(primAny)
			if primitive == nil then
				continue
			end
			local vertices, vertexCount, indices, indexCount = copyMesh(binData, jsonDoc, primitive, worldM)
			local r, g, b = materialColor(jsonDoc, primitive.material)
			for vi = 0, vertexCount - 1 do
				local x = buffer.readf32(vertices, vi * 24)
				local y = buffer.readf32(vertices, vi * 24 + 4)
				local z = buffer.readf32(vertices, vi * 24 + 8)
				if x < minx then minx = x end
				if y < miny then miny = y end
				if z < minz then minz = z end
				if x > maxx then maxx = x end
				if y > maxy then maxy = y end
				if z > maxz then maxz = z end
			end
			table.insert(parts, {
				name = nodeName,
				vertices = vertices,
				vertexCount = vertexCount,
				indices = indices,
				indexCount = indexCount,
				r = r,
				g = g,
				b = b,
			})
		end
	end

	if #parts == 0 then
		error("no meshes in wheel GLB")
	end

	local cx = (minx + maxx) * 0.5
	local cy = (miny + maxy) * 0.5
	local cz = (minz + maxz) * 0.5
	local dx = maxx - minx
	local dy = maxy - miny
	local dz = maxz - minz
	-- Cylinder axle along Y: disc radius from X/Z, half-width from Y
	local radius = math.max(dx, dz) * 0.5
	local halfWidth = dy * 0.5

	for _, part in parts do
		for vi = 0, part.vertexCount - 1 do
			local dst = vi * 24
			buffer.writef32(part.vertices, dst, buffer.readf32(part.vertices, dst) - cx)
			buffer.writef32(part.vertices, dst + 4, buffer.readf32(part.vertices, dst + 4) - cy)
			buffer.writef32(part.vertices, dst + 8, buffer.readf32(part.vertices, dst + 8) - cz)
		end
	end

	print(
		string.format(
			"wheel GLB: %d parts, radius=%.3f halfWidth=%.3f size=%.3fx%.3fx%.3f",
			#parts,
			radius,
			halfWidth,
			dx,
			dy,
			dz
		)
	)
	return {
		parts = parts,
		radius = math.max(radius, 0.01),
		halfWidth = math.max(halfWidth, 0.01),
		sizeX = math.max(dx, 0.01),
		sizeY = math.max(dy, 0.01),
		sizeZ = math.max(dz, 0.01),
	}
end

return wheel_glb
