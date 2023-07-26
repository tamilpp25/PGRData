local XAdventureEnd = XClass(nil, "XAdventureEnd")

function XAdventureEnd:Ctor(id)
    self.Config = XTheatreConfigs.GetTheatreEnding(id)
    -- TheatreAdventureSettleData
    self.SettleData = nil
end

function XAdventureEnd:InitWithServerData(settleData)
    self.SettleData = settleData
end

function XAdventureEnd:GetTitle()
    return self.Config.Name
end

function XAdventureEnd:GetDesc()
    return self.Config.Desc
end

function XAdventureEnd:GetIsNewEnd()
    return self.SettleData.NewEnding
end

function XAdventureEnd:GetIsNewScore()
    return self.SettleData.NewRecord
end

function XAdventureEnd:GetTotalScore()
    return self.SettleData.TotalPoint
end

function XAdventureEnd:GetUnlockPowerFavorIds()
    return self.SettleData.UnlockPowerFavorIds
end

function XAdventureEnd:GetRewardItemDatas()
    local result = {}
    -- if self.SettleData.ActivityCoin > 0 then
    --     table.insert(result, {
    --         TemplateId = XTheatreConfigs.TheatreCoin,
    --         Count = self.SettleData.ActivityCoin
    --     })
    -- end
    if self.SettleData.FavorCoin > 0 then
        table.insert(result, {
            TemplateId = XTheatreConfigs.TheatreFavorCoin,
            Count = self.SettleData.FavorCoin
        })
    end
    if self.SettleData.DecorationCoin > 0 then
        table.insert(result, {
            TemplateId = XTheatreConfigs.TheatreDecorationCoin,
            Count = self.SettleData.DecorationCoin
        })
    end
    return result
end

function XAdventureEnd:GetScoreDatas()
    return {
        {
            Name = XUiHelper.GetText("TheatrePassNode"),
            Count = self.SettleData.SettleNodeCount,
            Score = self.SettleData.SettleNodeCountPoint,
        },
        {
            Name = XUiHelper.GetText("TheatrePassFight"),
            Count = self.SettleData.SettleFightCount,
            Score = self.SettleData.SettleFightCountPoint,
        },
        {
            Name = XUiHelper.GetText("TheatrePassEvent"),
            Count = self.SettleData.SettleEventCount,
            Score = self.SettleData.SettleEventCountPoint,
        },
        {
            Name = XUiHelper.GetText("TheatrePassBoss"),
            Count = self.SettleData.SettleBossCount,
            Score = self.SettleData.SettleBossCountPoint,
        },
        {
            Name = XUiHelper.GetText("TheatrePassReopen"),
            Count = self.SettleData.SettleLeftReopenCount,
            Score = self.SettleData.SettleLeftReopenCountPoint,
        },
    }
end

return XAdventureEnd