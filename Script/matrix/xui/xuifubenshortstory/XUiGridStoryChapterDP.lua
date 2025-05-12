local XUiGridStage = require("XUi/XUiFubenMainLineChapter/XUiGridStage")

local XUiGridStoryChapterDP = XClass(nil, "XUiGridStoryChapterDP")

local MAX_STAGE_COUNT = CS.XGame.ClientConfig:GetInt("MainLineStageMaxCount")

function XUiGridStoryChapterDP:Ctor(rootUi, ui, autoChangeBgArgs, isOnZhouMu)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.IsOnZhouMu = isOnZhouMu
    self.RectTransform = self.Transform:GetComponent("RectTransform")
    self.GridStageList = {}
    self.GridEggStageList = {}
    self.LineList = {}
    XTool.InitUiObject(self)
    self:InitAutoScript()

    -- 周目模式，记录当前周目章节最后一关的初始通关状态
    if self.IsOnZhouMu then
        self.zhouMuChapterId = XDataCenter.FubenZhouMuManager.GetZhouMuChapterIdByZhouMuId(self.RootUi.ZhouMuId)

        local lastStage = XFubenZhouMuConfigs.GetZhouMuChapterLastStage(self.zhouMuChapterId)
        self.OriLastStageIsPass = XMVCA.XFuben:CheckStageIsPass(lastStage)
    end

    --配置的格子位移超过某个阀值时，更换背景图片
    if not XTool.IsTableEmpty(autoChangeBgArgs) then
        self.AutoChangeBgArgs = autoChangeBgArgs
        local behaviour = self.GameObject:AddComponent(typeof(CS.XLuaBehaviour))
        if self.Update then
            behaviour.LuaUpdate = function() self:Update() end
        end
    end

    -- ScrollRect的点击和拖拽会触发关闭详细面板
    self:RegisterClickEvent(self.ScrollRect, handler(self, self.CancelSelect))
    local dragProxy = self.ScrollRect.gameObject:AddComponent(typeof(CS.XUguiDragProxy))
    dragProxy:RegisterHandler(handler(self, self.OnDragProxy))
    self:OnEnable()

    --读取自定义颜色数据
    self.Colors = {
        TxtChapterNameColor = self.TxtChapterNameColor ~= nil and self.TxtChapterNameColor.color,
        TxtLeftTimeTipColor = self.TxtLeftTimeTipColor ~= nil and self.TxtLeftTimeTipColor.color,
        TxtLeftTimeColor = self.TxtLeftTimeColor ~= nil and self.TxtLeftTimeColor.color,
        StarColor = self.StarColor ~= nil and self.StarColor.color,
        StarDisColor = self.StarDisColor ~= nil and self.StarDisColor.color,
        ImageBottomColor = self.ImageBottomColor ~= nil and self.ImageBottomColor.color,
        TxtStarNumColor = self.TxtStarNumColor ~= nil and self.TxtStarNumColor.color,
        TxtDescrColor = self.TxtDescrColor ~= nil and self.TxtDescrColor.color,
        Triangle0Color = self.Triangle0Color ~= nil and self.Triangle0Color.color,
        Triangle1Color = self.Triangle1Color ~= nil and self.Triangle1Color.color,
        Triangle2Color = self.Triangle2Color ~= nil and self.Triangle2Color.color,
        Triangle3Color = self.Triangle3Color ~= nil and self.Triangle3Color.color
    }
    if self.PanelColors then
        self.PanelColors.gameObject:SetActiveEx(false)
    end
end

function XUiGridStoryChapterDP:GetColors()
    return self.Colors
end

function XUiGridStoryChapterDP:InitAutoChangeBgComponents()
    if XTool.IsTableEmpty(self.AutoChangeBgArgs) then return end

    local datumLinePrecent = self.AutoChangeBgArgs.DatumLinePrecent
    if not datumLinePrecent or datumLinePrecent == 0 then return end

    --阀值为滚动容器去掉自适应扩展的padding宽度之后的实际宽度/2
    -- local padding = self.BoundSizeFitter.padding
    -- local contentWidth = self.PanelStageContent.rect.width
    -- local realWidth = contentWidth - padding.left - padding.right
    --阀值修改为可视区中心
    local viewPortRect = XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort", "RectTransform")
    if not viewPortRect then return end
    local realWidth = viewPortRect.rect.width
    self.LimitPosX = realWidth * datumLinePrecent
