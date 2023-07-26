local XViewModelDlcHuntChapterDetail = require("XEntity/XDlcHunt/XViewModel/XViewModelDlcHuntChapterDetail")
local XUiDlcHuntBossLevelGrid = require("XUi/XUiDlcHunt/Boss/XUiDlcHuntBossLevelGrid")
local XUiDlcHuntBossLevelDescGrid = require("XUi/XUiDlcHunt/Boss/XUiDlcHuntBossLevelDescGrid")
local XUiDlcHuntUtil = require("XUi/XUiDlcHunt/XUiDlcHuntUtil")
local XUiDlcHuntBossLevelRewardGrid = require("XUi/XUiDlcHunt/Boss/XUiDlcHuntBossLevelRewardGrid")

---@class XUiDlcHuntBossLevel:XLuaUi
local XUiDlcHuntBossLevel = XLuaUiManager.Register(XLuaUi, "UiDlcHuntBossLevel")

function XUiDlcHuntBossLevel:Ctor()
    ---@type XViewModelDlcHuntChapterDetail
    self._ViewModel = XViewModelDlcHuntChapterDetail.New()
    self._UiDifficultyList = {}
    self._UiDescList = {}
    self._UiRewardList = {}
end

function XUiDlcHuntBossLevel:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function()
        if self:DialogMatching() then
            return
        end
        XLuaUiManager.RunMain()
    end)

    -- uiDlcHunt hide panelAsset
    self.PanelAsset.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcDetails, self.OnClickDetail)
    XUiHelper.RegisterClickEvent(self, self.BtnMatching, self.OnClickMatching)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcYellow, self.OnClickCreateRoom)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcBlue, self.OnClickMatch)
    XUiHelper.RegisterClickEvent(self, self.BtnDlcRank, self.OnClickRank)
    self.PanelAffix1.gameObject:SetActiveEx(false)
    self.GridLevel.gameObject:SetActiveEx(false)
    --self.PanelBt
    --self.GridIconChip
    XEventManager.AddEventListener(XEventId.EVENT_DLC_HUNT_BOSS_SELECT_CHAPTER_UPDATE, self.UpdateChapter, self)
end

function XUiDlcHuntBossLevel:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_HUNT_BOSS_SELECT_CHAPTER_UPDATE, self.UpdateChapter, self)
end

---@param chapter XDlcHuntChapter
function XUiDlcHuntBossLevel:OnStart(chapter)
    self:UpdateChapter(chapter)
end

function XUiDlcHuntBossLevel:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.UpdateMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH, self.UpdateMatching, self)
    XEventManager.AddEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
    self:UpdateChapter()
end

function XUiDlcHuntBossLevel:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_CANCEL_MATCH, self.UpdateMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH, self.UpdateMatching, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_ROOM_MATCH_PLAYERS, self.OnMatchPlayers, self)
end

---@param chapter XDlcHuntChapter
function XUiDlcHuntBossLevel:UpdateChapter(chapter)
    if chapter then
        self._ViewModel:SetChapter(chapter)
    else
        chapter = self._ViewModel:GetChapter()
    end
    self.ParentUi:UpdateBossModel(chapter:GetModel(), chapter:GetModel2())
    self:Update()
    self.PanelBoss:SelectIndex(1)
end

function XUiDlcHuntBossLevel:Update()
    self:UpdateList()
end

function XUiDlcHuntBossLevel:UpdateList()
    local worldList = self._ViewModel:GetWorldList()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiDifficultyList, worldList, self.GridLevel, XUiDlcHuntBossLevelGrid)
    local buttonList = {}
    for i = 1, #self._UiDifficultyList do
        buttonList[i] = self._UiDifficultyList[i]:GetButton()
    end
    self.PanelBoss:Init(buttonList, function(index)
        local world = worldList[index]
        self._ViewModel:SetWorld(world)
        self:UpdateInfo()
        self:UpdateReward()
        self:PlayAnimation("QieHuan")
    end)
