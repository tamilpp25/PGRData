---@class XUiFpsGamePopupChapterDetail : XLuaUi 关卡详情弹框
---@field _Control XFpsGameControl
local XUiFpsGamePopupChapterDetail = XLuaUiManager.Register(XLuaUi, "UiFpsGamePopupChapterDetail")

local ColorNormalAlpha = CS.UnityEngine.Color(28 / 255, 165 / 255, 167 / 255, 153 / 255)
local ColorNormal = CS.UnityEngine.Color(28 / 255, 165 / 255, 167 / 255, 1)
local ColorHardAlpha = CS.UnityEngine.Color(228 / 255, 68 / 255, 83 / 255, 153 / 255)
local ColorHard = CS.UnityEngine.Color(228 / 255, 68 / 255, 83 / 255, 1)

function XUiFpsGamePopupChapterDetail:OnAwake()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self.BtnEnter.CallBack = handler(self, self.OnBtnEnterClick)
end

---@param stage XTableFpsGameStage
function XUiFpsGamePopupChapterDetail:OnStart(stage)
    self._Stage = stage

    local endTime = self._Control:GetActivityGameEndTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiFpsGamePopupChapterDetail:OnEnable()
    self.Super.OnEnable(self)

    local uiObject
    local star = self._Control:GetStageStar(self._Stage.StageId)
    local starDescs = self._Stage.StarDesc

    self.TxtTitle.text = self._Stage.Name

    if self._Stage.ChapterId == XEnumConst.FpsGame.Challenge then
        local maxScore = self._Control:GetStageHistoryScore(self._Stage.StageId)
        if XTool.IsNumberValid(maxScore) then
            self.TxtMaxScore.text = maxScore
            self.TxtMaxScore.gameObject:SetActiveEx(true)
        else
            self.TxtMaxScore.gameObject:SetActiveEx(false)
        end
    else
        self.TxtMaxScore.gameObject:SetActiveEx(false)
    end

    XUiHelper.RefreshCustomizedList(self.GridStageStar.parent, self.GridStageStar, #starDescs, function(index, go)
        uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.PanelActive.gameObject:SetActiveEx(star >= index)
        uiObject.PanelUnActive.gameObject:SetActiveEx(star < index)
        uiObject.TxtUnActive.text = starDescs[index]
        uiObject.TxtActive.text = starDescs[index]

        local isStory = self._Stage.ChapterId == XEnumConst.FpsGame.Story
        uiObject.TxtUnActive.color = isStory and ColorNormalAlpha or ColorHardAlpha
        uiObject.TxtActive.color = isStory and ColorNormal or ColorHard
        uiObject.ImgStar.color = isStory and ColorNormalAlpha or ColorHardAlpha
        uiObject.ImgStarActive.color = isStory and ColorNormal or ColorHard

        if XTool.IsNumberValid(self._Stage.UnlockWeapon) and index == 1 then
            uiObject.GridWeapon.gameObject:SetActiveEx(true)
            local weaponConfig = self._Control:GetWeaponById(1)
            ---@type XUiGridFpsGameWeapon
            local weaponGrid = require("XUi/XUiFpsGame/XUiGridFpsGameWeapon").New(uiObject.GridWeapon, self, weaponConfig)
            weaponGrid:SetReceive(self._Control:IsWeaponUnlock(self._Stage.UnlockWeapon))
            weaponGrid:AddClick(function()
                XLuaUiManager.Open("UiFpsGameChooseWeapon", self._Stage.StageId, self._Stage.UnlockWeapon)
            end)
        else
            uiObject.GridWeapon.gameObject:SetActiveEx(false)
        end
    end)

    XUiHelper.RefreshCustomizedList(self.GridBuff.parent, self.GridBuff, #self._Stage.BuffIcon, function(index, go)
        uiObject = {}
        XUiHelper.InitUiClass(uiObject, go)
        uiObject.ImgBuff:SetSprite(self._Stage.BuffIcon[index])
        uiObject.TxtTitle.text = self._Stage.BuffTitle[index]
        uiObject.TxtDetail.text = self._Stage.BuffDesc[index]
    end)
end

function XUiFpsGamePopupChapterDetail:OnBtnEnterClick()
    XLuaUiManager.PopThenOpen("UiFpsGameChooseWeapon", self._Stage.StageId)
end

return XUiFpsGamePopupChapterDetail