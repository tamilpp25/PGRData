local XUiGridTwoSideTowerBuffDetail = XClass(nil, "XUiGridTwoSideTowerBuffDetail")

---@param obj UnityEngine.RectTransform
---@param stageData XTwoSideTowerStage
function XUiGridTwoSideTowerBuffDetail:Ctor(obj, stageData)
    self.StageData = stageData
    self.GameObject = obj.gameObject
    self.Transform = obj
    XTool.InitUiObject(self)
    self:Refresh()
end

function XUiGridTwoSideTowerBuffDetail:Refresh()
    local featureId = self.StageData:GetFeatureId()
    local featureCfg = XTwoSideTowerConfigs.GetFeatureCfg(featureId)
    self.TxtAmbien.text = featureCfg.Desc
    self.RImgIcon:SetRawImage(featureCfg.Icon)
    self.TxtBuffName.text = featureCfg.Name
    local isPass = self.StageData:IsPass()
    self.PanelClear.gameObject:SetActiveEx(isPass)
    self.TxtName.text = self.StageData:GetStageTypeName()
    self.TxtNumber.text = self.StageData:GetStageNumberName()
    if self.RImgTeaching then
        self.RImgTeaching:SetRawImage(featureCfg.Image)
    end
    self.Effect.gameObject:SetActiveEx(featureCfg.Type == 2)
end

return XUiGridTwoSideTowerBuffDetail