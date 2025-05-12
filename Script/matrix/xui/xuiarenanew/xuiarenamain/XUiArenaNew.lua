local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiArenaNewPrepare = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewPrepare")
local XUiArenaNewLeft = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewLeft")
local XUiArenaNewRight = require("XUi/XUiArenaNew/XUiArenaMain/XUiArenaNewRight")
local XUiArenaScene = require("XUi/XUiArenaNew/XUiArenaScene")

---@class XUiArenaNew : XLuaUi
---@field PanelPrepare UnityEngine.RectTransform
---@field BtnBack XUiComponent.XUiButton
---@field BtnMainUi XUiComponent.XUiButton
---@field PanelAsset UnityEngine.RectTransform
---@field BtnHelp XUiComponent.XUiButton
---@field PanelLeft UnityEngine.RectTransform
---@field PanelRight UnityEngine.RectTransform
---@field _Control XArenaControl
local XUiArenaNew = XLuaUiManager.Register(XLuaUi, "UiArenaNew")

local CameraState = {
    Main = 1,
    Chapter = 2,
    Tips = 3,
}

-- region 生命周期

function XUiArenaNew:OnAwake()
    ---@type XUiArenaNewPrepare
    self._PanelPrepareUi = nil
    ---@type XUiArenaNewLeft
    self._PanelLeftUi = nil
    ---@type XUiArenaNewRight
    self._PanelRightUi = nil
    ---@type XUiArenaScene
    self._Scene = XUiArenaScene.New(self.UiModelGo)
    self._CurrentState = CameraState.Main
    self._CurrentChapterIndex = 1
    self._Animation = nil
    self._EnterTimer = nil

    self:_InitAnimation()
    self:_RegisterButtonClicks()
end

---@param groupData XArenaGroupDataBase
function XUiArenaNew:OnStart(groupData)
    self._PanelPrepareUi = XUiArenaNewPrepare.New(self.PanelPrepare, self, groupData)
    self._PanelLeftUi = XUiArenaNewLeft.New(self.PanelLeft, self, groupData)
    self._PanelRightUi = XUiArenaNewRight.New(self.PanelRight, self, self._Scene)

    self._Scene:ChangeCamera("ChapterCamera")
    self._PanelRightUi:Close()
    self._PanelPrepareUi:Close()
    self._Scene:PlayStartAnimation()
    self._AssetUi = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:_ShowEnterEffect()
end

function XUiArenaNew:OnEnable()
    if not self._Control:CheckOpenNewActivityResultUi() then
        self._Control:CheckOpenActivityResultUi()
    end

    self:_RefreshCamera()
    self:_RegisterListeners()
end

function XUiArenaNew:OnDisable()
    self:_RemoveListeners()
    self:_RemoveEnterTimer()
end

function XUiArenaNew:OnDestroy()
    self._Scene:Destroy()
end

-- endregion

function XUiArenaNew:OnShowChapter(index)
    self._PanelLeftUi:Close()
    self._AssetUi:Close()
    self._PanelRightUi:Close()
    self._Scene:ChangeCamera("StageCamera" .. index)
    self:_SetExitPanelActive(false)
    self._CurrentChapterIndex = index
    self._CurrentState = CameraState.Chapter
end

function XUiArenaNew:OnShowTips()
    self._PanelLeftUi:Close()
    self._AssetUi:Close()
    self._PanelRightUi:Close()
    self._PanelPrepareUi:Close()
    self._Scene:SetZoneActive(false)
    self._Scene:ChangeCamera("TipsCamera")
    self:_SetExitPanelActive(false)
    self._CurrentState = CameraState.Tips
end

function XUiArenaNew:OnShowMainUi(isNotPlayAnimation)
    self:_Refresh()
    self._AssetUi:Open()
    self._Scene:SetZoneActive(true)
    self._Scene:CancelSelectZone()
    self._Scene:ChangeCamera("ChapterCamera")
    self:_SetExitPanelActive(true)
    self._CurrentState = CameraState.Main

    if not isNotPlayAnimation then
        self:_PlayBeginAnimation()
    end
end

-- region 私有方法

function XUiArenaNew:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "Arena")
end

function XUiArenaNew:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XEventId.EVENT_ARENA_RESHOW_MAIN_UI, self.OnShowMainUi, self)
end

function XUiArenaNew:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XEventId.EVENT_ARENA_RESHOW_MAIN_UI, self.OnShowMainUi, self)
end

function XUiArenaNew:_RefreshCamera()
    if self._CurrentState == CameraState.Tips then
        self:OnShowTips()
    elseif self._CurrentState == CameraState.Chapter then
        self._CurrentChapterIndex = self._Scene:GetCurrentSelectIndex()
        self:OnShowChapter(self._CurrentChapterIndex)
    else
        self:OnShowMainUi(true)
    end
end

function XUiArenaNew:_Refresh()
    self._PanelLeftUi:Open()
    if self._Control:GetIsRefreshMainPage() then
        if self._Control:IsInActivityFightStatus() then
            self._Control:GroupMemberRequest(Handler(self, self._RefreshLeftPanel))
        else
            self._Control:ScoreQueryRequest(Handler(self, self._RefreshLeftPanel))
        end
    end
    if self._Control:IsInActivityFightStatus() then
        self._Control:AreaDataRequest(function(areaData)
            self._PanelRightUi:Open()
            self._PanelRightUi:Refresh(areaData)
            self._PanelRightUi:CheckTaskRedDot()
        end)
        self._PanelPrepareUi:Close()
    else
        self._PanelPrepareUi:Open()
        self._PanelRightUi:Close()
    end
end

function XUiArenaNew:_RefreshLeftPanel(groupData)
    if groupData then
        self._PanelLeftUi:Refresh(groupData)
        self._Control:SetIsRefreshMainPage(false)
    end
end

function XUiArenaNew:_SetExitPanelActive(isActive)
    self.BtnBack.gameObject:SetActiveEx(isActive)
    self.BtnMainUi.gameObject:SetActiveEx(isActive)
    self.BtnHelp.gameObject:SetActiveEx(isActive)
end

function XUiArenaNew:_InitAnimation()
    if self.Transform then
        local animation = self.Transform:FindTransform("UiArenaNewJumpEnable")

        if animation then
            self._Animation = animation
        end
    end
end

function XUiArenaNew:_PlayBeginAnimation()
    if self._Animation then
        self._Animation.gameObject:PlayTimelineAnimation()
    end
end

function XUiArenaNew:_ShowEnterEffect()
    self:_RemoveEnterTimer()
    self._EnterTimer = XScheduleManager.ScheduleOnce(function()
        if self._Scene then
            self._Scene:ShowEnterEffect()
            self._Scene:ShowChangeEffect()
        end
        self._EnterTimer = nil
    end, XScheduleManager.SECOND)
end

function XUiArenaNew:_RemoveEnterTimer()
    if self._EnterTimer then
        XScheduleManager.UnSchedule(self._EnterTimer)
        self._EnterTimer = nil
    end
end

-- endregion

return XUiArenaNew
