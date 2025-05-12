local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiTransfinitePassageSettlement:XLuaUi
local XUiTransfinitePassageSettlement = XLuaUiManager.Register(XLuaUi, "UiTransfinitePassageSettlement")

function XUiTransfinitePassageSettlement:Ctor()
    ---@type XTransfiniteResult
    self._Result = false
end

function XUiTransfinitePassageSettlement:OnAwake()
    self:RegisterClickEvent(self.BtnContinue, self.OnClickGoOn)
    self:RegisterClickEvent(self.BtnSkip, self.OnClickSkip)
    ---@type XUiGridCommon
    self._GridReward = XUiGridCommon.New(self, self.GridReward)

    local util = require("XUi/XUiTransfinite/XUiTransfiniteUtil")
    util.HideEffectHuan(self)

    self.PanelBadgeUp.gameObject:SetActiveEx(false)
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
        -- 新徽章
        local medal = result:GetMedal()
        if result:IsIsland() then
            self.ImgBadge:SetRawImage(medal:GetIcon())
            self.TxtBadge.text = medal:GetName()
        else
            self.ImgBadge2:SetRawImage(medal:GetIcon())
            self.TxtBadge2.text = medal:GetName()
            -- 旧徽章
            local lastMedal = result:GetLastMedal()
            if lastMedal then
                self.ImgBadge:SetRawImage(lastMedal:GetIcon())
                self.TxtBadge.text = lastMedal:GetName()
            else
                self.PanelBadge.gameObject:SetActiveEx(false)
            end
            if self.Effect02 then
                self.Effect02.gameObject:SetActiveEx(not result:CheckIsNewMedal())
            end
        end
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

    -- 播放徽章升级动画
    if not result:IsIsland() and result:CheckIsNewMedal() then
        -- 新徽章
        local model = result:GetMedal()
        self.RImgBadgeUp:SetRawImage(model:GetIcon())
        self.TxtBadgeUp.text = model:GetName()
        self.PanelBadgeUp.gameObject:SetActiveEx(true)
        self:PlayAnimationWithMask("PanelBadgeUpEnable")
    end
end

function XUiTransfinitePassageSettlement:OnClickSkip()
    self.PanelBadgeUp.gameObject:SetActiveEx(false)
    self:PlayAnimationWithMask("BadgeQiehuan")
end

function XUiTransfinitePassageSettlement:OnClickGoOn()
    XDataCenter.TransfiniteManager.CloseUiSettle()
    -- 14关全通关后返回玩法主界面(普通模式)
    local result = self._Result
    if result and result:IsFinalStage() and not result:IsIsland() then
        XDataCenter.TransfiniteManager.CloseUiBattlePrepare()
    end
    self:Close()
end

return XUiTransfinitePassageSettlement
