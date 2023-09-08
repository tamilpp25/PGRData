---@class XUiTransfiniteObtain : XLuaUi
---@field BtnSure UnityEngine.UI.Button
---@field BtnCancel UnityEngine.UI.Button
---@field BtnBack UnityEngine.UI.Button
---@field TxtRoundNum UnityEngine.UI.Text
---@field TxtBestWinNum UnityEngine.UI.Text
---@field TxtPointsNum UnityEngine.UI.Text
---@field PanelContent UnityEngine.RectTransform
---@field GridCommon UnityEngine.RectTransform
---@field TxtTitle UnityEngine.UI.Text
---@field RewardView UnityEngine.RectTransform
local XUiTransfiniteObtain = XLuaUiManager.Register(XLuaUi, "UiTransfiniteObtain")

function XUiTransfiniteObtain:Ctor()
    self._Data = nil
    self._RewardGridList = {}
end

function XUiTransfiniteObtain:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnCancel, self.Close)
    self:RegisterClickEvent(self.BtnSure, self.Close)
end

function XUiTransfiniteObtain:OnStart(data)
    self._Data = data
end

function XUiTransfiniteObtain:OnEnable()
    if self._Data then
        local data = self._Data
        local rewardGridList = self._RewardGridList
        
        self.TxtRoundNum.text = data.RoundNum
        self.TxtBestWinNum.text = data.BestWinNum
        self.TxtPointsNum.text = data.PointsNum
        self.TxtTitle.gameObject:SetActiveEx(true)

        if not data.Rewards or #data.Rewards == 0 then
            self.RewardView.gameObject:SetActiveEx(false)
            self.ImgNoAward.gameObject:SetActiveEx(true)
        else
            self.RewardView.gameObject:SetActiveEx(true)
            self.ImgNoAward.gameObject:SetActiveEx(false)
            XUiHelper.RefreshCustomizedList(self.PanelContent, self.GridCommon, #data.Rewards, function(index, grid)
                local rewardGrid = rewardGridList[index]

                if not rewardGrid then
                    rewardGrid = XUiGridCommon.New(self, grid)
                    rewardGridList[index] = rewardGrid
                end

                rewardGrid:Refresh(data.Rewards[index])
            end)
        end
    end
end

return XUiTransfiniteObtain