end

function XUiGridStoryChapterDP:RefreshAutoChangeBgStageIndex()
    if not self.LimitPosX then return end

    --关卡格子相对于阀值点的位置
    local stageIndex = self.AutoChangeBgArgs.StageIndex
    if not stageIndex or stageIndex == 0 then return end

    local stageTransform = self.PanelStageContent.transform:Find("Stage" .. stageIndex)
    if XTool.UObjIsNil(stageTransform) then
        XLog.Error("XUiGridStoryChapterDP:RefreshAutoChangeBgStageIndex error:stage not exist,stageIndex is:" .. stageIndex)
        return
    end

    local stageParent = stageTransform:GetComponent("RectTransform")
    if XTool.UObjIsNil(stageParent) then
        XLog.Error("XUiGridStoryChapterDP:RefreshAutoChangeBgStageIndex error:stage parent not exist,stageIndex is:" .. stageIndex)
        return
    end

    if not stageParent.gameObject.activeSelf then self.FirstSetBg = true return end
    self.StagePosX = stageParent.anchoredPosition.x

    --滚动容器移动距离
    local delta = self.PanelStageContent.anchoredPosition.x
    -- delta = self.StagePosX > self.LimitPosX and -delta or delta
    --标记是否满足超过阀值的条件
    self.AutoChangeBgFlag = self.StagePosX + delta > self.LimitPosX
    self.FirstSetBg = self.AutoChangeBgFlag
end

--配置的格子滑动位移超过某个阀值时触发一次回调
function XUiGridStoryChapterDP:Update()
    if self.AutoChangeBgFlag == nil then return end

    local cbParamFlag = self.AutoChangeBgFlag--回调参数
    local delta = self.PanelStageContent.anchoredPosition.x--滚动容器移动距离
    local fitCondition = self.StagePosX + delta > self.LimitPosX--滑动距离条件判断


    --配置的格子在阀值左边还是右边
    local moveDirectLeft = self.StagePosX > self.LimitPosX
    if moveDirectLeft then
        cbParamFlag = not cbParamFlag
        --delta = -delta
        fitCondition = not fitCondition
    end

    --滑动距离条件判断
    if fitCondition then
        if self.AutoChangeBgFlag then
            --位移正向超过阀值回调
            self.AutoChangeBgArgs.AutoChangeBgCb(cbParamFlag)
            self.AutoChangeBgFlag = false
        end
    else
        if not self.AutoChangeBgFlag then
            --位移反向超过阀值回调
            self.AutoChangeBgArgs.AutoChangeBgCb(cbParamFlag)
            self.AutoChangeBgFlag = true
        end
    end
end

function XUiGridStoryChapterDP:OnDragProxy(dragType)
    if dragType == 0 then
        self:OnScrollRectBeginDrag()
    elseif dragType == 2 then
        self:OnScrollRectEndDrag()
    end
end

function XUiGridStoryChapterDP:OnScrollRectBeginDrag()
    if self:CancelSelect() then
        self.ScrollRect.enabled = false
    end
end

function XUiGridStoryChapterDP:OnScrollRectEndDrag()
    self.ScrollRect.enabled = true
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiGridStoryChapterDP:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiGridStoryChapterDP:AutoInitUi()
    self.PanelStageContent = XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort/PanelStageContent", "RectTransform")
    self.BoundSizeFitter = XUiHelper.TryGetComponent(self.Transform, "PaneStageList/ViewPort/PanelStageContent", "XBoundSizeFitter")
    self.SViewStageList = XUiHelper.TryGetComponent(self.Transform, "SViewStageList", "ScrollRect")
    self.ScrollRect = XUiHelper.TryGetComponent(self.Transform, "PaneStageList", "ScrollRect")
    -- 连线
    for i = 1, MAX_STAGE_COUNT do
        if not self.LineList[i] then
            local line = self.PanelStageContent.transform:Find("Line" .. i)
            self.LineList[i] = not XTool.UObjIsNil(line) and line
        end
    end
end

