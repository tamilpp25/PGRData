-- 意识公约主界面
local XUiAwarenessMain = XLuaUiManager.Register(XLuaUi, "UiAwarenessMain")
local XUiGridAwarenessChapter = require("XUi/XUiAwareness/Grid/XUiGridAwarenessChapter")

function XUiAwarenessMain:OnAwake()
    self:InitButton()
    self.ChapterGridList = {}

    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_ASSIGN_STAGE_CLICK, self.OnDetailShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_ASSIGN_STAGE_DETAIL_CLOSE, self.OnDetailHide, self)
end

function XUiAwarenessMain:InitButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function() XLuaUiManager.RunMain() end)
    self:BindHelpBtn(self.BtnHelp, "Awareness")
end

function XUiAwarenessMain:OnEnable()
    XDataCenter.FubenAwarenessManager.AwarenessGetDataRequest()
    self:Refresh()
    
    -- 检测提示trigger
    local chapterId = XDataCenter.FubenAwarenessManager.GetChapterFirstPassTrigger() 
    if chapterId then
        local chapterData = XDataCenter.FubenAwarenessManager.GetChapterDataById(chapterId)
        XUiManager.TipError(CS.XTextManager.GetText("AssignChapterCanOccupy", chapterData:GetName()))
    end
end

function XUiAwarenessMain:Refresh()
    -- 关卡列表
    local prefabName = CS.XGame.ClientConfig:GetString("GridAwarenessChapter")
    local chapterIdList = XDataCenter.FubenAwarenessManager.GetChapterIdList()
    for i, chapterId in pairs(chapterIdList) do
        local grid = self.ChapterGridList[i]
        if not grid then
            local parent = self["Stage" .. i]
            local prefab = parent:LoadPrefab(prefabName) 
            prefab:SetActiveEx(true)
            grid = XUiGridAwarenessChapter.New(self.RootUi, prefab)
            self.ChapterGridList[i] = grid
        end
        grid:Refresh(chapterId)
    end

    -- 进度
    local curr = XDataCenter.FubenAwarenessManager.GetAllChapterOccupyNum()
    local total = #XDataCenter.FubenAwarenessManager.GetChapterIdList()

    self.TxtTitleProgress.text = CS.XTextManager.GetText("AwarenessOccupyProgress", curr, total)
end

function XUiAwarenessMain:OnDetailShow(chapterId)
    local grid = nil
    for k, gridInList in pairs(self.ChapterGridList) do
        if gridInList.ChapterId == chapterId then
            grid = gridInList
            break
        end
    end

    -- 动画 居中当前grid
    self.DefaultContentPosX = self.PanelChapter.localPosition.x
    self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
    grid = grid.Transform
    local gridTf = grid.parent.gameObject:GetComponent("RectTransform")
    local diffX = gridTf.localPosition.x + self.PanelChapter.localPosition.x
    if diffX < XDataCenter.FubenMainLineManager.UiGridChapterMoveMinX or diffX > XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX then
        local tarPosX =  XDataCenter.FubenMainLineManager.UiGridChapterMoveMaxX - gridTf.localPosition.x
        local tarPos = self.PanelChapter.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        XUiHelper.DoMove(self.PanelChapter, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)
        end)
    end
end

function XUiAwarenessMain:OnDetailHide()
    -- 恢复到原来位置
    local tarPos = self.PanelChapter.localPosition
    tarPos.x = self.DefaultContentPosX
    XLuaUiManager.SetMask(true)
    XUiHelper.DoMove(self.PanelChapter, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
        self.ScrollRect.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
        XLuaUiManager.SetMask(false)
    end)
end

function XUiAwarenessMain:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_ASSIGN_STAGE_CLICK, self.OnDetailShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_ASSIGN_STAGE_DETAIL_CLOSE, self.OnDetailHide, self)
end
