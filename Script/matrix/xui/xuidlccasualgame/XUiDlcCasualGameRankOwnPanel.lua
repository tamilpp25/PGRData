---@class XUiDlcCasualGameRankOwnPanel : XUiNode
---@field TxtRankNormal UnityEngine.UI.Text
---@field ImgRankSpecial UnityEngine.UI.Image
---@field TxtRankPercent UnityEngine.UI.Text
---@field TxtRound UnityEngine.UI.Text
---@field TxtScore UnityEngine.UI.Text
---@field Head01 UnityEngine.RectTransform
---@field TxtPlayerName01 UnityEngine.UI.Text
---@field BtnPlayer01 XUiComponent.XUiButton
---@field Head02 UnityEngine.RectTransform
---@field TxtPlayerName02 UnityEngine.UI.Text
---@field BtnPlayer02 XUiComponent.XUiButton
---@field Head03 UnityEngine.RectTransform
---@field TxtPlayerName03 UnityEngine.UI.Text
---@field BtnPlayer03 XUiComponent.XUiButton
---@field TxtNone UnityEngine.UI.Text
---@field _Control XDlcCasualControl
local XUiDlcCasualGameRankOwnPanel = XClass(XUiNode, "XUiDlcCasualGameRankOwnPanel")
---@type XUiDlcCasualGamesUtility
local XUiDlcCasualGamesUtility = require("XUi/XUiDlcCasualGame/XUiDlcCasualGamesUtility")

local Floor = math.floor

function XUiDlcCasualGameRankOwnPanel:OnStart()
    self.TxtNone.gameObject:SetActiveEx(false)
end

---@param data XDlcCasualRank
function XUiDlcCasualGameRankOwnPanel:Refresh(data, ranking, totalCount)
    if not data then
        self:_SetNonePanelActive(true)
        return
    end

    local isTop = ranking >= 1 and ranking <= 3
    local textNameList = XUiDlcCasualGamesUtility.GetComponentList("TxtPlayerName0", self, 3)
    local imgHeadList = XUiDlcCasualGamesUtility.GetComponentList("Head0", self, 3)
    local btnPlayerList = XUiDlcCasualGamesUtility.GetComponentList("BtnPlayer0", self, 3)

    if isTop then
        local numberColor = self._Control:GetRankTopNumberColor()
        local topColor = self._Control:GetRankTopColor(ranking)
        
        self.ImgRankSpecial.gameObject:SetActiveEx(isTop)
        self.ImgRankSpecial.color = XUiHelper.Hexcolor2Color(topColor)
        self.TxtRank.text = XUiHelper.GetText("DlcCasualCubeTopRank", numberColor, ranking)
    else
        local numberColor = self._Control:GetRankNormalNumberColor()
        local maxCount = self._Control:GetMaxRankCount()

        if ranking > maxCount then
            if not XTool.IsNumberValid(totalCount) then
                self:_SetNonePanelActive(true, isTop)
                return
            else
                ranking = Floor(ranking / totalCount * 100) .. "%"

                if ranking < 1 then
                    ranking = 1
                end
            end
        end
        self.ImgRankSpecial.gameObject:SetActiveEx(isTop)    
        self.TxtRankNormal.text = XUiHelper.GetText("DlcCasualCubeTopRank", numberColor, ranking)
    end
    
    self.TxtScore.text = data:GetScore()
    self:_SetNonePanelActive(false, isTop)
    
    XUiDlcCasualGamesUtility.RefreshRankTeamGrid(textNameList, imgHeadList, btnPlayerList, data)
end

function XUiDlcCasualGameRankOwnPanel:_SetNonePanelActive(isActive, isTop)
    isTop = isTop or false
    
    self.TxtNone.gameObject:SetActiveEx(isActive)
    self.ImgRankSpecial.gameObject:SetActiveEx(not isActive and isTop)
    self.TxtRankNormal.gameObject:SetActiveEx(not isActive and not isTop)
    self.TxtScore.gameObject:SetActiveEx(not isActive)
    self.BtnPlayer01.gameObject:SetActiveEx(not isActive)
    self.BtnPlayer02.gameObject:SetActiveEx(not isActive)
    self.BtnPlayer03.gameObject:SetActiveEx(not isActive)
    self.ImgScoreBg.gameObject:SetActiveEx(not isActive)
end

return XUiDlcCasualGameRankOwnPanel