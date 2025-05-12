---@class XUiScoreTowerStoreyDetail : XLuaUi
---@field private _Control XScoreTowerControl
local XUiScoreTowerStoreyDetail = XLuaUiManager.Register(XLuaUi, "UiScoreTowerStoreyDetail")

function XUiScoreTowerStoreyDetail:OnAwake()
    self:RegisterUiEvents()
    self.GridStorey.gameObject:SetActiveEx(false)
    self.GridStageNormal.gameObject:SetActiveEx(false)
    self.GridStageBoss.gameObject:SetActiveEx(false)
end

---@param chapterId number 章节ID
---@param towerId number 塔ID
function XUiScoreTowerStoreyDetail:OnStart(chapterId, towerId)
    self:SetAutoCloseInfo(XMVCA.XScoreTower:GetActivityEndTime(), function(isClose)
        if isClose then
            XMVCA.XScoreTower:HandleActivityEnd()
        end
    end)
    self.ChapterId = chapterId
    self.TowerId = towerId
    self.CurFloorId = 0
    ---@type UiObject[]
    self.GridStoreyList = {}
    ---@type XUiGridScoreTowerStageNormal[]
    self.GridStageNormalList = {}
    ---@type XUiGridScoreTowerStageBoss
    self.GridStageBossUi = nil
    -- 关卡面板默认的位置
    self.DefaultStagePanelPos = self.PanelStage.localPosition
    self.MinX = self._Control:GetClientConfig("GridStageMoveMinX", 1, true)
    self.MaxX = self._Control:GetClientConfig("GridStageMoveMaxX", 1, true)
    self.TargetX = self._Control:GetClientConfig("GridStageMoveTargetX", 1, true)
    self.Duration = self._Control:GetClientConfig("GridStageMoveDuration", 1, true) / 1000
end

function XUiScoreTowerStoreyDetail:OnEnable()
    self.Super.OnEnable(self)
    self:Refresh()
    self:CheckSweepCondition()
end

function XUiScoreTowerStoreyDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_SCORE_TOWER_STAGE_CHANGE,
        XEventId.EVENT_SCORE_TOWER_OPEN_STAGE_DETAIL,
        XEventId.EVENT_SCORE_TOWER_CLOSE_STAGE_DETAIL,
    }
end

function XUiScoreTowerStoreyDetail:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_SCORE_TOWER_STAGE_CHANGE then
        self:OnStageChange(args[1])
    elseif event == XEventId.EVENT_SCORE_TOWER_OPEN_STAGE_DETAIL then
        self:OpenStageDetail(args[1], args[2])
    elseif event == XEventId.EVENT_SCORE_TOWER_CLOSE_STAGE_DETAIL then
        self:CloseStageDetail()
    end
end

function XUiScoreTowerStoreyDetail:OnDisable()
    self.Super.OnDisable(self)
end

function XUiScoreTowerStoreyDetail:Refresh()
    self.CurFloorId = self._Control:GetCurrentFloorId(self.ChapterId, self.TowerId)
    if not XTool.IsNumberValid(self.CurFloorId) then
        XLog.Error("error: CurFloorId is invalid")
        return
    end
    self:RefreshInfo()
    self:RefreshPlugInPoint()
    self:RefreshStageList()
    self:RefreshStoreyList()
end

-- 刷新塔层信息
function XUiScoreTowerStoreyDetail:RefreshInfo()
    -- 塔层名称
    self.TxtTitle.text = self._Control:GetFloorName(self.CurFloorId)
    -- 塔层背景图片
    local bgImgUrl = self._Control:GetFloorBgImgUrl(self.CurFloorId)
    if not string.IsNilOrEmpty(bgImgUrl) then
        self.Bg:SetRawImage(bgImgUrl)
    end
end

-- 刷新插件点数
function XUiScoreTowerStoreyDetail:RefreshPlugInPoint()
    if not self.PlugPointAsset then
        ---@type XUiPanelScoreTowerPlugPointAsset
        self.PlugPointAsset = require("XUi/XUiScoreTower/Common/XUiPanelScoreTowerPlugPointAsset").New(self.BtnTool, self)
    end
    self.PlugPointAsset:Open()
    self.PlugPointAsset:Refresh(self.ChapterId, self.TowerId, self.CurFloorId)
