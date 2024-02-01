---@class XUiGridTwoSideTowerFeature : XUiNode
---@field _Control XTwoSideTowerControl
local XUiGridTwoSideTowerFeature = XClass(XUiNode, "XUiGridTwoSideTowerFeature")

function XUiGridTwoSideTowerFeature:OnStart(callBack)
    self.CallBack = callBack
    XUiHelper.RegisterClickEvent(self, self.BtnShield, self.OnBtnShieldClick)
    XUiHelper.RegisterClickEvent(self, self.BtnRelieve, self.OnBtnRelieveClick)
end

function XUiGridTwoSideTowerFeature:Refresh(chapterId, stageId)
    self.ChapterId = chapterId
    self.StageId = stageId
    self.FeatureId = self._Control:GetStageFeatureId(stageId)
    self:RefreshView()
end

function XUiGridTwoSideTowerFeature:RefreshView()
    self.TxtBuffName.text = self._Control:GetFeatureName(self.FeatureId)
    self.TxtAmbient.text = self._Control:GetFeatureDescZonglan(self.FeatureId)
    self.RImgIcon:SetRawImage(self._Control:GetFeatureIcon(self.FeatureId))
    self.Effect.gameObject:SetActiveEx(self._Control:GetFeatureType(self.FeatureId) == 2)
    local isShield = self._Control:CheckChapterIsShieldFeature(self.ChapterId, self.FeatureId)
    if self.PanelScreen then
        self.PanelScreen.gameObject:SetActiveEx(isShield)
    end
    if self.BtnShield then
        self.BtnShield.gameObject:SetActiveEx(not isShield)
    end
    if self.BtnRelieve then
        self.BtnRelieve.gameObject:SetActiveEx(isShield)
    end
end

-- 屏蔽
function XUiGridTwoSideTowerFeature:OnBtnShieldClick()
    local endPoint = self._Control:GetChapterEndPointId(self.ChapterId)
    local endStageId = self._Control:GetPointStageIds(endPoint)[1]
    if not XTool.IsNumberValid(endStageId) then
        return
    end
    self._Control:TwoSideTowerShieldOrUnShieldFeatureIdRequest(endStageId, self.FeatureId, true,function()
        self:RefreshView()
        if self.CallBack then
            self.CallBack()
        end
    end)
end

-- 解除屏蔽
function XUiGridTwoSideTowerFeature:OnBtnRelieveClick()
    local endPoint = self._Control:GetChapterEndPointId(self.ChapterId)
    local endStageId = self._Control:GetPointStageIds(endPoint)[1]
    if not XTool.IsNumberValid(endStageId) then
        return
    end
    self._Control:TwoSideTowerShieldOrUnShieldFeatureIdRequest(endStageId, self.FeatureId, false,function()
        self:RefreshView()
        if self.CallBack then
            self.CallBack()
        end
    end)
end

return XUiGridTwoSideTowerFeature
