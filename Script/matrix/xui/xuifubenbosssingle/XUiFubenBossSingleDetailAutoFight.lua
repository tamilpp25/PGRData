---@class XUiFubenBossSingleDetailAutoFight : XUiNode
---@field TxtScore UnityEngine.UI.Text
---@field TxtCount UnityEngine.UI.Text
---@field BtnAutoFight XUiComponent.XUiButton
---@field BtnClose XUiComponent.XUiButton
---@field GridBossAutoFight1 UnityEngine.RectTransform
---@field GridBossAutoFight2 UnityEngine.RectTransform
---@field GridBossAutoFight3 UnityEngine.RectTransform
---@field BtnHelp XUiComponent.XUiButton
---@field TxtScoreDesc UnityEngine.UI.Text
---@field Parent XUiFubenBossSingleDetail
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleDetailAutoFight = XClass(XUiNode, "XUiFubenBossSingleDetailAutoFight")
local XUiFubenBossSingleHeadGrid = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleHeadGrid")

local Pairs = pairs

--region 生命周期
function XUiFubenBossSingleDetailAutoFight:OnStart()
    ---@type XUiFubenBossSingleHeadGrid[]
    self._TeamMemberList = {
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight1, self),
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight2, self),
        XUiFubenBossSingleHeadGrid.New(self.GridBossAutoFight3, self),
    }
    self._IsStaminaEnough = false
    self._IsChallengeCountEnough = false
    self._StageId = nil
    self:_RegisterButtonClicks()
end

--endregion

--region 按钮事件
function XUiFubenBossSingleDetailAutoFight:OnAutoFightSureClick()
    XMVCA.XFubenBossSingle:RequestAutoFight(self._StageId, function(isTip)
        XEventManager.DispatchEvent(XEventId.EVENT_BOSS_SINGLE_GET_REWARD)
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, isTip)
    end)
end

function XUiFubenBossSingleDetailAutoFight:OnBtnAutoFightClick()
    if not self._IsStaminaEnough then
        XUiManager.TipText("BossSingleAutoFightDesc7")
        return
    end

    if not self._IsChallengeCountEnough then
        XUiManager.TipText("BossSingleAutoFightDesc8")
        return
    end

    local titletext = XUiHelper.GetText("TipTitle")
    local stageData = XMVCA.XFuben:GetStageData(self._StageId)
    local curScore = stageData and stageData.Score or 0
    local contentText = curScore > 0 and XUiHelper.GetText("BossSingleAutoFightDesc11") or
        XUiHelper.GetText("BossSingleAutoFightDesc9")

    XUiManager.DialogTip(titletext, contentText, XUiManager.DialogType.Normal, nil,
        Handler(self, self.OnAutoFightSureClick))
end

function XUiFubenBossSingleDetailAutoFight:OnBtnCloseClick()
    self:_TipClose()
    self:Close()
end

function XUiFubenBossSingleDetailAutoFight:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", XUiHelper.GetText("BossSingleAutoFightDesc") or "")
end

--endregion

---@param autoFightData XBossSingleStageHistory
function XUiFubenBossSingleDetailAutoFight:Refresh(autoFightData, challengeCount, config)
    self._IsStaminaEnough = true
    self._IsChallengeCountEnough = true
    self._StageId = autoFightData:GetStageId()

    local score = config.Score + self._Control:GetBaseScoreByStageId(self._StageId)
    local curScore = autoFightData:GetScore() or 0
    local autoFightRebate = self._Control:GetAutoFightRebate()
    local scoreDesc = autoFightRebate .. "%"
    local allCount = self._Control:GetChallengeCount()
    local leftCount = allCount - challengeCount

    curScore = math.floor(autoFightRebate * curScore / 100)

    self.TxtScore.text = XUiHelper.GetText("BossSingleAutoFightDesc3", curScore, score)
    self.TxtScoreDesc.text = XUiHelper.GetText("BossSingleAutoFightRateDesc", scoreDesc)
    self.TxtCount.text = XUiHelper.GetText("BossSingleAutoFightDesc4", leftCount, allCount)

    if leftCount <= 0 then
        self._IsChallengeCountEnough = false
    end

    for _, grid in Pairs(self._TeamMemberList) do
        grid:Close()
    end

    for i, characterId in Pairs(autoFightData:GetCharacterList()) do
        if characterId > 0 then
            local grid = self._TeamMemberList[i]
            local maxStamina = self._Control:GetMaxStamina()
            local curStamina = maxStamina - self._Control:GetCharacterChallengeCount(characterId)

            grid:SetCharacterId(characterId)
            grid:Open()

            if curStamina <= 0 then
                self._IsStaminaEnough = false
            end
        end
    end
end

--region 私有方法
function XUiFubenBossSingleDetailAutoFight:_TipClose()
    self.Parent:RefreshToggleGroup()
end

function XUiFubenBossSingleDetailAutoFight:_RegisterButtonClicks()
    --在此处注册按钮事件
    XUiHelper.RegisterClickEvent(self, self.BtnAutoFight, self.OnBtnAutoFightClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnHelp, self.OnBtnHelpClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnCloseClick, true)
end

--endregion

return XUiFubenBossSingleDetailAutoFight
