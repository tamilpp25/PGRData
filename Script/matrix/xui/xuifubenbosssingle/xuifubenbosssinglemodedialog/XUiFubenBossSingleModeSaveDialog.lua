local XUiFubenBossSingleModeSaveDialogRecord = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleModeDialog/XUiFubenBossSingleModeSaveDialogRecord")

---@class XUiFubenBossSingleModeSaveDialog : XLuaUi
---@field BtnConfirm XUiComponent.XUiButton
---@field TxtInfo UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
---@field BtnTcanchaungRed XUiComponent.XUiButton
---@field BtnTanchuangClose XUiComponent.XUiButton
---@field Content UnityEngine.RectTransform
---@field GridDeployTeam UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleModeSaveDialog = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleModeSaveDialog")

function XUiFubenBossSingleModeSaveDialog:OnAwake()
    ---@type XUiFubenBossSingleModeSaveDialogRecord
    self._CurrentGrid = nil
    ---@type XUiFubenBossSingleModeSaveDialogRecord[]
    self._ClashGridList = {}
    self._StageId = nil
    self:_RegisterButtonClicks()
end

function XUiFubenBossSingleModeSaveDialog:OnStart(characterIds, score, stageId, clashMap)
    self._StageId = stageId
    self._Score = score
    self:_Init(characterIds, clashMap)
    self:_RefreshInfo(characterIds, clashMap)
end

function XUiFubenBossSingleModeSaveDialog:GetStageId()
    return self._StageId
end

function XUiFubenBossSingleModeSaveDialog:GetScore()
    return self._Score
end

function XUiFubenBossSingleModeSaveDialog:OnBtnConfirmClick()
    XMVCA.XFubenBossSingle:RequestSaveScore(self:GetStageId(), function(isTip)
        if isTip then
            XUiManager.TipText("BossSignleBufenTip", XUiManager.UiTipType.Tip)
        end
        self:Close()
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_SINGLE_BOSS_SAVE_NEW_RECORD)
        XUiManager.TipText("BossSingleModeSaveTip")
    end)
end

function XUiFubenBossSingleModeSaveDialog:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnConfirm, self.OnBtnConfirmClick, true)
    self:RegisterClickEvent(self.BtnTcanchaungRed, self.Close, true)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
end

function XUiFubenBossSingleModeSaveDialog:_Init(characterIds, clashMap)
    for _, clash in pairs(clashMap) do
        local grid = XUiHelper.Instantiate(self.GridDeployTeam, self.Content)
        local gridUi = XUiFubenBossSingleModeSaveDialogRecord.New(grid, self, characterIds, clash)
        
        table.insert(self._ClashGridList, gridUi)
    end
    self._CurrentGrid = XUiFubenBossSingleModeSaveDialogRecord.New(self.GridDeployTeam, self, characterIds)
end

function XUiFubenBossSingleModeSaveDialog:_RefreshInfo(characterIds, clashMap)
    local characterCount = 0
    local stageCount = 0
    local characterText = ""
    local stageText = ""
    local challengeData = self._Control:GetBossSingleChallengeData()

    for _, characterId in pairs(characterIds) do
        if challengeData:CheckCharacterClash(characterId) then
            characterCount = characterCount + 1
            characterText = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
        end
    end
    for _, clashFeature in pairs(clashMap) do
        stageCount = stageCount + 1
        stageText = clashFeature:GetName()
    end
    if characterCount > 1 or string.IsNilOrEmpty(characterText) then
        characterText = XUiHelper.GetText("BossSingleModeMoreCharacterClash")
    end
    if stageCount > 1 or string.IsNilOrEmpty(stageText) then
        stageText = XUiHelper.GetText("BossSingleModeMoreStageClash")
    end

    local textInfo = XUiHelper.GetText("BossSingleModeClash", characterText, stageText)

    self.TxtInfo.text = XUiHelper.ReplaceUnicodeSpace(textInfo)
end

return XUiFubenBossSingleModeSaveDialog
