local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiTransfiniteBattlePrepareGridHead = require("XUi/XUiTransfinite/Main/XUiTransfiniteBattlePrepareGridHead")
local XViewModelTransfiniteRoom = require("XEntity/XTransfinite/ViewModel/XViewModelTransfiniteRoom")

---@class XUiTransfiniteBattlePrepare:XLuaUi
local XUiTransfiniteBattlePrepare = XLuaUiManager.Register(XLuaUi, "UiTransfiniteBattlePrepare")

function XUiTransfiniteBattlePrepare:Ctor()
    ---@type XViewModelTransfiniteRoom
    self._ViewModel = XViewModelTransfiniteRoom.New()
end

function XUiTransfiniteBattlePrepare:OnAwake()
    local root = self.UiModelGo.transform
    self.UiModelParent = root:FindTransform("PanelRoleModel")
    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(self.UiModelParent)
    ---@type
    self._BtnAffix = { self.BtnAffix1, self.BtnAffix2, self.BtnAffix3 }
    if not self.ImgGift then
        self.ImgGift = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelGift/ImgGiftBg/ImgGift", "RawImage")
    end
    if not self.TxtLock then
        self.TxtLock = XUiHelper.TryGetComponent(self.PanelLock, "TxtLock", "Text")
    end
    if not self.PanelDrag then
        self.PanelDrag = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelDrag", "XDrag")
    end

    ---@type XUiTransfiniteBattlePrepareGridHead[]
    self._GridCharacter = {
        XUiTransfiniteBattlePrepareGridHead.New(self.PanelHero2),
        XUiTransfiniteBattlePrepareGridHead.New(self.PanelHero1),
        XUiTransfiniteBattlePrepareGridHead.New(self.PanelHero3),
    }
    for i = 1, #self._GridCharacter do
        local grid = self._GridCharacter[i]
        self:RegisterClickEvent(grid.BtnEmpty, self.OnClickTeam)
    end

    self:BindExitBtns()
    self:RegisterClickEvent(self.BtnLeft, self.OnClickLeft)
    self:RegisterClickEvent(self.BtnRight, self.OnClickRight)
    self:RegisterClickEvent(self.BtnResetting, self.OnClickReset)
    self:RegisterClickEvent(self.PaneHeroInformation, self.OnClickTeam)
    self:RegisterClickEvent(self.BtnWeather, self.OnClickEnvironment)
    self:RegisterClickEvent(self.Btn, self.OnClickScore)
    self.BtnBattle.CallBack = function()
        self:OnClickFight()
    end

    ---@type XUiGridCommon
    --self._GridReward = XUiGridCommon.New(self, self.GridReward)

    ---@type XUiGridCommon
    --self._GridRewardExtra = XUiGridCommon.New(self, self.GridRewardExtra)
end

function XUiTransfiniteBattlePrepare:OnStart(stageGroup)
    if stageGroup then
        self._ViewModel:SetStageGroup(stageGroup)
    end
    self._ViewModel:OnAwake()
    self.PanelAnchor.gameObject:SetActiveEx(false)
end

function XUiTransfiniteBattlePrepare:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_TRANSFINITE_UPDATE_ROOM, self.Update, self)
    self._ViewModel:OnEnable()
    self:Update()
end

function XUiTransfiniteBattlePrepare:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRANSFINITE_UPDATE_ROOM, self.Update, self)
end

