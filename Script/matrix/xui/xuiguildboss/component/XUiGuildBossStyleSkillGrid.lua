--工会boss技能grid组件
local XUiGuildBossStyleSkillGrid = XClass(nil, "XUiGuildBossStyleSkillGrid")

function XUiGuildBossStyleSkillGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end

--- func desc
---@param styleSkillConfig 表数据
---@param isActive 该技能是否激活
---@param isSelect 该技能的流派是否被选择
function XUiGuildBossStyleSkillGrid:Init(styleSkillConfig, isActive, isSelect)
    self.Config = styleSkillConfig
    self.TxtName.text = styleSkillConfig.Name
    self.Icon:SetRawImage(styleSkillConfig.Icon)
    self.BgTagActive.gameObject:SetActiveEx(isActive)
    local isFixed = styleSkillConfig.IsPermanent and styleSkillConfig.IsPermanent > 0
    self.BgTagFix.gameObject:SetActiveEx(isFixed)

    -- 未激活的把icon置灰（调透明度）
    local tempColor = self.Icon.color
    tempColor.a = (isActive or isFixed) and 1 or 0.7
    self.Icon.color = tempColor

    -- 公会等级解锁
    local guildLevel = XDataCenter.GuildManager.GetGuildLevel()
    local isLock = guildLevel < styleSkillConfig.UnlockLv
    self.Lock.gameObject:SetActiveEx(isLock)

    -- 按钮
    self.BtnSkill.CallBack = function ()
        XLuaUiManager.Open("UiGuildBossSkillDetails", styleSkillConfig, isActive, isLock, isSelect)
    end
end

return XUiGuildBossStyleSkillGrid