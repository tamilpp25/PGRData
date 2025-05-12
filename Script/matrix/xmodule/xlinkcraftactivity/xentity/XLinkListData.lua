--- 链条的数据存储对象，用于存储和管理一条链条的信息
---@class XLinkListData
local XLinkListData = XClass(nil, 'XLinkListData')

function XLinkListData:Ctor(data)
    self._Id = data.LinkId
    self._IsUsing = data.IsUsing
    
    self._SkillData = data.Skills  and data.Skills  or {}
end

function XLinkListData:IsUsing()
    return self._IsUsing
end

function XLinkListData:Select()
    self._IsUsing = true
end

function XLinkListData:Unselect()
    self._IsUsing = false
end

function XLinkListData:GetId()
    return self._Id
end

function XLinkListData:SetSkill(index, skillId)
    self._SkillData[index] = skillId
end

function XLinkListData:CheckIsSkillUsing(skillId)
    for index, v in pairs(self._SkillData) do
        if v == skillId then
            return true, index
        end
    end
    return false, 0
end

--获取链条技能，会克隆新表，防止外部修改
function XLinkListData:GetSkillList()
    local newList = {}
    for i, v in ipairs(self._SkillData) do
        table.insert(newList,v)
    end
    return newList
end

return XLinkListData