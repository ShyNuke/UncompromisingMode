local assets = {
	Asset("ANIM", "anim/mara_boss1_bullets.zip")
}

local prefabs = {
	"rock_break_fx"
}


-- Knockback.
-- Maybe rework init_knockback to include everything with knockback, not just giants?
-- I imagine its original purpose was to easily turn on/off the knockback mechanic in one place.
-- ...is there any particular reason that we aren't currently using it for much?
-- Anyway, I tried to gather up all the knockback resistors I found here for reference.
-- Is there any nuance I'm missing to the Uncomp/Vanilla knockback systems? -- Mara
local function OnHitOther(inst, other)
	if other:HasTag("creatureknockbackable") then
		other:PushEvent("knockback", { knocker = inst, radius = 2, strengthmult = 2.5 })
	else
		if other ~= nil
		and not other:HasTag("fat_gang")
		and not other:HasTag("heavybody") -- Vanilla player SG, unused since 2019ish?? But mentioned in daywalker knockback code. Might be used soon.
		and not other:HasTag("foodknockbackimmune")
		and not (other.components.rider ~= nil and other.components.rider:IsRiding())
		-- Don't knockback if the target is wearing knockback resistant equipment.
		and other.components.inventory ~= nil
		and (
			other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY) == nil
			or not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY):HasTag("marble")
			and not other.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY):HasTag("knockback_protection")
			and not other.components.inventory:ArmorHasTag("heavyarmor") -- Vanilla marble check; could be better to use this going forward for our anti-knockback equips?
		)
		then
			-- The actual knockback is defined here.
			other:PushEvent("knockback", { knocker = inst, radius = 2, strengthmult = 2.5 })
			-- Camera shake for dramatic effect WHY NOT
			if other.HUD ~= nil and other.HUD.shown then
				TheCamera:Shake(CAMERASHAKE.VERTICAL, .4, .02, .4)
			end
		end
	end
end

local function Perish(inst)
	inst:Remove()
end

-- Movement here.
local function WOOSH(inst)
	local nextvictim = FindClosestEntity(inst, 50, true, {"_health"}, { "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })
	
	if nextvictim ~= nil and math.random() > 0.95 then
		inst:FacePoint(nextvictim.Transform:GetWorldPosition())
		inst.components.locomotor:RunForward()
--	Maybe mix in a spiral pattern occasionally? Hm.
	else
		inst.components.locomotor:RunInDirection(math.random() * 359)
		inst.components.locomotor:RunForward()
	end
	
	inst:DoTaskInTime(2, Perish)
end

-- Here's the part where we violently murder anything we so much as lightly graze :D
-- And anything near it!
local function YEET(inst)
	local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "invisible", "notarget", "noattack", "playerghost" }
	
	inst.components.combat:DoAreaAttack(inst, 3, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
	
	local bonebreakfx = SpawnPrefab("rock_break_fx")
	if bonebreakfx ~= nil then
		bonebreakfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
	end
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_stone")
	
	inst:DoTaskInTime(0, Perish)
end

-- Proximity detonator.
local function OmaeWaMou(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local anythingwithafuckinghealthbar = TheSim:FindEntities(x, y, z, 2, {"_health"}, { "INLIMBO", "invisible", "notarget", "noattack", "playerghost" })
	
	if #anythingwithafuckinghealthbar ~= nil and #anythingwithafuckinghealthbar > 0 then
		inst:DoTaskInTime(0, YEET)
	end
	inst:DoTaskInTime(0.1, OmaeWaMou)
end


local function fn()
	local inst = CreateEntity()
	
	-- Core components
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
	
	MakeCharacterPhysics(inst, 50, .5)
	RemovePhysicsColliders(inst)
	inst:AddTag("NOBLOCK")
	
	inst.AnimState:SetBank("mara_boss1_bullets")
	inst.AnimState:SetBuild("mara_boss1_bullets")
	local names = { "boss1_bullet0", "boss1_bullet1", "boss1_bullet2", "boss1_bullet3", "boss1_bullet4", "boss1_bullet5" }
	inst.animname = names[math.random(#names)]
	inst.AnimState:PlayAnimation(inst.animname)
	inst.Transform:SetScale((1 + math.random()), (1 + math.random()), (1 + math.random()))
	
	inst.entity:SetPristine()
	
	if not TheWorld.ismastersim then
		return inst
	end
	
	inst:AddComponent("locomotor")
	inst.components.locomotor.walkspeed = ((30 * math.random()) + 25)
	inst.components.locomotor.runspeed = ((30 * math.random()) + 25)
	inst.components.locomotor:EnableGroundSpeedMultiplier(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }
	
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(10)
	inst.components.combat.onhitotherfn = OnHitOther
	
	inst:DoTaskInTime(0, WOOSH)
	inst:DoTaskInTime(0, OmaeWaMou)
	
	return inst
end

return Prefab("mara_boss1_bullets", fn, assets, prefabs)