function XUiGridStoryChapterDP:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiGridStoryChapterDP:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiGridStoryChapterDP:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiGridStoryChapterDP:AutoAddListener()
    --self:RegisterClickEvent(self.SViewStageList, self.OnSViewStageListClick)
end
-- auto
function XUiGridStoryChapterDP:ScrollRectRollBack()
    -- 滚动容器回弹
    local width = self.RectTransform.rect.width
    local innerWidth = self.PanelStageContent.rect.width
    innerWidth = innerWidth < width and width or innerWidth
    local diff = innerWidth - width
    local tarPosX
    if self.PanelStageContent.localPosition.x < -width / 2 - diff then
        tarPosX = -width / 2 - diff
    elseif self.PanelStageContent.localPosition.x > -width / 2 then
        tarPosX = -width / 2
    else
        -- self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        return false
    end

    self:PlayScrollViewMoveBack(tarPosX)
    return true
end

function XUiGridStoryChapterDP:PlayScrollViewMoveBack(tarPosX)
    local tarPos = self.PanelStageContent.localPosition
    tarPos.x = tarPosX
    XLuaUiManager.SetMask(true)

    XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        -- self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiGridStoryChapterDP:GetGridByStageId(stageId)
    if self.NormalStageList then
        for k, v in pairs(self.NormalStageList) do
            if v == stageId then
                return self.GridStageList[k]
            end
        end
    end
    if self.EggStageList then
        for k, v in pairs(self.EggStageList) do
            if v == stageId then
                return self.GridEggStageList[k]
            end
        end
    end
    return nil
end

function XUiGridStoryChapterDP:GoToStage(stageId)
    local grid = self:GetGridByStageId(stageId)
    if not grid then
        return
    end
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    --local posX = self.PanelStageContent.localPosition.x
    local posX = gridTf.localPosition.x - self.RectTransform.rect.width / 2
    self.ScrollRect.horizontalNormalizedPosition = 0
    -- local diff = (self.ScrollRect.content.rect.width - self.RectTransform.rect.width)
    self.ScrollRect.horizontalNormalizedPosition = posX / (1 * self.ScrollRect.content.rect.width - self.RectTransform.rect.width)
end

-- chapter 组件内容更新
function XUiGridStoryChapterDP:UpdateChapterGrid(data)
    self.ChapterId = data.ChapterId
    self.HideStageCb = data.HideStageCb
    self.ShowStageCb = data.ShowStageCb

    self.EggStageList = {}
    self.NormalStageList = {}
    for _, v in pairs(data.StageList) do
        local stageCfg = XMVCA.XFuben:GetStageCfg(v)
        if self:IsEggStage(stageCfg) then
            local eggNum = self:GetEggNum(data.StageList, stageCfg)
            if eggNum ~= 0 then
                local egg = { Id = v, Num = eggNum }
                table.insert(self.EggStageList, egg)
            end
        else
            table.insert(self.NormalStageList, v)
        end
    end

    self:SetStageList()
    self:InitAutoChangeBgComponents()

    CS.XTool.WaitForEndOfFrame(function()
        self:RefreshAutoChangeBgStageIndex()
    end)
end

-- 根据stageId选中
function XUiGridStoryChapterDP:ClickStageGridByStageId(selectStageId)
    if not selectStageId then return end
    local IsEggStage = false
    local stageInfo = XMVCA.XFuben:GetStageInfo(selectStageId)
    if not stageInfo.IsOpen then return end

    local index = 0
    for i = 1, #self.NormalStageList do
        local stageId = self.NormalStageList[i]
        if selectStageId == stageId then
            index = i
            break
        end
    end
    for i = 1, #self.EggStageList do
        local stageId = self.EggStageList[i]
        if selectStageId == stageId then
            index = i
            IsEggStage = true
            break
        end
    end

    if index ~= 0 then
        if IsEggStage then
            self:ClickEggStageGridByIndex(index)
        else
            self:ClickStageGridByIndex(index)
        end
    end
end

function XUiGridStoryChapterDP:GetEggNum(stageList, eggStageCfg)
    for k, v in pairs(stageList) do
        if v == eggStageCfg.PreStageId[1] then --1为1号前置关卡
            return k
        end
    end
    return 0
end

