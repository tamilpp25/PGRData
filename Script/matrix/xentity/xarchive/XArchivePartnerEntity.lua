local XPartnerBase = require("XEntity/XPartner/XPartnerBase")
local XArchivePartnerEntity = XClass(XPartnerBase, "XArchivePartnerEntity")

function XArchivePartnerEntity:Ctor(id, storyEntityList, settingEntityList)
    self.Id = id
    self.TemplateId = id--伙伴Id
    self.IsArchiveLock = true
    self.StoryEntityDic = {}
    self.StorySettingDic = {}
-------------------------------------------------

    self:CreateStoryEntityDic(storyEntityList)
    self:CreateSettingEntityDic(settingEntityList)
end

function XArchivePartnerEntity:UpdateData(data)
    for key, value in pairs(data or {}) do
        self[key] = value
    end
end

-------------------------宠物功能属性--------------------------
function XArchivePartnerEntity:GetId()
    return self.Id
end

function XArchivePartnerEntity:GetTemplateId()
    return self.TemplateId
end

function XArchivePartnerEntity:GetIsArchiveLock()
    return self.IsArchiveLock
end

----------------------------宠物图鉴基础属性--------------------------------
function XArchivePartnerEntity:GetArchivePartnerCfg()
    return XArchiveConfigs.GetPartnerConfigById(self.TemplateId)
end

function XArchivePartnerEntity:GetGroupId()
    return self:GetArchivePartnerCfg().GroupId
end

function XArchivePartnerEntity:GetOrder()
    return self:GetArchivePartnerCfg().Order
end

function XArchivePartnerEntity:GetLockIcon()
    return self:GetArchivePartnerCfg().LockIconPath
end

function XArchivePartnerEntity:GetIcon()
    return self:GetArchivePartnerCfg().IconPath
end

function XArchivePartnerEntity:GetStoryChapterId()
    return self:GetArchivePartnerCfg().StoryChapterId
end

-------------------------------------宠物故事---------------------------------

function XArchivePartnerEntity:CreateStoryEntityDic(storyEntityList)
    self.StoryEntityDic = {}
    for _,Entity in pairs(storyEntityList or {}) do
        self.StoryEntityDic[Entity:GetId()] = Entity
    end
end

function XArchivePartnerEntity:CreateSettingEntityDic(settingEntityList)
    self.StorySettingDic = {}
    for _,Entity in pairs(settingEntityList or {}) do
        self.StorySettingDic[Entity:GetId()] = Entity
    end
end

function XArchivePartnerEntity:UpdateStoryAndSettingEntity(unLockStoryList)
    for _,id in pairs(unLockStoryList or {}) do
        if self.StoryEntityDic[id] then
            self.StoryEntityDic[id]:UpdateData({IsLock = false})
        end
        if self.StorySettingDic[id] then
            self.StorySettingDic[id]:UpdateData({IsLock = false})
        end
    end
end

return XArchivePartnerEntity