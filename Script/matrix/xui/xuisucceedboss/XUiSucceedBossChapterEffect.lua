---@class XUiSucceedBossChapterEffect : XUiNode
---@field _Control XSucceedBossControl
local XUiSucceedBossChapterEffect = XClass(XUiNode, "XUiSucceedBossChapterEffect")

function XUiSucceedBossChapterEffect:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnGrid, self.OnClick)
    self.LevelBuffFightEventId = nil
end

function XUiSucceedBossChapterEffect:Update(levelConfig)
    local fightEventId = levelConfig.FightEventId
    local config = self._Control:GetFightEventShowConfig(fightEventId)
    if config then
        local icon  = config.Icon
        self.RImgIcon:SetRawImage(icon)
        self.LevelBuffFightEventId = levelConfig.FightEventId
    end
end

function XUiSucceedBossChapterEffect:OnClick()
    if not XTool.IsNumberValid(self.LevelBuffFightEventId) then
        return
    end
    local fightEventShowConfig = self._Control:GetFightEventShowConfig(self.LevelBuffFightEventId)
    XLuaUiManager.Open("UiReformBuffDetail", {
        Name = fightEventShowConfig.Name,
        Icon = fightEventShowConfig.Icon,
        Description = fightEventShowConfig.Desc,
    })
end

return XUiSucceedBossChapterEffect