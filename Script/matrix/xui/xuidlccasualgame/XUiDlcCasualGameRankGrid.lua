---@class XUiDlcCasualGameRankGrid : XUiNode
---@field TxtScore UnityEngine.UI.Text
---@field TxtRankNormal UnityEngine.UI.Text
---@field ImgRankSpecial UnityEngine.UI.Image
---@field TxtPlayerName01 UnityEngine.UI.Text
---@field Head01 UnityEngine.RectTransform
---@field TxtPlayerName02 UnityEngine.UI.Text
---@field Head02 UnityEngine.RectTransform
---@field TxtPlayerName03 UnityEngine.UI.Text
---@field Head03 UnityEngine.RectTransform
---@field TxtRound UnityEngine.UI.Text
---@field BtnPlayer01 XUiComponent.XUiButton
---@field BtnPlayer02 XUiComponent.XUiButton
---@field BtnPlayer03 XUiComponent.XUiButton
---@field _Control XDlcCasualControl
local XUiDlcCasualGameRankGrid = XClass(XUiNode, "XUiDlcCasualGameRankGrid")
---@type XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesUtility")

---@param data XDlcCasualRank
function XUiDlcCasualGameRankGrid:Refresh(data, index)
    local isTop = index >= 1 and index <= 3
    local textNameList = XUiDlcCasualGamesUtility.GetComponentList("TxtPlayerName0", self, 3)
    local imgHeadList = XUiDlcCasualGamesUtility.GetComponentList("Head0", self, 3)
    local btnPlayerList = XUiDlcCasualGamesUtility.GetComponentList("BtnPlayer0", self, 3)
    
    if isTop then
        local numberColor = self._Control:GetRankTopNumberColor()
        local topColor = self._Control:GetRankTopColor(index)
        
        self.ImgRankSpecial.gameObject:SetActiveEx(isTop)
        self.ImgRankSpecial.color = XUiHelper.Hexcolor2Color(topColor)
        self.TxtRankNormal.text = XUiHelper.GetText("DlcCasualCubeTopRank", numberColor, index)
    else
        local numberColor = self._Control:GetRankNormalNumberColor()

        self.ImgRankSpecial.gameObject:SetActiveEx(isTop)
        self.TxtRankNormal.text = XUiHelper.GetText("DlcCasualCubeTopRank", numberColor, index)
    end
    
    self.TxtScore.text = data:GetScore()

    XUiDlcCasualGamesUtility.RefreshRankTeamGrid(textNameList, imgHeadList, btnPlayerList, data)
end

return XUiDlcCasualGameRankGrid