function XUiTransfiniteBattlePrepare:Update(resetIndex)
    self._ViewModel:Update(resetIndex)
    local data = self._ViewModel.Data
    local modelName = data.BossModel
    self.RoleModel:UpdateRoleModel(modelName, nil, self.Name, function(model)
        self.PanelDrag.Target = model.transform
    end, nil, true)
    self.TxtBattleTime.text = data.Time
    self.BtnBattle:SetNameByGroup(0, data.Progress)

    self.ImgAddedRewardTitleBg.gameObject:SetActiveEx(data.IsStageReward)
    self.ImgNormalTitleBg.gameObject:SetActiveEx(data.IsStageNormal)
    self.ImgBossTitleBg.gameObject:SetActiveEx(data.IsStageHidden)

    self.BtnRight.gameObject:SetActiveEx(data.IsEnableRightArrow)
    self.BtnLeft.gameObject:SetActiveEx(data.IsEnableLeftArrow)

    local eventList = data.Event
    for i = 1, #self._BtnAffix do
        local btn = self._BtnAffix[i]
        local dataEvent = eventList[i]
        if dataEvent then
            btn.gameObject:SetActiveEx(true)
            btn:SetNameByGroup(0, dataEvent.Name)
            btn:SetRawImage(dataEvent.Icon)
            self:RegisterClickEvent(btn, function()
                self:OnClickBuff(dataEvent)
            end, true)
        else
            btn.gameObject:SetActiveEx(false)
        end
    end

    --self._GridReward:Refresh(data.Reward)
    --self._GridReward:SetCount(data.RewardAmount)
    --self._GridRewardExtra:Refresh(data.ExtraReward)
    --self._GridRewardExtra:SetCount(data.ExtraRewardAmount)

    --self.PanelNow.gameObject:SetActiveEx(data.IsStageCurrent)
    self.PanelLock.gameObject:SetActiveEx(data.IsStageLock)
    if data.IsStageLock then
        self.TxtLock.text = data.TxtStageLock
    end
    self.PanelComplete.gameObject:SetActiveEx(data.IsStagePassed)

    if data.IsStageCurrent then
        self.BtnBattle:SetDisable(false)
        self.BtnBattle:SetNameByGroup(1, XUiHelper.GetText("TransfiniteBeginChallengeStage"))
    elseif data.IsShowRepeatBtn then
        self.BtnBattle:SetDisable(false)
        self.BtnBattle:SetNameByGroup(1, XUiHelper.GetText("TransfiniteRepeatChallengeStage"))
    else
        self.BtnBattle:SetDisable(true, false)
        self.BtnBattle:SetNameByGroup(1, XUiHelper.GetText("TransfiniteBeginChallengeStage"))
    end

    local members = data.Members
    for i = 1, #self._GridCharacter do
        local grid = self._GridCharacter[i]
        local dataMember = members[i]
        grid:Update(dataMember)
    end

    self.TxtTips.gameObject:SetActiveEx(data.IsTeamEmpty)

    self.TxtGiftNumber.text = data.Score

    if self.TxtAddedRewardTitle then
        if data.ExtraRewardTime > 0 then
            self.TxtAddedRewardTitle.text = data.ExtraDesc
            self.TxtAddedRewardTitle.gameObject:SetActiveEx(true)
            self.PanelRewardTitle.gameObject:SetActiveEx(true)
        else
            self.TxtAddedRewardTitle.gameObject:SetActiveEx(false)
            self.PanelRewardTitle.gameObject:SetActiveEx(false)
        end
    end

    self.ImgGift:SetRawImage(data.ImgScore)
    -- 锚点信息
    if not self._ViewModel:IsIsland() then
        self.PanelAnchor.gameObject:SetActiveEx(data.IsShowAnchor)
        self.TxtNextAnchor.text = data.TxtAnchorProgress
    end
end

function XUiTransfiniteBattlePrepare:OnClickLeft()
    self._ViewModel:MoveLeft()
    self:Update()
    self:PlayAnimation("QieHuan")
end

function XUiTransfiniteBattlePrepare:OnClickRight()
    self._ViewModel:MoveRight()
    self:Update()
    self:PlayAnimation("QieHuan")
end

function XUiTransfiniteBattlePrepare:OnClickReset()
    self._ViewModel:OnClickReset()
end

function XUiTransfiniteBattlePrepare:OnClickTeam()
    self._ViewModel:OnClickMember()
end

function XUiTransfiniteBattlePrepare:OnClickFight()
    self._ViewModel:OnClickFight()
end

function XUiTransfiniteBattlePrepare:OnClickEnvironment()
    self._ViewModel:OnClickEnvironment()
end

---@param data XViewModelTransfiniteRoomEvent
function XUiTransfiniteBattlePrepare:OnClickBuff(data)
    XLuaUiManager.Open("UiReformBuffDetail", {
        Name = data.Name,
        Icon = data.Icon,
        Description = data.Desc,
    })
end

function XUiTransfiniteBattlePrepare:OnClickScore()
    local itemId = XDataCenter.ItemManager.ItemId.TransfiniteScore
    local item = XDataCenter.ItemManager.GetItem(itemId)
    XLuaUiManager.Open("UiTip", item)
end

return XUiTransfiniteBattlePrepare
