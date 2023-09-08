local XUiGridTwoSideTowerBuffDetail = require("XUi/XUiTwoSideTower/XUiGridTwoSideTowerBuffDetail")

---@class XUiTwoSideTowerOverview : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerOverview = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerOverview")

function XUiTwoSideTowerOverview:OnStart(chapterId)
    self.ChapterId = chapterId
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.OnBtnTanchuangCloseClick)
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.Details03UI = XTool.InitUiObjectByUi({}, self.GridDetails03)
    self.PointIdList = {}
    self.TagBtnList = {}
    ---@type XUiGridTwoSideTowerBuffDetail[]
    self.GridDetailsList = {}
    self:InitButtonGroup()
end

function XUiTwoSideTowerOverview:OnEnable()
    self.BtnContent:SelectIndex(1)
end

function XUiTwoSideTowerOverview:InitButtonGroup()
    -- 攻略提示页签
    local objFirst = XUiHelper.Instantiate(self.BtnFirst, self.BtnContent.transform)
    objFirst:SetName(self._Control:GetClientConfig("OverviewTabName"))
    objFirst.gameObject:SetActiveEx(true)
    table.insert(self.TagBtnList, objFirst)
    table.insert(self.PointIdList, 0)
    -- 关卡页签
    local pointIds = self._Control:GetChapterPointIds(self.ChapterId)
    for _, pointId in pairs(pointIds) do
        ---@type XUiComponent.XUiButton
        local obj = XUiHelper.Instantiate(self.BtnFirst, self.BtnContent.transform)
        obj:SetName(self._Control:GetPointName(pointId))
        obj.gameObject:SetActiveEx(true)
        table.insert(self.TagBtnList, obj)
        table.insert(self.PointIdList, pointId)
    end
    self.BtnContent:Init(self.TagBtnList, function(index) self:OnSelectBtnTag(index) end)
end

function XUiTwoSideTowerOverview:OnSelectBtnTag(index)
    if self.SelectIndex == index then
        return
    end
    self:PlayAnimation("QieHuan")
    self.SelectIndex = index
    self:HideDetails()
    -- 第一个特殊处理
    if index == 1 then
        self:RefreshDetails03()
        return
    end
    self:RefreshFeatureList()
end

function XUiTwoSideTowerOverview:HideDetails()
    self.Details03UI.GameObject:SetActiveEx(false)
    for _, grid in pairs(self.GridDetailsList) do
        CS.UnityEngine.GameObject.Destroy(grid.GameObject)
    end
    self.GridDetailsList = {}
end

function XUiTwoSideTowerOverview:RefreshDetails03()
    self.Details03UI.TxtId.text = string.format("%02d", self.ChapterId)
    self.Details03UI.TxtName.text = self._Control:GetChapterName(self.ChapterId)
    self.Details03UI.TxtDesc.text = self._Control:GetChapterOverviewDesc(self.ChapterId)
    local icon = self._Control:GetChapterOverviewIcon(self.ChapterId)
    self.Details03UI.RImgIcon:SetRawImage(icon)
    self.Details03UI.GameObject:SetActiveEx(true)
end

function XUiTwoSideTowerOverview:RefreshFeatureList()
    local pointId = self.PointIdList[self.SelectIndex]
    local stageIds = self._Control:GetPointStageIds(pointId)
    for index, stageId in pairs(stageIds) do
        local featureId = self._Control:GetStageFeatureId(stageId)
        local obj = self:GetDetailsObj(featureId)
        local grid = XUiGridTwoSideTowerBuffDetail.New(obj, self)
        self.GridDetailsList[index] = grid
        grid:Open()
        grid:Refresh(self.ChapterId, pointId, stageId)
    end
end

function XUiTwoSideTowerOverview:GetDetailsObj(featureId)
    local image = self._Control:GetFeatureImage(featureId)
    local obj
    if string.IsNilOrEmpty(image) then
        obj = XUiHelper.Instantiate(self.GridDetails01, self.Content)
    else
        obj = XUiHelper.Instantiate(self.GridDetails02, self.Content)
    end
    return obj
end

function XUiTwoSideTowerOverview:OnBtnTanchuangCloseClick()
    self:Close()
end

return XUiTwoSideTowerOverview
