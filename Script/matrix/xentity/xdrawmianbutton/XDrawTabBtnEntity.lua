local XDrawTabBtnEntity = XClass(nil, "XDrawTabBtnEntity")

function XDrawTabBtnEntity:Ctor(id)
    self.Id = id
    self.DrawGroupList = {}
end

function XDrawTabBtnEntity:GetCfg()
    return XDrawConfigs.GetDrawTabById(self.Id)
end

function XDrawTabBtnEntity:GetId()
    return self.Id
end

function XDrawTabBtnEntity:GetDrawGroupList()
    return self.DrawGroupList
end

function XDrawTabBtnEntity:GetRuleType()
    return XDrawConfigs.RuleType.Tab
end

function XDrawTabBtnEntity:GetTxtName1()
    return self:GetCfg().TxtName1
end

function XDrawTabBtnEntity:GetTxtName2()
    return self:GetCfg().TxtName2
end

function XDrawTabBtnEntity:GetTxtName3()
    return self:GetCfg().TxtName3
end

function XDrawTabBtnEntity:GetTxtTagName()--暂时没用
    return self:GetCfg().TxtTagName
end

function XDrawTabBtnEntity:GetTabBg()
    return self:GetCfg().TabBg
end

function XDrawTabBtnEntity:GetPriority()
    return self:GetCfg().Priority
end

function XDrawTabBtnEntity:GetParentName()
    return self:GetCfg().ParentName
end

function XDrawTabBtnEntity:GetConditions()
    return self:GetCfg().Condition
end

function XDrawTabBtnEntity:JudgeCanOpen(IsShowHint)
    local IsOpen = true
    local desc = ""
    for _, v in pairs(self:GetConditions()) do
        if v and v ~= 0 then
            IsOpen,desc = XConditionManager.CheckCondition(v)
            if not IsOpen then
                break
            end
        end
    end
    if IsShowHint then
        if not IsOpen then
            XUiManager.TipError(desc)
        end
        return IsOpen
    else
        return IsOpen
    end
end

function XDrawTabBtnEntity:InsertDrawGroupList(data)
    self.DrawGroupList = self.DrawGroupList or {}
    table.insert(self.DrawGroupList, data)
end

function XDrawTabBtnEntity:DoSelect()
    return self:JudgeCanOpen(true)
end

function XDrawTabBtnEntity:IsShowTag()
    local IsShowNewTag = false
    local IsUnLock = self:JudgeCanOpen(false)

    if IsUnLock then
        for _, drawGroupInfo in pairs(self.DrawGroupList or {}) do
            if drawGroupInfo:GetBannerBeginTime() > 0 then
                if XDataCenter.DrawManager.IsShowNewTag(drawGroupInfo:GetBannerBeginTime(), drawGroupInfo:GetRuleType(), drawGroupInfo:GetId()) then
                    IsShowNewTag = true
                    break
                end
            end
        end
    end
    return IsShowNewTag
end

function XDrawTabBtnEntity:IsMainButton()
    return true
end

return XDrawTabBtnEntity