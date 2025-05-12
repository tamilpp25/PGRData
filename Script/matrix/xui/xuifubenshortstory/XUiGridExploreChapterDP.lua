local XUiGridStage = require("XUi/XUiFubenMainLineChapter/XUiGridStage")

local XUiGridExploreChapterDP = XClass(nil, "XUiGridExploreChapterDP")
local MAX_STAGE_COUNT = CS.XGame.ClientConfig:GetInt("MainLineExploreStageMaxCount")
local FocusTime = 0.5
local ScaleLevel = {}

function XUiGridExploreChapterDP:Ctor(rootUi, ui, stageType)
    self.RootUi = rootUi
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.StageType = stageType or XEnumConst.FuBen.StageType.Mainline
    XTool.InitUiObject(self)
    self.GridStageList = {}
    self.GridEggStageList = {}
    self.LineList = {}
    self.CanPlayList = {}
    self:OnEnable()

    ScaleLevel = {
        Small = self.PanelDrag.MinScale,
        Big = self.PanelDrag.MaxScale,
        Normal = (self.PanelDrag.MinScale + self.PanelDrag.MaxScale) / 2,
    }
    self.Mask.gameObject:SetActiveEx(false)

    --读取自定义颜色数据
    self.Colors = {
        TxtChapterNameColor = self.TxtChapterNameColor ~= nil and self.TxtChapterNameColor.color, --章节名称
        TxtLeftTimeTipColor = self.TxtLeftTimeTipColor ~= nil and self.TxtLeftTimeTipColor.color, --剩余时间描述
        TxtLeftTimeColor = self.TxtLeftTimeColor ~= nil and self.TxtLeftTimeColor.color, --剩余时间
        StarColor = self.StarColor ~= nil and self.StarColor.color, --星星
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

function XUiGridExploreChapterDP:GetColors()
    return self.Colors
end

function XUiGridExploreChapterDP:GoToNearestStage()
    if #self.CanPlayList > 0 then
        local firstCanPlayId = self.CanPlayList[1]
        local firstGridStage = self.GridStageList[firstCanPlayId]
        if not firstGridStage then
            XLog.Error("ExploreGroup's setting is Error by stageIndex:" .. firstCanPlayId)
            return
        end

        local nearestTransform = firstGridStage.Transform
        local minDis = CS.UnityEngine.Vector3.Distance(nearestTransform.position, self.PanelDrag.gameObject.transform.position)
        for i = 2, #self.CanPlayList do
            local canPlayId = self.CanPlayList[i]
            local gridStage = self.GridStageList[canPlayId]
            if not gridStage then
                XLog.Error("ExploreGroup's setting is Error by stageIndex:" .. canPlayId)
                break
            end
            local tempDis = CS.UnityEngine.Vector3.Distance(gridStage.Transform.position, self.PanelDrag.gameObject.transform.position)
            if tempDis < minDis then
                nearestTransform = gridStage.Transform
                minDis = tempDis
            end
        end
        self.PanelDrag:FocusTarget(nearestTransform, ScaleLevel.Normal, FocusTime, CS.UnityEngine.Vector3.zero)
    end
end

function XUiGridExploreChapterDP:SetCanPlayList(canPlayList)
    self.CanPlayList = canPlayList
end

-- chapter 组件内容更新
function XUiGridExploreChapterDP:UpdateChapterGrid(data)
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
end

-- 根据stageId选中
function XUiGridExploreChapterDP:ClickStageGridByStageId(selectStageId)
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

function XUiGridExploreChapterDP:GetEggNum(stageList, eggStageCfg)
    for k, v in pairs(stageList) do
        if v == eggStageCfg.PreStageId[1] then --1为1号前置关卡
            return k
        end
    end
    return 0
end

function XUiGridExploreChapterDP:SetStageList()
    if XTool.UObjIsNil(self.GameObject) then return end

    if self.NormalStageList == nil then
        XLog.Error("Chapter have no id " .. self.ChapterId)
        return
    end
    
    local orderId = XFubenShortStoryChapterConfigs.GetChapterOrderIdByChapterId(self.ChapterId)
    
    -- 初始化副本显示列表，i作为order id，从1开始
    for i = 1, #self.NormalStageList do
        local stageId = self.NormalStageList[i]
        local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)
        local exploreInfoList
        if self.StageType == XEnumConst.FuBen.StageType.ShortStory then
            local exploreGroupId  = XFubenShortStoryChapterConfigs.GetExploreGroupIdByChapterId(self.ChapterId)
            exploreInfoList = XFubenShortStoryChapterConfigs.GetExploreGroupInfoByGroupId(exploreGroupId)
        end
        local preShowIndex = exploreInfoList[i] or {}
        local IsShow = true
        for _, index in pairs(preShowIndex or {}) do
            local stageInfo = XMVCA.XFuben:GetStageInfo(self.NormalStageList[index])
            if not stageInfo or not stageInfo.Passed then
                IsShow = IsShow and false
            end
        end
        if IsShow then
            local grid = self.GridStageList[i]
            if not grid then
                local uiName = "GridStage"
                uiName = stageCfg.StageGridStyle and string.format("%s%s", uiName, stageCfg.StageGridStyle) or uiName

                local parent = self.PanelStageContent.transform:Find(string.format("Stage%d", i))
                local prefabName = CS.XGame.ClientConfig:GetString(uiName)
                local prefab = parent:LoadPrefab(prefabName)

                grid = XUiGridStage.New(self.RootUi, prefab, handler(self, self.ClickStageGrid), XFubenConfigs.FUBENTYPE_NORMAL, true)
                grid.Parent = parent
                self.GridStageList[i] = grid
            end
            
            grid:UpdateStageMapGrid(stageCfg, orderId)
            if not XTool.UObjIsNil(grid.Parent.gameObject) then
                grid.Parent.gameObject:SetActiveEx(true)
            end
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
                    local parentsParent = self.PanelStageContent.transform:Find(string.format("Stage%d", self.EggStageList[i].Num))
                    local parent = self.PanelStageContent.transform:Find(string.format("Stage%d/EggStage", self.EggStageList[i].Num))
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

    for i = 1, MAX_STAGE_COUNT do
        if not self.GridStageList[i] then
            local parent = self.PanelStageContent.transform:Find(string.format("Stage%d", i))
            if parent then
                parent.gameObject:SetActiveEx(false)
            end
        end
    end

    if self.MoveArea then
        self.MoveArea:UpdateAreaSize()
    end