end

-- 刷新塔层关卡列表
function XUiScoreTowerStoreyDetail:RefreshStageList()
    self:RefreshNormalStageList()
    self:RefreshBossStageList()
end

-- 刷新普通关卡列表
function XUiScoreTowerStoreyDetail:RefreshNormalStageList()
    local stageIds = self._Control:GetFloorStageIdsByStageType(self.CurFloorId, XEnumConst.ScoreTower.StageType.Normal)
    if XTool.IsTableEmpty(stageIds) then
        for _, grid in pairs(self.GridStageNormalList) do
            grid:Close()
        end
        return
    end
    for index, stageId in ipairs(stageIds) do
        local parent = self[string.format("StageNormal%d", index)]
        if not parent then
            XLog.Error(string.format("error: StageNormal%d is nil", index))
            return
        end
        local grid = self.GridStageNormalList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridStageNormal, parent)
            grid = require("XUi/XUiScoreTower/Storey/XUiGridScoreTowerStageNormal").New(go, self)
            self.GridStageNormalList[index] = grid
        end
        grid:Open()
        grid:Refresh(self.ChapterId, self.TowerId, self.CurFloorId, stageId)
    end
    for i = #stageIds + 1, #self.GridStageNormalList do
        self.GridStageNormalList[i]:Close()
    end
end

-- 刷新Boss关卡列表
function XUiScoreTowerStoreyDetail:RefreshBossStageList()
    local stageIds = self._Control:GetFloorStageIdsByStageType(self.CurFloorId, XEnumConst.ScoreTower.StageType.Boss)
    if XTool.IsTableEmpty(stageIds) then
        if self.GridStageBossUi then
            self.GridStageBossUi:Close()
        end
        return
    end
    local stageId = stageIds[1] -- Boss关卡只有一个
    if not self.GridStageBossUi then
        local go = XUiHelper.Instantiate(self.GridStageBoss, self.StageBoss)
        self.GridStageBossUi = require("XUi/XUiScoreTower/Storey/XUiGridScoreTowerStageBoss").New(go, self)
    end
    self.GridStageBossUi:Open()
    self.GridStageBossUi:Refresh(self.ChapterId, self.TowerId, self.CurFloorId, stageId)
end

-- 刷新塔层列表
function XUiScoreTowerStoreyDetail:RefreshStoreyList()
    local floorIds = self._Control:GetAllFloorIds(self.TowerId)
    if XTool.IsTableEmpty(floorIds) then
        self.PanelStorey.gameObject:SetActiveEx(false)
        return
    end
    self.PanelStorey.gameObject:SetActiveEx(true)
    local floorCount = #floorIds
    for index, floorId in ipairs(floorIds) do
        local grid = self.GridStoreyList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridStorey, self.PanelStorey)
            self.GridStoreyList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid.gameObject.transform:SetAsFirstSibling()
        local isSelect = self.CurFloorId == floorId
        local isUnlock = self._Control:IsFloorUnlock(self.ChapterId, self.TowerId, floorId)
        grid:GetObject("ImgBgNormal").gameObject:SetActiveEx(not isSelect and isUnlock)
        grid:GetObject("ImgBgNow").gameObject:SetActiveEx(isSelect and isUnlock)
        grid:GetObject("ImgBgLock").gameObject:SetActiveEx(not isUnlock)
        grid:GetObject("TxtNum").gameObject:SetActiveEx(isUnlock)
        grid:GetObject("TxtNum").text = index
        grid:GetObject("ImgUp").gameObject:SetActiveEx(index < floorCount)
    end
    for i = floorCount + 1, #self.GridStoreyList do
        self.GridStoreyList[i].gameObject:SetActiveEx(false)
    end
end

