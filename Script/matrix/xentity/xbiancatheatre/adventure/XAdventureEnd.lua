local XAdventureRole = require("XEntity/XBiancaTheatre/Adventure/XAdventureRole")

---@class XBiancaTheatreAdventureEnd
local XAdventureEnd = XClass(nil, "XAdventureEnd")

function XAdventureEnd:Ctor(id)
    self.Config = XBiancaTheatreConfigs.GetBiancaTheatreEnding(id)
    -- TheatreAdventureSettleData
    self.SettleData = nil
    self.CurrentRoles = {}
    self.Items = {}
    self.AveragePower = 0   --已招募角色的平均战力
end

function XAdventureEnd:InitWithServerData(settleData)
    self.SettleData = settleData
    self:UpdateCharacters(settleData.Characters)
    self:UpdateItems(settleData.Items)
end

--更新本局拥有道具
function XAdventureEnd:UpdateItems(items)
    for index, value in ipairs(items) do
        table.insert(self.Items, value.ItemId)
    end
end

--更新已招募角色、计算平均战力
function XAdventureEnd:UpdateCharacters(characters)
    local adventureRole
    local totalPower = 0
    for index, value in ipairs(characters) do
        adventureRole = XAdventureRole.New(value.CharacterId)
        adventureRole:UpdateLevel(value.Level)
        totalPower = totalPower + adventureRole:GetAbility()
        table.insert(self.CurrentRoles, adventureRole)
    end

    local characterCount = #characters
    self.AveragePower = XTool.IsNumberValid(characterCount) and math.floor(totalPower / characterCount) or 0
end

function XAdventureEnd:GetActiveComboList()
    return XDataCenter.BiancaTheatreManager.GetComboList():GetActiveComboList(nil, self.CurrentRoles)
end

function XAdventureEnd:GetCurrentRoles()
    return self.CurrentRoles
end

--已招募角色
function XAdventureEnd:GetRolesCount()
    return #self.CurrentRoles
end

--已招募角色的平均战力
function XAdventureEnd:GetRoleAveragePower()
    return self.AveragePower
end

function XAdventureEnd:GetTitle()
    return self.Config.Name
end

function XAdventureEnd:GetDesc()
    return self.Config.Desc
end

function XAdventureEnd:GetStoryId()
    return self.Config.StoryId
end

function XAdventureEnd:GetRImgDesc()
    return self.Config.RImgDesc
end

function XAdventureEnd:GetBg()
    return self.Config.Bg
end

function XAdventureEnd:GetSpineBg()
    return self.Config.SpineBg
end

function XAdventureEnd:GetRImgTitle()
    return self.Config.RImgTitle
end

function XAdventureEnd:GetIcon()
    return self.Config.Icon
end

function XAdventureEnd:GetIconBg()
    return self.Config.IconBg
end

function XAdventureEnd:GetBgmCueId()
    return self.Config.BgmCueId
end

--完成节点数
function XAdventureEnd:GetNodeCount()
    return self.SettleData.NodeCount
end

--战斗节点数
function XAdventureEnd:GetFightNodeCount()
    return self.SettleData.FightNodeCount
end

--角色总星级数
function XAdventureEnd:GetTotalCharacterLevel()
    return self.SettleData.TotalCharacterLevel
end

--道具总数量
function XAdventureEnd:GetTotalItemCount()
    return self.SettleData.TotalItemCount
end

--完成章节数
function XAdventureEnd:GetChapterCount()
    return self.SettleData.ChapterCount
end

--完成节点数——分数
function XAdventureEnd:GetNodeCountScore()
    return self.SettleData.NodeCountScore
end

--角色总星级数——分数
function XAdventureEnd:GetTotalCharacterLevelScore()
    return self.SettleData.TotalCharacterLevelScore
end

--道具总数量——分数
function XAdventureEnd:GetTotalItemCountScore()
    return self.SettleData.TotalItemCountScore
end

--完成章节数——分数
function XAdventureEnd:GetChapterCountScore()
    return self.SettleData.ChapterCountScore
end

--积分合计
function XAdventureEnd:GetTotalScore()
    return self.SettleData.TotalScore
end

--结局ID
function XAdventureEnd:GetEndId()
    return self.SettleData.EndId
end

--结局倍率
function XAdventureEnd:GetEndFactor()
    return string.format("%0.1f", self.SettleData.EndFactor)
end

--困难难度倍率
function XAdventureEnd:GetDifficultyFactor()
    return self.SettleData.DifficultyFactor
end

--等级经验奖励
function XAdventureEnd:GetTotalExp()
    return self.SettleData.TotalExp
end

--外循环材料奖励
function XAdventureEnd:GetOutItemCount()
    return self.SettleData.OutItemCount
end

--使用分队ID
function XAdventureEnd:GetTeamId()
    return self.SettleData.TeamId
end

--已招募角色 XBiancaTheatreCharacter
function XAdventureEnd:GetCharacters()
    return self.SettleData.Characters
end

--本局拥有道具 XBiancaTheatreItem
function XAdventureEnd:GetItems()
    return self.Items
end

function XAdventureEnd:GetIsNewEnd()
    return self.SettleData.NewEnding or false
end

function XAdventureEnd:GetIsNewScore()
    return self.SettleData.NewRecord or false
end

function XAdventureEnd:GetUnlockPowerFavorIds()
    return self.SettleData.UnlockPowerFavorIds
end

function XAdventureEnd:GetScoreDatas()
    return {
        {
            --完成节点数
            Name = XBiancaTheatreConfigs.GetClientConfig("SettleDataName", 1),
            Count = self.SettleData.NodeCount,
            Score = self.SettleData.NodeCountScore,
        },
        {
            --战斗节点数
            Name = XBiancaTheatreConfigs.GetClientConfig("SettleDataName", 2),
            Count = self.SettleData.FightNodeCount,
            Score = self.SettleData.FightNodeCountScore,
        },
        {
            --角色总星级数
            Name = XBiancaTheatreConfigs.GetClientConfig("SettleDataName", 3),
            Count = self.SettleData.TotalCharacterLevel,
            Score = self.SettleData.TotalCharacterLevelScore,
        },
        {
            --道具总数量
            Name = XBiancaTheatreConfigs.GetClientConfig("SettleDataName", 4),
            Count = self.SettleData.TotalItemCount,
            Score = self.SettleData.TotalItemCountScore,
        },
        {
            --完成章节数
            Name = XBiancaTheatreConfigs.GetClientConfig("SettleDataName", 5),
            Count = self.SettleData.ChapterCount,
            Score = self.SettleData.ChapterCountScore,
        },
    }
end

return XAdventureEnd