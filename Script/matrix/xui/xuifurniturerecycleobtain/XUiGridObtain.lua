local XUiGridObtain = XClass(nil, "XUiGridObtain")

function XUiGridObtain:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self:AutoAddListener()
    self:SetSelected(false)
end

function XUiGridObtain:Init(rootUi)
    self.RootUi = rootUi
end

function XUiGridObtain:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridObtain:RegisterClickEvent函数错误, 参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridObtain:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridObtain:AutoAddListener()
    self:RegisterClickEvent(self.BtnClick, self.OnBtnClickClick)
end

function XUiGridObtain:OnBtnClickClick()
    local furnitureConfigId = XDataCenter.FurnitureManager.GetFurnitureConfigId(self.FurnitureId)
    XEventManager.DispatchEvent(XEventId.EVENT_CLICK_FURNITURE_GRID, self.FurnitureId, furnitureConfigId, self)
end

function XUiGridObtain:SetSelected(status)
    self.PanelSelect.gameObject:SetActiveEx(status)
end

function XUiGridObtain:IsSelected()
    return self.PanelSelect and self.PanelSelect.gameObject.activeSelf
end

-- 传入家具的唯一Id
function XUiGridObtain:Refresh(furnitureId, selectQualityList)
    self.FurnitureId = furnitureId

    local furnitureConfig = XDataCenter.FurnitureManager.GetFurnitureConfigByUniqueId(furnitureId)
    if not furnitureConfig then
        return
    end
    self:SetSelected(self.RootUi:GetGridSelected(furnitureId))

    local icon = XDataCenter.FurnitureManager.GetFurnitureIconById(furnitureId, XDormConfig.DormDataType.Self)
    self.RImgIcon:SetRawImage(icon, nil, true)

    local furnitureType = XDataCenter.FurnitureManager.GetFurnitureConfigByUniqueId(furnitureId).TypeId
    local totalScore = XDataCenter.FurnitureManager.GetFurnitureScore(furnitureId)
    local totalDesc = XFurnitureConfigs.GetFurnitureTotalAttrLevelDescription(furnitureType, totalScore)
    self.TxtScore.text = totalDesc
    self.Quality = XFurnitureConfigs.GetFurnitureTotalAttrLevel(furnitureType, totalScore)

    if self:IsSelected() then
        return
    end
    for _, selectQuality in ipairs(selectQualityList) do
        if self.Quality == selectQuality then
            self:SetSelected(true)
            break
        end
    end
    
    self:RefreshLabel(furnitureConfig.Id)
end

function XUiGridObtain:RefreshLabel(templateId)
    if self.GoodsLabel then
        self.GoodsLabel:Close()
    end
    if not XTool.IsNumberValid(templateId) then
        return
    end
    if not XUiConfigs.CheckHasLabel(templateId) then
        return
    end
    if not self.GoodsLabel then
        self.GoodsLabel = XUiHelper.CreateGoodsLabel(templateId, self.Transform, self.PanelPet)
    end
    self.GoodsLabel:Refresh(templateId, self.PanelPet ~= nil)
end

return XUiGridObtain