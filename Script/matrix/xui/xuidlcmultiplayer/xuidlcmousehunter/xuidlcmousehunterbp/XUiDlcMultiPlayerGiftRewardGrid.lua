---@class XUiDlcMultiPlayerGiftRewardGrid
---@field ImgDiscussionVictoryIcon UnityEngine.UI.RawImage
---@field ImgBg UnityEngine.RectTransform
---@field ItemPanel UnityEngine.RectTransform
---@field RewardItem UnityEngine.RectTransform
---@field RewardIBtnGettem XUiComponent.XUiButton
---@field Normal UnityEngine.RectTransform
---@field Lock UnityEngine.RectTransform
---@field TxtNormalLv UnityEngine.UI.Text
---@field TxtNormalLvTitle UnityEngine.UI.Text
---@field TxtLockLv UnityEngine.UI.Text
---@field TxtLocklLvTitle UnityEngine.UI.Text
local XUiDlcMultiPlayerGiftRewardGrid = XClass(XUiNode, "XUiDlcMultiPlayerGiftRewardGrid")

local XUiDlcMultiPlayerGiftRewardGridItem = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMouseHunterBp/XUiDlcMultiPlayerGiftRewardGridItem")

local MainRewardLvColor = CS.UnityEngine.Color(240 / 255, 121 / 255, 50 / 255, 1)
local MainRewardLvTitleColor = CS.UnityEngine.Color(240 / 255, 121 / 255, 50 / 255, 242 / 255)
local NormalLvColor = CS.UnityEngine.Color(99 / 255, 115 / 255, 237 / 255, 1)
local NormalLvTitleColor = CS.UnityEngine.Color(99 / 255, 115 / 255, 237 / 255, 242 / 255)

function XUiDlcMultiPlayerGiftRewardGrid:OnStart()
    self.GridItems = {}
    self.CanGetReawrd = false
    
    XUiHelper.RegisterClickEvent(self, self.BtnGet, self.OnBtnGetClick)
end

function XUiDlcMultiPlayerGiftRewardGrid:UpdateGrid(list, data)
    local lv = data.Lv
    local lvStr = tostring(lv)
    local curLv = self._Control:GetBpLevel()
    local mainReward = data.MainReward

    self.RewardItem.gameObject:SetActiveEx(false)
    self.Normal.gameObject:SetActiveEx(true)
    self.Lock.gameObject:SetActiveEx(false)
    self.TxtNormalLvTitle.text = XUiHelper.GetText("MultiMouseHunterBPLevel")
    self.TxtNormalLv.text = lvStr
    self.TxtLocklLvTitle.text = XUiHelper.GetText("MultiMouseHunterBPLevel")
    self.TxtLockLv.text = lvStr

    if self._Control:CheckReceiveBpReawrd(lv) then --已领取
        self.BtnGet:SetButtonState(CS.UiButtonState.Select)
        self.BtnGet.enabled = false
        self.CanGetReawrd = false
        self:_RefreshReward(data.RewardId, true)
        self.Lock.gameObject:SetActiveEx(true)
        self.BtnGet:SetName(XUiHelper.GetText("MultiMouseHunterBpAlreadyGetReward"))
    elseif lv <= curLv then --可领取
        self.BtnGet:SetButtonState(CS.UiButtonState.Normal)
        self.BtnGet.enabled = true
        self.CanGetReawrd = true
        self:_RefreshReward(data.RewardId, false)
        self.BtnGet:SetName(XUiHelper.GetText("MultiMouseHunterBpCanGetReward"))
    else --未达成
        self.BtnGet:SetButtonState(CS.UiButtonState.Disable)
        self.BtnGet.enabled = false
        self.CanGetReawrd = false
        self:_RefreshReward(data.RewardId, false)
        self.BtnGet:SetName(XUiHelper.GetText("MultiMouseHunterBpNoneGetReward"))
    end

    if mainReward == 1 then
        self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("BpMainRewardIcon").Values[1])
        self.TxtNormalLvTitle.color = MainRewardLvTitleColor
        self.TxtNormalLv.color = MainRewardLvColor
        self.TxtLocklLvTitle.color = MainRewardLvTitleColor
        self.TxtLockLv.color = MainRewardLvColor
    else
        self.ImgBg:SetRawImage(self._Control:GetDlcMultiplayerConfigConfigByKey("BpNormalRewardIcon").Values[1])
        self.TxtNormalLvTitle.color = NormalLvTitleColor
        self.TxtNormalLv.color = NormalLvColor
        self.TxtLocklLvTitle.color = NormalLvTitleColor
        self.TxtLockLv.color = NormalLvColor
    end
end

function XUiDlcMultiPlayerGiftRewardGrid:OnBtnGetClick()
    if not self.CanGetReawrd then
        return
    end
    self._Control:RequestDlcMultiplayerGetBpReward()
end

function XUiDlcMultiPlayerGiftRewardGrid:_RefreshReward(rewardId, isReceive)
    local gridItems = self.GridItems
    local rewardList = XRewardManager.GetRewardList(rewardId)
    if XTool.IsTableEmpty(rewardList) then
        return
    end

    for idx, reward in ipairs(rewardList) do
        local grid = gridItems[idx]
        if not grid then
            local ui = idx == 1 and self.RewardItem.gameObject or XUiHelper.Instantiate(self.RewardItem.gameObject, self.ItemPanel)
            grid = XUiDlcMultiPlayerGiftRewardGridItem.New(self.Parent.Parent, ui)
            gridItems[idx] = grid
        end
       
        grid:SetReceived(isReceive)
        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)
    end
end

return XUiDlcMultiPlayerGiftRewardGrid