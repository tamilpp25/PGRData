--######################## XUiRoleGrid ########################
local XUiBattleRoomRoleGrid = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleGrid")
local XUiRoleGrid = XClass(XUiBattleRoomRoleGrid, "XUiRoleGrid")

function XUiRoleGrid:SetData(entity, team, stageId)
    XUiRoleGrid.Super.SetData(self, entity, team, stageId)
    self.RImgUpIcon.gameObject:SetActiveEx(
        XDataCenter.GuildWarManager.CheckIsSpecialRole(entity:GetId()))
end

--######################## XUiChildPanel ########################
local XUiChildPanel = XClass(nil, "XUiChildPanel")

function XUiChildPanel:Ctor(ui)
    self.GuildWarManager = XDataCenter.GuildWarManager
    XUiHelper.InitUiClass(self, ui)
end

function XUiChildPanel:SetData(currentEntityId)
    local isSpecial = self.GuildWarManager.CheckIsSpecialRole(currentEntityId)
    self.GameObject:SetActiveEx(isSpecial)
    if not isSpecial then return end
    local buffData = self.GuildWarManager.GetSpecialRoleBuff(currentEntityId)
    if buffData == nil then return end
    self.RImgSkillIcon:SetRawImage(buffData.Icon)
    self.TxtSkillDesc.text = buffData.Desc
end

--######################## XUiGuildWarBattleRoomRoleDetail ########################
local XUiBattleRoomRoleDetailDefaultProxy = require("XUi/XUiNewRoomSingle/XUiBattleRoomRoleDetailDefaultProxy")
local XUiGuildWarBattleRoomRoleDetail = XClass(XUiBattleRoomRoleDetailDefaultProxy, "XUiGuildWarBattleRoomRoleDetail")

function XUiGuildWarBattleRoomRoleDetail:Ctor()
    self.GuildWarManager = XDataCenter.GuildWarManager
    self.BattleManager = self.GuildWarManager.GetBattleManager()
end

-- 获取实体数据
-- characterType : XEnumConst.CHARACTER.CharacterType 参数为空时要返回所有实体
-- return : { ... }
function XUiGuildWarBattleRoomRoleDetail:GetEntities(characterType)
    local result = XMVCA.XCharacter:GetOwnCharacterList(characterType)
    appendArray(result, self.BattleManager:GetRobots(characterType))
    return result
end

-- 获取子面板数据，主要用来增加编队界面自身玩法信息，就不用污染通用的预制体
--[[
    return : {
        assetPath : 资源路径
        proxy : 子面板代理
        proxyArgs : 子面板SetData传入的参数列表
    }
]]
function XUiGuildWarBattleRoomRoleDetail:GetChildPanelData()
    return {
        assetPath = XUiConfigs.GetComponentUrl("UpCharacterSkill"),
        proxy = XUiChildPanel,
        proxyArgs = { "CurrentEntityId" },
    }
end

-- 获取左边角色格子代理，默认为XUiBattleRoomRoleGrid
-- 如果只是做一些简单的显示，比如等级读取自定义，可以直接使用AOPOnDynamicTableEventAfter接口去处理也可以
-- return : 继承自XUiBattleRoomRoleGrid的类
function XUiGuildWarBattleRoomRoleDetail:GetGridProxy()
    return XUiRoleGrid
end

-- return : bool 是否开启自动关闭检查, number 自动关闭的时间戳(秒), function 每秒更新的回调 function(isClose) isClose标志是否到达结束时间
function XUiGuildWarBattleRoomRoleDetail:GetAutoCloseInfo()
    return true, self.GuildWarManager.GetRoundEndTime(), function(isClose)
        if isClose then
            self.GuildWarManager.OnActivityEndHandler()
        end
    end
end

return XUiGuildWarBattleRoomRoleDetail