end

function XUiDlcHuntBossLevel:UpdateInfo()
    local descList = self._ViewModel:GetWorldDesc()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiDescList, descList, self.PanelAffix1, XUiDlcHuntBossLevelDescGrid)
end

function XUiDlcHuntBossLevel:OnClickDetail()
    XLuaUiManager.Open("UiDlcHuntBossDetails", self._ViewModel:GetWorld())
end

function XUiDlcHuntBossLevel:OnClickCreateRoom()
    if self:DialogMatching() then
        return
    end
    if self:TipUnlock() then
        return
    end
    XDataCenter.DlcRoomManager.CreateRoom(self._ViewModel:GetWorld(), 1, true)
end

function XUiDlcHuntBossLevel:OnClickMatch()
    if self:TipUnlock() then
        return
    end
    XDataCenter.DlcRoomManager.Match(self._ViewModel:GetWorld())
end

function XUiDlcHuntBossLevel:OnClickMatching()
    XDataCenter.DlcRoomManager.CancelMatch()
end

function XUiDlcHuntBossLevel:UpdateMatching()
    -- matching
    if XDataCenter.DlcRoomManager.IsMatching() then
        self.BtnMatching.gameObject:SetActiveEx(true)
        self.BtnDlcBlue.gameObject:SetActiveEx(false)
        return
    end

    -- normal
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.BtnDlcBlue.gameObject:SetActiveEx(true)
end

function XUiDlcHuntBossLevel:OnClickRank()
    local world = self._ViewModel:GetWorld()
    XLuaUiManager.Open("UiDlcHuntTeamRank", world)
end

function XUiDlcHuntBossLevel:Close()
    if self:DialogMatching() then
        return
    end
    self.ParentUi:DlcCloseChildUi(self.Name)
end

function XUiDlcHuntBossLevel:DialogMatching()
    if XDataCenter.DlcRoomManager.IsMatching() then
        XUiManager.TipMsg(CS.XTextManager.GetText("OnlineInstanceMatching"))
        return true
    end
    return false
end

function XUiDlcHuntBossLevel:UpdateReward()
    local rewardList = self._ViewModel:GetRewards()
    XUiDlcHuntUtil.UpdateDynamicItem(self._UiRewardList, rewardList, self.GridIconChip, XUiDlcHuntBossLevelRewardGrid)
end

function XUiDlcHuntBossLevel:TipUnlock()
    local world = self._ViewModel:GetWorld()
    local isUnlock, reason = world:IsUnlock()
    if not isUnlock then
        if reason == XDlcHuntWorldConfig.CHAPTER_LOCK_STATE.LOCK_FOR_FRONT_WORLD_NOT_PASS then
            local preWorld = world:GetPreWorld()
            if preWorld then
                XUiManager.TipMsg(XUiHelper.GetText("DlcHuntWorldLock4PreWorld", preWorld:GetName()))
            end
        end
        return true
    end
    return false
end

--匹配人数过多
function XUiDlcHuntBossLevel:OnMatchPlayers(code)
    self:UpdateMatching()
    if code == XCode.MatchInvalidToManyMatchPlayers then
        XLuaUiManager.Open("UiDlcHuntDialog",
                CS.XTextManager.GetText("MultiDimMainDetailMatchTipTitle"),
                CS.XTextManager.GetText("MultiDimMainDetailMatchTipContent"),
                function()
                    self:OnClickCreateRoom()
                end)
        return
    end
    if code == XCode.MatchPlayerHaveNotCreateRoom then
        XLuaUiManager.Open("UiDlcHuntDialog",
                CS.XTextManager.GetText("MultiDimMainDetailMatchTipTitle"),
                CS.XTextManager.GetText("DlcHuntAssistCreateRoom"),
                function()
                    self:OnClickCreateRoom()
                end)
        return
    end
end

return XUiDlcHuntBossLevel