function XUiGridStoryChapterDP:SetStageList()
    if self.NormalStageList == nil then
        XLog.Error("Chapter have no id " .. self.ChapterId)
        return
    end
    
    local orderId = XFubenShortStoryChapterConfigs.GetChapterOrderIdByChapterId(self.ChapterId)
    
    -- 初始化副本显示列表，i作为order id，从1开始
    for i = 1, #self.NormalStageList do
        local stageId = self.NormalStageList[i]
        local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
        local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)

        if stageInfo.IsOpen or self.IsOnZhouMu then
            local grid = self.GridStageList[i]
            if not grid then
                local uiName
                if stageInfo.Type == XEnumConst.FuBen.StageType.ActivtityBranch then
                    uiName = "GridBranchStage"
                elseif stageInfo.Type == XEnumConst.FuBen.StageType.ActivityBossSingle then
                    uiName = "GridActivityBossSingleStage"
                elseif stageInfo.Type == XEnumConst.FuBen.StageType.RepeatChallenge then
                    uiName = "GridRepeatChallengeStage"
                else
                    uiName = "GridStage"
                end
                uiName = stageCfg.StageGridStyle and uiName .. stageCfg.StageGridStyle or uiName

                local parent = self.PanelStageContent.transform:Find("Stage" .. i)
                local prefabName = CS.XGame.ClientConfig:GetString(uiName)
                local prefab = parent:LoadPrefab(prefabName)

                grid = XUiGridStage.New(self.RootUi, prefab, handler(self, self.ClickStageGrid), XFubenConfigs.FUBENTYPE_NORMAL, false, self.IsOnZhouMu)
                grid.Parent = parent
                self.GridStageList[i] = grid
            end

            grid:UpdateStageMapGrid(stageCfg, orderId)
            grid.Parent.gameObject:SetActiveEx(true)

            self:SetLineActive(i, true)
        end
    end

    for i = 1, #self.EggStageList do
        local stageId = self.EggStageList[i].Id
        local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
        local stageInfo = XMVCA.XFuben:GetStageInfo(stageId)

        if stageInfo.IsOpen then
            if XMVCA.XFuben:GetUnlockHideStageById(stageId) then
                local grid = self.GridEggStageList[i]
                if not grid then
                    local uiName = "GridStageSquare"
                    local parentsParent = self.PanelStageContent.transform:Find("Stage" .. self.EggStageList[i].Num)
                    local parent = self.PanelStageContent.transform:Find("Stage" .. self.EggStageList[i].Num .. "/EggStage")
                    local prefabName = CS.XGame.ClientConfig:GetString(uiName)
                    local prefab = parent:LoadPrefab(prefabName)
                    grid = XUiGridStage.New(self.RootUi, prefab, handler(self, self.ClickStageGrid), XFubenConfigs.FUBENTYPE_NORMAL)
                    grid.Parent = parentsParent
                    self.GridEggStageList[i] = grid
                end
                grid:UpdateStageMapGrid(stageCfg, orderId)
            end
        end
    end

    local activeStageCount = #self.GridStageList
    for i = activeStageCount + 1, MAX_STAGE_COUNT do
        local parent = self.PanelStageContent.transform:Find("Stage" .. i)
        if parent then
            parent.gameObject:SetActiveEx(false)
        end

        self:SetLineActive(i, false)
    end

    -- 移动至ListView正确的位置
    if self.BoundSizeFitter then
        self.BoundSizeFitter:SetLayoutHorizontal()
    end
end

function XUiGridStoryChapterDP:SetLineActive(index, active)
    local line = self.LineList[index - 1]
    if line then
        line.gameObject:SetActiveEx(active)
    end
end

-- 选中一个 stage grid
function XUiGridStoryChapterDP:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.Stage.StageId == grid.Stage.StageId then
        return
    end

    local stageInfo = XMVCA.XFuben:GetStageInfo(grid.Stage.StageId)
    if not stageInfo.Unlock then
        XUiManager.TipMsg(XMVCA.XFuben:GetFubenOpenTips(grid.Stage.StageId))
        return
    end

    -- 选中回调
    if self.ShowStageCb then
        self.ShowStageCb(grid.Stage, grid.ChapterOrderId)
    end

    if stageInfo.Type == XEnumConst.FuBen.StageType.ActivityBossSingle then
        return
    end

    -- 取消上一个选择
    if curGrid then
        curGrid:SetStageActive()
        curGrid:SetStoryStageActive()
    end

    -- 选中当前选择
    grid:SetStageSelect()

    grid:SetStoryStageSelect()

    if not self.IsOnZhouMu then
        -- 滚动容器自由移动
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        -- 面板移动
        self:PlayScrollViewMove(grid)
    end

    self.CurStageGrid = grid
