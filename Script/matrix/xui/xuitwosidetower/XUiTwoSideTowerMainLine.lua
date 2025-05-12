local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPanelTwoSideTowerRoadLine = require("XUi/XUiTwoSideTower/XUiPanelTwoSideTowerRoadLine")

---@class XUiTwoSideTowerMainLine : XLuaUi
---@field _Control XTwoSideTowerControl
local XUiTwoSideTowerMainLine = XLuaUiManager.Register(XLuaUi, "UiTwoSideTowerMainLine")

function XUiTwoSideTowerMainLine:OnAwake()
    self:RegisterUiEvents()
    self.GridAffix.gameObject:SetActiveEx(false)
    self.GridFeatureList = {}
end

function XUiTwoSideTowerMainLine:OnStart(chapterId)
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self.ChapterId = chapterId
    self:InitStage()
    -- 开启自动关闭检查
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiTwoSideTowerMainLine:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()

    self._Control:CheckOpenUiChapterSettle(self.ChapterId)
    self._Control:CheckOpenUiChapterOverview(self.ChapterId)
end

function XUiTwoSideTowerMainLine:OnGetLuaEvents()
    return {
        XEventId.EVENT_TWO_SIDE_TOWER_POINT_STATUS_CHANGE
    }
end

function XUiTwoSideTowerMainLine:OnNotify(event, ...)
    if event == XEventId.EVENT_TWO_SIDE_TOWER_POINT_STATUS_CHANGE then
        self:Refresh()
    end
end

function XUiTwoSideTowerMainLine:InitStage()
    local prefab = self._Control:GetChapterFubenPrefab(self.ChapterId)
    local roadLineObj = self.PanelChapter:LoadPrefab(prefab)
    ---@type XUiPanelTwoSideTowerRoadLine
    self.RoadLinePanel = XUiPanelTwoSideTowerRoadLine.New(roadLineObj, self, self.ChapterId)
    self.RoadLinePanel:Open()
end

function XUiTwoSideTowerMainLine:Refresh()
    self:RefreshView()
    self:RefreshScore()
    self:RefreshFeatureList()
    self:RefreshEndStageStatus()
    -- 刷新路线
    self.RoadLinePanel:Refresh()
end

function XUiTwoSideTowerMainLine:RefreshView()
    -- 标题
    self.TxtTitle.text = self._Control:GetChapterName(self.ChapterId)
    -- 背景
    local chapterType = self._Control:GetChapterTypeByChapterId(self.ChapterId)
    self.Bg:SetRawImage(self._Control:GetClientConfig("ChapterBgIcon", chapterType))
    -- Boss图片
    self.Boss:SetRawImage(self._Control:GetChapterMonsterBg(self.ChapterId))
end

-- 刷新积分
function XUiTwoSideTowerMainLine:RefreshScore()
    -- 历史最高记录
    local isClear = self._Control:CheckChapterCleared(self.ChapterId)
    self.TxtHistory.gameObject:SetActiveEx(isClear)
    if isClear then
        local maxScoreIcon = self._Control:GetMaxChapterScoreIcon(self.ChapterId)
        self.RImgHistoryRank:SetRawImage(maxScoreIcon)
    end
    -- 当前评分（终末关卡通关后显示）
    local endPointId = self._Control:GetChapterEndPointId(self.ChapterId)
    local pointIsPass = self._Control:CheckPointIsPass(self.ChapterId, endPointId)
    self.PanelCurRank.gameObject:SetActiveEx(pointIsPass)
    if pointIsPass then
        local curScoreIcon = self._Control:GetCurChapterScoreIcon(self.ChapterId)
        self.RImgCurrentRank:SetRawImage(curScoreIcon)
    end
end

