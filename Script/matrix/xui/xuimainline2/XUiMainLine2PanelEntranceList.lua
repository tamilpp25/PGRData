---@class XUiMainLine2PanelEntranceList : XUiNode
---@field private _Control XMainLine2Control
local XUiMainLine2PanelEntranceList = XClass(XUiNode, "XUiMainLine2PanelEntranceList")

function XUiMainLine2PanelEntranceList:OnStart(chapterId, mainId, skipStageId, isOpenStageDetail)
    self.ChapterId = chapterId
    self.MainId = mainId
    self.SkipStageId = skipStageId
    self.IsOpenStageDetail = isOpenStageDetail
    self.EntranceDatas = self._Control:GetChapterEntranceDatas(chapterId)
    self.GridEntrances = {}
    self.BgIndex = 0
    self.StagePosXs = {}

    self:InitUi()
    self:InitEntrances()
    self:InitChangeBgTimer()
end

function XUiMainLine2PanelEntranceList:OnEnable()
    self:RefreshEntrances()

    -- 定位到关卡
    if self.SkipStageId then
        -- 跳转打开界面
        self:SkipToStage(self.SkipStageId, self.IsOpenStageDetail)
        self.SkipStageId = nil
        self.IsOpenStageDetail = nil
    else
        local isPass = self._Control:IsChapterPassed(self.ChapterId)
        if isPass then
            -- 章节通关，跳转到服务器记录打的最后一关，考虑老玩家重打主线
            local stageId = self._Control:GetLastPassStage(self.ChapterId)
            self:SkipToStage(stageId)
        else
            -- 章节未通关，跳转到最新的关卡
            local index = self._Control:GetChapterNextEntrance(self.ChapterId)
            self:LocateToEntrance(index)
        end
    end
end

function XUiMainLine2PanelEntranceList:OnDisable()
    
end

function XUiMainLine2PanelEntranceList:OnDestroy()
    self:ClearChangeBgTimer()

    self.ChapterId = nil
    self.MainId = nil
    self.EntranceDatas = nil
    self.GridEntrances = nil
    self.BgIndex = nil
    self.StagePosXs = nil
end

-- 初始化UI引用
function XUiMainLine2PanelEntranceList:InitUi()
    self.PanelStageContent = self.PanelStageContent or self.Transform:Find("PaneStageList/ViewPort/PanelStageContent")
    self.ScrollRect = self.ScrollRect or XUiHelper.TryGetComponent(self.Transform, "PaneStageList", "ScrollRect")
    self.LocateOffsetX = self.ScrollRect.viewport.rect.width * 0.5
end

-- 初始化入口
function XUiMainLine2PanelEntranceList:InitEntrances()
    local XUiMainLine2GridEntrance =  require("XUi/XUiMainLine2/XUiMainLine2GridEntrance")
    for i, data in pairs(self.EntranceDatas) do
        local parentGo = self.PanelStageContent:Find("Stage"..i)
        local lineGo = self.PanelStageContent:Find("Line"..(i-1))

        local stageId = data.StageIds[1]
        local stageCfg = XMVCA:GetAgency(ModuleId.XFuben):GetStageCfg(stageId)
        local uiName = "GridStage" .. stageCfg.StageGridStyle
        local prefabName = CS.XGame.ClientConfig:GetString(uiName)
        local prefab = parentGo:LoadPrefab(prefabName)

        parentGo.gameObject:SetActiveEx(true)
        local stage = XUiMainLine2GridEntrance.New(prefab, self, data, self.ChapterId, self.MainId, parentGo, lineGo)
        stage:Open()
        table.insert(self.GridEntrances, stage)
    end
end

-- 刷新入口列表
function XUiMainLine2PanelEntranceList:RefreshEntrances()
    for _, entrance in ipairs(self.GridEntrances) do
        entrance:Refresh()
    end
end

