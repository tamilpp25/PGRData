local XUiGridTreasureGrade = require("XUi/XUiFubenMainLineChapter/XUiGridTreasureGrade")
local XUiPanelFubenChallengeStageList = XClass(XUiNode, "XUiPanelFubenChallengeStageList")
local XUiGridFubenChallengeStage = require("XUi/XUiCharacterFiles/Default/XUiGridFubenChallengeStage")
local XUguiDragProxy = CS.XUguiDragProxy

function XUiPanelFubenChallengeStageList:OnStart(cfg)
    self.Cfg = cfg
    self:InitPanel()
    self.GridTreasureList = {}
end

function XUiPanelFubenChallengeStageList:OnEnable()
    self:OnShow()
end

function XUiPanelFubenChallengeStageList:SetSubDetailPanelKey(detailPanelKey)
    self._DetailPanelKey = detailPanelKey
end

function XUiPanelFubenChallengeStageList:InitPanel()
    self.StageIds = self.Cfg.ChallengeStage

    self.DragProxy = self.PaneStageList:GetComponent(typeof(XUguiDragProxy))
    if not self.DragProxy then
        self.DragProxy = self.PaneStageList.gameObject:AddComponent(typeof(XUguiDragProxy))
    end
    self.DragProxy:RegisterHandler(handler(self, self.OnDragProxy))

    self.Stages = {}
    self.StageGroup = {}
    for i = 1, #self.StageIds do
        local itemStage = self.PanelStageContent:Find(string.format("Stage%d", i))
        if not itemStage then
            XLog.Error("XUiPanelFubenKoroStage:HandleStages() 函数错误: 游戏物体PanelStageContent下找不到名字为:" .. string.format("Stage%d", i) .. "的游戏物体")
            return
        end
        self.StageGroup[i] = itemStage
        self.Stages[i] = XUiGridFubenChallengeStage.New(itemStage, self)
        self.Stages[i]:Open()
    end

    self.Lines = {}
    for i = 1, #self.StageIds - 1 do
        local itemLine = self.PanelStageContent:Find(string.format("Line%d", i))
        self.Lines[i] = itemLine
    end
    self.LineIcon = self.PanelStageContent:Find("IconEnd")
    self.BtnCloseDetail.CallBack = function() self:OnBtnCloseDetailClick() end
end

--初始化挑战目标
function XUiPanelFubenChallengeStageList:InitTreasureGrade()
    local baseItem = self.GridTreasureGrade
    self.GridTreasureGrade.gameObject:SetActiveEx(false)

    for j = 1, #self.GridTreasureList do
        self.GridTreasureList[j].GameObject:SetActiveEx(false)
    end

    local targetList = self.Cfg.TreasureId
    if not targetList then
        return
    end

    local gridCount = #targetList
    for i = 1, gridCount do
        local grid = self.GridTreasureList[i]

        if not grid then
            local item = CS.UnityEngine.Object.Instantiate(baseItem)  -- 复制一个item
            grid = XUiGridTreasureGrade.New(self.Parent, item, XDataCenter.FubenManager.StageType.NewCharAct)
            grid.Transform:SetParent(self.PanelGradeContent, false)
            self.GridTreasureList[i] = grid
        end

        local treasureCfg = XFubenNewCharConfig.GetTreasureCfg(targetList[i])
        local curStars = XDataCenter.FubenNewCharActivityManager.GetKoroStarProgressById(self.Cfg.Id)
        grid:UpdateGradeGrid(curStars, treasureCfg, self.Cfg.Id)

        grid:InitTreasureList()
        grid.GameObject:SetActiveEx(true)
    end
end

--初始化收集进度
function XUiPanelFubenChallengeStageList:InitStarts()
    local curStars
    local totalStars
    curStars, totalStars = XDataCenter.FubenNewCharActivityManager.GetProcess()

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)

    local received = true
    for _, v in pairs(self.Cfg.TreasureId) do
        if not XDataCenter.FubenNewCharActivityManager.IsTreasureGet(v) then
            received = false
            break
        end
    end
    self.ImgLingqu.gameObject:SetActiveEx(received)

    local isShowRed = XDataCenter.FubenNewCharActivityManager.CheckTreasureReward(self.Cfg.Id)
    self.ImgRedProgress.gameObject:SetActiveEx(isShowRed)
end

function XUiPanelFubenChallengeStageList:OnShow()
    self:Open()
    for i = 1, #self.StageIds do
        self.Stages[i]:UpdateNode(self.Cfg.Id, self.StageIds[i], i)
    end
    for i = 1, #self.StageIds - 1 do
        self.Lines[i].gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageIds[i]))
    end

    local fristNewStageIndex = 1 
    for i = 2, #self.StageIds do
        local isPass = XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageIds[i - 1])
        
        if isPass then
            self.Stages[i]:Open()
        else
            self.Stages[i]:Close()
        end
        
        fristNewStageIndex = isPass and i or fristNewStageIndex
    end
    --定位最新关卡
    if fristNewStageIndex > 1 then self:SetPanelInNewStage(self.StageGroup[fristNewStageIndex].transform) end

    self.LineIcon.gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageIds[#self.StageIds - 1]))
    if self.LineEnable then
        self.LineEnable:PlayTimelineAnimation()
    end
end

--选中关卡
function XUiPanelFubenChallengeStageList:UpdateNodesSelect(stageId)
    local stageIds = self.StageIds
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

--取消选中关卡
function XUiPanelFubenChallengeStageList:ClearNodesSelect()
    local stageIds = self.StageIds
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

function XUiPanelFubenChallengeStageList:OpenStageDetails(stageId, id)
    self.IsOpenDetails = true
    self.BtnCloseDetail.gameObject:SetActiveEx(true)

    self.Parent:OpenOneChildUi(self._DetailPanelKey, self)
    self.Parent:FindChildUiObj(self._DetailPanelKey):SetStageDetail(stageId, id)
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

--关闭战斗详情
function XUiPanelFubenChallengeStageList:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)
    
    if XLuaUiManager.IsUiShow(self._DetailPanelKey) then
        self.Parent:FindChildUiObj(self._DetailPanelKey):CloseDetailWithAnimation()
    end
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiPanelFubenChallengeStageList:PlayScrollViewMove(gridTransform)
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

--自动定位
function XUiPanelFubenChallengeStageList:SetPanelInNewStage(gridTransform)
    local gridRect = gridTransform:GetComponent("RectTransform")
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX - gridRect.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

--点击关闭详情按钮
function XUiPanelFubenChallengeStageList:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiPanelFubenChallengeStageList:CheckCanClose()
    if self.IsOpenDetails then
        self:CloseStageDetails()
        return false
    end
    return true
end

--拖拽事件处理
function XUiPanelFubenChallengeStageList:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

return XUiPanelFubenChallengeStageList