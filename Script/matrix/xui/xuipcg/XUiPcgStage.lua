---@class XUiPcgStage : XLuaUi
---@field private _Control XPcgControl
local XUiPcgStage = XLuaUiManager.Register(XLuaUi, "UiPcgStage")

function XUiPcgStage:OnAwake()
    self:RegisterUiEvents()
end

function XUiPcgStage:OnStart(chapterId, index)
    self.ChapterId = chapterId
    self.ChapterIndex = index -- 对应XUiPcgMain界面第几个章节
    self.ChapterCfg = self._Control:GetConfigChapter(self.ChapterId)
    self.StageIds = self._Control:GetChapterStageIds(self.ChapterId)
    self:InitStageList()
    self:InitContentPos()
end

function XUiPcgStage:OnEnable()
    self:Refresh()
end

function XUiPcgStage:OnDisable()
end

function XUiPcgStage:OnDestroy()
    self.ChapterCfg = nil
end

function XUiPcgStage:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiPcgStage:OnBtnBackClick()
    self:Close()
end

function XUiPcgStage:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

-- 刷新界面
function XUiPcgStage:Refresh()
    self:RefreshChapterInfo()
    self:RefreshStageList()
end

-- 初始化关卡列表
function XUiPcgStage:InitStageList()
    self.GridStage.gameObject:SetActiveEx(false)
    local index = 1
    while(self["ListStage"..index] ~= nil) do
        self["ListStage"..index].gameObject:SetActiveEx(false)
        index = index + 1
    end
    local listStage = self["ListStage"..self.ChapterIndex]
    listStage.gameObject:SetActiveEx(true)

    self.StageGrids = {}
    local XUiGridPcgStage = require("XUi/XUiPcg/XUiGrid/XUiGridPcgStage")
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, _ in ipairs(self.StageIds) do
        local stageLink = listStage.transform:Find("Stage"..i)
        if not stageLink then
            XLog.Error(string.format("当前章节关卡数量为%s，预制体UiPcgStage的ListStage%s下缺少Stage%s挂点!请UI老师添加!", #self.StageIds, self.ChapterIndex, i))
            goto CONTINUE
        end

        local go = CSInstantiate(self.GridStage.gameObject, stageLink)
        ---@type XUiGridPcgStage
        local grid = XUiGridPcgStage.New(go, self)
        grid:Open()
        grid:SetClickCallBack(function(index)
            self:OnStageClick(index)
        end, function(index)
            self:OnBtnGiveUpClick(index)
        end)
        table.insert(self.StageGrids, grid)
        :: CONTINUE ::
    end
end

-- 初始化拖拽区域的位置
function XUiPcgStage:InitContentPos()
    local curStageId = self._Control:GetCurrentStageId()
    local index = self:GetStageIndex(curStageId)
    if XTool.IsNumberValid(index) then
        self:LocateToStage(index)
    else
        index = #self.StageIds
        for i = #self.StageIds, 1, -1 do
            local stageId = self.StageIds[i]
            local isPassed = self._Control:IsStagePassed(stageId)
            if not isPassed then
                index = i
            end
        end
        self:LocateToStage(index)
    end
end

-- 定位到关卡入口
function XUiPcgStage:LocateToStage(index)
    local listStage = self["ListStage"..self.ChapterIndex]
    local stageLink = listStage.transform:Find("Stage"..index)
    local offsetX = self.PanelStageList.rect.width * 0.5 -- 拖拽区域的中间
    local posX = -stageLink.anchoredPosition.x + offsetX
    if posX > 0 then posX = 0 end -- 向右拖拽到极限
    self.Content.anchoredPosition = CS.UnityEngine.Vector2(posX, self.Content.anchoredPosition.y)
end

-- 刷新章节信息
function XUiPcgStage:RefreshChapterInfo()
    local chapterCfg = self._Control:GetConfigChapter(self.ChapterId)
    self.TxtTitle.text = chapterCfg.Name
    local curStar, allStar = self._Control:GetChapterStarCount(self.ChapterId)
    local progressTxt = self._Control:GetClientConfig("ChapterProgressTxt", 2)
    self.TxtStarNum.text = string.format(progressTxt, curStar, allStar)
    self.RImgBg:SetRawImage(chapterCfg.BgIcon)
end

-- 刷新关卡列表
function XUiPcgStage:RefreshStageList()
    for i, stageId in ipairs(self.StageIds) do
        ---@type XUiGridPcgStage
        local grid = self.StageGrids[i]
        grid:SetData(i, stageId)
    end
end

-- 点击关卡
function XUiPcgStage:OnStageClick(index)
    local stageId = self.StageIds[index]
    
    -- 未解锁提示
    local isUnlock, tips = self._Control:IsStageUnlock(stageId)
    if not isUnlock then
        XUiManager.TipError(tips)
        return
    end
    
    -- 挑战中直接进入
    local currentStageId = self._Control:GetCurrentStageId()
    if currentStageId == stageId then
        self._Control.GameSubControl:OnStageContinue()
        XLuaUiManager.Open("UiPcgGame")
        return
    elseif currentStageId and currentStageId ~= stageId then
        local failTips = self._Control:GetClientConfig("ChallengeFailTips")
        XUiManager.TipError(failTips)
        return
    end

    -- 打开详情界面
    XLuaUiManager.Open("UiPcgStageDetail", stageId)
end

-- 点击关卡放弃
function XUiPcgStage:OnBtnGiveUpClick(index)
    local stageId = self.StageIds[index]
    local content = self._Control:GetClientConfig("GiveUpGameTips")
    XLuaUiManager.Open("UiPcgPopup", content, function()
        XMVCA.XPcg:PcgStageEndRequest(stageId, function()
            self:RefreshStageList()
        end)
    end)
end

-- 获取关卡的下标
function XUiPcgStage:GetStageIndex(stageId)
    for i, tempStageId in ipairs(self.StageIds) do
        if tempStageId == stageId then
            return i
        end
    end
end

return XUiPcgStage
