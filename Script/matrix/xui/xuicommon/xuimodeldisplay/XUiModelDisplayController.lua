---@class XUiModelDisplayController
local XUiModelDisplayController = XClass(nil, "XUiModelDisplayController")

function XUiModelDisplayController:Ctor(modelRoot, showShadow, fixLight)
    if XTool.UObjIsNil(modelRoot) then
        XLog.Error("ModelRoot Is Nil!")
        return
    end
    
    self.GameObject = modelRoot.gameObject
    self.Transform = modelRoot.transform
    self.Controller = self.GameObject:GetComponent(typeof(CS.XUiModelDisplayController))

    if XTool.UObjIsNil(self.Controller) then
        self.Controller = self.GameObject:AddComponent(typeof(CS.XUiModelDisplayController))
    end
    self.ShowShadow = showShadow
    --单个模型才能使用，耗性能
    self.FixLight = fixLight
    
    self.Controller:InitShadow(showShadow, fixLight)
end

function XUiModelDisplayController:AddMultiModel(id, componentId, modelUrl, controllerUrl, parent, componentType)
    componentType = componentType or typeof(CS.XUiModelComponentBase)
    parent = parent or self.Transform

    self.Controller:AddModelDisplay(componentType, id, componentId, modelUrl, controllerUrl, parent)
end

function XUiModelDisplayController:AddSingleModel(id, modelUrl, controllerUrl, parent, componentType)
    self:AddMultiModel(id, 0, modelUrl, controllerUrl, parent, componentType)
end

function XUiModelDisplayController:AddModelComponent(id, componentId, modelUrl, controllerUrl, parent, componentType)
    componentType = componentType or typeof(CS.XUiModelComponentBase)
    parent = parent or self.Transform

    self.Controller:AddModelComponent(componentType, id, componentId, modelUrl, controllerUrl, parent)
end

function XUiModelDisplayController:GetModelObject(id, componentId)
    return self.Controller:GetModelObject(id, componentId)
end

function XUiModelDisplayController:GetModelAnimator(id, componentId)
    return self.Controller:GetModelAnimator(id, componentId)
end

function XUiModelDisplayController:ChangeModelComponent(id, componentId, modelUrl, controllerUrl, parent)
    parent = parent or self.Transform

    self.Controller:ChangeModelComponent(id, componentId, modelUrl, controllerUrl, parent)
end

function XUiModelDisplayController:SetModelComponentActive(id, componentId, isActive)
    self.Controller:SetModelComponentActive(id, componentId, isActive)
end

function XUiModelDisplayController:SetModelActive(id, isActive)
    self.Controller:SetModelActive(id, isActive)
end

function XUiModelDisplayController:HideAllModel()
    self.Controller:HideAllModel()
end

function XUiModelDisplayController:IsModelExist(id)
    return self.Controller:IsModelExist(id)
end

function XUiModelDisplayController:IsModelComponentExist(id, componentId)
    return self.Controller:IsModelComponentExist(id, componentId)
end

function XUiModelDisplayController:PlayAnimation(id, animationName, normalizedTime, layer)
    self.Controller:PlayAnimation(id, animationName, layer or -1, normalizedTime or 0)
end

function XUiModelDisplayController:SetModelComponentMaterials(id, componentId, objectName, materialsUrl)
    self.Controller:SetModelComponentMaterials(id, componentId, objectName, materialsUrl)
end

function XUiModelDisplayController:DestroyAllModel()
    self.Controller:DestroyAllModel()
end

return XUiModelDisplayController