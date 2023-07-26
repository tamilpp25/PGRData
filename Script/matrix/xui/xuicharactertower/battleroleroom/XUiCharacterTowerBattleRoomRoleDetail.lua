local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
---@class XUiCharacterTowerBattleRoomRoleGrid:XUiBattleRoomRoleGrid
local XUiCharacterTowerBattleRoomRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiCharacterTowerBattleRoomRoleGrid")

---@param team XTeam
function XUiCharacterTowerBattleRoomRoleGrid:SetData(entity, team, stageId, pos)
    self.Super.SetData(self, entity, team, stageId, pos)
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local chapterId = stageInfo.ChapterId
    ---@type XCharacterTowerChapter
    local chapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    local characterId = chapterViewModel:GetChapterCharacterId()
    if entity:GetId() == characterId then
        local isInTeam = team:GetEntityIdIsInTeam(characterId)
        if self.ImgInFight then
            self.ImgInFight.gameObject:SetActiveEx(not isInTeam)
        end
    else
        if self.ImgInFight then
            self.ImgInFight.gameObject:SetActiveEx(false)
        end
    end
    -- 初始品质
    if self.ImgQuality then
        ---@type XCharacterAgency
        local ag = XMVCA:GetAgency(ModuleId.XCharacter)
        local initQualityCfg = ag:GetModelCharacterQualityIcon(ag:GetCharacterInitialQuality(entity:GetId()))
        self.ImgQuality:SetSprite(initQualityCfg.IconCharacterInit)
    end
end

local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
---@class XUiCharacterTowerBattleRoomRoleDetail : XUiBattleRoomRoleDetailDefaultProxy
local XUiCharacterTowerBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiCharacterTowerBattleRoomRoleDetail")

function XUiCharacterTowerBattleRoomRoleDetail:Ctor(stageId, team, pos)
    self.StageId = stageId
    self.Pos = pos
    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
    local chapterId = stageInfo.ChapterId
    ---@type XCharacterTowerChapter
    local chapterViewModel = XDataCenter.CharacterTowerManager.GetCharacterTowerChapter(chapterId)
    self.CharacterId = chapterViewModel:GetChapterCharacterId()
end

function XUiCharacterTowerBattleRoomRoleDetail:GetGridProxy()
    return XUiCharacterTowerBattleRoomRoleGrid
end

function XUiCharacterTowerBattleRoomRoleDetail:GetFilterControllerConfig()
    ---@type XCharacterAgency
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    return characterAgency:GetModelCharacterFilterController()["UiCharacterTowerBattle"]
end

function XUiCharacterTowerBattleRoomRoleDetail:GetFilterSortOverrideFunTable()
    return {
        CheckFunList = {
            -- 必现出战
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isInFightA = self.CharacterId == idA
                local isInFightB = self.CharacterId == idB
                if isInFightA ~= isInFightB then
                    return true
                end
            end
        },
        SortFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local isInFightA = self.CharacterId == idA
                local isInFightB = self.CharacterId == idB
                if isInFightA ~= isInFightB then
                    return isInFightA
                end
            end
        }
    }
end

return XUiCharacterTowerBattleRoomRoleDetail