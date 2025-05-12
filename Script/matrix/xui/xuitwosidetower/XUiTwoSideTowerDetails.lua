local XUiGridTwoSideTowerFeature = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerFeature")

---@class UiTwoSideTowerDetails : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerDetails = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerDetails")

function XUiTwoSideTowerDetails:OnAwake()
    self:RegisterUiEvents()

    self.FeatureEndUi = XTool.InitUiObjectByUi({}, self.PanelFeatureEnd)
    self.FeatureNormalUi = XTool.InitUiObjectByUi({}, self.PanelFeatureNormal)
    self.FeatureEndUi.GridFeature.gameObject:SetActiveEx(false)
    self.FeatureNormalUi.GridFeature.gameObject:SetActiveEx(false)
    ---@type XUiGridTwoSideTowerFeature[]
    self.GridFeatureEndList = {}
    ---@type XUiGridTwoSideTowerFeature[]
    self.GridFeatureNormalList = {}
end

function XUiTwoSideTowerDetails:OnStart(stageIds, chapterId, pointType, callBack)
    self.StageIds = stageIds
    self.ChapterId = chapterId
    self.PointType = pointType
    self.CallBack = callBack
end

function XUiTwoSideTowerDetails:OnEnable()
    self.FeatureEndUi.GameObject:SetActiveEx(self.PointType == XEnumConst.TwoSideTower.PointType.End)
    self.FeatureNormalUi.GameObject:SetActiveEx(self.PointType == XEnumConst.TwoSideTower.PointType.Normal)
    if self.PointType == XEnumConst.TwoSideTower.PointType.Normal then
        self:RefreshFeatureNormalList()
    end
    if self.PointType == XEnumConst.TwoSideTower.PointType.End then
        self:RefreshFeatureEndList()
    end
end

function XUiTwoSideTowerDetails:RefreshFeatureNormalList()
    if XTool.IsTableEmpty(self.StageIds) then
        return
    end
    for index, stageId in pairs(self.StageIds) do
        local grid = self.GridFeatureNormalList[index]
        if not grid then
            local go = index == 1 and self.FeatureNormalUi.GridFeature or XUiHelper.Instantiate(self.FeatureNormalUi.GridFeature, self.FeatureNormalUi.Content)
            grid = XUiGridTwoSideTowerFeature.New(go, self)
            self.GridFeatureNormalList[index] = grid
        end
        grid:Open()
        grid:Refresh(self.ChapterId, stageId)
    end
    for i = #self.StageIds + 1, #self.GridFeatureNormalList do
        self.GridFeatureNormalList[i]:Close()
    end
end

function XUiTwoSideTowerDetails:RefreshFeatureEndList()
    if not XTool.IsNumberValid(self.ChapterId) then
        return
    end
    local pointIds = self._Control:GetChapterPointIds(self.ChapterId)
    local stageIds = {}
    for _, pointId in pairs(pointIds) do
        local stageId = self._Control:GetPointPassStageId(self.ChapterId, pointId)
        if stageId > 0 then
            table.insert(stageIds, stageId)
        end
    end
    for index, stageId in pairs(stageIds) do
        local grid = self.GridFeatureEndList[index]
        if not grid then
            local go = index == 1 and self.FeatureEndUi.GridFeature or XUiHelper.Instantiate(self.FeatureEndUi.GridFeature, self.FeatureEndUi.Content)
            grid = XUiGridTwoSideTowerFeature.New(go, self, handler(self, self.RefreshScoreUi))
            self.GridFeatureEndList[index] = grid
        end
        grid:Open()
        grid:Refresh(self.ChapterId, stageId)
    end
    for i = #stageIds + 1, #self.GridFeatureEndList do
        self.GridFeatureEndList[i]:Close()
    end
    self:RefreshScoreUi()
end

function XUiTwoSideTowerDetails:RefreshScoreUi()
    -- 评分降低
    local isLower = self._Control:CheckChapterShieldFeaturesCount(self.ChapterId)
    if self.FeatureEndUi.TxtScore then
        self.FeatureEndUi.TxtScore.gameObject:SetActiveEx(isLower)
    end
end

function XUiTwoSideTowerDetails:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick)
end

function XUiTwoSideTowerDetails:OnBtnTanchuangCloseClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

return XUiTwoSideTowerDetails
