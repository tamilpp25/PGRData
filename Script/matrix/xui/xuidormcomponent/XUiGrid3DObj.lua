local XUiGrid3DObj = XClass(nil, "XUiGrid3DObj")

function XUiGrid3DObj:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform

    XTool.InitUiObject(self)
end

function XUiGrid3DObj:RefreshEffect(effectId, bindWorldPos, renderUIProxy)
    if self.EffectId == effectId then
        return
    end

    self.EffectId = effectId

    local effectConfig = XDormConfig.GetMoodEffectConfig(effectId)
    self.EffectObj = self.Transform:LoadPrefab(effectConfig.Path)

    self.EffectObj.transform:SetParent(self.PanelEffectObj, false)

    if effectConfig.Bind == 2 then
        self.EffectObj.transform.localPosition = CS.UnityEngine.Vector3.zero
    end

    if effectConfig.Bind == 1 then
        renderUIProxy:BindEffect(self.EffectObj)
    end

    if bindWorldPos then
        self.PanelEffectObj.transform.position = bindWorldPos
    else
        local position = CS.UnityEngine.Vector3(0, effectConfig.Hight, 0)
        self.PanelEffectObj.transform.localPosition = position
    end
end



function XUiGrid3DObj:Show(id, effectId, transform, bindWorldPos, renderUIProxy, headTransform, isPet)
    local effectConfig = XDormConfig.GetMoodEffectConfig(effectId)

    if effectConfig.Bind == 2 then
        self.Transform:SetParent(headTransform, false)
        self.Transform.localPosition = CS.UnityEngine.Vector3.zero
    else
        self.Transform:SetParent(transform, false)
        local position = Vector3.zero
        if not isPet then
            local styleConfig = XDormConfig.GetCharacterStyleConfigById(id)
            position = CS.UnityEngine.Vector3(0, styleConfig.EffectWidgetHight, 0)
        else
            local furnitureConfigId = XDataCenter.FurnitureManager.GetFurnitureConfigId(id)
            if XTool.IsNumberValid(furnitureConfigId) then
                local petId = XFurnitureConfigs.GetFurniturePetId(furnitureConfigId)
                if XTool.IsNumberValid(petId) then
                    local template = XDormConfig.GetDormPetTemplate(petId)
                    position = CS.UnityEngine.Vector3(0, template.EffectWidgetHeight, 0)
                end
            end
        end
        self.Transform.localPosition = position
    end

    self.GameObject:SetLayerRecursively(transform.gameObject.layer)
    self:RefreshEffect(effectId, bindWorldPos, renderUIProxy)
    self.BtnClick.gameObject:SetActive(false)
    self.GameObject:SetActive(true)
end

function XUiGrid3DObj:Hide()
    self.EffectObj = nil
    self.EffectId = 0
    self.GameObject:SetActive(false)
end

return XUiGrid3DObj