--白情约会小游戏活动角色管理器
local XWhiteValentineCharaManager = XClass(nil, "XWhiteValentineCharaManager")
--==================
--角色列表排序方法(只比较配置ID)
--@param chara1,chara2:比较的角色
--==================
local SortCharaListByCharaId = function(chara1, chara2)
    if chara1:GetAttrType() ~= chara2:GetAttrType() then
        return chara1:GetAttrType() < chara2:GetAttrType()
    elseif chara1:GetAttrValue() ~= chara2:GetAttrValue() then
        return chara1:GetAttrValue() > chara2:GetAttrValue()
    else
        return chara1:GetCharaId() < chara2:GetCharaId()
    end
end
--==================
--构造函数
--==================
function XWhiteValentineCharaManager:Ctor(Game)
    self.Game = Game
    self:InitCharas()
end
--==================
--初始化所有角色
--==================
function XWhiteValentineCharaManager:InitCharas()
    self.Charas = {}
    local allChara = XWhiteValentineConfig.GetAllWhiteValentineChara()
    local XChara = require("XEntity/XMiniGame/WhiteValentine2021/XWhiteValentineChara")
    for _, charaData in pairs(allChara) do
        local newChara = XChara.New(self, charaData.Id)
        self.Charas[charaData.Id] = newChara
    end
end
--==================
--刷新数据
--@param CharaDb:CharaData列表。CharaData = {int Id //角色ID
--                  long EventEndTime //结束时间戳,0 表示未派遣角色
--                  int FinishEventCount //此角色的完成事件计数}
--==================
function XWhiteValentineCharaManager:RefreshData(CharaDb)
    if not CharaDb then return end
    for _, charaData in pairs(CharaDb) do
        local chara = self.Charas[charaData.Id]
        if chara then chara:RefreshData(charaData) end
    end
end
--==================
--添加新成员
--@param charaId:角色Id
--==================
function XWhiteValentineCharaManager:AddNewChara(charaId)
    local chara = self.Charas[charaId]
    chara:SetInTeam(true)
end
--==================
--刷新单个成员数据
--@param charaData:成员数据 = {int Id //角色ID
--                  long EventEndTime //结束时间戳,0 表示未派遣角色
--                  int FinishEventCount //此角色的完成事件计数}
--==================
function XWhiteValentineCharaManager:RefreshChara(charaData)
    local chara = self.Charas[charaData.Id]
    if not chara then return end
    chara:RefreshData(charaData)
end
--==================
--获取成员对象
--@param charaId:角色Id
--==================
function XWhiteValentineCharaManager:GetChara(charaId)
    if not charaId then return nil end
    return self.Charas[charaId]
end
--==================
--获取所有已被邀请的成员对象
--==================
function XWhiteValentineCharaManager:GetAllInTeamChara()
    local charaList = {}
    for _, chara in pairs(self.Charas) do
        if chara:GetInTeam() then
            table.insert(charaList, chara)
        end
    end
    return charaList
end
--==================
--获取所有没被邀请的成员对象
--==================
function XWhiteValentineCharaManager:GetAllOutTeamChara()
    local charaList = {}
    for _, chara in pairs(self.Charas) do
        if not chara:GetInTeam() then
            table.insert(charaList, chara)
        end
    end
    table.sort(charaList, SortCharaListByCharaId)
    return charaList
end
--==================
--获取根据角色ID与派遣状况排列的角色列表
--==================
function XWhiteValentineCharaManager:GetCharaListSortByDispatching(attrType)
    local charaList = {}
    local attrCharaList = {}
    local otherCharaList = {}
    local dispatchingCharaList = {}
    for _, chara in pairs(self:GetAllInTeamChara()) do
        if chara:GetDispatching() then
            table.insert(dispatchingCharaList, chara)
        elseif chara:GetAttrType() == attrType then
            table.insert(attrCharaList, chara)
        else
            table.insert(otherCharaList, chara)
        end
    end
    table.sort(attrCharaList, SortCharaListByCharaId)
    table.sort(otherCharaList, SortCharaListByCharaId)
    table.sort(dispatchingCharaList, SortCharaListByCharaId)
    for _, chara in pairs(attrCharaList) do
        table.insert(charaList, chara)
    end
    for _, chara in pairs(otherCharaList) do
        table.insert(charaList, chara)
    end
    for _, chara in pairs(dispatchingCharaList) do
        table.insert(charaList, chara)
    end
    return charaList
end
--==================
--获取根据角色属性排列的邀约角色列表
--==================
function XWhiteValentineCharaManager:GetOutTeamCharaByAttrType(attrType)
    local charaList = {}
    local allChara = self:GetAllOutTeamChara()
    for _, chara in pairs(allChara) do
        if chara:GetAttrType() == attrType then
            table.insert(charaList, chara)
        end
    end
    return charaList
end
--==================
--检查是否有未邀约的角色
--==================
function XWhiteValentineCharaManager:CheckOutTeamCharaExist()
    for _, chara in pairs(self.Charas) do
        if not chara:GetInTeam() then
            return true
        end
    end
    return false
end

return XWhiteValentineCharaManager