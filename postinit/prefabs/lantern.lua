local env = env
GLOBAL.setfenv(1, GLOBAL)



env.AddPrefabPostInit("lantern", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    if inst.components.equippable ~= nil then
        local OnEquip_old = inst.components.equippable.onequipfn

        inst.components.equippable.onequipfn = function(inst, owner)
            if inst.upgraded then
                owner:AddTag("batteryuser")
            end

            if OnEquip_old ~= nil then
                OnEquip_old(inst, owner)
            end
        end

        local OnUnequip_old = inst.components.equippable.onunequipfn

        inst.components.equippable.onunequipfn = function(inst, owner)
            if owner.components.upgrademoduleowner == nil then
                local item = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
                if item ~= nil then
                    if not item:HasTag("electricaltool") and owner:HasTag("batteryuser") then
                        owner:RemoveTag("batteryuser")
                    end
                else
                    if owner:HasTag("batteryuser") then
                        owner:RemoveTag("batteryuser")
                    end
                end
            end

            if OnUnequip_old ~= nil then
                OnUnequip_old(inst, owner)
            end
        end
    end

    local function OnUpgrade(inst)
        if inst ~= nil then
            inst:AddTag("overchargeable")
            inst.upgraded = true
            inst:SetPrefabNameOverride("LANTERN_ELECTRICAL")
            inst.components.upgradeable.upgradetype = nil
            inst.components.fueled.fueltype = FUELTYPE.BATTERYPOWER
            inst.components.fueled.maxfuel = TUNING.LANTERN_LIGHTTIME * 2
            inst.components.fueled:DoDelta(0)--do a 0delta to update the %, maybe?
            inst:AddTag("electricaltool")
            inst.components.named:SetName(STRINGS.NAMES.LANTERN_ELECTRICAL)
            local owner = inst.components.inventoryitem:GetGrandOwner()

            if owner ~= nil and owner.components.inventory ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) == inst then
                owner:AddTag("batteryuser")
            end
        end --but wait! won't that fuck everything up?
    end --maybe I could alter in onequip instead too.

    local _OnSave = inst.OnSave
    local function OnSave(inst, data)
        if inst.upgraded then
            data.upgraded = inst.upgraded
        end
        if inst.components.fueled ~= nil then
            data.saved_fuel_value = inst.components.fueled:GetPercent()
        end
        if _OnSave ~= nil then
            _OnSave(inst, data)
        end
    end

    local _OnLoad = inst.OnLoad
    local function OnLoad(inst, data)
        if data ~= nil and data.upgraded then
            inst.upgraded = true
            OnUpgrade(inst)
            if data.saved_fuel_value ~= nil and inst.components.fueled ~= nil then
                inst:DoTaskInTime(0, function() inst.components.fueled:SetPercent(data.saved_fuel_value) end)
            end
        end
        if _OnLoad ~= nil then
            _OnLoad(inst, data)
        end
    end

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.ELECTRICAL
    inst.components.upgradeable.onupgradefn = OnUpgrade

    inst:AddComponent("named")

    inst:AddTag("NORATCHECK")
end)
