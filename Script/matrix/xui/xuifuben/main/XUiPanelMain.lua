
local XUiGridWeeklyManager = require("XUi/XUiFuben/Main/XUiGridWeeklyManager")
local XUiPanelActivity = require("XUi/XUiFuben/Main/XUiPanelActivity")
local XUiBtnDownload = require("XUi/XUiDlcDownload/XUiBtnDownload")
local XUiPanelMain = XClass(XSignalData, "XUiPanelMain")

--######################## 静态方法 BEGIN ########################

function XUiPanelMain.CheckHasRedPoint()
    local FubenManagerEx = XDataCenter.FubenManagerEx
    local managers = FubenManagerEx.GetShowOnMainWeeklyManagers(true)
    for _, manager in ipairs(managers) do
        if manager:ExCheckIsShowRedPoint() then
            return true
        end
    end
    return false
end

--######################## 静态方法 END ########################

function XUiPanelMain:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.RootUi = rootUi
    self.UiPanelActivity = nil
    self.FubenManagerEx = XDataCenter.FubenManagerEx
    self.ItemManager = XDataCenter.ItemManager
    self.CurrentChapter = nil
    self.CurrentChapterManager = nil
    ---@type XUiGridWeeklyManager[]
    self.GridWeeklyDic = {}
    self.FirstTagIndex = nil
    self.ActivityManagerIndex = nil
    self.RefreshTimeId = XFubenConfigs.GetMainPanelTimeId()
    self.VersionName = XFubenConfigs.GetMainPanelName()
    self.VersionItemId = XFubenConfigs.GetMainPanelItemId()
    ---@type XUiBtnDownload
    self.GirdBtnDownload = XUiBtnDownload.New(self.BtnDownload)
    self.ImgLock = self.PanelLock.transform:Find("ImgLock")
    self:RegisterUiEvents()
end

function XUiPanelMain:SetData(firstIndex, activityManagerIndex)
    self.FirstTagIndex = firstIndex
    self.ActivityManagerIndex = activityManagerIndex
    self:Refresh()
    if activityManagerIndex and activityManagerIndex > 0 then
        self:OnBtnActivityClicked()
    end
    -- self:RefreshBg() 移到外层去了
end

function XUiPanelMain:OnEnable()
    self.InTime = nil
    self:Refresh()
    -- 刷新当前活动
    if self.UiPanelActivity then
        self.UiPanelActivity:OnEnable()
    end
end

function XUiPanelMain:TimeUpdate()
    for _, grid in pairs(self.GridWeeklyDic) do
        grid:RefreshTimeTips()
    end
    self:RefreshCurrentActivity()
    if self.UiPanelActivity and self.UiPanelActivity.GameObject.activeSelf then
        self.UiPanelActivity:TimeUpdate()
    end
    -- self:RefreshBg()
end

function XUiPanelMain:Refresh()
    -- 刷新当前活动
    self:RefreshCurrentActivity()
    -- 刷新当前章节
    self:RefreshCurrentChapter()
    -- 刷新周常
    self:RefreshWeeklyManagers()
end
--######################## 私有方法 ########################

function XUiPanelMain:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnActivity, self.OnBtnActivityClicked)
    XUiHelper.RegisterClickEvent(self, self.BtnChapter, self.OnBtnChapterClicked)
    if not XTool.UObjIsNil(self.BtnShop) then
        XUiHelper.RegisterClickEvent(self, self.BtnShop, self.OpenActivityShop)
    end
end

function XUiPanelMain:OnBtnActivityClicked()
    if not XFunctionManager.CheckInTimeByTimeId(self.RefreshTimeId) then
        return
    end
    self:OpenActivityUi()
end

function XUiPanelMain:OnBtnChapterClicked()
    if self.GirdBtnDownload:CheckNeedDownload() then
        self.GirdBtnDownload:OnBtnClick()
        return
    end
    if self.CurrentChapter == nil then
        return
    end
    self.CurrentChapterManager:ExOpenChapterUi(self.CurrentChapter, self.CurrentChapter:GetDifficulty())
end

-- 刷新周常活动
function XUiPanelMain:RefreshWeeklyManagers()
    self.FubenManagerEx.CheckShowManagersFinish(function()
        self:_RefreshWeeklyManagers()
    end)
end

function XUiPanelMain:_RefreshWeeklyManagers()
    local managers = self.FubenManagerEx.GetShowOnMainWeeklyManagers()
    local manager = nil
    local go = nil
    for index = 1, 4 do
        manager = managers[index]
        if self["WeeklyGrid" .. index] and self["WeeklyGrid" .. index].gameObject then
            self["WeeklyGrid" .. index].gameObject:SetActiveEx(manager ~= nil)
            if manager then
                local grid = self.GridWeeklyDic[index]
                if grid == nil then
                    go = XUiHelper.Instantiate(self.GridWeekActivity, self["WeeklyGrid" .. index])
                    go.gameObject:SetActiveEx(true)
                    grid = XUiGridWeeklyManager.New(go)
                    self.GridWeeklyDic[index] = grid
                end
                grid:SetData(managers[index])
            end
        end
    end
end

function XUiPanelMain:RefreshCurrentActivity()
    local inTime = XFunctionManager.CheckInTimeByTimeId(self.RefreshTimeId) -- 防止按钮一直刷新 检测到切换时再刷新
    if inTime ~= self.InTime then
        self:Change(inTime)
    end
    self.InTime = inTime
end

