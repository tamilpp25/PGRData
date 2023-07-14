---@class XDormQuest
local XDormQuest = XClass(nil, "XDormQuest")

function XDormQuest:Ctor(id)
    self:UpdateData(id)
end

function XDormQuest:UpdateData(id)
    self.Id = id
    self.Config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.Quest, id)
end

-- 委托名称
function XDormQuest:GetQuestName()
    return self.Config.Name or ""
end

-- 委托类型
function XDormQuest:GetQuestType()
    return self.Config.Type
end

-- 委托内容
function XDormQuest:GetQuestContent()
    return self.Config.Content or ""
end

-- 委托等级
function XDormQuest:GetQuestQuality()
    return self.Config.Quality
end

-- 发布势力
function XDormQuest:GetQuestAnnouncer()
    return self.Config.Announcer
end

-- 队伍成员数量要求
function XDormQuest:GetQuestMemberCount()
    return self.Config.MemberCount
end

-- 完成所需时间
function XDormQuest:GetQuestNeedTime()
    return self.Config.NeedTime or 0
end

-- 额外奖励推荐属性
function XDormQuest:GetQuestRecommendAttrib()
    return self.Config.RecommendAttrib or {}
end

-- 完成奖励
function XDormQuest:GetQuestFinishReward()
    return self.Config.FinishReward or 0
end

-- 额外奖励
function XDormQuest:GetQuestExtraReward()
    return self.Config.ExtraReward or 0
end

return XDormQuest