-- 检查是否满足扫荡条件，满足则弹框提示
function XUiScoreTowerStoreyDetail:CheckSweepCondition()
    if not XTool.IsNumberValid(self.CurFloorId) then
        return
    end
    local isFullSweep, isSweepTower, curFloorId = self._Control:IsTowerSweepConditionPass(self.ChapterId, self.TowerId)
    if not isFullSweep then
        return
    end

    local title = self._Control:GetClientConfig("TowerStoreySweepTitle")
    local content = self._Control:GetClientConfig("TowerStoreySweepContent", isSweepTower and 2 or 1)
    content = XUiHelper.FormatText(content, isSweepTower and self._Control:GetTowerName(self.TowerId) or self._Control:GetFloorName(curFloorId))
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        XLuaUiManager.Remove("UiScoreTowerPopupStageDetail")
        self._Control:SweepFloorRequest(self.TowerId, function()
            local curTowerId = self._Control:GetCurrentTowerId(self.ChapterId)
            if XTool.IsNumberValid(curTowerId) then
                self:Refresh()
            else
                XLuaUiManager.PopThenOpen("UiScoreTowerChapterDetail", self.ChapterId)
            end
        end)
    end)
end

-- 关卡信息变更
---@param stageId number 关卡ID
function XUiScoreTowerStoreyDetail:OnStageChange(stageId)
    for _, grid in pairs(self.GridStageNormalList) do
        if grid:GetStageId() == stageId then
            grid:RefreshOther(true)
            grid:RefreshCharacterList()
        end
    end
    if self.GridStageBossUi then
        self.GridStageBossUi:RefreshOther(true)
        self.GridStageBossUi:RefreshCharacterList()
    end
    if self.PlugPointAsset and self.PlugPointAsset:IsNodeShow() then
        self.PlugPointAsset:RefreshCount()
    end
end

-- 打开关卡详情
---@param stageId number 关卡ID
---@param stageType number 关卡类型
function XUiScoreTowerStoreyDetail:OpenStageDetail(stageId, stageType)
    local stageNode
    if stageType == XEnumConst.ScoreTower.StageType.Normal then
        for _, grid in pairs(self.GridStageNormalList) do
            if grid:GetStageId() == stageId then
                grid:SetSelect(true)
                stageNode = grid.Transform.parent
            end
        end
    elseif stageType == XEnumConst.ScoreTower.StageType.Boss then
        if self.GridStageBossUi then
            self.GridStageBossUi:SetSelect(true)
            stageNode = self.GridStageBossUi.Transform.parent
        end
    else
        XLog.Error(string.format("error: stage type is invalid, stageId: %s, stageType: %s", stageId, stageType))
    end
    if not XTool.UObjIsNil(stageNode) then
        self:MoveSelectedStageToCenter(stageNode)
    end
    if self.PlugPointAsset then
        self.PlugPointAsset:Close()
    end
end

-- 关闭关卡详情
function XUiScoreTowerStoreyDetail:CloseStageDetail()
    for _, grid in pairs(self.GridStageNormalList) do
        grid:SetSelect(false)
    end
    if self.GridStageBossUi then
        self.GridStageBossUi:SetSelect(false)
    end
    self:RecoverStagePosition()
    self:RefreshPlugInPoint()
end

-- 选中的关卡格子移到中间
---@param rectTransform UnityEngine.RectTransform
function XUiScoreTowerStoreyDetail:MoveSelectedStageToCenter(rectTransform)
    local diffX = rectTransform.localPosition.x + self.PanelStage.localPosition.x
    if diffX < self.MinX or diffX > self.MaxX then
        local tarPosX = self.TargetX - rectTransform.localPosition.x
        local tarPos = self.PanelStage.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStage, tarPos, self.Duration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

-- 恢复关卡格子位置
function XUiScoreTowerStoreyDetail:RecoverStagePosition()
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelStage, self.DefaultStagePanelPos, self.Duration, XUiHelper.EaseType.Sin, function()
        XLuaUiManager.SetMask(false)
    end)
end

function XUiScoreTowerStoreyDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnGiveUp, self.OnBtnGiveUpClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiScoreTowerStoreyDetail:OnBtnBackClick()
    self:Close()
end

function XUiScoreTowerStoreyDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiScoreTowerStoreyDetail:OnBtnGiveUpClick()
    local title = self._Control:GetClientConfig("TowerStoreyGiveUpTitle")
    local content = self._Control:GetClientConfig("TowerStoreyGiveUpContent")
    XUiManager.DialogTip(title, content, XUiManager.DialogType.Normal, nil, function()
        self._Control:AdvanceSettleRequest(self.TowerId, function()
            XLuaUiManager.PopThenOpen("UiScoreTowerChapterDetail", self.ChapterId)
        end)
    end)
end

return XUiScoreTowerStoreyDetail
