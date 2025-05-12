---@class XUiGridTwoSideTowerBuffDetail : XUiNode
---@field _Control XTwoSideTowerControl
local XUiGridTwoSideTowerBuffDetail = XClass(XUiNode, "XUiGridTwoSideTowerBuffDetail")

function XUiGridTwoSideTowerBuffDetail:Refresh(chapterId, pointId, stageId)
    local featureId = self._Control:GetStageFeatureId(stageId)
    -- 描述
    self.TxtAmbien.text = self._Control:GetFeatureDescZonglan(featureId)
    -- 图片
    self.RImgIcon:SetRawImage(self._Control:GetFeatureIcon(featureId))
    -- 名称
    self.TxtBuffName.text = self._Control:GetFeatureName(featureId)
    -- 关卡名称
    self.TxtName.text = self._Control:GetStageTypeName(stageId)
    -- 关卡编号
    self.TxtNumber.text = self._Control:GetStageNumberName(stageId)
    if self.RImgTeaching then
        self.RImgTeaching:SetRawImage(self._Control:GetFeatureImage(featureId))
    end
    self.Effect.gameObject:SetActiveEx(self._Control:GetFeatureType(featureId) == 2)
    -- 是否通关
    local passStageId = self._Control:GetPointPassStageId(chapterId, pointId)
    local isPass = XTool.IsNumberValid(passStageId) and passStageId == stageId
    self.PanelClear.gameObject:SetActiveEx(isPass)
end

return XUiGridTwoSideTowerBuffDetail