-- 初始化切换背景定时器
function XUiMainLine2PanelEntranceList:InitChangeBgTimer()
    local stageIndexs = self._Control:GetChapterBgStageIndexs(self.ChapterId)
    if #stageIndexs == 0 then
        return
    end

    -- 记录切换背景入口相的anchoredPosition.x
    for _, index in ipairs(stageIndexs) do
        local stageGo = self.PanelStageContent:Find("Stage" .. tostring(index))
        local posX = stageGo.anchoredPosition.x
        table.insert(self.StagePosXs, posX)
    end

    self:ClearChangeBgTimer()
    self.ChangeBgTimer = XScheduleManager.ScheduleForever(function()
        self:CheckChangeBg()
    end, 100)
end

-- 检测切换背景
function XUiMainLine2PanelEntranceList:CheckChangeBg(ignoreAnim)
    local curIndex = self:CalcuBgIndex()
    if self.BgIndex ~= curIndex then
        -- 背景图
        local bgStageIndexs = self._Control:GetChapterBgStageIndexs(self.ChapterId)
        for i = 1, #bgStageIndexs do
            local bg = self:GetRImgChapterBg(i)
            bg.alpha = i == curIndex and 1 or 0
        end

        -- 动画
        if not ignoreAnim then
            local animIndex = curIndex > self.BgIndex and curIndex or -curIndex
            local anim = self:GetBgQieHuanAnim(animIndex)
            if anim then
                anim:PlayTimelineAnimation()
            end
        end

        self.Parent:RefreshChapterUiColor(curIndex)
        self.BgIndex = curIndex
    end
end

-- 计算背景下标
function XUiMainLine2PanelEntranceList:CalcuBgIndex()
    local moveLength = -self.PanelStageContent.anchoredPosition.x -- 滚动容器移动距离
    for i = #self.StagePosXs, 1, -1 do
        local posX = self.StagePosXs[i]
        -- 不需要关卡贴到屏幕左边才切换背景图，在滑动区域中心点就切换
        if moveLength > posX - self.LocateOffsetX then  
            return i
        end
    end

    return 1
end

-- 清除切换背景定时器
function XUiMainLine2PanelEntranceList:ClearChangeBgTimer()
    if self.ChangeBgTimer then
        XScheduleManager.UnSchedule(self.ChangeBgTimer)
        self.ChangeBgTimer = nil
    end
end

-- 获取章节背景图
function XUiMainLine2PanelEntranceList:GetRImgChapterBg(index)
    local bgName = "RImgChapterBg" .. tostring(index)
    local rImgBg = self[bgName]
    if not rImgBg then
        rImgBg = self.Transform:Find(bgName):GetComponent("CanvasGroup")
        self[bgName] = rImgBg
    end
    return rImgBg
end

-- 获取背景图切换动画
function XUiMainLine2PanelEntranceList:GetBgQieHuanAnim(index)
    local animName = "BgQieHuan" .. tostring(index)
    local bgAnim = self[animName]
    if not bgAnim then
        bgAnim = self.Transform:Find("Animation/" .. animName)
        self[animName] = bgAnim
    end
    return bgAnim
end

-- 根据关卡Id获取入口下标
function XUiMainLine2PanelEntranceList:GetEntranceIndexByStageId(stageId)
    for i, data in pairs(self.EntranceDatas) do
        for _, sId in ipairs(data.StageIds) do
            if sId == stageId then
                return i
            end
        end
    end

    XLog.Error(string.format("关卡%s不属于章节%s", stageId, self.ChapterId))
    return nil
end

-- 跳转到关卡
function XUiMainLine2PanelEntranceList:SkipToStage(stageId, isOpenDetail)
    if stageId == 0 then
        return
    end

    local index = self:GetEntranceIndexByStageId(stageId)
    if not index then
        return
    end

    self:LocateToEntrance(index)
    if isOpenDetail then
        local entrance = self.GridEntrances[index]
        entrance:OnBtnStageClick()
    end
end

-- 定位到入口
function XUiMainLine2PanelEntranceList:LocateToEntrance(index)
    local stageGo = self.PanelStageContent:Find("Stage" .. tostring(index))
    local posX = -stageGo.anchoredPosition.x + self.LocateOffsetX
    self.PanelStageContent.anchoredPosition = CS.UnityEngine.Vector2(posX, self.PanelStageContent.anchoredPosition.y)

    self:CheckChangeBg(true)
end

return XUiMainLine2PanelEntranceList