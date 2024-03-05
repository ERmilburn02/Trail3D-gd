@tool
@icon("./Icon.png")
class_name Trail3D extends Node3D

#region Properties
@export_group("Trail Properties")
@export var emitting: bool;
@export var duration: float = 0.5;
@export var snapshotInterval: float = 0.02;
@export var width: float = 1.0;
@export var widthCurve: Curve;
@export var UVScale: Vector2 = Vector2.ONE;
@export var material: Material;
#endregion

#region Private Properties
var snapshotBuffer: Array[TargetSnapshot] = [];
var trailMesh: MeshInstance3D;

var t: float = 0;
var snapshotT: float = 0;
#endregion

func Init():
    # Fill this function with as many logs as possible to find out what's happening.
    for child in get_children():
        remove_child(child);
        child.queue_free();

    trailMesh = MeshInstance3D.new();
    add_child(trailMesh);
    trailMesh.mesh = ImmediateMesh.new();

    if trailMesh.mesh is ImmediateMesh:
        var mesh: ImmediateMesh = trailMesh.mesh;
        mesh.clear_surfaces();

    trailMesh.top_level = true;
    t = 0;
    snapshotT = 0;
    snapshotBuffer = [];

func PushSnapshot():
    snapshotBuffer.append(TargetSnapshot.new(global_position, global_transform.basis, t));

func DrawTrail():
    if trailMesh.mesh is ImmediateMesh:
        var mesh: ImmediateMesh = trailMesh.mesh;
        mesh.clear_surfaces();

        if snapshotBuffer.size() < 2:
            return ; # Only draw a face if there's two snapshot to draw between.

        mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material);
        for i in range(1, snapshotBuffer.size()):
            DrawFace(mesh, i);
        mesh.surface_end();

func DrawFace(mesh: ImmediateMesh, index: int):
    var snapshot: TargetSnapshot = snapshotBuffer[index];
    var previousSnapshot: TargetSnapshot = snapshotBuffer[index - 1];

    var snapX: float = float(index) / float(snapshotBuffer.size());
    var snapWidth: float = widthCurve.sample(snapX);

    var prevSnapX: float = float(index - 1) / float(snapshotBuffer.size());
    var prevSnapWidth: float = widthCurve.sample(prevSnapX);

    var vert1: Vector3 = previousSnapshot.position + previousSnapshot.basis.y.normalized() * prevSnapWidth * width;
    var vert2: Vector3 = snapshot.position + snapshot.basis.y.normalized() * snapWidth * width;
    var vert3: Vector3 = previousSnapshot.position - previousSnapshot.basis.y.normalized() * prevSnapWidth * width;
    var vert4: Vector3 = snapshot.position - snapshot.basis.y.normalized() * snapWidth * width;

    var normal: Vector3 = snapshot.basis.z.normalized();

    var snapUVx: float = lerp(0, 1, snapX) * UVScale.x;
    var prevSnapUVx: float = lerp(0, 1, prevSnapX) * UVScale.x;

    var snapUVy: float = lerp(0, 1, snapWidth) * UVScale.y;
    var prevSnapUVy: float = lerp(0, 1, prevSnapWidth) * UVScale.y;

    var vert1UV: Vector2 = Vector2(prevSnapUVx, 0.5 + prevSnapUVy / 2);
    var vert2UV: Vector2 = Vector2(snapUVx, 0.5 + snapUVy / 2);
    var vert3UV: Vector2 = Vector2(prevSnapUVx, 0.5 - prevSnapUVy / 2);
    var vert4UV: Vector2 = Vector2(snapUVx, 0.5 - snapUVy / 2);

    var tri1Verts: Array[Vector3] = [vert1, vert2, vert3];
    var tri1Norms: Array[Vector3] = [normal, normal, normal];
    var tri1UVs: Array[Vector2] = [vert1UV, vert2UV, vert3UV];
    var tri1: Triangle = Triangle.new(tri1Verts, tri1Norms, tri1UVs, t);

    var tri2Verts: Array[Vector3] = [vert4, vert3, vert2];
    var tri2Norms: Array[Vector3] = [normal, normal, normal];
    var tri2UVs: Array[Vector2] = [vert4UV, vert3UV, vert2UV];
    var tri2: Triangle = Triangle.new(tri2Verts, tri2Norms, tri2UVs, t);

    for i in tri1.vertices.size():
        mesh.surface_set_uv(tri1.uvs[i]);
        mesh.surface_set_normal(tri1.normals[i]);
        mesh.surface_add_vertex(tri1.vertices[i]);

    for i in tri2.vertices.size():
        mesh.surface_set_uv(tri2.uvs[i]);
        mesh.surface_set_normal(tri2.normals[i]);
        mesh.surface_add_vertex(tri2.vertices[i]);

func _enter_tree():
    Init();

func _process(delta: float):
    if !emitting or widthCurve == null:
        return ;

    if snapshotBuffer == null:
        Init();

    if trailMesh.mesh == null:
        emitting = false;
        return ;

    var dt: float = delta;

    if snapshotT > snapshotInterval:
        var count: int = snapshotBuffer.size();
        if count > 0:
            if snapshotBuffer[count - 1].position != global_position:
                PushSnapshot();

            if t - snapshotBuffer[0].time > duration:
                snapshotBuffer.remove_at(0);
        else:
            PushSnapshot();

        DrawTrail();
        snapshotT = 0;

    t += dt;
    snapshotT += dt;

class Triangle:
    var vertices: Array[Vector3];
    var normals: Array[Vector3];
    var uvs: Array[Vector2];
    var time: float;

    func _init(vertices: Array[Vector3], normals: Array[Vector3], uvs: Array[Vector2], time: float):
        self.vertices = vertices
        self.normals = normals
        self.uvs = uvs
        self.time = time

class TargetSnapshot:
    var position: Vector3;
    var basis: Basis;
    var time: float;

    func _init(position: Vector3, basis: Basis, time: float):
        self.position = position
        self.basis = basis
        self.time = time