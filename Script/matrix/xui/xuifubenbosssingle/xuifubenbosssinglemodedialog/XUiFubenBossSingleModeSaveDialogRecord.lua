local XUiFubenBossSingleModeDetailGridHead = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeDetailGridHead")

---@class XUiFubenBossSingleModeSaveDialogRecord : XUiNode
---@field TxtValue UnityEngine.UI.Text
---@field GridCharacter UnityEngine.RectTransform
---@field ListCharacter UnityEngine.RectTransform
---@field PanelNow UnityEngine.RectTransform
---@field PanelDel UnityEngine.RectTransform
---@field _Control XFubenBossSingleControl
---@field Parent XUiFubenBossSingleModeSaveDialog
local XUiFubenBossSingleModeSaveDialogRecord = XClass(XUiNode, "XUiFubenBossSingleModeSaveDialogRecord")

function XUiFubenBossSingleModeSaveDialogRecord:OnStart(characterIds, clashFeature)
    ---@type XUiFubenBossSingleModeDetailGridHead[]
    self._HeadGridList = {}

    self:_Init(characterIds, clashFeature)
end

function XUiFubenBossSingleModeSaveDialogRecord:_Init(characterIds, clash)
    self.GridCharacter.gameObject:SetActiveEx(false)
    if clash then
        self:_InitDeletePanel(characterIds, clash)
    else
        self:_InitCurrentPanel(characterIds)
    end
end

function XUiFubenBossSingleModeSaveDialogRecord:_InitCurrentPanel(characterIds)
    local count = self._Control:GetMaxTeamCharacterMember()
    local challengeData = self._Control:GetBossSingleChallengeData()
    local stageId = self.Parent:GetStageId()
    local totalScore = self._Control:GetBossStageScoreByStageId(stageId)
    
    for i = 1, count do
        local characterId = characterIds[i]
        local headGrid = self._HeadGridList[i]
        local isClash = false
        
        if characterId then
            isClash = challengeData:CheckCharacterClash(characterId)
        end
        if not headGrid then
            local grid = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)

            headGrid = XUiFubenBossSingleModeDetailGridHead.New(grid, self)
            self._HeadGridList[i] = headGrid
        end

        headGrid:Open()
        headGrid:Refresh(characterId, isClash, true)
    end
    for i = count + 1, #self._HeadGridList do
        self._HeadGridList[i]:Close()
    end

    self.TxtValue.text = self.Parent:GetScore() .. "/" .. totalScore
    self.PanelDel.gameObject:SetActiveEx(false)
    self.PanelNow.gameObject:SetActiveEx(true)
end

---@param clash XBossSingleFeature
function XUiFubenBossSingleModeSaveDialogRecord:_InitDeletePanel(characterIds, clash)
    local characterList = clash:GetCharacterList()
    local count = self._Control:GetMaxTeamCharacterMember()
    local isClashMap = {}
    
    for _, characterId in pairs(characterIds) do
        if clash:CheckCharacterClash(characterId) then
            isClashMap[characterId] = true
        end
    end
    for i = 1, count do
        local characterId = characterList[i]
        local headGrid = self._HeadGridList[i]

        if not headGrid then
            local grid = XUiHelper.Instantiate(self.GridCharacter, self.ListCharacter)

            headGrid = XUiFubenBossSingleModeDetailGridHead.New(grid, self)
            self._HeadGridList[i] = headGrid
        end

        headGrid:Open()
        headGrid:Refresh(characterId, isClashMap[characterId], false)
    end
    for i = count + 1, #self._HeadGridList do
        self._HeadGridList[i]:Close()
    end

    self.TxtValue.text = clash:GetScore() .. "/" .. clash:GetTotalScore()
    self.PanelDel.gameObject:SetActiveEx(true)
    self.PanelNow.gameObject:SetActiveEx(false)
end

--endregion

return XUiFubenBossSingleModeSaveDialogRecord