function XUiPanelMain:Change(inTime)
    -- v2.0 ui添加了图片资源处理
    self.BgZs = self.Transform:Find("BgZs")
    self.ImgBg = self.Transform:Find("BtnActivity/ImgBg")
    if self.BgZs then
        self.BgZs.gameObject:SetActiveEx(inTime)
        self.ImgBg.gameObject:SetActiveEx(inTime)
    end
    if not inTime then
        self.BtnActivity:SetDisable(true)
        self.ImgTitle.gameObject:SetActiveEx(false)
        self.BtnShop.gameObject:SetActiveEx(false)
        return
    end
    self.ImgTitle.gameObject:SetActiveEx(true)
    self.BtnActivity:SetDisable(false)
    self.BtnActivity:SetNameByGroup(0, self.VersionName)
    self.BtnActivity:SetNameByGroup(1, self.FubenManagerEx.GetActivityMainUiTips())
    self.BtnActivity:SetNameByGroup(2, self:GetMainTimeTip())
    local itemId = self.VersionItemId
    self.PanelActivityItem1.gameObject:SetActiveEx(itemId > 0)
    self.PanelActivityItem2.gameObject:SetActiveEx(itemId > 0)
    if itemId > 0 and not XTool.UObjIsNil(self.BtnShop) then
        self.BtnShop:SetNameByGroup(0, self.ItemManager.GetCount(itemId))
        self.BtnShop:SetSprite(self.ItemManager.GetItemIcon(itemId))
    end
end

function XUiPanelMain:GetMainTimeTip()
    local startTime = XFunctionManager.GetStartTimeByTimeId(self.RefreshTimeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.RefreshTimeId)
    return string.format( "%s-%s"
        , XTime.TimestampToGameDateTimeString(startTime, "MM.dd")
        , XTime.TimestampToGameDateTimeString(endTime, "MM.dd"))
end

function XUiPanelMain:RefreshCurrentChapter()
    local currentChapter, currentChapterManager = self.FubenManagerEx.GetCurrentRecordChapterAndManager()
    self.CurrentChapter = currentChapter
    self.CurrentChapterManager = currentChapterManager
    self.PanelChapterHave.gameObject:SetActiveEx(currentChapter ~= nil)
    self.PaenlChapterNone.gameObject:SetActiveEx(currentChapter == nil)
    if currentChapter == nil then
        self.PanelChapterNewEffect.gameObject:SetActiveEx(false)
        self.PanelChapterActivityTag.gameObject:SetActiveEx(false)
        self.PanelChapterMultipleWeeksTag.gameObject:SetActiveEx(false)
        self.BtnDownload.gameObject:SetActiveEx(false)
        return
    end
    
    self.RImgChapterIcon:SetRawImage(currentChapter:GetIcon())
    if currentChapterManager == self.FubenManagerEx.GetMainLineManager() then   -- 主线
        self.RImgChapterIcon.gameObject:GetComponent("RectTransform").sizeDelta = Vector2(460, 228) --ui规定的主线、支线尺寸
        self.EntryType = XDlcConfig.EntryType.MainChapter
        self.EntryParam = currentChapter:GetId()
    else    -- 支线
        self.RImgChapterIcon.gameObject:GetComponent("RectTransform").sizeDelta = Vector2(511, 224)
        local chapterType = currentChapterManager:ExGetChapterType()
        self.EntryType = XDlcConfig.GetEntryTypeByChapterType(chapterType)
        self.EntryParam = currentChapter:GetId()
    end
    self.GirdBtnDownload:Init(self.EntryType, self.EntryParam, nil, handler(self, self.OnDownloadComplete))
    self.GirdBtnDownload:RefreshView()
    self:RefreshLock(currentChapter:GetIsLocked(), self.GirdBtnDownload:CheckNeedDownload())
    self.TxtChapterName.text = currentChapter:GetName()
    self.PanelChapterNewEffect.gameObject:SetActiveEx(currentChapter:CheckHasNewTag())
    self.PanelChapterActivityTag.gameObject:SetActiveEx(currentChapter:CheckHasTimeLimitTag())
    local weeklyChallengeCount = currentChapter:GetWeeklyChallengeCount()
    self.PanelChapterMultipleWeeksTag.gameObject:SetActiveEx(weeklyChallengeCount > 0)
    self.TxtChapterWeekNum.text = weeklyChallengeCount
end

function XUiPanelMain:OpenActivityUi()
    XLuaUiManager.Open("UiActivityChapter", self.ActivityManagerIndex)
end

-- v1.31 战斗面板材料关货币显示优化
function XUiPanelMain:OpenActivityShop()
    XDataCenter.FubenRepeatChallengeManager.OpenShopByCB(function ()
        self.RootUi:PlayAnimationWithMask("AnimStart")
    end, nil)
end

function XUiPanelMain:CloseActivityUi()
    self.RootUi.Bg.gameObject:SetActiveEx(true)
    self.GameObject:SetActiveEx(true)
    self.RootUi:SetOperationActive(true)
end

function XUiPanelMain:OnDownloadComplete()
    if XTool.UObjIsNil(self.PanelLock) or not self.CurrentChapter then
        return
    end
    self:RefreshLock(self.CurrentChapter:GetIsLocked(), self.GirdBtnDownload:CheckNeedDownload())
end

function XUiPanelMain:RefreshLock(isLock, isNeedDownload)
    self.PanelLock.gameObject:SetActiveEx(isLock or isNeedDownload)
    if not XTool.UObjIsNil(self.ImgLock) then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end
end

return XUiPanelMain