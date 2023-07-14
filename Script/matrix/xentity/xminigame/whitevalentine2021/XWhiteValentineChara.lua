-- 约会小游戏角色对象
local XWhiteValentineChara = XClass(nil, "XWhiteValentineChara")
--==========构造函数，初始化，实体操作==========
--==================
--构造函数
--==================
function XWhiteValentineChara:Ctor(CharaManager, CharaId, CharaData)
    self.CharaManager = CharaManager
    self:InitConfig(CharaId)
    self:RefreshData(CharaData)
end
--==================
--初始化配置
--==================
function XWhiteValentineChara:InitConfig(CharaId)
    self:ResetStatus()
    self.Config = XWhiteValentineConfig.GetWhiteValentineCharaByCharaId(CharaId)
    self.AttrCfg = XWhiteValentineConfig.GetWhiteValentineAttrById(self:GetAttrType())
end
--==================
--重置状态
--==================
function XWhiteValentineChara:ResetStatus()
    self.Dispatching = false
    self:SetInTeam(false)
    self:SetFinishEventCount(0)
end
--==================
--刷新数据
--@param CharaData:{int Id //角色ID，long EventEndTime //事件完成时间, int FinishEventCount //完成的事件次数}
--==================
function XWhiteValentineChara:RefreshData(CharaData)
    if not CharaData then return end
    self:SetInTeam(true)
    self.Dispatching = CharaData.EventEndTime > 0
    self:SetFinishEventCount(CharaData.FinishEventCount)
end
--=================== END =====================
--=================Get,Set,Check================
--==================
--获取游戏ID
--==================
function XWhiteValentineChara:GetGameId()
    return self.CharaManager:GetGameId()
end
--==================
--获取角色ID
--==================
function XWhiteValentineChara:GetCharaId()
    return self.Config and self.Config.Id
end
--==================
--获取角色名
--==================
function XWhiteValentineChara:GetName()
    return self.Config and self.Config.Name
end
--==================
--获取角色图标
--==================
function XWhiteValentineChara:GetIconPath()
    return self.Config and self.Config.IconPath
end
--==================
--获取角色属性类型
--==================
function XWhiteValentineChara:GetAttrType()
    return self.Config and self.Config.AttrType
end
--==================
--获取角色属性数值
--==================
function XWhiteValentineChara:GetAttrValue()
    return self.Config and self.Config.AttrValue
end
--==================
--获取角色属性图标
--==================
function XWhiteValentineChara:GetAttrIcon()
    return self.AttrCfg and self.AttrCfg.IconPath
end
--==================
--获取偶遇约会ID
--==================
function XWhiteValentineChara:GetEncounterStoryId()
    return self.Config and self.Config.EncounterStoryId
end
--==================
--获取邀约约会ID
--==================
function XWhiteValentineChara:GetInviteStoryId()
    return self.Config and self.Config.InviteStoryId
end
--==================
--获取约会故事配置
--@param storyType:WhiteValentineManager.StoryType 故事类型
--==================
function XWhiteValentineChara:GetStoryByStoryType(storyType)
    local storyName = XDataCenter.WhiteValentineManager.StoryTypeName[storyType]
    local storyId = storyName and 0 or -1
    if storyId == -1 then return nil end
    if self["Get" .. storyName .. "StoryId"] then
        storyId = self["Get" .. storyName .. "StoryId"](self)
    end
    local storyCfg = XWhiteValentineConfig.GetWhiteValentineStoryById(storyId)
    return storyCfg
end
--==================
--获取特殊通讯ID
--==================
function XWhiteValentineChara:GetCommuId()
    return self.Config and self.Config.CommuId
end
--==================
--获取节省时间百分比
--==================
function XWhiteValentineChara:GetCutDownTime()
    return self.Config and self.Config.CutDownTime
end
--==================
--获取增加贡献值奖励百分比
--==================
function XWhiteValentineChara:GetContributionBuff()
    return self.Config and self.Config.ContributionBuff
end
--==================
--设置已完成约会数目
--==================
function XWhiteValentineChara:SetFinishEventCount(finishEventCount)
    if not finishEventCount then return end
    if finishEventCount < 0 then finishEventCount = 0 end
    self.FinishEventCount = finishEventCount
end
--==================
--获取角色是否已获取
--==================
function XWhiteValentineChara:GetInTeam()
    return self.InTeam
end
--==================
--设置角色获取状态
--==================
function XWhiteValentineChara:SetInTeam(isInTeam)
    self.InTeam = isInTeam
end
--==================
--获取角色是否已派遣
--==================
function XWhiteValentineChara:GetDispatching()
    return self.Dispatching
end
--=================== END =====================
return XWhiteValentineChara