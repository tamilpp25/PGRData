---@class XUiTransfinitePassageSettlement:XLuaUi
local XUiTransfinitePassageSettlement = XLuaUiManager.Register(XLuaUi, "UiTransfinitePassageSettlement")

function XUiTransfinitePassageSettlement:Ctor()
    ---@type XTransfiniteResult
    self._Result = false
end

function XUiTransfinitePassageSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnContinue, self.OnClickGoOn)
    ---@type XUiGridCommon
    self._GridReward = XUiGridCommon.New(self, self.GridReward)

    local util = require("XUi/XUiTransfinite/XUiTransfiniteUtil")
    util.HideEffectHuan(self)
end

---@param result XTransfiniteResult
function XUiTransfinitePassageSettlement:OnStart(result)
    self._Result = result
end

function XUiTransfinitePassageSettlement:OnEnable()
    self:Update()
end

function XUiTransfinitePassageSettlement:Update()
    local result = self._Result
    if not result then
        return
    end
    local stageGroupName = result:GetStageGroupName()
    self.TxtTitle.text = stageGroupName
    self.TxtWinNumber.text = result:GetWinAmount()
    self.TxtBattleTime.text = XUiHelper.GetTime(result:GetStageGroupClearTime())
    if result:IsFinalStage() then
        self.PanelBadge.gameObject:SetActiveEx(true)
        if self.PanelBadgeTitle then
            self.PanelBadgeTitle.gameObject:SetActiveEx(true)
        end
        self.TxtDefault2.gameObject:SetActiveEx(false)
        local medal = result:GetMedal()
        self.ImgBadge:SetRawImage(medal:GetIcon())
        self.TxtBadge.text = medal:GetName()
    else
        self.PanelBadge.gameObject:SetActiveEx(false)
        if self.PanelBadgeTitle then
            self.PanelBadgeTitle.gameObject:SetActiveEx(false)
        end
        self.TxtDefault2.gameObject:SetActiveEx(true)
    end

    local rewardGoodList = result:GetRewardGoodList()
    if rewardGoodList and rewardGoodList[1] then
        self._GridReward:Refresh(rewardGoodList[1])
        self._GridReward.GameObject:SetActiveEx(true)
        self.TxtDefault.gameObject:SetActiveEx(false)
    else
        --self._GridReward:Refresh(XDataCenter.ItemManager.ItemId.TransfiniteScore)
        --self._GridReward:SetCount(0)
        self._GridReward.GameObject:SetActiveEx(false)
        self.TxtDefault.gameObject:SetActiveEx(true)
    end

    local playerName = XPlayer.Name
    local time = XTime.GetServerNowTimestamp()
    local timeStr = XTime.TimestampToLocalDateTimeString(time, "yyyy/MM/dd")
    self.TxtTitle2.text = XUiHelper.GetText("TransfiniteResult", playerName, timeStr, stageGroupName)
end

function XUiTransfinitePassageSettlement:OnClickGoOn()
    XDataCenter.TransfiniteManager.CloseUiSettle()
    self:Close()
end

return XUiTransfinitePassageSettlement