function XUiTwoSideTowerMainLine:RefreshFeatureList()
    local endPointId = self._Control:GetChapterEndPointId(self.ChapterId)
    -- 终末关卡是否通关
    local endPointIsPass = self._Control:CheckPointIsPass(self.ChapterId, endPointId)
    local pointIds = self._Control:GetChapterPointIds(self.ChapterId)
    for index, pointId in ipairs(pointIds) do
        local grid = self.GridFeatureList[index]
        if not grid then
            local go = index == 1 and self.GridAffix or XUiHelper.Instantiate(self.GridAffix, self.PanelAffixList)
            grid = XTool.InitUiObjectByUi({}, go)
            self.GridFeatureList[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        -- 当前节点是否通关
        local isPointPass = self._Control:CheckPointIsPass(self.ChapterId, pointId)
        grid.Empty.gameObject:SetActiveEx(not isPointPass)
        grid.Off.gameObject:SetActiveEx(false)
        grid.On.gameObject:SetActiveEx(isPointPass)
        local icon
        local featureId
        if isPointPass then
            featureId = self._Control:GetPassStageFeatureIdByPointId(self.ChapterId, pointId)
            icon = self._Control:GetFeatureIcon(featureId)
        else
            icon = self._Control:GetClientConfig("FeatureDefaultIcon")
        end
        grid.ImgAffixOn:SetRawImage(icon)
        grid.ImgAffixOff:SetRawImage(icon)
        if endPointIsPass and isPointPass then
            local isShield = self._Control:CheckChapterIsLastShieldFeature(self.ChapterId, featureId)
            grid.Off.gameObject:SetActiveEx(isShield)
            grid.On.gameObject:SetActiveEx(not isShield)
            grid.PanelScreen.gameObject:SetActiveEx(isShield)
        end
        if grid.Button then
            XUiHelper.RegisterClickEvent(grid, grid.Button, function()
                if not isPointPass then
                    local tipDesc = self._Control:GetClientConfig("ChapterFeatureClickTip")
                    local stageIds = self._Control:GetPointStageIds(pointId)
                    local desc = XUiHelper.FormatText(tipDesc, self._Control:GetStageTypeName(stageIds[1]))
                    XUiManager.TipMsg(desc)
                    return
                end
                local data = {
                    Name = self._Control:GetFeatureName(featureId),
                    Icon = self._Control:GetFeatureIcon(featureId),
                    Description = self._Control:GetFeatureDescZonglan(featureId)
                }
                XLuaUiManager.Open("UiReformBuffDetail", data)
            end)
        end
    end
    for i = #pointIds + 1, #self.GridFeatureList do
        self.GridFeatureList[i].GameObject:SetActiveEx(false)
    end
end

-- 刷新终末关卡的状态
function XUiTwoSideTowerMainLine:RefreshEndStageStatus()
    local allNormalPass = self._Control:CheckNormalPointIsPass(self.ChapterId)
    self.BtnEndStageClick:SetDisable(not allNormalPass)
end

function XUiTwoSideTowerMainLine:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.BtnOverview, self.OnBtnOverviewClick)
    XUiHelper.RegisterClickEvent(self, self.BtnReset, self.OnBtnResetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnEndStageClick, self.OnBtnEndStageClickClick)

    self:BindHelpBtn(self.BtnHelp, self._Control:GetHelpKey())
end

function XUiTwoSideTowerMainLine:OnBtnBackClick()
    self:Close()
end

function XUiTwoSideTowerMainLine:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTwoSideTowerMainLine:OnBtnOverviewClick()
    XLuaUiManager.Open("UiTwoSideTowerOverview", self.ChapterId)
end

function XUiTwoSideTowerMainLine:OnBtnResetClick()
    local title = self._Control:GetClientConfig("ResetChapterTitle")
    local content = self._Control:GetClientConfig("ResetChapterContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:TwoSideTowerResetChapterRequest(self.ChapterId, function()
            self:Refresh()
        end)
    end)
end

function XUiTwoSideTowerMainLine:OnBtnEndStageClickClick()
    local allNormalPass = self._Control:CheckNormalPointIsPass(self.ChapterId)
    if not allNormalPass then
        XUiManager.TipMsg(self._Control:GetClientConfig("NormalPointNotPassTip"))
        return
    end
    XLuaUiManager.Open("UiTwoSideTowerEndStageDetail", self.ChapterId)
end

return XUiTwoSideTowerMainLine
