local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridClickClearReward = XClass(nil, "XUiGridClickClearReward")

function XUiGridClickClearReward:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)

    self.GridCommon.gameObject:SetActive(false)

    self.GridList = {}

    self.BtnReceive.CallBack = function() self:OnBtnReceiveClick() end
end

function XUiGridClickClearReward:OnBtnReceiveClick()

    if not self.Data:CheckCanTake() then
        return
    end

    XDataCenter.XClickClearGameManager.GetRewardRequest(self.Data:GetGameStageId(), function(reward)
        XUiManager.OpenUiObtain(reward, CS.XTextManager.GetText("Award"))
        local gameStageId = self.Data:GetGameStageId()
        self.Data = XDataCenter.XClickClearGameManager.GetRewardData(gameStageId)
        -- self:Refresh(self.Data)
    end)
end

function XUiGridClickClearReward:Refresh(data)
    self.Data = data
    local conditionDesc = self.Data:GetConditionDesc()
    self.TxtGradeCondition.text = conditionDesc
    if self.Data:CheckIsTaked() then
        self:SetBtnAlreadyReceive()
    else
        if self.Data:CheckCanTake() then
            self:SetBtnActive()
        else
            self:SetBtnCannotReceive()
        end
    end
    self:SetupTreasureList()
end

function XUiGridClickClearReward:SetBtnActive()
    self.BtnReceive.gameObject:SetActive(true)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiGridClickClearReward:SetBtnCannotReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(false)
    self.ImgCannotReceive.gameObject:SetActive(true)
end

function XUiGridClickClearReward:SetBtnAlreadyReceive()
    self.BtnReceive.gameObject:SetActive(false)
    self.ImgAlreadyReceived.gameObject:SetActive(true)
    self.ImgCannotReceive.gameObject:SetActive(false)
end

function XUiGridClickClearReward:SetupTreasureList()
    if self.Data == nil or self.Data:GetRewardId() == nil then
        XLog.Error("treasure have no RewardId ")
        return
    end

    local rewards = XRewardManager.GetRewardList(self.Data:GetRewardId())
    for i, item in ipairs(rewards) do
        local grid = self.GridList[i]
        if not grid then
            local ui = CS.UnityEngine.Object.Instantiate(self.GridCommon)
            grid = XUiGridCommon.New(self.RootUi, ui)
            grid.Transform:SetParent(self.PanelTreasureContent, false)
            self.GridList[i] = grid
        end
        grid:Refresh(item)
        grid.GameObject:SetActive(true)
    end

    for j = 1, #self.GridList do
        if j > #rewards then
            self.GridList[j].GameObject:SetActive(false)
        end
    end
end

return XUiGridClickClearReward