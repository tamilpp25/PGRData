-- 虚像地平线招募商店成员对象
local XExpeditionRecruitMembers = XClass(nil, "XExpeditionRecruitMembers")
local XChara = require("XEntity/XExpedition/XExpeditionCharacter")
--===================
--构造函数
--@param drawNum: 一次招募的数量
--===================
function XExpeditionRecruitMembers:Ctor(drawNum)
    self.DrawNum = drawNum
    self:InitMembers()
    self:Reset()
end
--===================
--重置状态
--===================
function XExpeditionRecruitMembers:Reset()
    self.IsPicked = false
    self.RecruitPos = -1
    self.IsBlank = true
end
--===================
--初始化招募角色列表
--===================
function XExpeditionRecruitMembers:InitMembers()
    self.Members = {}
    for i = 1, self.DrawNum do
        self.Members[i] = XChara.New()
    end
end
--===================
--初始化招募角色列表
--===================
function XExpeditionRecruitMembers:GetIsPicked()
    return self.IsPicked
end
--===================
--初始化招募角色列表
--===================
function XExpeditionRecruitMembers:SetIsPicked(isPicked)
    self.IsPicked = isPicked
end
--===================
--获取被招募角色的位置
--===================
function XExpeditionRecruitMembers:GetRecruitPos()
    return self.RecruitPos
end
--===================
--设置角色是否被招募
--===================
function XExpeditionRecruitMembers:SetRecruitPos(pos)
    self.RecruitPos = pos
    self:SetIsPicked(true)
end

function XExpeditionRecruitMembers:GetIsBlank()
    return self.IsBlank
end

function XExpeditionRecruitMembers:GetCharaByPos(pos)
    return self.Members[pos]
end
--===================
--重置招募角色
--===================
function XExpeditionRecruitMembers:ResetCharaData(pos, baseId, rank)
    local member = self:GetCharaByPos(pos)
    member:ResetData(rank)
    member:RefreshData(baseId)
end
return XExpeditionRecruitMembers