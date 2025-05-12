---@class XUiArenaScenePlayerGrid : XUiNode
---@field TxtRank UnityEngine.UI.Text
---@field BtnPlayer XUiComponent.XUiButton
---@field HeadObject UnityEngine.RectTransform
---@field ImgMedal UnityEngine.UI.Image
---@field TxtName UnityEngine.UI.Text
---@field TxtScoreNum UnityEngine.UI.Text
---@field TxtNone UnityEngine.UI.Text
local XUiArenaScenePlayerGrid = XClass(nil, "XUiArenaScenePlayerGrid")

function XUiArenaScenePlayerGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)

    self._Animation = self.Transform:FindTransform("ListRankEnable")
    self._CanvasGroup = self.GameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))

    self:AlphaHide()
    self:_RegisterButtonClicks()
end

function XUiArenaScenePlayerGrid:OnBtnPlayerClick()
    if self._PlayerData then
        local playerId = self._PlayerData:GetId()

        if playerId ~= XPlayer.Id then
            XDataCenter.PersonalInfoManager.ReqShowInfoPanel(playerId)
        end
    end
end

---@param playerData XArenaLordPlayerData
---@param index number
function XUiArenaScenePlayerGrid:Refresh(playerData, index)
    if playerData then
        self._PlayerData = playerData
        self.ImgMedal.gameObject:SetActiveEx(false)
        self.BtnPlayer.gameObject:SetActiveEx(true)
        self.TxtScoreNum.gameObject:SetActiveEx(true)
        self.TxtNone.gameObject:SetActiveEx(false)
        self.TxtName.text = playerData:GetName()
        self.TxtScoreNum.text = playerData:GetPoint()
        XUiPlayerHead.InitPortraitWithoutStandIcon(playerData:GetCurrentHeadPortraitId(),
            playerData:GetCurrentHeadFrameId(), self.HeadObject)
    else
        self.BtnPlayer.gameObject:SetActiveEx(false)
        self.TxtScoreNum.gameObject:SetActiveEx(false)
        self.TxtNone.gameObject:SetActiveEx(true)
    end
    self.TxtRank.text = XUiHelper.GetText("ArenaRankNo", index)
end

function XUiArenaScenePlayerGrid:AlphaHide()
    if self._CanvasGroup then
        self._CanvasGroup.alpha = 0
    end
end

function XUiArenaScenePlayerGrid:PlayAnimation()
    if not XTool.UObjIsNil(self._Animation) then
        self._Animation:PlayTimelineAnimation()
    end
end

-- region 私有方法

function XUiArenaScenePlayerGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnPlayer.CallBack = Handler(self, self.OnBtnPlayerClick)
end

-- endregion

return XUiArenaScenePlayerGrid
