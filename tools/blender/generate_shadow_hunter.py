import bpy, math, os
from mathutils import Vector

OUT = os.environ.get("DARK_SUMMONER_GLB_OUT", "assets/generated/shadow_hunter.glb")
os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)

def mat(name, color, metallic=0.0, rough=0.5, emission=None):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    bs=m.node_tree.nodes.get("Principled BSDF"); bs.inputs["Base Color"].default_value=(*color,1)
    bs.inputs["Metallic"].default_value=metallic; bs.inputs["Roughness"].default_value=rough
    if emission:
        (bs.inputs["Emission Color"] if "Emission Color" in bs.inputs else bs.inputs["Emission"]).default_value=(*emission,1); bs.inputs["Emission Strength"].default_value=1.4
    return m
obs=mat("Obsidian Armor",(0.055,0.045,0.09),.62,.3); cloth=mat("Royal Violet Cloth",(.19,.11,.32),.18,.68)
silver=mat("Antique Silver",(.42,.43,.55),.8,.24); skin=mat("Warm Pale Skin",(.55,.39,.34),0,.8)
glow=mat("Aether Violet Glow",(.42,.08,.85),.25,.2,(.55,.12,1)); steel=mat("Moonsteel",(.48,.65,.82),.9,.18,(.12,.3,.55))

ad=bpy.data.armatures.new("ShadowHunter_Skeleton"); rig=bpy.data.objects.new("ShadowHunter_Rig",ad); bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active=rig; rig.select_set(True); bpy.ops.object.mode_set(mode="EDIT")
bones={"root":((0,0,0),(0,0,.35),None),"pelvis":((0,0,.65),(0,0,1),"root"),"spine":((0,0,1),(0,0,1.62),"pelvis"),"head":((0,0,1.62),(0,0,2.22),"spine"),"arm.L":((-.32,0,1.48),(-.62,0,1.05),"spine"),"arm.R":((.32,0,1.48),(.62,0,1.05),"spine"),"leg.L":((-.18,0,.72),(-.2,0,.18),"pelvis"),"leg.R":((.18,0,.72),(.2,0,.18),"pelvis"),"weapon":((.58,-.02,1.12),(.82,-.02,1.55),"arm.R")}
for n,(h,t,p) in bones.items():
    b=ad.edit_bones.new(n); b.head=h; b.tail=t
    if p: b.parent=ad.edit_bones[p]
bpy.ops.object.mode_set(mode="OBJECT"); rig.show_in_front=True

def bind(o,bone):
    vg=o.vertex_groups.new(name=bone); vg.add(list(range(len(o.data.vertices))),1,"REPLACE")
    mod=o.modifiers.new("Hero Skeleton","ARMATURE"); mod.object=rig; o.parent=rig
    o.matrix_parent_inverse=rig.matrix_world.inverted()
    return o
def box(n,loc,scale,ma,bone,bevel=.06):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc); o=bpy.context.object; o.name=n; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(ma)
    be=o.modifiers.new("Soft Armor Edges","BEVEL"); be.width=bevel; be.segments=2
    o.modifiers.new("Weighted Normals","WEIGHTED_NORMAL"); return bind(o,bone)
def ball(n,loc,scale,ma,bone):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=12,location=loc); o=bpy.context.object; o.name=n; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); o.data.materials.append(ma)
    for p in o.data.polygons: p.use_smooth=True
    return bind(o,bone)
def cone(n,loc,radius,depth,ma,bone,verts=8):
    bpy.ops.mesh.primitive_cone_add(vertices=verts,radius1=radius,radius2=0,depth=depth,location=loc)
    o=bpy.context.object; o.name=n; o.data.materials.append(ma); return bind(o,bone)

for s,x in (("L",-.19),("R",.19)):
    b="leg."+s; box("Boot_"+s,(x,-.01,.18),(.32,.43,.28),obs,b); box("Greave_"+s,(x,0,.48),(.27,.34,.38),cloth,b); box("Knee_"+s,(x,-.19,.62),(.25,.12,.16),silver,b,.035)
