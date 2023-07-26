local XMaintainerActionGameDataEntity = XClass(nil, "XMaintainerActionGameDataEntity")
local CSTextManagerGetText = CS.XTextManager.GetText

function XMaintainerActionGameDataEntity:Ctor()
    self.Id = 1--服务器发来的数据会更新
    self.Cards = {}
    self.FightWinCount = 0
    self.BoxCount = 0
    self.UsedActionCount = 0
    self.ExtraActionCount = 0
    self.ResetTime = 0
    self.HasWarehouseNode = false
    self.WarehouseFinishCount = 0
    self.HasMentorNode = false
    --添加字段需要在管理器的数据创建方法中添加相关的赋值
    self.MentorStatus = XMaintainerActionConfigs.MonterNodeStatus.NotActive
end

function XMaintainerActionGameDataEntity:UpdateData(Data)
    for key, value in pairs(Data) do
        self[key] = value
    end
end

function XMaintainerActionGameDataEntity:GetId()
    return self.Id
end

function XMaintainerActionGameDataEntity:GetResetTime()
    return self.ResetTime
end

function XMaintainerActionGameDataEntity:GetCards()
    return self.Cards
end

function XMaintainerActionGameDataEntity:GetFightWinCount()
    return self.FightWinCount
end

function XMaintainerActionGameDataEntity:GetBoxCount()
    return self.BoxCount
end

function XMaintainerActionGameDataEntity:GetUsedActionCount()
    return self.UsedActionCount
end

function XMaintainerActionGameDataEntity:GetExtraActionCount()
    return self.ExtraActionCount
end

function XMaintainerActionGameDataEntity:GetHasWarehouseNode()
    return self.HasWarehouseNode
end

function XMaintainerActionGameDataEntity:GetWarehouseFinishCount()
    return self.WarehouseFinishCount
end

function XMaintainerActionGameDataEntity:GetHasMentorNode()
    return self.HasMentorNode
end

function XMaintainerActionGameDataEntity:GetMentorStatus()
    return self.MentorStatus
end

function XMaintainerActionGameDataEntity:GetCfg()
    return XMaintainerActionConfigs.GetMaintainerActionTemplateById(self.Id)
end

function XMaintainerActionGameDataEntity:GetTimeId()
    return self:GetCfg().TimeId
end

function XMaintainerActionGameDataEntity:GetName()
    return self:GetCfg().Name
end

function XMaintainerActionGameDataEntity:GetStoryId()
    return self:GetCfg().StoryId
end

function XMaintainerActionGameDataEntity:GetMaxDailyActionCount()
    return self:GetCfg().MaxDailyActionCount
end

function XMaintainerActionGameDataEntity:GetMaxFightWinCount()
    return self:GetCfg().MaxFightWinCount
end

function XMaintainerActionGameDataEntity:GetMaxBoxCount()
    return self:GetCfg().MaxBoxCount
end

function XMaintainerActionGameDataEntity:GetMaxWarehouseFinishCount()
    return self:GetCfg().MaxWarehouseFinishCount
end

function XMaintainerActionGameDataEntity:GetTeacherMailId()
    return self:GetCfg().TeacherMailId
end

function XMaintainerActionGameDataEntity:GetStudentMailId()
    return self:GetCfg().StudentMailId
end

function XMaintainerActionGameDataEntity:PlusExtraActionCount(num)
    self.ExtraActionCount = self.ExtraActionCount + num
end

function XMaintainerActionGameDataEntity:PlusBoxCount()
    self.BoxCount = self.BoxCount + 1
end

function XMaintainerActionGameDataEntity:PlusFightWinCount()
    self.FightWinCount = self.FightWinCount + 1
end

function XMaintainerActionGameDataEntity:PlusWarehouseFinishCount()
    self.WarehouseFinishCount = self.WarehouseFinishCount + 1
end

function XMaintainerActionGameDataEntity:SetMentorStatus(status)
    self.MentorStatus = status
end

function XMaintainerActionGameDataEntity:CardChange(oldCard,newCard)
    for index,card in pairs(self.Cards) do
        if card == oldCard then
            table.remove(self.Cards, index)
            table.insert(self.Cards,newCard)
            break
        end
    end
end

function XMaintainerActionGameDataEntity:IsFightOver()
    return self:GetFightWinCount() >= self:GetMaxFightWinCount()
   
end

function XMaintainerActionGameDataEntity:IsBoxOver()
    return self:GetBoxCount() >= self:GetMaxBoxCount()
end

function XMaintainerActionGameDataEntity:IsWarehouseOver()
    return self:GetWarehouseFinishCount() >= self:GetMaxWarehouseFinishCount()
end

function XMaintainerActionGameDataEntity:IsMentorOver()
    return self:GetMentorStatus() == XMaintainerActionConfigs.MonterNodeStatus.Finish
end

return XMaintainerActionGameDataEntity