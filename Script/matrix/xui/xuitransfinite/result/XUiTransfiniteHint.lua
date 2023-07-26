local XUiTransfiniteBattlePrepareGridHead = require("XUi/XUiTransfinite/Main/XUiTransfiniteBattlePrepareGridHead")

---@class XUiTransfiniteHint:XLuaUi
local XUiTransfiniteHint = XLuaUiManager.Register(XLuaUi, "UiTransfiniteHint")

function XUiTransfiniteHint:Ctor()
    ---@type XTransfiniteStageGroup
    self._StageGroup = false
end

function XUiTransfiniteHint:OnAwake()
    --self:BindExitBtns(self.BtnClose)
    self:BindExitBtns(self.BtnTanchuangClose)
    self:RegisterClickEvent(self.BtnCancel, self.Cancel)
    self:RegisterClickEvent(self.BtnConfirm, self.Confirm)

    ---@type XUiTransfiniteBattlePrepareGridHead[]
    self._GridCharacter = {
        XUiTransfiniteBattlePrepareGridHead.New(self.PanelHero2),
        XUiTransfiniteBattlePrepareGridHead.New(self.PanelHero1),
        XUiTransfiniteBattlePrepareGridHead.New(self.PanelHero3),
    }
end

function XUiTransfiniteHint:OnStart(stageGroup)
    self._StageGroup = stageGroup
end

function XUiTransfiniteHint:OnEnable()
    self:Update()
end

function XUiTransfiniteHint:Update()
    local stageGroup = self._StageGroup
    if not stageGroup then
        XLog.Error("[XUiTransfiniteHint] StageGroup is empty")
        return
    end

    local lastResult = stageGroup:GetLastResult()
    if not lastResult then
        XLog.Error("[XUiTransfiniteHint] LastResult is empty")
        return
    end
    local characterList = lastResult.CharacterResultList
    local members = {}
    for i = 1, #characterList do
        local character = characterList[i]
        local characterId = character.CharacterId
        local hp = character.HpPercent
        local sp = character.Energy

        ---@type XViewModelTransfiniteRoomMember
        local dataMember = {
            Index = i,
            Icon = XDataCenter.CharacterManager.GetCharRoundnessHeadIcon(characterId),
            Hp = hp,
            Sp = sp / 100,
            IsCaptain = false,
            IsFirst = false,
            IsDead = hp == 0,
        }
        members[#members + 1] = dataMember
    end

    for i = 1, #self._GridCharacter do
        local grid = self._GridCharacter[i]
        local dataMember = members[i]
        grid:Update(dataMember)
    end

    local time = lastResult.StageSpendTime
    local timeStr = XUiHelper.GetTime(time)
    self.TxtTime.text = timeStr

    local stageId = lastResult.LastWinStageId
    if stageId then
        local stage = stageGroup:GetStage(stageId)
        if stage then
            local needTime = stage:GetRewardExtraTime()
            if needTime > 0 then
                self.TxtCondition.gameObject:SetActiveEx(true)

                local isExtraMissionIncomplete = stage:IsExtraMissionIncomplete(time)
                if isExtraMissionIncomplete then
                    self.TxtNoComplete.gameObject:SetActiveEx(true)
                    self.TxtComplete.gameObject:SetActiveEx(false)
                else
                    self.TxtNoComplete.gameObject:SetActiveEx(false)
                    self.TxtComplete.gameObject:SetActiveEx(true)
                end
                self.TxtCondition1.text = XUiHelper.GetText("TransfiniteTimeExtra", needTime)
            else
                self.TxtCondition.gameObject:SetActiveEx(false)
            end
        else
            XLog.Error("[XUiTransfiniteHint] LastWinStageId is invalid")
        end
    else
        XLog.Error("[XUiTransfiniteHint] LastWinStageId is empty")
    end
end

function XUiTransfiniteHint:Cancel()
    XDataCenter.TransfiniteManager.RequestGiveUpLastResult(self._StageGroup)
    self._StageGroup:ClearLastResult()
    self:Close()
end

function XUiTransfiniteHint:Confirm()
    XDataCenter.TransfiniteManager.RequestConfirmLastResult(self._StageGroup)
    self:Close()
end

return XUiTransfiniteHint