-- 边界公约区域界面
local XUiPanelAssignMain = XLuaUiManager.Register(XLuaUi, "UiPanelAssignMain")
local XUiGridAssignChapter = require("XUi/XUiAssign/XUiGridAssignChapter")

function XUiPanelAssignMain:OnAwake()
    self:InitComponent()
end

function XUiPanelAssignMain:OnStart() -- 用于跳转到stageId
    self:InitChapterGridList()
end

function XUiPanelAssignMain:InitComponent()
    self.PanelAsset = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:BindHelpBtn(self.BtnHelp, "Assign")

    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnBuff, self.OnBtnBuffClick)
    self:RegisterClickEvent(self.BtnTreasure, self.OnBtnTreasureClick)

end

function XUiPanelAssignMain:OnBtnTreasureClick()
    XLuaUiManager.Open("UiAssignTreasureDetail", self)
end

function XUiPanelAssignMain:InitChapterGridList()
    self.ListData = XDataCenter.FubenAssignManager.GetChapterIdList()
    self.ChapterGridList = {}
    local prefabName = CS.XGame.ClientConfig:GetString("GridAssignChapter")
    for i, chapterId in ipairs(self.ListData) do
        local parent = self["Stage" .. i]
        if parent then
            local prefab = parent:LoadPrefab(prefabName)
            local grid = XUiGridAssignChapter.New(self.RootUi, prefab)
            grid.Parent = parent
            prefab:SetActiveEx(true)
            parent.gameObject:SetActiveEx(false)
            table.insert(self.ChapterGridList, grid)
        else
            XLog.Error("配置章节数超过ui结点数，index:" .. i .. ", chapterId:" .. chapterId)
        end
    end
end

function XUiPanelAssignMain:OnEnable()
    if self.IsInitialed then
        self:Refresh()
    else
        self.IsInitialed = true
        XDataCenter.FubenAssignManager.AssignGetDataRequest(function()
            self:InitRefresh()
        end)
    end

    -- 检测提示trigger
    local chapterId = XDataCenter.FubenAssignManager.GetChapterFirstPassTrigger() 
    if chapterId then
        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
        XUiManager.TipError(CS.XTextManager.GetText("AssignChapterCanOccupy", chapterData:GetDesc()))
    end
end

function XUiPanelAssignMain:OnGetEvents()
    return { XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END }
end

--事件监听
function XUiPanelAssignMain:OnNotify(evt)
    if evt == XEventId.EVENT_ASSIGN_SELECT_OCCUPY_END then
        self:Refresh()
    end
end

function XUiPanelAssignMain:OnDestroy()
end

function XUiPanelAssignMain:OnBtnBackClick()
    self:Close()
end

function XUiPanelAssignMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPanelAssignMain:OnBtnBuffClick()
    -- XLuaUiManager.Open("UiAssignBuff")
    XLuaUiManager.Open("UiAssignOccupyProgress")
end

function XUiPanelAssignMain:InitRefresh()
    self:Refresh()
    self:ShowCurrentChapter()
    self:FirstShowHelpTip()
end

function XUiPanelAssignMain:Refresh()
    --标题驻守进度
    local chapterIdList = XDataCenter.FubenAssignManager.GetChapterIdList()
    local total = #chapterIdList
    local curr = 0
    for i, chapterId in ipairs(chapterIdList) do
        local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
        if chapterData:IsOccupy() then
            curr = curr + 1
        end
    end
    self.ImgTitleProgress.text = CS.XTextManager.GetText("AssignOccypyProgress", curr, total)

    -- 格子
    for i, grid in ipairs(self.ChapterGridList) do
        local chapterId = self.ListData[i]
        if not chapterId then
            grid.Parent.gameObject:SetActiveEx(false)
        else
            -- 只显示解锁章节
            local chapterData = XDataCenter.FubenAssignManager.GetChapterDataById(chapterId)
            if chapterData:IsPass() or XDataCenter.FubenAssignManager.IsCurrentChapter(chapterId) then
                grid.Parent.gameObject:SetActiveEx(true)
                grid:Refresh(chapterId)
            else
                grid.Parent.gameObject:SetActiveEx(false)
            end
        end
    end

    -- 适配所有子RectTransform的大小
    self.BoundSizeFitter:SetLayoutHorizontal()

    -- 奖励进度
    local curr = XDataCenter.FubenAssignManager.GetAllChapterRewardedNum()
    local total = #XDataCenter.FubenAssignManager.GetChapterIdList()
    self.TxtStarNum.text = CS.XTextManager.GetText("Fract", curr, total)
    self.ImgTreasureProgress.fillAmount = curr/total
    self.RewardRed.gameObject:SetActive(XDataCenter.FubenAssignManager.IsRewardRedPoint())
end

-- 显示当前章节
function XUiPanelAssignMain:ShowCurrentChapter()
    local showIndex = 0
    for i, _ in ipairs(self.ChapterGridList) do
        local chapterId = self.ListData[i]
        if chapterId and XDataCenter.FubenAssignManager.IsCurrentChapter(chapterId) then
            showIndex = i
            break
        end
    end
    if showIndex <= 3 then
        return
    end
    local showGrid = self.ChapterGridList[showIndex]
    local posX = showGrid.Parent.transform.localPosition.x - self.RectTransform.rect.width * 0.8
    self.ScrollRect.horizontalNormalizedPosition = posX / (1 * self.ScrollRect.content.rect.width - self.RectTransform.rect.width)
end

function XUiPanelAssignMain:FirstShowHelpTip()
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    local key = XDataCenter.FubenAssignManager.GetAccountEnterKey()
    local data = XSaveTool.GetData(key)
    if not data then
        XUiManager.ShowHelpTip("Assign")
        XSaveTool.SaveData(key, 1)
    end
end