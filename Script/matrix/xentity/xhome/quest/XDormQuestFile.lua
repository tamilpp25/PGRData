---@class XDormQuestFile
local XDormQuestFile = XClass(nil, "XDormQuestFile")

function XDormQuestFile:Ctor(id)
    self:UpdateData(id)
end

function XDormQuestFile:UpdateData(id)
    self.Id = id
    self.Config = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestFile, id)
    self.DetailConfig = XDormQuestConfigs.GetCfgByIdKey(XDormQuestConfigs.TableKey.QuestFileDetail, id)
end

-- 发布势力
function XDormQuestFile:GetQuestFileAnnouncer()
    return self.Config.Announcer or 0
end

--region 委托文件详情

function XDormQuestFile:GetQuestFileDetailName()
    return self.DetailConfig.Name or ""
end

-- 装饰图片
function XDormQuestFile:GetQuestFileDetailCover()
    return self.DetailConfig.Cover or ""
end

function XDormQuestFile:GetQuestFileDetailGroupId()
    return self.DetailConfig.GroupId or 0
end

function XDormQuestFile:GetQuestFileDetailSubGroupId()
    return self.DetailConfig.SubGroupId or 0
end

function XDormQuestFile:GetQuestFileDetailTitle()
    return self.DetailConfig.Title or ""
end

-- 编辑人
function XDormQuestFile:GetQuestFileDetailEditor()
    return self.DetailConfig.Editor or ""
end

-- 审核人
function XDormQuestFile:GetQuestFileDetailApprover()
    return self.DetailConfig.Approver or ""
end

function XDormQuestFile:GetQuestFileDetailSubTitle()
    return self.DetailConfig.SubTitle or {}
end

function XDormQuestFile:GetQuestFileDetailSubContent()
    return self.DetailConfig.SubContent or {}
end

--endregion

return XDormQuestFile