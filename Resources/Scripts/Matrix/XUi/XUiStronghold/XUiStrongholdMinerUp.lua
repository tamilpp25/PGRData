local CSXTextManagerGetText = CS.XTextManager.GetText
local stringFormat = string.format

--战斗胜利后，矿工数量变动时的提示界面
local XUiStrongholdMinerUp = XLuaUiManager.Register(XLuaUi, "UiStrongholdMinerUp")

function XUiStrongholdMinerUp:OnAwake()
    self:AutoAddListener()
end

function XUiStrongholdMinerUp:OnStart(groupId)
    self.BtnCloseTs.gameObject:SetActiveEx(false)

    if not groupId then
        self:Close()
        return
    end

    local stageName = XStrongholdConfigs.GetGroupName(groupId)
    self.TxtLevelName.text = CSXTextManagerGetText("StrongholdStageClear", stageName)

    local oldMinerCount = XDataCenter.StrongholdManager.GetCookieMinerCount()
    local minerCount = XDataCenter.StrongholdManager.GetMinerCount()
    self.TxtLv1.text = oldMinerCount
    self.TxtLv2.text = minerCount

    --获得矿石
    local itemId = XDataCenter.StrongholdManager.GetMineralItemId()
    local oldItemCount = XDataCenter.StrongholdManager.GetOldItemCount()
    local itemCount = XDataCenter.ItemManager.GetCount(itemId)
    local changeCount = itemCount - oldItemCount
    self.TxtFreeActionPoint.text = stringFormat("%s (+%s)", oldItemCount, changeCount)

    --预期总产出
    local oldTotalMineralCount = XDataCenter.StrongholdManager.GetOldTotalMineralCount()
    local totalMineralCount = XDataCenter.StrongholdManager.GetPredictTotalMineralCount()
    local changeTotalMineralCount = totalMineralCount - oldTotalMineralCount
    self.TxtMaxFriendCount.text = stringFormat("%s (+%s)", oldTotalMineralCount, changeTotalMineralCount)

    self.Timer = XScheduleManager.ScheduleOnce(function()
        self.BtnCloseTs.gameObject:SetActiveEx(true)
    end, 1000)
end

function XUiStrongholdMinerUp:OnDisable()
    if self.Timer then
        XScheduleManager.UnSchedule(self.Timer)
        self.Timer = nil
    end
end

function XUiStrongholdMinerUp:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, handler(self, self.Close))
end