local XUiPanelFubenWeiLaStage = XClass(nil, "XUiPanelFubenWeiLaStage")
local XUiFubenWeiLaStageItem = require("XUi/XUiNewChar/WeiLa/XUiFubenWeiLaStageItem")
local UIFUBENKOROTUTORIA_TEACHING_DETAIL = "UiFunbenKoroTutoriaTeachingDetail"
local UIFUBENKOROTUTORIA_CHALLENGE_DETAIL = "UiFunbenKoroTutoriaChallengeDetail"
local XUguiDragProxy = CS.XUguiDragProxy

function XUiPanelFubenWeiLaStage:Ctor(uiRoot, ui, cfg, panelType)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.UiRoot = uiRoot
    self.Cfg = cfg
    self:InitPanel(panelType)
    self.GridTreasureList = {}
end

function XUiPanelFubenWeiLaStage:InitPanel(panelType)
    if panelType == XFubenNewCharConfig.KoroPanelType.Teaching then
        self.StageIds = self.Cfg.StageId
    end
    if panelType == XFubenNewCharConfig.KoroPanelType.Challenge then
        self.StageIds = self.Cfg.ChallengeStage
    end

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
        self.Stages[i] = XUiFubenWeiLaStageItem.New(self, itemStage)
        itemStage.gameObject:SetActiveEx(true)
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
function XUiPanelFubenWeiLaStage:InitTreasureGrade()
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
            grid = XUiGridTreasureGrade.New(self.UiRoot, item, XDataCenter.FubenManager.StageType.NewCharAct)
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
function XUiPanelFubenWeiLaStage:InitStarts()
    local curStars
    local totalStars
    curStars, totalStars = XDataCenter.FubenNewCharActivityManager.GetKoroStarProgressById(self.Cfg.Id)

    self.ImgJindu.fillAmount = totalStars > 0 and curStars / totalStars or 0
    self.ImgJindu.gameObject:SetActiveEx(true)
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", curStars, totalStars)

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

function XUiPanelFubenWeiLaStage:OnShow(type)
    self.PanelType = type
    self.GameObject:SetActiveEx(true)
    for i = 1, #self.StageIds do
        self.Stages[i]:UpdateNode(self.Cfg.Id, self.StageIds[i], i, self.PanelType)
    end
    if self.PanelType == XFubenNewCharConfig.KoroPanelType.Challenge then
        self.BtnTreasure.CallBack = function()
            self:OnBtnTreasureClick()
        end
        self.BtnTreasureBg.CallBack = function()
            self:OnBtnTreasureBgClick()
        end
        self:InitStarts()
    end
    for i = 1, #self.StageIds - 1 do
        self.Lines[i].gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageIds[i]))
    end

    for i = 2, #self.StageIds do
        self.StageGroup[i].gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageIds[i - 1]))
    end
    self.LineIcon.gameObject:SetActiveEx(XDataCenter.FubenNewCharActivityManager.CheckStagePass(self.StageIds[#self.StageIds - 1]))
    self.LineEnable:PlayTimelineAnimation()
end

function XUiPanelFubenWeiLaStage:OnHide()
    self.GameObject:SetActiveEx(false)
end

--选中关卡
function XUiPanelFubenWeiLaStage:UpdateNodesSelect(stageId)
    local stageIds = self.StageIds
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(stageIds[i] == stageId)
        end
    end
end

--取消选中关卡
function XUiPanelFubenWeiLaStage:ClearNodesSelect()
    local stageIds = self.StageIds
    for i = 1, #stageIds do
        if self.Stages[i] then
            self.Stages[i]:SetNodeSelect(false)
        end
    end
    self.IsOpenDetails = false
end

function XUiPanelFubenWeiLaStage:OpenStageDetails(stageId, id)
    self.IsOpenDetails = true
    self.BtnCloseDetail.gameObject:SetActiveEx(true)

    if self.PanelType == XFubenNewCharConfig.KoroPanelType.Teaching then
        self.UiRoot:OpenOneChildUi(UIFUBENKOROTUTORIA_TEACHING_DETAIL, self)
        self.UiRoot:FindChildUiObj(UIFUBENKOROTUTORIA_TEACHING_DETAIL):SetStageDetail(stageId, id)
        if XLuaUiManager.IsUiShow(UIFUBENKOROTUTORIA_CHALLENGE_DETAIL) then
            self.UiRoot:FindChildUiObj(UIFUBENKOROTUTORIA_CHALLENGE_DETAIL):Close()
        end
    end

    if self.PanelType == XFubenNewCharConfig.KoroPanelType.Challenge then
        self.UiRoot:OpenOneChildUi(UIFUBENKOROTUTORIA_CHALLENGE_DETAIL, self)
        self.UiRoot:FindChildUiObj(UIFUBENKOROTUTORIA_CHALLENGE_DETAIL):SetStageDetail(stageId, id)
        if XLuaUiManager.IsUiShow(UIFUBENKOROTUTORIA_TEACHING_DETAIL) then
            self.UiRoot:FindChildUiObj(UIFUBENKOROTUTORIA_TEACHING_DETAIL):Close()
        end
    end
    if self.AssetPanel then
        self.AssetPanel.GameObject:SetActiveEx(false)
    end
    self.PanelStageContentRaycast.raycastTarget = false
end

--关闭战斗详情
function XUiPanelFubenWeiLaStage:CloseStageDetails()
    self.IsOpenDetails = false
    self.BtnCloseDetail.gameObject:SetActiveEx(false)

    if XLuaUiManager.IsUiShow(UIFUBENKOROTUTORIA_TEACHING_DETAIL) then
        self.UiRoot:FindChildUiObj(UIFUBENKOROTUTORIA_TEACHING_DETAIL):CloseDetailWithAnimation()
    end


    if XLuaUiManager.IsUiShow(UIFUBENKOROTUTORIA_CHALLENGE_DETAIL) then
        self.UiRoot:FindChildUiObj(UIFUBENKOROTUTORIA_CHALLENGE_DETAIL):CloseDetailWithAnimation()
    end
    self.PanelStageContentRaycast.raycastTarget = true
    self:ClearNodesSelect()
    self.PaneStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
end

function XUiPanelFubenWeiLaStage:PlayScrollViewMove(gridTransform)
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

--点击关闭详情按钮
function XUiPanelFubenWeiLaStage:OnBtnCloseDetailClick()
    self:CloseStageDetails()
end

function XUiPanelFubenWeiLaStage:CheckCanClose()
    if self.IsOpenDetails then
        self:CloseStageDetails()
        return false
    end
    return true
end

function XUiPanelFubenWeiLaStage:OnBtnTreasureBgClick()
    self.TreasureDisable:PlayTimelineAnimation(function()
        self.PanelTreasure.gameObject:SetActiveEx(false)
        self:InitStarts()
    end)
end

function XUiPanelFubenWeiLaStage:OnBtnTreasureClick()
    self:InitTreasureGrade()
    self.PanelTreasure.gameObject:SetActiveEx(true)
    self.TreasureEnable:PlayTimelineAnimation()
end

--拖拽事件处理
function XUiPanelFubenWeiLaStage:OnDragProxy(dragType)
    if self.IsOpenDetails and dragType == 0 then
        self:CloseStageDetails()
    end
end

return XUiPanelFubenWeiLaStage