end

-- 选中一个 stage grid
function XUiGridExploreChapterDP:ClickStageGrid(grid)
    local curGrid = self.CurStageGrid
    if curGrid and curGrid.Stage.StageId == grid.Stage.StageId then
        return
    end

    local stageInfo = XMVCA.XFuben:GetStageInfo(grid.Stage.StageId)
    if not stageInfo.Unlock then
        XUiManager.TipMsg(XMVCA.XFuben:GetFubenOpenTips(grid.Stage.StageId))
        return
    end

    -- 取消上一个选择
    if curGrid then
        curGrid:SetStageActive()
    end

    -- 选中当前选择
    grid:SetStageSelect()
    grid:SetStoryStageSelect()

    self.CurStageGrid = grid
    self.IsNotPassedFightStage = false

    local stageCfg = XMVCA.XFuben:GetStageCfg(grid.Stage.StageId)
    if stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHT or stageCfg.StageType == XFubenConfigs.STAGETYPE_COMMON then
        self.IsNotPassedFightStage = not stageInfo.Passed
    end

    self.Mask.gameObject:SetActiveEx(true)
    XScheduleManager.ScheduleOnce(function()
        self.PanelDrag:FocusTarget(grid.Transform, ScaleLevel.Big, FocusTime, CS.UnityEngine.Vector3.zero, function()
            -- 选中回调
            if self.ShowStageCb then
                self.ShowStageCb(grid.Stage, grid.ChapterOrderId)
            end
            self.Mask.gameObject:SetActiveEx(false)
        end)
    end, 0)
end

function XUiGridExploreChapterDP:IsEggStage(stageCfg)
    return stageCfg.StageType == XFubenConfigs.STAGETYPE_STORYEGG or stageCfg.StageType == XFubenConfigs.STAGETYPE_FIGHTEGG
end

-- 模拟点击一个关卡
function XUiGridExploreChapterDP:ClickStageGridByIndex(index)
    local grid = self.GridStageList[index]
    self:ClickStageGrid(grid)
end

function XUiGridExploreChapterDP:ClickEggStageGridByIndex(index)
    local grid = self.GridEggStageList[index]
    self:ClickStageGrid(grid)
end

function XUiGridExploreChapterDP:Show()
    if self.GameObject.activeSelf == true then return end
    self.GameObject:SetActiveEx(true)
end

function XUiGridExploreChapterDP:Hide()
    if not self.GameObject:Exist() or self.GameObject.activeSelf == false then return end
    self.GameObject:SetActiveEx(false)
end

function XUiGridExploreChapterDP:OnEnable()
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

function XUiGridExploreChapterDP:OnDisable()
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

function XUiGridExploreChapterDP:CancelSelect()
    if not self.CurStageGrid then
        return false
    end

    self.CurStageGrid:SetStageActive()
    self.CurStageGrid:SetStoryStageActive()
    self.CurStageGrid = nil

    if self.HideStageCb then
        self.HideStageCb()
    end
end

function XUiGridExploreChapterDP:OnQuickJumpClick(index)
    self:ClickStageGridByIndex(index)
end

function XUiGridExploreChapterDP:ScaleBack()
    self.PanelDrag:FocusTarget(self.CurStageGrid.Transform, ScaleLevel.Normal, FocusTime, CS.UnityEngine.Vector3.zero, nil)
end

return XUiGridExploreChapterDP