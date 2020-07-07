tool
extends Reference
class_name RMSS2D_Edge

var quads: Array = []
var z_index: int = 0

static func different_render(q1: RMSS2D_Quad, q2: RMSS2D_Quad) -> bool:
	"""
	Will return true if the 2 quads must be drawn in two calls
	"""
	if (
		q1.texture != q2.texture
		or q1.flip_texture != q2.flip_texture
		or q1.texture_normal != q2.texture_normal
	):
		return true
	return false



static func get_consecutive_quads_for_mesh(_quads: Array) -> Array:
	if _quads.empty():
		return []

	var quad_ranges = []
	var quad_range = []
	quad_range.push_back(_quads[0])
	for i in range(1, _quads.size(), 1):
		var quad_prev = _quads[i - 1]
		var quad = _quads[i]
		if different_render(quad, quad_prev):
			quad_ranges.push_back(quad_range)
			quad_range = [quad]
		else:
			quad_range.push_back(quad)

	quad_ranges.push_back(quad_range)
	return quad_ranges


static func generate_array_mesh_from_quad_sequence(_quads: Array, total_length: float) -> ArrayMesh:
	if _quads.empty():
		return ArrayMesh.new()

	var first_quad = _quads[0]
	var tex: Texture = first_quad.tex
	var change_in_length: float = -1.0

	var length: float = 0.0
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q in _quads:
		if tex != null:
			change_in_length = (
				(round(total_length / tex.get_size().x) * tex.get_size().x)
				/ total_length
			)

		var section_length: float = q.get_length() * change_in_length
		if section_length == 0:
			section_length = tex.get_size().x
		st.add_color(Color.white)

		# A
		if tex != null:
			if not q.flip_texture:
				_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 0))
			else:
				_add_uv_to_surface_tool(
					st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 0)
				)
		st.add_vertex(_to_vector3(q.pt_a))

		# B
		if tex != null:
			if not q.flip_texture:
				_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 1))
			else:
				_add_uv_to_surface_tool(
					st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 1)
				)
		st.add_vertex(_to_vector3(q.pt_b))

		# C
		if tex != null:
			if not q.flip_texture:
				_add_uv_to_surface_tool(
					st, Vector2((length + section_length) / tex.get_size().x, 1)
				)
			else:
				_add_uv_to_surface_tool(
					st,
					Vector2(
						(
							(total_length * change_in_length - (section_length + length))
							/ tex.get_size().x
						),
						1
					)
				)
		st.add_vertex(_to_vector3(q.pt_c))

		# A
		if tex != null:
			if not q.flip_texture:
				_add_uv_to_surface_tool(st, Vector2(length / tex.get_size().x, 0))
			else:
				_add_uv_to_surface_tool(
					st, Vector2((total_length * change_in_length - length) / tex.get_size().x, 0)
				)
		st.add_vertex(_to_vector3(q.pt_a))

		# C
		if tex != null:
			if not q.flip_texture:
				_add_uv_to_surface_tool(
					st, Vector2((length + section_length) / tex.get_size().x, 1)
				)
			else:
				_add_uv_to_surface_tool(
					st,
					Vector2(
						(
							(total_length * change_in_length - (length + section_length))
							/ tex.get_size().x
						),
						1
					)
				)
		st.add_vertex(_to_vector3(q.pt_c))

		# D
		if tex != null:
			if not q.flip_texture:
				_add_uv_to_surface_tool(
					st, Vector2((length + section_length) / tex.get_size().x, 0)
				)
			else:
				_add_uv_to_surface_tool(
					st,
					Vector2(
						(
							(total_length * change_in_length - (length + section_length))
							/ tex.get_size().x
						),
						0
					)
				)
		st.add_vertex(_to_vector3(q.pt_d))
		length += section_length

	st.index()
	st.generate_normals()
	return st.commit()


func get_meshes() -> Array:
	"""
	Returns an array of RMSS2D_Mesh
	# Get Arrays of consecutive quads with the same mesh data
	# For each array
	## Generate Mesh Data from the quad
	"""

	var consecutive_quad_arrays = get_consecutive_quads_for_mesh(quads)
	var meshes = []
	for consecutive_quads in consecutive_quad_arrays:
		# Iterate over the quads now until change in direction or texture or looped around
		var st: SurfaceTool = SurfaceTool.new()
		var total_length: float = 0.0
		for q in consecutive_quads:
			total_length += q.get_length()
		var array_mesh: ArrayMesh = generate_array_mesh_from_quad_sequence(
			consecutive_quads, total_length
		)
		var tex: Texture = consecutive_quads[0].tex
		var tex_normal: Texture = consecutive_quads[0].normal_tex
		var flip = consecutive_quads[0].flip_texture
		var transform = Transform2D()
		var mesh_data = RMSS2D_Mesh.new(tex, tex_normal, flip)
		mesh_data.meshes.push_back(array_mesh)
		meshes.push_back(mesh_data)

	return meshes


static func _add_uv_to_surface_tool(surface_tool: SurfaceTool, uv: Vector2):
	surface_tool.add_uv(uv)
	surface_tool.add_uv2(uv)

static func _to_vector3(vector: Vector2):
	return Vector3(vector.x, vector.y, 0)