box("Armored_Torso",(0,0,1.30),(.72,.43,.72),obs,"spine",.13)
box("Chest_Plate",(0,-.225,1.34),(.52,.12,.45),cloth,"spine",.08)
ball("Aether_Chest_Core",(0,-.30,1.43),(.105,.055,.13),glow,"spine")
box("Belt",(0,-.02,.99),(.72,.47,.14),silver,"pelvis",.04)
box("Shoulder_L",(-.43,0,1.55),(.35,.48,.30),cloth,"spine",.09); box("Shoulder_R",(.43,0,1.55),(.35,.48,.30),cloth,"spine",.09)
box("Rear_Cape",(0,.24,1.12),(.88,.13,1.12),cloth,"spine",.09); cone("Cape_Tip",(0,.24,.48),.48,.5,obs,"spine",6)
ball("Face",(0,-.035,1.88),(.31,.28,.34),skin,"head"); ball("Hood",(0,.035,1.98),(.39,.34,.38),obs,"head")
cone("Hood_Crown",(0,.04,2.28),.34,.42,cloth,"head",8); box("Face_Mask",(0,-.292,1.82),(.42,.08,.16),obs,"head",.035)
for x in (-.12,.12): box("Glowing_Eye",(x,-.34,1.88),(.075,.035,.035),glow,"head",.012)
ball("Forehead_Gem",(0,-.31,2.08),(.075,.045,.09),glow,"head")
for s,x in (("L",-.49),("R",.49)):
    b="arm."+s; ball("Upper_Arm_"+s,(x,0,1.34),(.17,.19,.31),obs,b); ball("Gauntlet_"+s,(x*1.35,-.02,1.08),(.18,.20,.20),silver,b); ball("Glove_"+s,(x*1.38,-.04,.98),(.14,.16,.12),obs,b)
box("Dagger_Grip",(.73,-.05,1.29),(.10,.12,.34),obs,"weapon",.02); box("Dagger_Guard",(.73,-.05,1.46),(.32,.10,.07),silver,"weapon",.02)
cone("Moonsteel_Dagger",(.73,-.05,1.78),.12,.60,steel,"weapon",6); ball("Blade_Pommel",(.73,-.05,1.10),(.09,.09,.09),glow,"weapon")

def action(name, keys):
    a=bpy.data.actions.new(name); rig.animation_data_create(); rig.animation_data.action=a
    for f,values in keys:
        for bn,v in values.items():
            pb=rig.pose.bones[bn]; pb.rotation_mode="XYZ"; pb.rotation_euler=v.get("r",(0,0,0)); pb.location=v.get("l",(0,0,0))
            pb.keyframe_insert(data_path="rotation_euler",frame=f,group=bn); pb.keyframe_insert(data_path="location",frame=f,group=bn)
    for fc in a.fcurves:
        for k in fc.keyframe_points: k.interpolation="BEZIER"
    return a
Z=(0,0,0)
action("idle",[(1,{"spine":{"r":Z},"head":{"r":Z}}),(16,{"spine":{"r":(0,.025,0)},"head":{"r":(0,-.02,0)}}),(31,{"spine":{"r":Z},"head":{"r":Z}})])
action("run",[(1,{"arm.L":{"r":(.45,0,0)},"arm.R":{"r":(-.45,0,0)},"leg.L":{"r":(-.55,0,0)},"leg.R":{"r":(.55,0,0)}}),(9,{"arm.L":{"r":(-.45,0,0)},"arm.R":{"r":(.45,0,0)},"leg.L":{"r":(.55,0,0)},"leg.R":{"r":(-.55,0,0)}}),(17,{"arm.L":{"r":(.45,0,0)},"arm.R":{"r":(-.45,0,0)},"leg.L":{"r":(-.55,0,0)},"leg.R":{"r":(.55,0,0)}})])
for n,a in (("attack_1",-1),("attack_2",1),("attack_3",-1.35)):
    action(n,[(1,{"arm.R":{"r":(0,a,0)},"weapon":{"r":(0,a,0)}}),(7,{"arm.R":{"r":(0,-a*.9,0)},"weapon":{"r":(0,-a*.9,0)}}),(13,{"arm.R":{"r":Z},"weapon":{"r":Z}})])
action("skill",[(1,{"spine":{"r":Z}}),(10,{"spine":{"r":(0,0,.35)},"arm.L":{"r":(-.8,0,0)},"arm.R":{"r":(.8,0,0)}}),(22,{"spine":{"r":Z},"arm.L":{"r":Z},"arm.R":{"r":Z}})])
action("hurt",[(1,{"spine":{"r":(0,0,-.18)}}),(7,{"spine":{"r":(0,0,.12)}}),(12,{"spine":{"r":Z}})])
action("dodge",[(1,{"root":{"l":Z}}),(7,{"root":{"l":(0,.22,.05)},"spine":{"r":(.2,0,0)}}),(13,{"root":{"l":Z},"spine":{"r":Z}})])
action("defeat",[(1,{"spine":{"r":Z}}),(20,{"spine":{"r":(0,0,1.25)},"head":{"r":(0,0,.5)}})])
action("victory",[(1,{"arm.L":{"r":Z},"arm.R":{"r":Z}}),(12,{"arm.L":{"r":(-1.1,0,0)},"arm.R":{"r":(1.1,0,0)}}),(24,{"arm.L":{"r":Z},"arm.R":{"r":Z}})])

bpy.ops.object.select_all(action="DESELECT"); rig.select_set(True); bpy.context.view_layer.objects.active=rig
bpy.ops.export_scene.gltf(filepath=OUT,export_format="GLB",use_selection=False,export_apply=True,export_animations=True,export_animation_mode="ACTIONS",export_skins=True,export_materials="EXPORT")
print("DARK_SUMMONER_GLB_EXPORTED="+OUT)