end

-- 返回滚动容器是否动画回弹
function XUiGridStoryChapterDP:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid:SetStageActive()
    self.CurStageGrid:SetStoryStageActive()
    self.CurStageGrid = nil

    if self.HideStageCb then
        self.HideStageCb()
    end
    return self:ScrollRectRollBack()
end

function XUiGridStoryChapterDP:PlayScrollViewMove(grid)
    -- 动画
    local gridTf = grid.Parent.gameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.PanelStageContent.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX = XDataCenter.FubenMainLineManager.UiGridChapterMoveTargetX - gridTf.localPosition.x
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiGridStoryChapterDP:IsEggStage(stageCfg)
    return stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG
end

-- 模拟点击一个关卡
function XUiGridStoryChapterDP:ClickStageGridByIndex(index)
    local grid = self.GridStageList[index]
    self:ClickStageGrid(grid)
end

function XUiGridStoryChapterDP:ClickEggStageGridByIndex(index)
    local grid = self.GridEggStageList[index]
    self:ClickStageGrid(grid)
end

function XUiGridStoryChapterDP:Show()
    if self.GameObject.activeSelf == true then return end
    self.GameObject:SetActiveEx(true)
end

function XUiGridStoryChapterDP:Hide()
    if not self.GameObject:Exist() or self.GameObject.activeSelf == false then return end
    self.GameObject:SetActiveEx(false)
end

function XUiGridStoryChapterDP:OnEnable()
    if self.IsOnZhouMu then
        local animaState = XDataCenter.FubenZhouMuManager.CheckPlayTipAnima(self.RootUi.ZhouMuId, self.zhouMuChapterId, self.OriLastStageIsPass)

        if animaState == XFubenZhouMuConfigs.EnumZhouMuTipAnima.PlayStart then
            -- 新周目开启动画
            self.RootUi:PlayAnimation("MultipleWeekBegin")

        elseif animaState == XFubenZhouMuConfigs.EnumZhouMuTipAnima.PlayEndStart then
            -- 先播放当前周目结束动画，然后切换到新周目，再播放新周目开启动画
            self.RootUi:PlayAnimation("MultipleWeekEnd", function()
                self.RootUi:OnBtnSwitch1MultipleWeeksClick()
                self.RootUi:PlayAnimation("MultipleWeekBegin")
            end)

        elseif animaState == XFubenZhouMuConfigs.EnumZhouMuTipAnima.PlayEnd then
            -- 周目结束动画
            self.RootUi:PlayAnimation("MultipleWeekEnd")
        end

        -- 在检查完是否播放动画后更新标志
        self.zhouMuChapterId = XDataCenter.FubenZhouMuManager.GetZhouMuChapterIdByZhouMuId(self.RootUi.ZhouMuId)
        local lastStage = XFubenZhouMuConfigs.GetZhouMuChapterLastStage(self.zhouMuChapterId)
        self.OriLastStageIsPass = XMVCA.XFuben:CheckStageIsPass(lastStage)
    end

    if self.Enabled then
        return
    end
    if self.GridStageList then
        for _, v in pairs(self.GridStageList) do
            v:OnEnable()
        end
    end
    if self.GridEggStageList then
        for _, v in pairs(self.GridEggStageList) do
            v:OnEnable()
        end
    end
    self.Enabled = true
end

function XUiGridStoryChapterDP:OnDisable()
    if not self.Enabled then
        return
    end
    if self.GridStageList then
        for _, v in pairs(self.GridStageList) do
            v:OnDisable()
        end
    end
    if self.GridEggStageList then
        for _, v in pairs(self.GridEggStageList) do
            v:OnDisable()
        end
    end
    self.Enabled = false
end

return XUiGridStoryChapterDP