local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiArenaOnlineChapter = XLuaUiManager.Register(XLuaUi, "UiArenaOnlineChapter")
local XUiChapterPrefab = require("XUi/XUiArenaOnline/XUiChapterPrefab")

function XUiArenaOnlineChapter:OnAwake()
    self:AutoAddListener()
end

function XUiArenaOnlineChapter:OnStart()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    local chapterCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
    if not chapterCfg then return end

    self:CheckFirstOpen()
    XLog.Error("[XResourceManager优化] 已经无法运行, 从XResourceManager改为loadPrefab")
    local prefab = CS.UnityEngine.Object.Instantiate(self.Resource.Asset)
    prefab.transform:SetParent(self.PanelChapter, false)
    prefab.gameObject:SetLayerRecursively(self.PanelChapter.gameObject.layer)

    self.ChapterGrid = XUiChapterPrefab.New(prefab, self)
end

function XUiArenaOnlineChapter:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.AddEventListener(XEventId.EVENT_ARENAONLINE_DAY_REFRESH, self.OnArenaOnlineDayRefrsh, self)

    if self.ChapterGrid then
        self.ChapterGrid:OnEnable()
    end
end

function XUiArenaOnlineChapter:OnDisable()
    if self.ChapterGrid then
        self.ChapterGrid:OnDisable()
    end
    
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_WEEK_REFRESH, self.OnArenaOnlineWeekRefrsh, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENAONLINE_DAY_REFRESH, self.OnArenaOnlineDayRefrsh, self)
end

function XUiArenaOnlineChapter:GetSortingOrder()
    return self.Canvas.sortingOrder
end

function XUiArenaOnlineChapter:CheckFirstOpen()
    local firstOpen = XDataCenter.ArenaOnlineManager.CheckFirstOpen()
    if firstOpen then
        local chapterCfg = XDataCenter.ArenaOnlineManager.GetCurChapterCfg()
        XDataCenter.MovieManager.PlayMovie(chapterCfg.StoryId, function()
                XDataCenter.ArenaOnlineManager.SetFirstOpen()
                XLuaAudioManager.PauseMusic()
            end)
    end
end

-- 区域联机周刷新
function XUiArenaOnlineChapter:OnArenaOnlineWeekRefrsh()
    XDataCenter.ArenaOnlineManager.RunMain()
end

-- 区域联机日刷新
function XUiArenaOnlineChapter:OnArenaOnlineDayRefrsh()
    if self.ChapterGrid then
        self.ChapterGrid:OnEnable()
    end
end

function XUiArenaOnlineChapter:OnDestroy()
    if self.Resource then
        self.Resource:Release()
    end

    if self.ChapterGrid then
        self.ChapterGrid:OnDestroy()
        CS.UnityEngine.Object.Destroy(self.ChapterGrid.GameObject)
    end
end

function XUiArenaOnlineChapter:AutoAddListener()
    self:BindHelpBtn(self.BtnHelp, "ArenaOnline")
    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end
end

function XUiArenaOnlineChapter:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiArenaOnlineChapter:OnBtnBackClick()
    self:Close()
end

function XUiArenaOnlineChapter:OnGetEvents()
    return {CS.XEventId.EVENT_UI_DONE}
end

function XUiArenaOnlineChapter:OnNotify(evt)
    if evt == CS.XEventId.EVENT_UI_DONE then
        --区域变更播放动画
        if XDataCenter.ArenaOnlineManager.IsAreaChanged() then
            self.ChapterGrid:PlayTipsAnimation()
        end
    end
end