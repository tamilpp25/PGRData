
---@class XUiPanelResetHud : XLuaBehaviour
---@field Target UnityEngine.Transform
---@field GameObject UnityEngine.GameObject
---@field Offset UnityEngine.Vector3
local XUiPanelResetHud = XClass(XLuaBehaviour, "XUiPanelResetHud")

function XUiPanelResetHud:Ctor(rootUi, ui)
    XTool.InitUiObjectByUi(self, ui)
    self.Offset = CS.UnityEngine.Vector3.zero
    self.Pivot = CS.UnityEngine.Vector2(0.5, 0.5)
    self.Angle = CS.UnityEngine.Vector2(0, 0)
    self.GridPool = {}
    self.ScoreList = {
        XFurnitureConfigs.AttrType.AttrA, XFurnitureConfigs.AttrType.AttrB, XFurnitureConfigs.AttrType.AttrC
    }
    
    self.BtnReceive.CallBack = function() 
        self:OnBtnReceiveClick()
    end
end

function XUiPanelResetHud:Show(furnitureId, placeType, target, roomId)
    if not XTool.IsNumberValid(furnitureId) then
        self:Hide()
        return
    end
    self.RoomId = roomId
    self.Target = target
    local furniture = XDataCenter.FurnitureManager.GetFurnitureById(furnitureId)
    local template = XFurnitureConfigs.GetFurnitureTemplateById(furniture:GetConfigId())
    self.TxtName.text = template.Name
    
    self.Behaviour.enabled = true
    self.GameObject:SetActiveEx(true)
    for i, attr in ipairs(self.ScoreList) do
        local attrValue = furniture:GetAttrScore(attr, furniture.AttrList[attr])
        local quality, max = XFurnitureConfigs.GetFurnitureSingleAttrLevel(template.TypeId, attr, attrValue)
        local grid = self.GridPool[i]
        if not grid then
            local ui = i == 1 and self.ScoreItem or XUiHelper.Instantiate(self.ScoreItem, self.Panellist)
            grid = {}
            XTool.InitUiObjectByUi(grid, ui)
            self.GridPool[i] = grid
        end
        local typeData = XFurnitureConfigs.GetDormFurnitureType(i)
        local color = XFurnitureConfigs.FurnitureAttrTagColor[quality] or XFurnitureConfigs.FurnitureAttrTagColor[1]
        local level = XFurnitureConfigs.FurnitureAttrLevel[quality] or XFurnitureConfigs.FurnitureAttrLevel[1]
        grid.Txt.text = string.format("<color=%s><size=30>%s%d</size></color>", color, level, attrValue)
        grid.ImgIcon:SetSprite(typeData.TypeIcon)
    end
    if not XTool.UObjIsNil(target) then
        local ctrl = XHomeSceneManager.GetSceneCameraController()
        if ctrl then
            local angleY = CS.UnityEngine.Vector3.Angle(ctrl.transform.forward, target.transform.position - ctrl.transform.position)
            local angleX = CS.UnityEngine.Vector3.Angle(ctrl.transform.up, CS.UnityEngine.Vector3.up)
            self.Angle.x = angleX
            self.Angle.y = angleY
            ctrl:SetTartAngle(self.Angle)
        end
    end
    self.Offset.y = template.AttrTagY
    self.Furniture = furniture
end

function XUiPanelResetHud:Hide()
    self.Behaviour.enabled = false
    self.GameObject:SetActiveEx(false)
end

function XUiPanelResetHud:Update()
    if XTool.UObjIsNil(self.GameObject) or not self.GameObject.activeInHierarchy then
        return
    end

    if XTool.UObjIsNil(self.Target) then
        self:Hide()
        return
    end
    
    self:UpdateTransform()
end

function XUiPanelResetHud:UpdateTransform()
    CS.XUiHelper.SetViewPosToTransformLocalPosition(XHomeSceneManager.GetSceneCamera(), self.Transform, self.Target.transform, self.Offset, self.Pivot)
end

function XUiPanelResetHud:OnBtnReceiveClick()
    if not self.Furniture then
        return
    end
    XLuaUiManager.Open("UiFurnitureBuild", XFurnitureConfigs.GainType.Remake, nil, nil, self.Furniture.Id, self.RoomId)
end

return XUiPanelResetHud