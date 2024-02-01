local XUiBattleRoleRoomDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoleRoomDefaultProxy")

---@class XUiFubenBossSingleModeBattleRoleRoom : XUiBattleRoleRoomDefaultProxy
local XUiFubenBossSingleModeBattleRoleRoom = XClass(XUiBattleRoleRoomDefaultProxy,
    "XUiFubenBossSingleModeBattleRoleRoom")

function XUiFubenBossSingleModeBattleRoleRoom:Ctor(_, stageId)
    self._FeatureId = XMVCA.XFubenBossSingle:GetFreatureIdByStageId(stageId)
end

function XUiFubenBossSingleModeBattleRoleRoom:OnNotify(event, stageType)
    if event == XEventId.EVENT_ACTIVITY_ON_RESET then
        if stageType == XEnumConst.FuBen.StageType.BossSingle then
            XMVCA.XFubenBossSingle:OnActivityEnd()
        end
    end
end

function XUiFubenBossSingleModeBattleRoleRoom:GetIsCanEnterFight(team, stageId)
    local isSuccess, errorDesc = self.Super.GetIsCanEnterFight(self, team, stageId)
    
    if not isSuccess then
        return isSuccess, errorDesc
    end
    if XMVCA.XFubenBossSingle:CheckCanChallengeRecord() then
        return true
    end

    local challengeData = XMVCA.XFubenBossSingle:GetChallengeSingleData()
    local characterIds = team:GetEntityIds()
    
    isSuccess = true
    errorDesc = nil
    for _, characterId in pairs(characterIds) do
        if challengeData:CheckCharacterClash(characterId) then
            local feature = challengeData:GetClashFeature(characterId)

            if feature and feature:GetStageId() ~= stageId then
                local fullName = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
                
                isSuccess = false
                if errorDesc then
                    errorDesc = XUiHelper.GetText("BossSingleCharacterClash", errorDesc, fullName)
                else
                    errorDesc = fullName
                end
            end
        end
    end
    if errorDesc then
        errorDesc = XUiHelper.GetText("BossSingleCharacterClashDesc", errorDesc)
    end

    return isSuccess, errorDesc
end

---@param team XTeam
function XUiFubenBossSingleModeBattleRoleRoom:EnterFight(team, stageId, challengeCount, isAssist)
    local challengeData = XMVCA.XFubenBossSingle:GetChallengeSingleData()
    local characterIds = team:GetEntityIds()
    local isClash = false
    local clashMap = {}

    local characterCount = 0
    local stageCount = 0
    local characterText = ""
    local stageText = ""

    for _, characterId in pairs(characterIds) do
        if challengeData:CheckCharacterClash(characterId) then
            local feature = challengeData:GetClashFeature(characterId)

            if feature and feature:GetStageId() ~= stageId then
                isClash = true
                clashMap[feature:GetFeatureId()] = feature
                characterCount = characterCount + 1
                characterText = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
            end
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

    local content = XUiHelper.ReplaceUnicodeSpace(XUiHelper.GetText("BossSingleModeEnterFightTip", characterText,
        stageText))

    if isClash then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, XUiManager.DialogType.Normal, nil, function()
            self.Super.EnterFight(self, team, stageId, challengeCount, isAssist)
        end)
    else
        self.Super.EnterFight(self, team, stageId, challengeCount, isAssist)
    end
end

function XUiFubenBossSingleModeBattleRoleRoom:AOPOnStartAfter(rootUi)
    if XTool.IsNumberValid(self._FeatureId) then
        if rootUi.XUiPanelRecommendGeneralSkill then
            if XMVCA.XFubenBossSingle:CheckShowRecommend(self._FeatureId) then
                rootUi.XUiPanelRecommendGeneralSkill:Open()
            else
                rootUi.XUiPanelRecommendGeneralSkill:Close()
            end
        end
    end
end

return XUiFubenBossSingleModeBattleRoleRoom
